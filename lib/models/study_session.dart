import 'package:objectbox/objectbox.dart';

@Entity()
class StudySession {
  @Id()
  int id = 0;

  @Property()
  DateTime when = DateTime.now();

  @Property()
  double units = 0.0;

  @Property()
  bool applied = false;

  StudySession();

  factory StudySession.create({
    DateTime? when,
    double units = 0.0,
    bool applied = false,
  }) {
    final session = StudySession();
    session.when = when ?? DateTime.now();
    session.units = units;
    session.applied = applied;
    return session;
  }

  /// Calculate performance as a percentage (0.0 to 1.0)
  /// For study sessions, this is based on units completed
  double get performance {
    // For now, we'll use a simple calculation based on units
    // This could be enhanced to compare against goals
    if (units <= 0) return 0.0;
    
    // Simple performance calculation - could be made more sophisticated
    // by comparing against subject goals
    return (units / 10.0).clamp(0.0, 1.0); // Assuming 10 units is 100% performance
  }

  @override
  String toString() =>
      'StudySession{id: $id, when: $when, units: $units, applied: $applied}';
}
