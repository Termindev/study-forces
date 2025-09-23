import 'package:objectbox/objectbox.dart';

@Entity()
class Rank {
  @Id()
  int id = 0;

  @Property()
  int requiredRating = 0;

  @Property()
  String name = '';

  @Property()
  String description = '';

  @Property()
  String color = '#FFFFFFFF';

  @Property()
  bool glow = false;

  Rank();

  factory Rank.create({
    int id = 0,
    int requiredRating = 0,
    String name = '',
    String description = '',
    String color = '#FFFFFFFF',
    bool glow = false,
  }) {
    final rank = Rank();
    rank.id = id;
    rank.requiredRating = requiredRating;
    rank.name = name;
    rank.description = description;
    rank.color = color;
    rank.glow = glow;
    return rank;
  }
}
