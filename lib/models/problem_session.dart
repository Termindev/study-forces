import 'package:objectbox/objectbox.dart';

@Entity()
class ProblemSession {
  @Id()
  int id = 0;

  @Property()
  DateTime when = DateTime.now();

  @Property()
  int problemsAttempted = 0;

  @Property()
  int problemsCorrect = 0;

  @Property()
  int durationSeconds = 0;

  @Property()
  bool applied = false;

  ProblemSession();

  /// Create a new (unsaved) ProblemSession.
  /// Do NOT set `id` here; leave it 0 for ObjectBox to assign.
  factory ProblemSession.create({
    DateTime? when,
    int problemsAttempted = 0,
    int problemsCorrect = 0,
    int durationSeconds = 0,
    bool applied = false,
  }) {
    final session = ProblemSession();
    session.when = when ?? DateTime.now();
    session.problemsAttempted = problemsAttempted;
    session.problemsCorrect = problemsCorrect;
    session.durationSeconds = durationSeconds;
    session.applied = applied;
    return session;
  }

  /// Calculate performance as a percentage (0.0 to 1.0)
  /// For problem sessions, this is based on accuracy
  double get performance {
    if (problemsAttempted <= 0) return 0.0;
    
    // Performance is based on accuracy (correct / attempted)
    return (problemsCorrect / problemsAttempted).clamp(0.0, 1.0);
  }

  @override
  String toString() =>
      'ProblemSession{id: $id, when: $when, attempted: $problemsAttempted, correct: $problemsCorrect, duration: $durationSeconds, applied: $applied}';
}
