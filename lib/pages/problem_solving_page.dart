import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/subject_store.dart';
import '../models/subject.dart';
import '../models/problem_session.dart';
import 'add_problem_session.dart';
import 'select_subject_for_problem.dart';

class ProblemSolvingPage extends StatefulWidget {
  const ProblemSolvingPage({super.key});

  @override
  State<ProblemSolvingPage> createState() => _ProblemSolvingPageState();
}

class _ProblemSolvingPageState extends State<ProblemSolvingPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SubjectStore>(
      builder: (context, store, child) {
        if (store.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get all problem sessions from all subjects
        final allProblemSessions = <MapEntry<Subject, ProblemSession>>[];
        for (final subject in store.subjects) {
          if (subject.problemEnabled) {
            for (final session in subject.problemSessions) {
              allProblemSessions.add(MapEntry(subject, session));
            }
          }
        }

        // Sort by date (newest first)
        allProblemSessions.sort((a, b) => b.value.when.compareTo(a.value.when));

        // Group by date
        final groupedSessions =
            <String, List<MapEntry<Subject, ProblemSession>>>{};
        for (final entry in allProblemSessions) {
          final dateKey = _formatDate(entry.value.when);
          groupedSessions.putIfAbsent(dateKey, () => []).add(entry);
        }

        if (groupedSessions.isEmpty) {
          return Scaffold(
            body: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Problem Sessions Yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start solving problems to see your sessions here',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _navigateToSubjectSelector(context),
              child: const Icon(Icons.add),
            ),
          );
        }

        return Scaffold(
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedSessions.length,
            itemBuilder: (context, index) {
              final dateKey = groupedSessions.keys.elementAt(index);
              final sessions = groupedSessions[dateKey]!;
              final isLastGroup = index == groupedSessions.length - 1;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      dateKey,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ),

                  // Sessions for this date
                  ...sessions.map(
                    (entry) => _buildSessionCard(context, store, entry),
                  ),

                  if (!isLastGroup) ...[
                    const SizedBox(height: 16),
                    Divider(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                      thickness: 1,
                    ),
                    const SizedBox(height: 8),
                  ] else
                    const SizedBox(height: 16),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _navigateToSubjectSelector(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    SubjectStore store,
    MapEntry<Subject, ProblemSession> entry,
  ) {
    final subject = entry.key;
    final session = entry.value;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: session.applied
              ? Colors.green.withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
          child: Icon(
            session.applied ? Icons.check : Icons.schedule,
            color: session.applied ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          subject.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${session.problemsAttempted} attempted, ${session.problemsCorrect} correct',
            ),
            Text(
              '${_formatDuration(session.durationSeconds)} • ${_formatTime(session.when)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (session.applied)
              Text(
                'Processed',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) =>
              _handleMenuAction(context, store, subject, session, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    SubjectStore store,
    Subject subject,
    ProblemSession session,
    String action,
  ) {
    switch (action) {
      case 'edit':
        _editSession(context, store, subject, session);
        break;
      case 'delete':
        _deleteSession(context, store, subject, session);
        break;
    }
  }

  void _editSession(
    BuildContext context,
    SubjectStore store,
    Subject subject,
    ProblemSession session,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProblemSessionPage(
          subjectId: subject.id,
          existingSession: session,
        ),
      ),
    );
  }

  void _deleteSession(
    BuildContext context,
    SubjectStore store,
    Subject subject,
    ProblemSession session,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Problem Session'),
        content: Text(
          'Are you sure you want to delete this problem session?\n\n'
          '${session.problemsAttempted} attempted, ${session.problemsCorrect} correct\n'
          'on ${_formatDate(session.when)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await store.deleteProblemSessionSmart(subject.id, session.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Problem session deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting session: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToSubjectSelector(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectSubjectForProblemPage(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == today) {
      return 'Today';
    } else if (sessionDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }
}
