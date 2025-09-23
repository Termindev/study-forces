import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/subject_store.dart';
import '../models/problem_session.dart';
import '../constants/app_constants.dart';
import '../components/common/form_field_wrapper.dart';

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

  Future<void> _submitForm(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final store = Provider.of<SubjectStore>(context, listen: false);

      // Parse input values
      final problemsAttempted = int.parse(_problemsAttemptedController.text);
      final problemsCorrect = int.parse(_problemsCorrectController.text);
      final durationMinutes = int.parse(_durationMinutesController.text);

      // Use the selected date (time is not relevant for rating algorithms)
      final sessionDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      if (widget.existingSession != null) {
        // Editing existing session
        final updatedSession = ProblemSession.create(
          when: sessionDateTime,
          problemsAttempted: problemsAttempted,
          problemsCorrect: problemsCorrect,
          durationSeconds: durationMinutes * 60, // Convert minutes to seconds
          applied: widget.existingSession!.applied,
        );
        updatedSession.id = widget.existingSession!.id; // Preserve the ID

        await store.editProblemSessionSmartWithDateCheck(
          widget.subjectId,
          widget.existingSession!.id,
          updatedSession,
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
          durationSeconds: durationMinutes * 60, // Convert minutes to seconds
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
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingSession != null
                  ? 'Error updating problem session: ${e.toString()}'
                  : 'Error adding problem session: ${e.toString()}',
            ),
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

              // Problem Statistics
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
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      _requiredNumberValidator(value, "Duration"),
                ),
              ),

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
