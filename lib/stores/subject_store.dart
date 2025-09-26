import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:objectbox/objectbox.dart';

import '../objectbox.dart';
import '../models/subject.dart';
import '../models/study_session.dart';
import '../models/problem_session.dart';
import '../models/rank.dart';

class SubjectStore extends ChangeNotifier {
  late final Box<Subject> subjectBox;
  late final Box<ProblemSession> problemSessionBox;
  late final Box<StudySession> studySessionBox;
  late final Box<Rank> rankBox;
  late final ObjectBox objectBox;
  List<Subject> subjects = [];
  bool loading = true;
  String? error;

  StreamSubscription<Query<Subject>>? _subs;

  SubjectStore(ObjectBox objectBox) {
    this.objectBox = objectBox;
    subjectBox = objectBox.subjectBox;
    problemSessionBox = objectBox.problemSessionBox;
    studySessionBox = objectBox.studySessionBox;
    rankBox = objectBox.rankBox;
    _init();
  }

  void _init() {
    // Load initial data
    subjects = subjectBox.getAll();
    print('DEBUG: Loaded ${subjects.length} subjects from database');

    // Fix any subjects with empty names
    bool needsUpdate = false;
    for (int i = 0; i < subjects.length; i++) {
      print(
        'DEBUG: Subject $i: name="${subjects[i].name}", id=${subjects[i].id}',
      );
      if (subjects[i].name.isEmpty) {
        print('DEBUG: Fixing empty name for subject ${subjects[i].id}');
        subjects[i].name = 'Subject ${subjects[i].id}';
        needsUpdate = true;
      }
    }

    if (needsUpdate) {
      print('DEBUG: Updating subjects with fixed names');
      subjectBox.putMany(subjects);
    }

    loading = false;
    notifyListeners();

    // Watch for changes
    final query = subjectBox.query().watch();
    _subs = query.listen((event) {
      subjects = event.find();
      print(
        'DEBUG: Query listener updated subjects: ${subjects.length} subjects',
      );
      for (int i = 0; i < subjects.length; i++) {
        print(
          'DEBUG: Updated subject $i: name="${subjects[i].name}", id=${subjects[i].id}',
        );
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subs?.cancel();
    super.dispose();
  }

  Subject? getById(int id) {
    try {
      return subjectBox.get(id);
    } catch (_) {
      return null;
    }
  }

  // ---------------- Subjects ----------------
  Future<int> addSubject(Subject subject) async {
    try {
      print('DEBUG: Adding subject with name: "${subject.name}"');
      loading = true;
      notifyListeners();
      final id = subjectBox.put(subject);
      print('DEBUG: Subject saved with ID: $id');
      return id;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> updateSubject(Subject subject) async {
    try {
      subjectBox.put(subject);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<void> deleteSubject(int id) async {
    try {
      subjectBox.remove(id);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<void> putSubjectsBulk(List<Subject> subjects) async {
    try {
      subjectBox.putMany(subjects);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<void> resetAndRecalculateSubject(int subjectId) async {
    try {
      final subject = subjectBox.get(subjectId);
      if (subject != null) {
        subject.resetAndRecalculateStudy();
        subject.resetAndRecalculateProblem();
        subjectBox.put(subject);
        notifyListeners();
      }
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  // ---------------- Study sessions ----------------
  Future<Subject> addStudySession(int subjectId, StudySession session) async {
    try {
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      subject.addStudySession(session.units, session.when);
      subjectBox.put(subject);
      notifyListeners();

      return subject;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<Subject> editStudySession(
    int subjectId,
    int sessionId,
    StudySession updated,
  ) async {
    try {
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      final idx = subject.studySessions.indexWhere((s) => s.id == sessionId);
      if (idx == -1) throw StateError('Study session not found');

      subject.studySessions[idx] = updated;
      subject.resetAndRecalculateStudy();
      subjectBox.put(subject);
      notifyListeners();

      return subject;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<Subject> removeStudySession(int subjectId, int sessionId) async {
    try {
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      subject.studySessions.removeWhere((s) => s.id == sessionId);
      subject.resetAndRecalculateStudy();
      subjectBox.put(subject);
      notifyListeners();

      return subject;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<Subject> removeStudySessionsWhere(
    int subjectId,
    bool Function(StudySession) predicate,
  ) async {
    try {
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      subject.studySessions.removeWhere(predicate);
      subject.resetAndRecalculateStudy();
      subjectBox.put(subject);
      notifyListeners();

      return subject;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  // ---------------- Problem sessions ----------------
  Future<Subject> addProblemSession(
    int subjectId,
    ProblemSession session,
  ) async {
    try {
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      subject.addProblemSession(
        session.problemsAttempted,
        session.problemsCorrect,
        session.durationSeconds,
        session.when,
      );
      subjectBox.put(subject);
      notifyListeners();

      return subject;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<Subject> editProblemSession(
    int subjectId,
    int sessionId,
    ProblemSession updated,
  ) async {
    try {
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      final idx = subject.problemSessions.indexWhere((p) => p.id == sessionId);
      if (idx == -1) throw StateError('Problem session not found');

      subject.problemSessions[idx] = updated;
      subject.resetAndRecalculateProblem();
      subjectBox.put(subject);
      notifyListeners();

      return subject;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<Subject> removeProblemSession(int subjectId, int sessionId) async {
    try {
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      subject.problemSessions.removeWhere((p) => p.id == sessionId);
      subject.resetAndRecalculateProblem();
      subjectBox.put(subject);
      notifyListeners();

      return subject;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<Subject> removeProblemSessionsWhere(
    int subjectId,
    bool Function(ProblemSession) predicate,
  ) async {
    try {
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      subject.problemSessions.removeWhere(predicate);
      subject.resetAndRecalculateProblem();
      subjectBox.put(subject);
      notifyListeners();

      return subject;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  // ---------------- Apply rate changes ----------------
  Future<bool> applyStudyRateChangesAndSave(
    int subjectId,
    DateTime asOf,
  ) async {
    try {
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      subject.applyStudyRateChanges(asOf);
      subjectBox.put(subject);
      notifyListeners();

      return true;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<bool> applyProblemRateChangesAndSave(
    int subjectId,
    DateTime asOf,
  ) async {
    try {
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      subject.applyProblemRateChanges(asOf);
      subjectBox.put(subject);
      notifyListeners();

      return true;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<void> applyRateChangesForAll(DateTime asOf) async {
    try {
      loading = true;
      notifyListeners();

      final allSubjects = subjectBox.getAll();
      for (final subject in allSubjects) {
        subject.applyStudyRateChanges(asOf);
        subject.applyProblemRateChanges(asOf);
      }

      subjectBox.putMany(allSubjects);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ---------------- Smart Delete Methods ----------------
  Future<Subject> deleteStudySessionSmart(int subjectId, int sessionId) async {
    try {
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      final session = subject.studySessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => throw StateError('Study session not found'),
      );

      print(
        'DEBUG: Deleting study session ${session.id}, applied: ${session.applied}',
      );

      // Check if this deletion affects processed sessions
      final sessionDate = session.when;
      final shouldRecalculate =
          session.applied ||
          _isSessionBeforeProcessed(subject, sessionDate, true);

      // Simply remove from the ToMany relationship - ObjectBox will handle the rest
      subject.studySessions.removeWhere((s) => s.id == sessionId);
      print('DEBUG: Removed session from subject.studySessions');

      // Reset and recalculate if this affects processed data
      if (shouldRecalculate) {
        print(
          'DEBUG: Session affects processed data, resetting and recalculating',
        );
        subject.resetAndRecalculateStudy();
      }

      subjectBox.put(subject);
      notifyListeners();

      print('DEBUG: Study session deleted successfully');
      return subject;
    } catch (e) {
      print('DEBUG: Error deleting study session: $e');
      error = e.toString();
      rethrow;
    }
  }

  Future<Subject> deleteProblemSessionSmart(
    int subjectId,
    int sessionId,
  ) async {
    try {
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      final session = subject.problemSessions.firstWhere(
        (p) => p.id == sessionId,
        orElse: () => throw StateError('Problem session not found'),
      );

      print(
        'DEBUG: Deleting problem session ${session.id}, applied: ${session.applied}',
      );

      // Check if this deletion affects processed sessions
      final sessionDate = session.when;
      final shouldRecalculate =
          session.applied ||
          _isSessionBeforeProcessed(subject, sessionDate, false);

      // Simply remove from the ToMany relationship - ObjectBox will handle the rest
      subject.problemSessions.removeWhere((p) => p.id == sessionId);
      print('DEBUG: Removed session from subject.problemSessions');

      // Reset and recalculate if this affects processed data
      if (shouldRecalculate) {
        print(
          'DEBUG: Session affects processed data, resetting and recalculating',
        );
        subject.resetAndRecalculateProblem();
      }

      subjectBox.put(subject);
      notifyListeners();

      print('DEBUG: Problem session deleted successfully');
      return subject;
    } catch (e) {
      print('DEBUG: Error deleting problem session: $e');
      error = e.toString();
      rethrow;
    }
  }

  // ---------------- Smart Edit Methods ----------------
  Future<Subject> editStudySessionSmart(
    int subjectId,
    int sessionId,
    StudySession updated,
  ) async {
    try {
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      final session = subject.studySessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => throw StateError('Study session not found'),
      );

      // Check if session has been processed
      if (session.applied) {
        // If processed, reset and recalculate everything
        subject.resetAndRecalculateStudy();
      } else {
        // If not processed, just update the session
        final idx = subject.studySessions.indexWhere((s) => s.id == sessionId);
        subject.studySessions[idx] = updated;
      }

      subjectBox.put(subject);
      notifyListeners();

      return subject;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<Subject> editProblemSessionSmart(
    int subjectId,
    int sessionId,
    ProblemSession updated,
  ) async {
    try {
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      final session = subject.problemSessions.firstWhere(
        (p) => p.id == sessionId,
        orElse: () => throw StateError('Problem session not found'),
      );

      // Check if session has been processed
      if (session.applied) {
        // If processed, reset and recalculate everything
        subject.resetAndRecalculateProblem();
      } else {
        // If not processed, just update the session
        final idx = subject.problemSessions.indexWhere(
          (p) => p.id == sessionId,
        );
        subject.problemSessions[idx] = updated;
      }

      subjectBox.put(subject);
      notifyListeners();

      return subject;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  // ---------------- Smart Add Methods with Date Checking ----------------
  Future<Subject> addStudySessionSmart(
    int subjectId,
    StudySession session,
  ) async {
    try {
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      // Check if the session date falls within already processed ranges
      if (_shouldReprocessStudyFromDate(subject, session.when)) {
        // Add the session first
        subject.addStudySession(session.units, session.when);
        // Then reset and recalculate everything
        subject.resetAndRecalculateStudyFromDate(session.when);
      } else {
        // Normal add - just add the session
        subject.addStudySession(session.units, session.when);
      }

      subjectBox.put(subject);
      notifyListeners();

      return subject;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<Subject> addProblemSessionSmart(
    int subjectId,
    ProblemSession session,
  ) async {
    try {
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      // Check if the session date falls within already processed ranges
      if (_shouldReprocessProblemFromDate(subject, session.when)) {
        // Add the session first
        subject.addProblemSession(
          session.problemsAttempted,
          session.problemsCorrect,
          session.durationSeconds,
          session.when,
        );
        // Then reset and recalculate everything
        subject.resetAndRecalculateProblemFromDate(session.when);
      } else {
        // Normal add - just add the session
        subject.addProblemSession(
          session.problemsAttempted,
          session.problemsCorrect,
          session.durationSeconds,
          session.when,
        );
      }

      subjectBox.put(subject);
      notifyListeners();

      return subject;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<Subject> editStudySessionSmartWithDateCheck(
    int subjectId,
    int sessionId,
    StudySession updated,
  ) async {
    try {
      print(
        'DEBUG: editStudySessionSmartWithDateCheck called with sessionId: $sessionId',
      );
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      // Verify session exists
      final existingSession = subject.studySessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => throw StateError('Study session not found'),
      );
      print(
        'DEBUG: Found existing study session: ${existingSession.toString()}',
      );

      // Check if this edit affects processed sessions
      final oldDate = existingSession.when;
      final newDate = updated.when;
      final shouldRecalculate =
          existingSession.applied ||
          _isSessionBeforeProcessed(subject, oldDate, true) ||
          _isSessionBeforeProcessed(subject, newDate, true) ||
          _shouldReprocessStudyFromDate(subject, newDate);

      // Update the session
      final idx = subject.studySessions.indexWhere((s) => s.id == sessionId);
      print('DEBUG: Updating study session at index $idx');
      subject.studySessions[idx] = updated;

      // Reset and recalculate if this affects processed data
      if (shouldRecalculate) {
        print(
          'DEBUG: Edit affects processed data, resetting and recalculating',
        );
        subject.resetAndRecalculateStudy();
      } else {
        print('DEBUG: Normal study edit - no reprocessing needed');
      }

      print('DEBUG: Saving subject to database');
      subjectBox.put(subject);

      // Also save the updated session to its own box to ensure it's persisted
      final updatedSession = subject.studySessions.firstWhere(
        (s) => s.id == sessionId,
      );
      print(
        'DEBUG: Saving updated study session to study session box: ${updatedSession.toString()}',
      );
      studySessionBox.put(updatedSession);

      notifyListeners();

      return subject;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<Subject> editProblemSessionSmartWithDateCheck(
    int subjectId,
    int sessionId,
    ProblemSession updated,
  ) async {
    try {
      print(
        'DEBUG: editProblemSessionSmartWithDateCheck called with sessionId: $sessionId',
      );
      final subject = subjectBox.get(subjectId);
      if (subject == null) throw StateError('Subject not found');

      // Verify session exists
      final existingSession = subject.problemSessions.firstWhere(
        (p) => p.id == sessionId,
        orElse: () => throw StateError('Problem session not found'),
      );
      print('DEBUG: Found existing session: ${existingSession.toString()}');

      // Check if this edit affects processed sessions
      final oldDate = existingSession.when;
      final newDate = updated.when;
      final shouldRecalculate =
          existingSession.applied ||
          _isSessionBeforeProcessed(subject, oldDate, false) ||
          _isSessionBeforeProcessed(subject, newDate, false) ||
          _shouldReprocessProblemFromDate(subject, newDate);

      // Update the session
      final idx = subject.problemSessions.indexWhere((p) => p.id == sessionId);
      print('DEBUG: Updating problem session at index $idx');
      subject.problemSessions[idx] = updated;

      // Reset and recalculate if this affects processed data
      if (shouldRecalculate) {
        print(
          'DEBUG: Edit affects processed data, resetting and recalculating',
        );
        subject.resetAndRecalculateProblem();
      } else {
        print('DEBUG: Normal problem edit - no reprocessing needed');
      }

      print('DEBUG: Saving subject to database');
      subjectBox.put(subject);

      // Also save the updated session to its own box to ensure it's persisted
      final updatedSession = subject.problemSessions.firstWhere(
        (p) => p.id == sessionId,
      );
      print(
        'DEBUG: Saving updated session to problem session box: ${updatedSession.toString()}',
      );
      problemSessionBox.put(updatedSession);

      notifyListeners();

      return subject;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  // ---------------- Helper Methods for Date Checking ----------------
  bool _shouldReprocessStudyFromDate(Subject subject, DateTime sessionDate) {
    if (!subject.studyEnabled || subject.studyFrequency <= 0) return false;
    if (subject.lastProcessedStudy == null) return false;

    // Check if the session date is before or equal to the last processed date
    return sessionDate.isBefore(subject.lastProcessedStudy!) ||
        sessionDate.isAtSameMomentAs(subject.lastProcessedStudy!);
  }

  bool _shouldReprocessProblemFromDate(Subject subject, DateTime sessionDate) {
    if (!subject.problemEnabled || subject.problemFrequency <= 0) return false;
    if (subject.lastProcessedProblems == null) return false;

    // Check if the session date is before or equal to the last processed date
    return sessionDate.isBefore(subject.lastProcessedProblems!) ||
        sessionDate.isAtSameMomentAs(subject.lastProcessedProblems!);
  }

  // Helper method to check if a session is before any processed sessions
  bool _isSessionBeforeProcessed(
    Subject subject,
    DateTime sessionDate,
    bool isStudy,
  ) {
    if (isStudy) {
      if (subject.lastProcessedStudy == null) return false;
      return sessionDate.isBefore(subject.lastProcessedStudy!);
    } else {
      if (subject.lastProcessedProblems == null) return false;
      return sessionDate.isBefore(subject.lastProcessedProblems!);
    }
  }
}
