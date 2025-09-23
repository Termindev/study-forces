import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_forces/widgets/add_subject.dart';
import '../stores/subject_store.dart';
import './subject_page.dart';
import 'add_study_session.dart';
import 'add_problem_session.dart';
import '../components/subject/subject_card.dart';
import '../components/common/loading_widget.dart';
import '../components/common/empty_state_widget.dart';
import '../components/common/error_widget.dart';
import '../constants/app_constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SubjectStore>(
        builder: (context, store, child) {
          if (store.loading) {
            return const LoadingWidget(message: 'Loading subjects...');
          }

          if (store.error != null) {
            return AppErrorWidget(
              message: store.error!,
              onRetry: () {
                store.subjects = store.subjectBox.getAll();
              },
            );
          }

          if (store.subjects.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.school_outlined,
              title: 'No subjects yet',
              subtitle:
                  'Tap + to add your first subject and start tracking your progress!',
              action: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddSubject()),
                  ).then((_) {
                    final store = Provider.of<SubjectStore>(
                      context,
                      listen: false,
                    );
                    store.subjects = store.subjectBox.getAll();
                  });
                },
                child: const Icon(Icons.add),
              ),
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
              itemCount: store.subjects.length,
              itemBuilder: (context, index) {
                final subject = store.subjects[index];
                return SubjectCard(
                  subject: subject,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SubjectPage(subjectId: subject.id),
                      ),
                    );
                  },
                  onStudyTap: subject.studyEnabled
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddStudySessionPage(subject: subject),
                            ),
                          );
                        }
                      : null,
                  onProblemTap: subject.problemEnabled
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddProblemSessionPage(subjectId: subject.id),
                            ),
                          );
                        }
                      : null,
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
            MaterialPageRoute(builder: (context) => const AddSubject()),
          ).then((_) {
            final store = Provider.of<SubjectStore>(context, listen: false);
            store.subjects = store.subjectBox.getAll();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
