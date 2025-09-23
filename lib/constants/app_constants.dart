class AppConstants {
  // App Information
  static const String appName = 'Study Forces';
  static const String appVersion = 'Beta';
  static const String appTitle = '$appName - $appVersion';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Form Spacing
  static const double formFieldSpacing = 36.0;
  static const double formSectionSpacing = 44.0;

  // Border Radius
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;

  // Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 12.0;

  // Icon Sizes
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // Text Sizes
  static const double textXS = 10.0;
  static const double textS = 12.0;
  static const double textM = 14.0;
  static const double textL = 16.0;
  static const double textXL = 18.0;
  static const double textXXL = 20.0;
  static const double textXXXL = 24.0;

  // Card Dimensions
  static const double cardMinHeight = 80.0;
  static const double cardMaxHeight = 200.0;

  // Input Field Dimensions
  static const double inputHeight = 48.0;
  static const double inputPadding = 16.0;

  // Button Dimensions
  static const double buttonHeight = 48.0;
  static const double buttonMinWidth = 120.0;

  // List Item Dimensions
  static const double listItemHeight = 72.0;
  static const double listItemPadding = 16.0;

  // Validation
  static const int minRating = 1;
  static const int maxRating = 1000;
  static const double minTimeGoal = 0.1;
  static const double maxTimeGoal = 60.0;
  static const int minFrequency = 1;
  static const int maxFrequency = 30;

  // Default Values
  static const int defaultBaseRating = 100;
  static const int defaultMaxRating = 500;
  static const double defaultRatingConstant = 1.0;
  static const int defaultFrequency = 1;
  static const double defaultTimeGoal = 2.0;

  // Error Messages
  static const String errorRequired = 'This field is required';
  static const String errorInvalidNumber = 'Please enter a valid number';
  static const String errorPositiveNumber = 'Please enter a positive number';
  static const String errorMinValue = 'Value must be at least';
  static const String errorMaxValue = 'Value must be at most';

  // Success Messages
  static const String successSubjectAdded = 'Subject added successfully';
  static const String successSubjectUpdated = 'Subject updated successfully';
  static const String successSubjectDeleted = 'Subject deleted successfully';
  static const String successSessionAdded = 'Session added successfully';
  static const String successSessionUpdated = 'Session updated successfully';
  static const String successSessionDeleted = 'Session deleted successfully';

  // Empty State Messages
  static const String emptySubjects =
      'No subjects yet.\nTap + to add your first subject!';
  static const String emptyStudySessions =
      'No study sessions yet.\nTap + to add your first session!';
  static const String emptyProblemSessions =
      'No problem sessions yet.\nTap + to add your first session!';
  static const String emptyRanks =
      'No ranks defined.\nAdd a rank to get started!';
}
