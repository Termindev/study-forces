import 'package:path_provider/path_provider.dart';

// These imports will work after code generation
import 'models/subject.dart';
import 'models/study_session.dart';
import 'models/problem_session.dart';
import 'models/rank.dart';
import 'models/rating_log.dart';

import 'objectbox.g.dart';

class ObjectBox {
  late final Store store;

  ObjectBox._create(this.store);

  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    // Use the openStore function from the generated code
    final store = await openStore(directory: '${docsDir.path}/objectbox');
    return ObjectBox._create(store);
  }

  // Getters for boxes
  Box<Subject> get subjectBox => store.box<Subject>();
  Box<StudySession> get studySessionBox => store.box<StudySession>();
  Box<ProblemSession> get problemSessionBox => store.box<ProblemSession>();
  Box<Rank> get rankBox => store.box<Rank>();
  Box<RatingLog> get ratingLogBox => store.box<RatingLog>();
}
