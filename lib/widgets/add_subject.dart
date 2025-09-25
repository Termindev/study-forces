import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/subject_store.dart';
import '../models/subject.dart';
import '../models/rank.dart';
import 'rank_management.dart';
import '../components/common/form_field_wrapper.dart';
import '../constants/app_constants.dart';

class AddSubject extends StatefulWidget {
  const AddSubject({super.key});

  @override
  State<AddSubject> createState() => _AddSubjectState();
}

class _AddSubjectState extends State<AddSubject> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // Study session fields
  bool _studyEnabled = true;
  final TextEditingController _unitNameController = TextEditingController(
    text: "pages",
  );
  final TextEditingController _baseRatingController = TextEditingController(
    text: "0",
  );
  final TextEditingController _maxRatingController = TextEditingController(
    text: "1000",
  );
  final TextEditingController _studyRatingConstantController =
      TextEditingController(text: "1.0");
  final TextEditingController _problemRatingConstantController =
      TextEditingController(text: "1.0");
  final TextEditingController _studyFreqController = TextEditingController(
    text: "1",
  );
  final TextEditingController _minUnitsController = TextEditingController();
  final TextEditingController _maxUnitsController = TextEditingController();

  // Problem solving fields
  bool _problemEnabled = true;
  final TextEditingController _problemFreqController = TextEditingController(
    text: "1",
  );
  final TextEditingController _minQuestionsController = TextEditingController();
  final TextEditingController _maxQuestionsController = TextEditingController();
  final TextEditingController _timeGoalController = TextEditingController();

  // Ranks
  List<Rank> _ranks = [];

  bool _isSubmitting = false;

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
      final subjectStore = Provider.of<SubjectStore>(context, listen: false);

      // Parse input values
      final baseRating = int.parse(_baseRatingController.text);
      final maxRating = int.parse(_maxRatingController.text);
      final studyRatingConstant = double.parse(
        _studyRatingConstantController.text,
      );
      final problemRatingConstant = double.parse(
        _problemRatingConstantController.text,
      );
      final studyFreq = int.parse(_studyFreqController.text);
      final problemFreq = int.parse(_problemFreqController.text);

      // Parse goal values - these are required when the section is enabled
      final minUnits = _studyEnabled && _minUnitsController.text.isNotEmpty
          ? int.parse(_minUnitsController.text)
          : 0;
      final maxUnits = _studyEnabled && _maxUnitsController.text.isNotEmpty
          ? int.parse(_maxUnitsController.text)
          : 0;
      final minQuestions =
          _problemEnabled && _minQuestionsController.text.isNotEmpty
          ? int.parse(_minQuestionsController.text)
          : 0;
      final maxQuestions =
          _problemEnabled && _maxQuestionsController.text.isNotEmpty
          ? int.parse(_maxQuestionsController.text)
          : 0;

      // Parse time values (convert to seconds)
      final timeGoal = _problemEnabled && _timeGoalController.text.isNotEmpty
          ? (double.parse(_timeGoalController.text) * 60)
                .round() // Convert minutes to seconds
          : 0;

      // Create subject using the constructor
      final subjectName = _nameController.text.trim();
      print('DEBUG: Creating subject with name: "$subjectName"');
      final subject = Subject()
        ..name = subjectName.isEmpty ? 'TEST SUBJECT' : subjectName
        ..description = _descController.text
        ..baseRating = baseRating
        ..maxRating = maxRating
        ..studyRatingConstant = studyRatingConstant
        ..problemRatingConstant = problemRatingConstant
        ..studyEnabled = _studyEnabled
        ..problemEnabled = _problemEnabled
        ..unitName = _studyEnabled ? _unitNameController.text : "units"
        ..studyFrequency = studyFreq
        ..problemFrequency = problemFreq
        ..studyRating = baseRating
        ..problemRating = baseRating;

      // Add ranks to subject
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

      // Set study-specific properties
      if (_studyEnabled) {
        subject.studyGoalMin = minUnits;
        subject.studyGoalMax = maxUnits;
      }

      // Set problem-specific properties
      if (_problemEnabled) {
        subject.problemGoalMin = minQuestions;
        subject.problemGoalMax = maxQuestions;
        subject.problemTimeGoal = timeGoal;
      }

      await subjectStore.addSubject(subject);

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject added successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding subject: ${e.toString()}')),
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
        title: const Text("Add a new subject"),
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
                    : const Text("Create Subject"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up all controllers
    _nameController.dispose();
    _descController.dispose();
    _unitNameController.dispose();
    _baseRatingController.dispose();
    _maxRatingController.dispose();
    _studyRatingConstantController.dispose();
    _problemRatingConstantController.dispose();
    _studyFreqController.dispose();
    _minUnitsController.dispose();
    _maxUnitsController.dispose();
    _problemFreqController.dispose();
    _minQuestionsController.dispose();
    _maxQuestionsController.dispose();
    _timeGoalController.dispose();
    super.dispose();
  }
}
