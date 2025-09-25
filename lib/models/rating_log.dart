import 'package:objectbox/objectbox.dart';

@Entity()
class RatingLog {
  @Id()
  int id = 0;

  @Property()
  DateTime when = DateTime.now();

  @Property()
  int rating = 0;

  RatingLog();

  RatingLog.create({DateTime? when, this.rating = 0})
    : when = when ?? DateTime.now();
}
