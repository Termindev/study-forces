import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../stores/subject_store.dart';
import '../models/problem_session.dart';
import '../constants/app_constants.dart';
import '../components/common/form_field_wrapper.dart';
// Timer feature removed

class DecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow empty string
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Check if the new value is a valid decimal number
    final regex = RegExp(r'^\d*\.?\d*$');
    if (regex.hasMatch(newValue.text)) {
      return newValue;
    }

    // If not valid, return the old value
    return oldValue;
  }
}

class AddProblemSessionPage extends StatefulWidget {
  final int subjectId;
  final ProblemSession? existingSession;

  const AddProblemSessionPage({
    super.key,
    required this.subjectId,
    this.existingSession,
  });

  @override
  State<AddProblemSessionPage> createState() => _AddProblemSessionPageState();
}

class _AddProblemSessionPageState extends State<AddProblemSessionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _problemsAttemptedController =
      TextEditingController();
  final TextEditingController _problemsCorrectController =
      TextEditingController();
  final TextEditingController _durationMinutesController =
      TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  // Timer feature removed

  @override
  void initState() {
    super.initState();
    if (widget.existingSession != null) {
      _problemsAttemptedController.text = widget
          .existingSession!
          .problemsAttempted
          .toString();
      _problemsCorrectController.text = widget.existingSession!.problemsCorrect
          .toString();
      _durationMinutesController.text =
          (widget.existingSession!.durationSeconds / 60).toString();
      _selectedDate = widget.existingSession!.when;
    }
  }

  @override
  void dispose() {
    _problemsAttemptedController.dispose();
    _problemsCorrectController.dispose();
    _durationMinutesController.dispose();
    super.dispose();
  }

  // Validator for required numeric fields
  String? _requiredNumberValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final numValue = int.tryParse(value);
    if (numValue == null) {
      return '$fieldName must be a number';
    }
    if (numValue < 0) {
      return '$fieldName must be non-negative';
    }
    return null;
  }

  // Validator for duration (allows decimal values)
  String? _requiredDurationValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return '$fieldName must be a number';
    }
    if (numValue < 0) {
      return '$fieldName must be non-negative';
    }
    return null;
  }

  // Validator for problems correct (must be <= problems attempted)
  String? _problemsCorrectValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Problems correct is required';
    }
    final correct = int.tryParse(value);
    if (correct == null) {
      return 'Problems correct must be a number';
    }
    if (correct < 0) {
      return 'Problems correct must be non-negative';
    }

    final attempted = int.tryParse(_problemsAttemptedController.text);
    if (attempted != null && correct > attempted) {
      return 'Problems correct cannot exceed problems attempted';
    }
    return null;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Timer feature removed

  Future<void> _submitForm(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final store = Provider.of<SubjectStore>(context, listen: false);

      // Parse input values with proper error handling
      final problemsAttemptedText = _problemsAttemptedController.text.trim();
      final problemsCorrectText = _problemsCorrectController.text.trim();
      final durationMinutesText = _durationMinutesController.text.trim();

      final problemsAttempted = int.tryParse(problemsAttemptedText);
      final problemsCorrect = int.tryParse(problemsCorrectText);
      final durationMinutes = double.tryParse(durationMinutesText);

      // Validate parsed values
      if (problemsAttempted == null) {
        throw ArgumentError('Problems attempted must be a valid number');
      }
      if (problemsCorrect == null) {
        throw ArgumentError('Problems correct must be a valid number');
      }
      if (durationMinutes == null) {
        throw ArgumentError('Duration must be a valid number');
      }

      // Use the selected date (time is not relevant for rating algorithms)
      final sessionDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      if (widget.existingSession != null) {
        // Editing existing session - modify the existing session directly
        final existingSession = widget.existingSession!;
        print('DEBUG: Editing problem session ${existingSession.id}');
        print(
          'DEBUG: Before - attempted: ${existingSession.problemsAttempted}, correct: ${existingSession.problemsCorrect}, duration: ${existingSession.durationSeconds}',
        );

        existingSession.when = sessionDateTime;
        existingSession.problemsAttempted = problemsAttempted;
        existingSession.problemsCorrect = problemsCorrect;
        existingSession.durationSeconds = (durationMinutes * 60)
            .round(); // Convert minutes to seconds
        // Keep the existing applied status

        print(
          'DEBUG: After - attempted: ${existingSession.problemsAttempted}, correct: ${existingSession.problemsCorrect}, duration: ${existingSession.durationSeconds}',
        );

        await store.editProblemSessionSmartWithDateCheck(
          widget.subjectId,
          existingSession.id,
          existingSession,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Problem session updated')),
          );
        }
      } else {
        // Adding new session
        final session = ProblemSession.create(
          when: sessionDateTime,
          problemsAttempted: problemsAttempted,
          problemsCorrect: problemsCorrect,
          durationSeconds: (durationMinutes * 60)
              .round(), // Convert minutes to seconds
        );

        // Use smart add method that handles date checking automatically
        await store.addProblemSessionSmart(widget.subjectId, session);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Problem session added successfully')),
          );
        }
      }

      // Navigate back
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Show error message and trigger form validation to highlight errors
      if (mounted) {
        // Trigger form validation to show field errors
        _formKey.currentState?.validate();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingSession != null
                  ? 'Error updating problem session: ${e.toString()}'
                  : 'Error adding problem session: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingSession != null
              ? 'Edit Problem Session'
              : 'Add Problem Session',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Date Selection
              const Text(
                "Session Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppConstants.spacingM),

              // Date picker
              ListTile(
                title: const Text("Date"),
                subtitle: Text(
                  "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _isSubmitting ? null : _selectDate,
              ),

              const SizedBox(height: AppConstants.formSectionSpacing),

              // Manual Input Form
              const Text(
                "Problem Statistics",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppConstants.spacingM),

              FormFieldWrapper(
                child: TextFormField(
                  controller: _problemsAttemptedController,
                  decoration: const InputDecoration(
                    labelText: "Problems Attempted*",
                    hintText: "How many problems did you attempt?",
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      _requiredNumberValidator(value, "Problems attempted"),
                  onChanged: (value) {
                    // Trigger validation for problems correct when attempted changes
                    if (_problemsCorrectController.text.isNotEmpty) {
                      _formKey.currentState?.validate();
                    }
                  },
                ),
              ),

              FormFieldWrapper(
                child: TextFormField(
                  controller: _problemsCorrectController,
                  decoration: const InputDecoration(
                    labelText: "Problems Correct*",
                    hintText: "How many problems did you solve correctly?",
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _problemsCorrectValidator,
                ),
              ),

              FormFieldWrapper(
                child: TextFormField(
                  controller: _durationMinutesController,
                  decoration: const InputDecoration(
                    labelText: "Duration (minutes)*",
                    hintText: "How long did the session take?",
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [DecimalTextInputFormatter()],
                  validator: (value) =>
                      _requiredDurationValidator(value, "Duration"),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              const SizedBox(height: 30),

              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submitForm(context),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text("Add Problem Session"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
