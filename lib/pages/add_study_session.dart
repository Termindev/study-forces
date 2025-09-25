import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_forces/models/study_session.dart';
import 'package:study_forces/models/subject.dart';
import 'package:study_forces/stores/subject_store.dart';

class AddStudySessionPage extends StatefulWidget {
  final Subject subject;
  final StudySession? existingSession;

  const AddStudySessionPage({
    super.key,
    required this.subject,
    this.existingSession,
  });

  @override
  State<AddStudySessionPage> createState() => _AddStudySessionPageState();
}

class _AddStudySessionPageState extends State<AddStudySessionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _unitsController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingSession != null) {
      _unitsController.text = widget.existingSession!.units.toString();
      _selectedDateTime = widget.existingSession!.when;
    } else {
      _unitsController.text = '1';
    }
  }

  @override
  void dispose() {
    _unitsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
    });
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final store = context.read<SubjectStore>();
    final units = double.tryParse(_unitsController.text.trim()) ?? 0.0;
    if (units <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Units must be greater than 0')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.existingSession != null) {
        // Editing existing session - modify the existing session directly
        final existingSession = widget.existingSession!;
        print('DEBUG: Editing study session ${existingSession.id}');
        print(
          'DEBUG: Before - units: ${existingSession.units}, when: ${existingSession.when}',
        );

        existingSession.units = units;
        existingSession.when = _selectedDateTime;
        // Keep the existing applied status

        print(
          'DEBUG: After - units: ${existingSession.units}, when: ${existingSession.when}',
        );

        await store.editStudySessionSmartWithDateCheck(
          widget.subject.id,
          existingSession.id,
          existingSession,
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Study session updated')));
      } else {
        // Adding new session
        final session = StudySession.create(
          units: units,
          when: _selectedDateTime,
        );

        // Use smart add method that handles date checking automatically
        await store.addStudySessionSmart(widget.subject.id, session);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Study session added')));
      }

      // Return to previous screen
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingSession != null
                ? 'Failed to update session: $e'
                : 'Failed to add session: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.subject;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingSession != null
              ? 'Edit Study Session'
              : 'Add Study Session',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Subject header
              Text(subject.name, style: Theme.of(context).textTheme.titleLarge),
              if (subject.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0, bottom: 12.0),
                  child: Text(subject.description),
                ),
              const SizedBox(height: 12),

              // Units input
              TextFormField(
                controller: _unitsController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Units',
                  hintText: 'e.g. 1.5',
                  suffixText: subject.unitName,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isEmpty) return 'Enter units';
                  final parsed = double.tryParse(text);
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Date/time picker
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('When'),
                        const SizedBox(height: 6),
                        Text(
                          '${_selectedDateTime.toLocal()}'
                              .split('.')
                              .first
                              .split(" ")
                              .first,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _saving ? null : () => _pickDate(context),
                    child: const Text('Pick'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : () => _submit(context),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.existingSession != null
                                  ? 'Edit Session'
                                  : 'Add Session',
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
