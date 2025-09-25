import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../models/subject.dart';
import '../models/study_session.dart';
import '../models/problem_session.dart';
import '../models/rank.dart';
import '../models/rating_log.dart';

class DataExportService {
  static final DataExportService _instance = DataExportService._internal();
  factory DataExportService() => _instance;
  DataExportService._internal();

  /// Export all data to a JSON file using file_picker
  Future<String?> exportData(dynamic objectBox) async {
    try {
      // Get all data from ObjectBox
      final subjects = objectBox.subjectBox.getAll();
      final ranks = objectBox.rankBox.getAll();

      // ToMany relationships are automatically loaded when accessed

      // Exporting subjects with their embedded data

      // Create export data structure
      final exportData = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'appName': 'StudyForces',
        'data': {
          'subjects': subjects.map((s) => _subjectToJson(s)).toList(),
          'ranks': ranks.map((r) => _rankToJson(r)).toList(),
        },
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final jsonBytes = Uint8List.fromList(utf8.encode(jsonString));

      // Sessions are embedded within each subject's JSON data

      // Generate suggested filename
      final now = DateTime.now();
      final suggestedName =
          'studyforces_backup_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}.json';

      // Use file_picker to save the file
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save StudyForces Backup',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: jsonBytes,
      );

      if (outputFile != null) {
        return outputFile;
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Share the exported data file
  Future<void> shareExportedData(String filePath) async {
    try {
      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'StudyForces Data Backup');
    } catch (e) {
      throw Exception('Failed to share data: $e');
    }
  }

  /// Import data from a JSON file
  Future<void> importData(dynamic objectBox, String filePath) async {
    try {
      // Read file
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonString);

      // Validate file format
      if (data['appName'] != 'StudyForces') {
        throw Exception('Invalid backup file format');
      }

      // Clear existing data
      objectBox.subjectBox.removeAll();
      objectBox.studySessionBox.removeAll();
      objectBox.problemSessionBox.removeAll();
      objectBox.rankBox.removeAll();
      objectBox.ratingLogBox.removeAll();

      // Import subjects with their embedded sessions and relationships
      if (data['data']['subjects'] != null) {
        for (final subjectData in data['data']['subjects']) {
          final subject = _subjectFromJson(subjectData, {});
          subject.id = 0; // Let ObjectBox assign new ID

          // Save the subject first to get an ID
          objectBox.subjectBox.put(subject);

          // Now save the sessions to their respective boxes
          for (final session in subject.studySessions) {
            session.id = 0; // Let ObjectBox assign new ID
            objectBox.studySessionBox.put(session);
          }

          for (final session in subject.problemSessions) {
            session.id = 0; // Let ObjectBox assign new ID
            objectBox.problemSessionBox.put(session);
          }

          for (final rank in subject.ranks) {
            rank.id = 0; // Let ObjectBox assign new ID
            objectBox.rankBox.put(rank);
          }

          for (final log in subject.studyRatingHistory) {
            log.id = 0; // Let ObjectBox assign new ID
            objectBox.ratingLogBox.put(log);
          }

          for (final log in subject.problemRatingHistory) {
            log.id = 0; // Let ObjectBox assign new ID
            objectBox.ratingLogBox.put(log);
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  // JSON conversion methods
  Map<String, dynamic> _subjectToJson(Subject subject) {
    return {
      'id': subject.id,
      'name': subject.name,
      'description': subject.description,
      'baseRating': subject.baseRating,
      'maxRating': subject.maxRating,
      'studyEnabled': subject.studyEnabled,
      'problemEnabled': subject.problemEnabled,
      'unitName': subject.unitName,
      'studyFrequency': subject.studyFrequency,
      'studyGoalMin': subject.studyGoalMin,
      'studyGoalMax': subject.studyGoalMax,
      'studyStreak': subject.studyStreak,
      'studyRating': subject.studyRating,
      'lastProcessedStudy': subject.lastProcessedStudy?.toIso8601String(),
      'studyRatingConstant': subject.studyRatingConstant,
      'problemFrequency': subject.problemFrequency,
      'problemGoalMin': subject.problemGoalMin,
      'problemGoalMax': subject.problemGoalMax,
      'problemStreak': subject.problemStreak,
      'problemTimeGoal': subject.problemTimeGoal,
      'problemRating': subject.problemRating,
      'lastProcessedProblems': subject.lastProcessedProblems?.toIso8601String(),
      'problemRatingConstant': subject.problemRatingConstant,
      'ranks': subject.ranks.map((r) => _rankToJson(r)).toList(),
      'studySessions': subject.studySessions
          .map((s) => _studySessionToJson(s))
          .toList(),
      'problemSessions': subject.problemSessions
          .map((s) => _problemSessionToJson(s))
          .toList(),
      'studyRatingHistory': subject.studyRatingHistory
          .map((r) => _ratingLogToJson(r))
          .toList(),
      'problemRatingHistory': subject.problemRatingHistory
          .map((r) => _ratingLogToJson(r))
          .toList(),
    };
  }

  Subject _subjectFromJson(
    Map<String, dynamic> json,
    Map<int, int> rankIdMapping,
  ) {
    final subject = Subject();
    subject.name = json['name'] ?? '';
    subject.description = json['description'] ?? '';
    subject.baseRating = json['baseRating'] ?? 0;
    subject.maxRating = json['maxRating'] ?? 1000;
    subject.studyEnabled = json['studyEnabled'] ?? false;
    subject.problemEnabled = json['problemEnabled'] ?? false;
    subject.unitName = json['unitName'] ?? 'units';
    subject.studyFrequency = json['studyFrequency'] ?? 1;
    subject.studyGoalMin = json['studyGoalMin'] ?? 0;
    subject.studyGoalMax = json['studyGoalMax'] ?? 0;
    subject.studyStreak = json['studyStreak'] ?? 0;
    subject.studyRating = json['studyRating'] ?? 0;
    subject.lastProcessedStudy = json['lastProcessedStudy'] != null
        ? DateTime.parse(json['lastProcessedStudy'])
        : null;
    subject.studyRatingConstant = json['studyRatingConstant'] ?? 1.0;
    subject.problemFrequency = json['problemFrequency'] ?? 1;
    subject.problemGoalMin = json['problemGoalMin'] ?? 0;
    subject.problemGoalMax = json['problemGoalMax'] ?? 0;
    subject.problemStreak = json['problemStreak'] ?? 0;
    subject.problemTimeGoal = json['problemTimeGoal'] ?? 0;
    subject.problemRating = json['problemRating'] ?? 0;
    subject.lastProcessedProblems = json['lastProcessedProblems'] != null
        ? DateTime.parse(json['lastProcessedProblems'])
        : null;
    subject.problemRatingConstant = json['problemRatingConstant'] ?? 1.0;

    // Import embedded sessions and relationships
    if (json['studySessions'] != null) {
      for (final sessionData in json['studySessions']) {
        final session = _studySessionFromJson(sessionData);
        subject.studySessions.add(session);
      }
    }

    if (json['problemSessions'] != null) {
      for (final sessionData in json['problemSessions']) {
        final session = _problemSessionFromJson(sessionData);
        subject.problemSessions.add(session);
      }
    }

    if (json['ranks'] != null) {
      for (final rankData in json['ranks']) {
        final rank = _rankFromJson(rankData);
        subject.ranks.add(rank);
      }
    }

    if (json['studyRatingHistory'] != null) {
      for (final logData in json['studyRatingHistory']) {
        final log = _ratingLogFromJson(logData);
        subject.studyRatingHistory.add(log);
      }
    }

    if (json['problemRatingHistory'] != null) {
      for (final logData in json['problemRatingHistory']) {
        final log = _ratingLogFromJson(logData);
        subject.problemRatingHistory.add(log);
      }
    }

    return subject;
  }

  Map<String, dynamic> _studySessionToJson(StudySession session) {
    return {
      'id': session.id,
      'when': session.when.toIso8601String(),
      'units': session.units,
      'applied': session.applied,
    };
  }

  StudySession _studySessionFromJson(Map<String, dynamic> json) {
    final session = StudySession();
    session.when = DateTime.parse(json['when']);
    session.units = json['units'] ?? 0.0;
    session.applied = json['applied'] ?? false;
    return session;
  }

  Map<String, dynamic> _problemSessionToJson(ProblemSession session) {
    return {
      'id': session.id,
      'when': session.when.toIso8601String(),
      'problemsAttempted': session.problemsAttempted,
      'problemsCorrect': session.problemsCorrect,
      'durationSeconds': session.durationSeconds,
      'applied': session.applied,
    };
  }

  ProblemSession _problemSessionFromJson(Map<String, dynamic> json) {
    final session = ProblemSession();
    session.when = DateTime.parse(json['when']);
    session.problemsAttempted = json['problemsAttempted'] ?? 0;
    session.problemsCorrect = json['problemsCorrect'] ?? 0;
    session.durationSeconds = json['durationSeconds'] ?? 0;
    session.applied = json['applied'] ?? false;
    return session;
  }

  Map<String, dynamic> _rankToJson(Rank rank) {
    return {
      'id': rank.id,
      'requiredRating': rank.requiredRating,
      'name': rank.name,
      'description': rank.description,
      'color': rank.color,
      'glow': rank.glow,
    };
  }

  Rank _rankFromJson(Map<String, dynamic> json) {
    final rank = Rank();
    rank.requiredRating = json['requiredRating'] ?? 0;
    rank.name = json['name'] ?? '';
    rank.description = json['description'] ?? '';
    rank.color = json['color'] ?? '#FF6200EA';
    rank.glow = json['glow'] ?? false;
    return rank;
  }

  Map<String, dynamic> _ratingLogToJson(RatingLog log) {
    return {
      'id': log.id,
      'when': log.when.toIso8601String(),
      'rating': log.rating,
    };
  }

  RatingLog _ratingLogFromJson(Map<String, dynamic> json) {
    final log = RatingLog();
    log.when = DateTime.parse(json['when']);
    log.rating = json['rating'] ?? 0;
    return log;
  }
}
