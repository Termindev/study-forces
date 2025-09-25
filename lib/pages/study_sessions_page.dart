import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/subject_store.dart';
import '../models/subject.dart';
import '../models/study_session.dart';
import 'add_study_session.dart';
import 'select_subject_for_study.dart';
import '../components/session/session_list_item.dart';
import '../components/common/loading_widget.dart';
import '../components/common/empty_state_widget.dart';
import '../components/common/error_widget.dart';
import '../constants/app_constants.dart';

class StudySessionsPage extends StatefulWidget {
  const StudySessionsPage({super.key});

  @override
  State<StudySessionsPage> createState() => _StudySessionsPageState();
}

class _StudySessionsPageState extends State<StudySessionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SubjectStore>(
        builder: (context, store, child) {
          if (store.loading) {
            return const LoadingWidget(message: 'Loading study sessions...');
          }

          if (store.error != null) {
            return AppErrorWidget(
              message: store.error!,
              onRetry: () {
                store.subjects = store.subjectBox.getAll();
              },
            );
          }

          // Get all study sessions from all subjects
          final allStudySessions = <MapEntry<Subject, StudySession>>[];
          for (final subject in store.subjects) {
            if (subject.studyEnabled) {
              for (final session in subject.studySessions) {
                allStudySessions.add(MapEntry(subject, session));
              }
            }
          }

          // Sort by date (newest first)
          allStudySessions.sort((a, b) => b.value.when.compareTo(a.value.when));

          // Group by date
          final groupedSessions =
              <String, List<MapEntry<Subject, StudySession>>>{};
          for (final entry in allStudySessions) {
            final dateKey = _formatDate(entry.value.when);
            groupedSessions.putIfAbsent(dateKey, () => []).add(entry);
          }

          if (groupedSessions.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.book_outlined,
              title: 'No Study Sessions Yet',
              subtitle:
                  'Start your first study session to track your progress!',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              store.subjects = store.subjectBox.getAll();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.spacingS,
              ),
              itemCount: groupedSessions.length,
              itemBuilder: (context, index) {
                final dateKey = groupedSessions.keys.elementAt(index);
                final sessions = groupedSessions[dateKey]!;
                final isLastGroup = index == groupedSessions.length - 1;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingM,
                        vertical: AppConstants.spacingS,
                      ),
                      child: Text(
                        dateKey,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...sessions.map((entry) {
                      final subject = entry.key;
                      final session = entry.value;

                      return SessionListItem(
                        session: session,
                        isStudySession: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddStudySessionPage(
                                subject: subject,
                                existingSession: session,
                              ),
                            ),
                          );
                        },
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddStudySessionPage(
                                subject: subject,
                                existingSession: session,
                              ),
                            ),
                          );
                        },
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Study Session'),
                              content: const Text(
                                'Are you sure you want to delete this study session?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            try {
                              await store.deleteStudySessionSmart(
                                subject.id,
                                session.id,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Study session deleted successfully',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          }
                        },
                      );
                    }),

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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SelectSubjectForStudyPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
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
}
