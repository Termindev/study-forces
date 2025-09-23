import 'package:objectbox/objectbox.dart';
import 'dart:math';
import 'rank.dart';
import 'study_session.dart';
import 'rating_log.dart';
import 'problem_session.dart';

@Entity()
class Subject {
  @Id()
  int id = 0;

  // Basic properties
  @Property()
  String name = '';

  @Property()
  String description = '';

  @Property()
  int baseRating = 0;

  @Property()
  int maxRating = 1000;

  // Enable/disable
  @Property()
  bool studyEnabled = false;

  @Property()
  bool problemEnabled = false;

  // Study properties
  @Property()
  String unitName = 'units';

  @Property()
  int studyFrequency = 1;

  @Property()
  int studyGoalMin = 0;

  @Property()
  int studyGoalMax = 0;

  @Property()
  int studyStreak = 0;

  @Property()
  int studyRating = 0;

  @Property()
  DateTime? lastProcessedStudy;

  @Property()
  double studyRatingConstant = 1.0;

  // Problem properties
  @Property()
  int problemFrequency = 1;

  @Property()
  int problemGoalMin = 0;

  @Property()
  int problemGoalMax = 0;

  @Property()
  int problemStreak = 0;

  @Property()
  int problemTimeGoal = 0;

  @Property()
  int problemRating = 0;

  @Property()
  DateTime? lastProcessedProblems;

  @Property()
  double problemRatingConstant = 1.0;

  // Relationships
  final ranks = ToMany<Rank>();
  final studySessions = ToMany<StudySession>();
  final problemSessions = ToMany<ProblemSession>();
  final studyRatingHistory = ToMany<RatingLog>();
  final problemRatingHistory = ToMany<RatingLog>();

  Subject();

  // Session management methods
  void addStudySession(double units, DateTime when) {
    // create an unsaved StudySession (id left 0) and add it to the ToMany.
    studySessions.add(StudySession.create(units: units, when: when));
  }

  void addProblemSession(
    int attempted,
    int correct,
    int duration,
    DateTime when,
  ) {
    problemSessions.add(
      ProblemSession.create(
        problemsAttempted: attempted,
        problemsCorrect: correct,
        durationSeconds: duration,
        when: when,
      ),
    );
  }

  bool deleteStudySession(int id) {
    final session = studySessions.firstWhere(
      (session) => session.id == id,
      orElse: () => StudySession(),
    );
    if (session.id != 0) {
      studySessions.remove(session);
      return true;
    }
    return false;
  }

  bool deleteProblemSession(int id) {
    final session = problemSessions.firstWhere(
      (session) => session.id == id,
      orElse: () => ProblemSession(),
    );
    if (session.id != 0) {
      problemSessions.remove(session);
      return true;
    }
    return false;
  }

  // Performance calculation methods
  /// Returns study performance for the given (inclusive) window [start, end].
  /// Defensive: returns 0 if studyGoalMax is 0 or no sessions.
  double getStudyPerformance(DateTime start, DateTime end) {
    if (studyGoalMax == 0) return 0;

    final sessions = studySessions.where(
      (s) => !s.when.isBefore(start) && !s.when.isAfter(end) && !s.applied,
    );

    final totalUnits = sessions.fold<double>(
      0,
      (sum, session) => sum + session.units,
    );

    if (totalUnits == 0) return 0;

    return (totalUnits / studyGoalMax) * maxRating;
  }

  /// Returns problem performance for the given (inclusive) window [start, end].
  /// Defensive: returns 0 if problemGoalMax or problemTimeGoal is 0, or if no attempts.
  double getProblemPerformance(DateTime start, DateTime end) {
    if (problemGoalMax == 0 || problemTimeGoal == 0) return 0;

    final sessions = problemSessions.where(
      (s) => !s.when.isBefore(start) && !s.when.isAfter(end) && !s.applied,
    );

    int totalAttempted = 0;
    int totalCorrect = 0;
    int totalTime = 0;

    for (final session in sessions) {
      totalAttempted += session.problemsAttempted;
      totalCorrect += session.problemsCorrect;
      totalTime += session.durationSeconds;
    }

    if (totalAttempted == 0) return 0;

    final avgTime = totalTime / totalAttempted;

    // Protection against division by zero
    if (avgTime <= 0) return 0;

    return (totalAttempted / problemGoalMax) *
        (problemTimeGoal / avgTime) * // Fixed: goal time / actual time
        (totalCorrect / totalAttempted) *
        maxRating;
  }

  // Streak multiplier calculation
  double getStreakMultiplier(int streak) {
    if (streak > 0) {
      return 1 + (log(streak + 1) / log(10));
    } else if (streak < 0) {
      // S_{m-} = log(1 + days_without_streak) / 6
      final daysWithoutStreak = streak.abs();
      return log(1 + daysWithoutStreak) / 6;
    }
    return 1.0;
  }

  /// Calculate negative streak multiplier for no-streak rate-loss
  /// Returns a percentage value (0-100) representing the percentage of rating to lose
  double getNegativeStreakMultiplier(int daysWithoutStreak) {
    if (daysWithoutStreak <= 0) return 0.0;
    final result =
        log(1 + daysWithoutStreak) / 3; // Changed from /6 to /3 for higher loss
    return result * 100; // Convert to percentage (0-100)
  }

  /// Processes windows from `lastProcessedStudy` (or the first session date)
  /// up to `asOf`, consuming only unapplied sessions. Sessions that contributed
  /// to a processed window are marked `applied = true`.
  void applyStudyRateChanges(DateTime asOf) {
    if (!studyEnabled || studySessions.isEmpty) return;
    if (studyFrequency <= 0) return; // guard

    DateTime processingDate = lastProcessedStudy ?? _firstStudySessionDate();

    while (true) {
      final windowEnd = processingDate.add(Duration(days: studyFrequency));

      // Only process full windows (windowEnd must be <= asOf)
      if (windowEnd.isAfter(asOf)) break;

      // collect unapplied sessions within this window
      final sessionsInWindow = studySessions
          .where(
            (s) =>
                !s.when.isBefore(processingDate) &&
                !s.when.isAfter(windowEnd) &&
                !s.applied,
          )
          .toList();

      // calculate performance for those sessions
      final totalUnits = sessionsInWindow.fold<double>(
        0,
        (sum, s) => sum + s.units,
      );
      final performance = (studyGoalMax <= 0 || totalUnits <= 0)
          ? 0
          : (totalUnits / studyGoalMax) * maxRating;

      double deltaR = (performance - studyRating) / studyRatingConstant;

      // Use the calculated streak for the multiplier, not the stored streak
      final currentStreak = calculateStudyStreak();
      final daysWithoutStreak = calculateDaysWithoutStudyStreak();

      if (performance >= studyGoalMin) {
        // Positive performance - use streak multiplier
        studyStreak = max(1, studyStreak + 1);
        final streakMult = getStreakMultiplier(currentStreak);
        studyRating += (deltaR * streakMult).round();
      } else {
        // Negative performance - check if we need to apply no-streak rate-loss
        if (studyStreak > 0) {
          // First hit: apply S_{m+} × R_current / 125
          final firstHitLoss =
              (getStreakMultiplier(studyStreak) * studyRating / 125).round();
          studyRating -= firstHitLoss;
          studyStreak = 0; // Reset streak
        } else {
          // Subsequent hits: apply R_current × (100 - S_{m-}) / 100
          // This means we keep (100 - S_{m-})% of the rating, losing S_{m-}%
          final sMinus = getNegativeStreakMultiplier(daysWithoutStreak);
          final newRating = (studyRating * (100 - sMinus) / 100).round();
          final loss = studyRating - newRating;
          // Ensure minimum loss of 1 point
          studyRating = newRating - max(0, 1 - loss);
          print(
            'Study Rating Decay: daysWithoutStreak=$daysWithoutStreak, sMinus=$sMinus%, loss=$loss, rating: ${studyRating + loss} -> $studyRating',
          );
        }
        studyStreak = min(-1, studyStreak - 1);
      }

      studyRating = studyRating.clamp(baseRating, maxRating);
      studyRatingHistory.add(
        RatingLog.create(when: windowEnd, rating: studyRating),
      );

      // mark sessions that contributed as applied so they won't be counted again
      for (final s in sessionsInWindow) {
        s.applied = true;
      }

      // advance to the end of this processed window (guaranteed <= asOf)
      lastProcessedStudy = windowEnd;
      processingDate = windowEnd;
    }
  }

  /// Processes windows for problem sessions similarly to study processing.
  /// Only processes a window when its end is <= asOf, so lastProcessedProblems
  /// never moves into the future.
  void applyProblemRateChanges(DateTime asOf) {
    if (!problemEnabled || problemSessions.isEmpty) return;
    if (problemFrequency <= 0) return; // guard

    DateTime processingDate =
        lastProcessedProblems ?? _firstProblemSessionDate();

    while (true) {
      final windowEnd = processingDate.add(Duration(days: problemFrequency));

      // Only process complete windows
      if (windowEnd.isAfter(asOf)) break;

      // collect unapplied sessions in window
      final sessionsInWindow = problemSessions
          .where(
            (s) =>
                !s.when.isBefore(processingDate) &&
                !s.when.isAfter(windowEnd) &&
                !s.applied,
          )
          .toList();

      // aggregate metrics
      int totalAttempted = 0;
      int totalCorrect = 0;
      int totalTime = 0;

      for (final session in sessionsInWindow) {
        totalAttempted += session.problemsAttempted;
        totalCorrect += session.problemsCorrect;
        totalTime += session.durationSeconds;
      }

      // defensive checks
      final bool invalidGoals = problemGoalMax == 0 || problemTimeGoal == 0;
      if (invalidGoals || totalAttempted == 0) {
        // Add a rating history entry (unchanged rating) and advance.
        problemRatingHistory.add(
          RatingLog.create(when: windowEnd, rating: problemRating),
        );

        // We do NOT mark sessions applied here if totalAttempted == 0 (keeps them available for future windows).
        lastProcessedProblems = windowEnd;
        processingDate = windowEnd;
        continue;
      }

      final avgTime = totalTime / totalAttempted;

      // Protection against division by zero
      if (avgTime <= 0) {
        // Add a rating history entry (unchanged rating) and advance.
        problemRatingHistory.add(
          RatingLog.create(when: windowEnd, rating: problemRating),
        );
        lastProcessedProblems = windowEnd;
        processingDate = windowEnd;
        continue;
      }

      final performance =
          (totalAttempted / problemGoalMax) *
          (problemTimeGoal / avgTime) * // Fixed: goal time / actual time
          (totalCorrect / totalAttempted) *
          maxRating;

      double deltaR = (performance - problemRating) / problemRatingConstant;

      // Use the calculated streak for the multiplier, not the stored streak
      final currentStreak = calculateProblemStreak();
      final daysWithoutStreak = calculateDaysWithoutProblemStreak();

      if (performance >= problemGoalMin) {
        // Positive performance - use streak multiplier
        problemStreak = max(1, problemStreak + 1);
        final streakMult = getStreakMultiplier(currentStreak);
        problemRating += (deltaR * streakMult).round();
      } else {
        // Negative performance - check if we need to apply no-streak rate-loss
        if (problemStreak > 0) {
          // First hit: apply S_{m+} × R_current / 125
          final firstHitLoss =
              (getStreakMultiplier(problemStreak) * problemRating / 125)
                  .round();
          problemRating -= firstHitLoss;
          problemStreak = 0; // Reset streak
        } else {
          // Subsequent hits: apply R_current × (100 - S_{m-}) / 100
          // This means we keep (100 - S_{m-})% of the rating, losing S_{m-}%
          final sMinus = getNegativeStreakMultiplier(daysWithoutStreak);
          final newRating = (problemRating * (100 - sMinus) / 100).round();
          final loss = problemRating - newRating;
          // Ensure minimum loss of 1 point
          problemRating = newRating - max(0, 1 - loss);
        }
        problemStreak = min(-1, problemStreak - 1);
      }

      problemRating = problemRating.clamp(baseRating, maxRating);
      problemRatingHistory.add(
        RatingLog.create(when: windowEnd, rating: problemRating),
      );

      // mark sessions that contributed as applied
      for (final s in sessionsInWindow) {
        s.applied = true;
      }

      // advance to the end of this processed window (guaranteed <= asOf)
      lastProcessedProblems = windowEnd;
      processingDate = windowEnd;
    }
  }

  void resetAndRecalculateStudy() {
    studyRating = baseRating;
    studyStreak = 0;
    lastProcessedStudy = null;
    studyRatingHistory.clear();

    for (final session in studySessions) {
      session.applied = false;
    }

    applyStudyRateChanges(DateTime.now());
  }

  void resetAndRecalculateProblem() {
    problemRating = baseRating;
    problemStreak = 0;
    lastProcessedProblems = null;
    problemRatingHistory.clear();

    for (final session in problemSessions) {
      session.applied = false;
    }

    applyProblemRateChanges(DateTime.now());
  }

  /// Smart reset and recalculate for study sessions from a specific date
  /// This resets processing from the given date and recalculates everything
  void resetAndRecalculateStudyFromDate(DateTime fromDate) {
    // Reset to base rating and clear history
    studyRating = baseRating;
    studyStreak = 0;
    lastProcessedStudy = null;
    studyRatingHistory.clear();

    // Mark all sessions as unapplied
    for (final session in studySessions) {
      session.applied = false;
    }

    // Recalculate from the beginning
    applyStudyRateChanges(DateTime.now());
  }

  /// Smart reset and recalculate for problem sessions from a specific date
  /// This resets processing from the given date and recalculates everything
  void resetAndRecalculateProblemFromDate(DateTime fromDate) {
    // Reset to base rating and clear history
    problemRating = baseRating;
    problemStreak = 0;
    lastProcessedProblems = null;
    problemRatingHistory.clear();

    // Mark all sessions as unapplied
    for (final session in problemSessions) {
      session.applied = false;
    }

    // Recalculate from the beginning
    applyProblemRateChanges(DateTime.now());
  }

  // Helper: get the earliest study session date (or now if none)
  DateTime _firstStudySessionDate() {
    if (studySessions.isEmpty) return DateTime.now();
    DateTime minDate = studySessions.first.when;
    for (final s in studySessions) {
      if (s.when.isBefore(minDate)) minDate = s.when;
    }
    return minDate;
  }

  // Helper: get the earliest problem session date (or now if none)
  DateTime _firstProblemSessionDate() {
    if (problemSessions.isEmpty) return DateTime.now();
    DateTime minDate = problemSessions.first.when;
    for (final s in problemSessions) {
      if (s.when.isBefore(minDate)) minDate = s.when;
    }
    return minDate;
  }

  /// Calculate the actual study streak based on consecutive days of study
  /// This is independent of performance goals and just looks at consecutive study days
  int calculateStudyStreak() {
    if (studySessions.isEmpty) return 0;

    // Get all study sessions, sorted by date (most recent first)
    final sortedSessions = List<StudySession>.from(studySessions)
      ..sort((a, b) => b.when.compareTo(a.when));

    int streak = 0;
    DateTime currentDate = DateTime.now();

    // Normalize to start of day for comparison
    currentDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    for (final session in sortedSessions) {
      final sessionDate = DateTime(
        session.when.year,
        session.when.month,
        session.when.day,
      );

      // Check if this session is on the expected date
      if (sessionDate.isAtSameMomentAs(currentDate)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else if (sessionDate.isBefore(currentDate)) {
        // Gap found, streak ends
        break;
      }
      // If sessionDate is after currentDate, skip it (it's in the future)
    }

    return streak;
  }

  /// Calculate the actual problem streak based on consecutive days of problem solving
  int calculateProblemStreak() {
    if (problemSessions.isEmpty) return 0;

    // Get all problem sessions, sorted by date (most recent first)
    final sortedSessions = List<ProblemSession>.from(problemSessions)
      ..sort((a, b) => b.when.compareTo(a.when));

    int streak = 0;
    DateTime currentDate = DateTime.now();

    // Normalize to start of day for comparison
    currentDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    for (final session in sortedSessions) {
      final sessionDate = DateTime(
        session.when.year,
        session.when.month,
        session.when.day,
      );

      // Check if this session is on the expected date
      if (sessionDate.isAtSameMomentAs(currentDate)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else if (sessionDate.isBefore(currentDate)) {
        // Gap found, streak ends
        break;
      }
      // If sessionDate is after currentDate, skip it (it's in the future)
    }

    return streak;
  }

  /// Calculate days without study streak
  int calculateDaysWithoutStudyStreak() {
    if (studySessions.isEmpty) return 0;

    final sortedSessions = List<StudySession>.from(studySessions)
      ..sort((a, b) => b.when.compareTo(a.when));

    DateTime currentDate = DateTime.now();
    currentDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    int daysWithoutStreak = 0;
    bool foundRecentSession = false;

    for (final session in sortedSessions) {
      final sessionDate = DateTime(
        session.when.year,
        session.when.month,
        session.when.day,
      );

      if (sessionDate.isAtSameMomentAs(currentDate)) {
        foundRecentSession = true;
        break;
      } else if (sessionDate.isBefore(currentDate)) {
        daysWithoutStreak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      }
    }

    return foundRecentSession ? 0 : daysWithoutStreak;
  }

  /// Calculate days without problem streak
  int calculateDaysWithoutProblemStreak() {
    if (problemSessions.isEmpty) return 0;

    final sortedSessions = List<ProblemSession>.from(problemSessions)
      ..sort((a, b) => b.when.compareTo(a.when));

    DateTime currentDate = DateTime.now();
    currentDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    int daysWithoutStreak = 0;
    bool foundRecentSession = false;

    for (final session in sortedSessions) {
      final sessionDate = DateTime(
        session.when.year,
        session.when.month,
        session.when.day,
      );

      if (sessionDate.isAtSameMomentAs(currentDate)) {
        foundRecentSession = true;
        break;
      } else if (sessionDate.isBefore(currentDate)) {
        daysWithoutStreak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      }
    }

    return foundRecentSession ? 0 : daysWithoutStreak;
  }
}
