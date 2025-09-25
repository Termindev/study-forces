import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/subject_store.dart';
import '../models/rank.dart';
import '../widgets/rank_management.dart';
import '../constants/app_constants.dart';
import '../components/common/form_field_wrapper.dart';

class EditSubjectPage extends StatefulWidget {
  final int subjectId;

  const EditSubjectPage({super.key, required this.subjectId});

  @override
  State<EditSubjectPage> createState() => _EditSubjectPageState();
}

class _EditSubjectPageState extends State<EditSubjectPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;

  // Rating fields
  late TextEditingController _baseRatingController;
  late TextEditingController _maxRatingController;
  late TextEditingController _studyRatingConstantController;
  late TextEditingController _problemRatingConstantController;

  // Study session fields
  late bool _studyEnabled;
  late TextEditingController _unitNameController;
  late TextEditingController _studyFreqController;
  late TextEditingController _minUnitsController;
  late TextEditingController _maxUnitsController;

  // Problem solving fields
  late bool _problemEnabled;
  late TextEditingController _problemFreqController;
  late TextEditingController _minQuestionsController;
  late TextEditingController _maxQuestionsController;
  late TextEditingController _timeGoalController;

  // Ranks
  late List<Rank> _ranks;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Get the subject from the store
    final store = Provider.of<SubjectStore>(context, listen: false);
    final subject = store.getById(widget.subjectId);

    if (subject == null) {
      // Handle case where subject doesn't exist
      Navigator.pop(context);
      return;
    }

    // Initialize controllers with current values
    _nameController = TextEditingController(text: subject.name);
    _descController = TextEditingController(text: subject.description);

    // Rating properties
    _baseRatingController = TextEditingController(
      text: subject.baseRating.toString(),
    );
    _maxRatingController = TextEditingController(
      text: subject.maxRating.toString(),
    );
    _studyRatingConstantController = TextEditingController(
      text: subject.studyRatingConstant.toString(),
    );
    _problemRatingConstantController = TextEditingController(
      text: subject.problemRatingConstant.toString(),
    );

    // Study properties
    _studyEnabled = subject.studyEnabled;
    _unitNameController = TextEditingController(text: subject.unitName);
    _studyFreqController = TextEditingController(
      text: subject.studyFrequency.toString(),
    );
    _minUnitsController = TextEditingController(
      text: subject.studyGoalMin.toString(),
    );
    _maxUnitsController = TextEditingController(
      text: subject.studyGoalMax.toString(),
    );

    // Problem properties
    _problemEnabled = subject.problemEnabled;
    _problemFreqController = TextEditingController(
      text: subject.problemFrequency.toString(),
    );
    _minQuestionsController = TextEditingController(
      text: subject.problemGoalMin.toString(),
    );
    _maxQuestionsController = TextEditingController(
      text: subject.problemGoalMax.toString(),
    );
    _timeGoalController = TextEditingController(
      text: (subject.problemTimeGoal / 60)
          .toString(), // Convert seconds to minutes
    );

    // Initialize ranks
    _ranks = List.from(subject.ranks);
  }

  @override
  void dispose() {
    // Clean up all controllers
    _nameController.dispose();
    _descController.dispose();
    _baseRatingController.dispose();
    _maxRatingController.dispose();
    _studyRatingConstantController.dispose();
    _problemRatingConstantController.dispose();
    _unitNameController.dispose();
    _studyFreqController.dispose();
    _minUnitsController.dispose();
    _maxUnitsController.dispose();
    _problemFreqController.dispose();
    _minQuestionsController.dispose();
    _maxQuestionsController.dispose();
    _timeGoalController.dispose();
    super.dispose();
  }

  // Validator for required numeric fields
  String? _requiredNumberValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (int.tryParse(value) == null) {
      return '$fieldName must be a number';
    }
    return null;
  }

  // Validator for required decimal fields
  String? _requiredDecimalValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return '$fieldName must be a number';
    }
    if (numValue <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  // Validator for required integer fields that must be greater than 0
  String? _requiredPositiveIntegerValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final numValue = int.tryParse(value);
    if (numValue == null) {
      return '$fieldName must be a number';
    }
    if (numValue <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  // Validator for goal frequency (must be at least 1)
  String? _frequencyValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Frequency is required';
    }
    final numValue = int.tryParse(value);
    if (numValue == null) {
      return 'Frequency must be a number';
    }
    if (numValue < 1) {
      return 'Frequency must be at least 1 day';
    }
    return null;
  }

  // Validator for rating constants (must be >= 1.0)
  String? _ratingConstantValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return '$fieldName must be a number';
    }
    if (numValue < 1.0) {
      return '$fieldName must be at least 1.0';
    }
    return null;
  }

  // Validator for min units (must be <= max units)
  String? _minUnitsValidator(String? value) {
    final result = _requiredPositiveIntegerValidator(value, "Min units");
    if (result != null) return result;

    final minValue = int.tryParse(value!);
    final maxValue = int.tryParse(_maxUnitsController.text);

    if (minValue != null && maxValue != null && minValue > maxValue) {
      return 'Min units cannot be greater than max units';
    }
    return null;
  }

  // Validator for max units (must be >= min units)
  String? _maxUnitsValidator(String? value) {
    final result = _requiredPositiveIntegerValidator(value, "Max units");
    if (result != null) return result;

    final minValue = int.tryParse(_minUnitsController.text);
    final maxValue = int.tryParse(value!);

    if (minValue != null && maxValue != null && minValue > maxValue) {
      return 'Max units cannot be less than min units';
    }
    return null;
  }

  // Validator for min questions (must be <= max questions)
  String? _minQuestionsValidator(String? value) {
    final result = _requiredPositiveIntegerValidator(value, "Min questions");
    if (result != null) return result;

    final minValue = int.tryParse(value!);
    final maxValue = int.tryParse(_maxQuestionsController.text);

    if (minValue != null && maxValue != null && minValue > maxValue) {
      return 'Min questions cannot be greater than max questions';
    }
    return null;
  }

  // Validator for max questions (must be >= min questions)
  String? _maxQuestionsValidator(String? value) {
    final result = _requiredPositiveIntegerValidator(value, "Max questions");
    if (result != null) return result;

    final minValue = int.tryParse(_minQuestionsController.text);
    final maxValue = int.tryParse(value!);

    if (minValue != null && maxValue != null && minValue > maxValue) {
      return 'Max questions cannot be less than min questions';
    }
    return null;
  }

  Future<void> _submitForm(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final store = Provider.of<SubjectStore>(context, listen: false);
      final subject = store.getById(widget.subjectId);

      if (subject == null) {
        throw StateError('Subject not found');
      }

      // Update subject properties
      subject.name = _nameController.text.trim();
      subject.description = _descController.text;
      subject.baseRating = int.parse(_baseRatingController.text);
      subject.maxRating = int.parse(_maxRatingController.text);
      subject.studyRatingConstant = double.parse(
        _studyRatingConstantController.text,
      );
      subject.problemRatingConstant = double.parse(
        _problemRatingConstantController.text,
      );
      subject.studyEnabled = _studyEnabled;
      subject.problemEnabled = _problemEnabled;

      // Update ranks
      subject.ranks.clear();
      for (final rank in _ranks) {
        // Create a new rank with proper ID assignment
        final newRank = Rank.create(
          requiredRating: rank.requiredRating,
          name: rank.name,
          description: rank.description,
          color: rank.color,
          glow: rank.glow,
        );
        subject.ranks.add(newRank);
      }

      // Update study properties
      if (_studyEnabled) {
        subject.unitName = _unitNameController.text;
        subject.studyFrequency = int.parse(_studyFreqController.text);
        subject.studyGoalMin = int.parse(_minUnitsController.text);
        subject.studyGoalMax = int.parse(_maxUnitsController.text);
      } else {
        // Reset study properties if disabled
        subject.unitName = 'units';
        subject.studyGoalMin = 0;
        subject.studyGoalMax = 0;
      }

      // Update problem properties
      if (_problemEnabled) {
        subject.problemFrequency = int.parse(_problemFreqController.text);
        subject.problemGoalMin = int.parse(_minQuestionsController.text);
        subject.problemGoalMax = int.parse(_maxQuestionsController.text);
        subject.problemTimeGoal = (double.parse(_timeGoalController.text) * 60)
            .round(); // Convert minutes to seconds
      } else {
        // Reset problem properties if disabled
        subject.problemGoalMin = 0;
        subject.problemGoalMax = 0;
        subject.problemTimeGoal = 0;
      }

      // Save changes
      await store.updateSubject(subject);

      // Recalculate ratings after updating
      subject.resetAndRecalculateStudy();
      subject.resetAndRecalculateProblem();
      await store.updateSubject(subject);

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject updated successfully')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating subject: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _deleteSubject(BuildContext context) async {
    final store = Provider.of<SubjectStore>(context, listen: false);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Subject'),
          content: const Text(
            'Are you sure you want to delete this subject and all its data? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        await store.deleteSubject(widget.subjectId);

        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject deleted successfully')),
        );

        Navigator.of(context).pop();
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting subject: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Subject"),
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
              // General Information
              const Text(
                "General Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppConstants.spacingM),
              FormFieldWrapper(
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Subject Name*"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a subject name';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Trigger validation when text changes
                    if (_formKey.currentState != null) {
                      _formKey.currentState!.validate();
                    }
                  },
                ),
              ),
              FormFieldWrapper(
                child: TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: "Description"),
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: AppConstants.formSectionSpacing),

              // Rating Information
              const Text(
                "Rating Settings",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppConstants.spacingM),
              FormFieldWrapper(
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _baseRatingController,
                        decoration: const InputDecoration(
                          labelText: "Base Rating*",
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            _requiredNumberValidator(value, "Base rating"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _maxRatingController,
                        decoration: const InputDecoration(
                          labelText: "Max Rating*",
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            _requiredNumberValidator(value, "Max rating"),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.formSectionSpacing),

              // Ranks Section
              RankManagementWidget(
                ranks: _ranks,
                onRanksChanged: (ranks) {
                  setState(() {
                    _ranks = ranks;
                  });
                },
              ),
              const SizedBox(height: AppConstants.formSectionSpacing),

              // Study Sessions Section
              SwitchListTile(
                title: const Text(
                  "Enable Study Sessions",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                value: _studyEnabled,
                onChanged: (value) {
                  setState(() {
                    _studyEnabled = value;
                    if (!_studyEnabled && !_problemEnabled) {
                      _problemEnabled = true;
                    }
                  });
                },
              ),
              if (_studyEnabled) ...[
                const SizedBox(height: AppConstants.spacingM),
                FormFieldWrapper(
                  child: TextFormField(
                    controller: _unitNameController,
                    decoration: const InputDecoration(labelText: "Unit Name*"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a unit name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                FormFieldWrapper(
                  child: TextFormField(
                    controller: _studyFreqController,
                    decoration: const InputDecoration(
                      labelText: "Goal Frequency (days)*",
                    ),
                    keyboardType: TextInputType.number,
                    validator: _frequencyValidator,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                FormFieldWrapper(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minUnitsController,
                          decoration: const InputDecoration(
                            labelText: "Min Units*",
                          ),
                          keyboardType: TextInputType.number,
                          validator: _minUnitsValidator,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _maxUnitsController,
                          decoration: const InputDecoration(
                            labelText: "Max Units*",
                          ),
                          keyboardType: TextInputType.number,
                          validator: _maxUnitsValidator,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                FormFieldWrapper(
                  child: TextFormField(
                    controller: _studyRatingConstantController,
                    decoration: const InputDecoration(
                      labelText: "Study Rating Constant*",
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => _ratingConstantValidator(
                      value,
                      "Study rating constant",
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.formSectionSpacing),
              ],

              // Problem Solving Section
              SwitchListTile(
                title: const Text(
                  "Enable Problem Solving",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                value: _problemEnabled,
                onChanged: (value) {
                  setState(() {
                    _problemEnabled = value;
                    if (!_problemEnabled && !_studyEnabled) {
                      _studyEnabled = true;
                    }
                  });
                },
              ),
              if (_problemEnabled) ...[
                const SizedBox(height: AppConstants.spacingM),
                FormFieldWrapper(
                  child: TextFormField(
                    controller: _problemFreqController,
                    decoration: const InputDecoration(
                      labelText: "Goal Frequency (days)*",
                    ),
                    keyboardType: TextInputType.number,
                    validator: _frequencyValidator,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                FormFieldWrapper(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minQuestionsController,
                          decoration: const InputDecoration(
                            labelText: "Min Questions*",
                          ),
                          keyboardType: TextInputType.number,
                          validator: _minQuestionsValidator,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _maxQuestionsController,
                          decoration: const InputDecoration(
                            labelText: "Max Questions*",
                          ),
                          keyboardType: TextInputType.number,
                          validator: _maxQuestionsValidator,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                FormFieldWrapper(
                  child: TextFormField(
                    controller: _timeGoalController,
                    decoration: const InputDecoration(
                      labelText: "Time per Problem*",
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) =>
                        _requiredDecimalValidator(value, "Time goal"),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                FormFieldWrapper(
                  child: TextFormField(
                    controller: _problemRatingConstantController,
                    decoration: const InputDecoration(
                      labelText: "Problem Rating Constant*",
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => _ratingConstantValidator(
                      value,
                      "Problem rating constant",
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submitForm(context),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text("Update Subject"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : () => _deleteSubject(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Delete Subject"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
