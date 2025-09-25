import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/subject_store.dart';
import './edit_subject_page.dart'; // We'll create this next
import '../utils/rank_utils.dart';
import '../widgets/rating_history_chart.dart';
import '../models/rank.dart';

class SubjectPage extends StatefulWidget {
  final int subjectId;

  const SubjectPage({super.key, required this.subjectId});

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  Future<void> _resetAndRecalculate(BuildContext context) async {
    final store = Provider.of<SubjectStore>(context, listen: false);
    final subject = store.getById(widget.subjectId);

    if (subject == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Subject not found')));
      return;
    }

    try {
      // Reset and recalculate both study and problem ratings
      subject.resetAndRecalculateStudy();
      subject.resetAndRecalculateProblem();

      // Save the changes
      await store.updateSubject(subject);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject ratings reset and recalculated successfully'),
        ),
      );

      // Pop the page to go back
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resetting ratings: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<SubjectStore>(context);
    final subject = store.getById(widget.subjectId);

    if (subject == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Subject Not Found')),
        body: const Center(child: Text('Subject not found')),
      );
    }

    // Calculate performance for the current frequency window
    final now = DateTime.now();
    DateTime studyStartDate, problemStartDate;

    if (subject.studyEnabled && subject.lastProcessedStudy != null) {
      studyStartDate = subject.lastProcessedStudy!;
    } else {
      studyStartDate = now.subtract(Duration(days: subject.studyFrequency));
    }

    if (subject.problemEnabled && subject.lastProcessedProblems != null) {
      problemStartDate = subject.lastProcessedProblems!;
    } else {
      problemStartDate = now.subtract(Duration(days: subject.problemFrequency));
    }
    print(studyStartDate);
    print(now);
    print(subject.lastProcessedStudy);
    final studyPerformance = subject.studyEnabled
        ? subject.getStudyPerformance(studyStartDate, now)
        : 0;

    final problemPerformance = subject.problemEnabled
        ? subject.getProblemPerformance(problemStartDate, now)
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _resetAndRecalculate(context),
            tooltip: 'Reset & Recalculate Ratings',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditSubjectPage(subjectId: subject.id),
                ),
              ).then((_) {
                // Refresh the page when returning from editing
                setState(() {});
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (subject.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  subject.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),

            // Study Rating and Performance
            if (subject.studyEnabled)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Study Rating & Performance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Rating:'),
                          Text(
                            subject.studyRating.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Performance:'),
                          Text(
                            studyPerformance.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Performance Window:'),
                          Text('${subject.studyFrequency} days'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            if (subject.studyEnabled) const SizedBox(height: 16),

            // Problem Solving Rating and Performance
            if (subject.problemEnabled)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Problem Solving Rating & Performance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Rating:'),
                          Text(
                            subject.problemRating.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Performance:'),
                          Text(
                            problemPerformance.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Performance Window:'),
                          Text('${subject.problemFrequency} days'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Study Statistics (only if study is enabled)
            if (subject.studyEnabled)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Study Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Study Sessions:'),
                          Text(subject.studySessions.length.toString()),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Study Streak:'),
                          Text(subject.calculateStudyStreak().toString()),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Study Frequency:'),
                          Text('${subject.studyFrequency} days'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Study Goal:'),
                          Text(
                            '${subject.studyGoalMin}-${subject.studyGoalMax} ${subject.unitName}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            if (subject.studyEnabled) const SizedBox(height: 16),

            // Problem Solving Statistics (only if problem solving is enabled)
            if (subject.problemEnabled)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Problem Solving Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Problem Sessions:'),
                          Text(subject.problemSessions.length.toString()),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Problem Streak:'),
                          Text(subject.calculateProblemStreak().toString()),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Problem Frequency:'),
                          Text('${subject.problemFrequency} days'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Problem Goal:'),
                          Text(
                            '${subject.problemGoalMin}-${subject.problemGoalMax} problems',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Time Goal:'),
                          Text('${subject.problemTimeGoal} seconds/problem'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Rating History Charts
            if (subject.studyEnabled && subject.studyRatingHistory.isNotEmpty)
              RatingHistoryChart(
                ratingHistory: subject.studyRatingHistory,
                title: 'Study Rating History',
                color: Colors.blue,
                maxRating: subject.maxRating,
              ),

            if (subject.studyEnabled && subject.studyRatingHistory.isNotEmpty)
              const SizedBox(height: 16),

            if (subject.problemEnabled &&
                subject.problemRatingHistory.isNotEmpty)
              RatingHistoryChart(
                ratingHistory: subject.problemRatingHistory,
                title: 'Problem Rating History',
                color: Colors.green,
                maxRating: subject.maxRating,
              ),

            if (subject.problemEnabled &&
                subject.problemRatingHistory.isNotEmpty)
              const SizedBox(height: 16),

            // Ranks Section
            if (subject.ranks.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ranks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Current ranks
                      if (subject.studyEnabled || subject.problemEnabled) ...[
                        const Text(
                          'Current Ranks:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (subject.studyEnabled) ...[
                              Builder(
                                builder: (context) {
                                  final studyRank = RankUtils.getCurrentRank(
                                    subject.studyRating,
                                    subject.ranks,
                                  );
                                  if (studyRank != null) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(
                                          int.parse(
                                            studyRank.color.replaceFirst(
                                              '#',
                                              '0x',
                                            ),
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: studyRank.glow
                                            ? [
                                                BoxShadow(
                                                  color: Color(
                                                    int.parse(
                                                      studyRank.color
                                                          .replaceFirst(
                                                            '#',
                                                            '0x',
                                                          ),
                                                    ),
                                                  ).withOpacity(0.5),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${studyRank.name} (Study)',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Text(
                                        'No Study Rank',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (subject.problemEnabled) ...[
                              Builder(
                                builder: (context) {
                                  final problemRank = RankUtils.getCurrentRank(
                                    subject.problemRating,
                                    subject.ranks,
                                  );
                                  if (problemRank != null) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(
                                          int.parse(
                                            problemRank.color.replaceFirst(
                                              '#',
                                              '0x',
                                            ),
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: problemRank.glow
                                            ? [
                                                BoxShadow(
                                                  color: Color(
                                                    int.parse(
                                                      problemRank.color
                                                          .replaceFirst(
                                                            '#',
                                                            '0x',
                                                          ),
                                                    ),
                                                  ).withOpacity(0.5),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${problemRank.name} (Problem)',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Text(
                                        'No Problem Rank',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      // All available ranks
                      const Text(
                        'All Ranks:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120, // Fixed height for horizontal scrolling
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                (() {
                                  final sortedRanks = List<Rank>.from(
                                    subject.ranks,
                                  );
                                  sortedRanks.sort(
                                    (a, b) => a.requiredRating.compareTo(
                                      b.requiredRating,
                                    ),
                                  );
                                  return sortedRanks;
                                })().map((rank) {
                                  final color = Color(
                                    int.parse(
                                      rank.color.replaceFirst('#', '0x'),
                                    ),
                                  );
                                  final isStudyRank =
                                      subject.studyEnabled &&
                                      RankUtils.getCurrentRank(
                                            subject.studyRating,
                                            subject.ranks,
                                          )?.id ==
                                          rank.id;
                                  final isProblemRank =
                                      subject.problemEnabled &&
                                      RankUtils.getCurrentRank(
                                            subject.problemRating,
                                            subject.ranks,
                                          )?.id ==
                                          rank.id;
                                  final isCurrentRank =
                                      isStudyRank || isProblemRank;

                                  return Container(
                                    width:
                                        200, // Fixed width for horizontal scrolling
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isCurrentRank
                                          ? color.withOpacity(0.1)
                                          : Colors.grey[800],
                                      border: Border.all(
                                        color: isCurrentRank
                                            ? color
                                            : Colors.grey[300]!,
                                        width: isCurrentRank ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: isCurrentRank && rank.glow
                                          ? [
                                              BoxShadow(
                                                color: color.withOpacity(0.3),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: rank.glow
                                                    ? [
                                                        BoxShadow(
                                                          color: color
                                                              .withOpacity(0.5),
                                                          blurRadius: 6,
                                                          spreadRadius: 1,
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: const Icon(
                                                Icons.star,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                rank.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: isCurrentRank
                                                      ? color
                                                      : null,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isCurrentRank) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'CURRENT',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          'Rating: ${rank.requiredRating}',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 10,
                                          ),
                                        ),
                                        if (rank.description.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            rank.description,
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 10,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        if (rank.glow)
                                          const Text(
                                            '✨ Glows',
                                            style: TextStyle(
                                              color: Colors.amber,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
