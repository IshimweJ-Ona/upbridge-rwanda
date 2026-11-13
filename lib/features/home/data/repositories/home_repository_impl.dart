// Loads the youth overview from existing shared collection contracts in parallel.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/features/home/domain/entities/home_summary.dart';
import 'package:upbridge/features/home/domain/entities/next_step.dart';
import 'package:upbridge/features/home/domain/repositories/home_repository.dart';
import 'package:upbridge/shared/services/firebase/firestore_schema.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({required this._firestore});

  final FirebaseFirestore _firestore;

  @override
  Future<HomeSummary> loadSummary(String userId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'Must not be empty.');
    }
    final progress = _firestore
        .collection(Fs.taskProgress)
        .where('userId', isEqualTo: userId);
    final submissions = _firestore
        .collection(Fs.submissions)
        .where('userId', isEqualTo: userId);
    final projects = _firestore
        .collection(Fs.projects)
        .where('ownerId', isEqualTo: userId);
    final publishedOpportunities = _firestore
        .collection(Fs.opportunities)
        .where('status', isEqualTo: OpportunityStatus.published);

    final results = await Future.wait([
      progress.get(),
      submissions.get(),
      projects.get(),
      publishedOpportunities.get(),
    ]);
    final progressDocs = results[0].docs;
    final submissionDocs = results[1].docs;
    final approvedTasks = progressDocs
        .where((doc) => doc.data()['status'] == SubmissionStatus.approved)
        .length;
    final pendingReviews = submissionDocs
        .where((doc) => doc.data()['status'] == SubmissionStatus.submitted)
        .length;
    final revision = progressDocs
        .where(
          (doc) => doc.data()['status'] == SubmissionStatus.changesRequested,
        )
        .firstOrNull;
    final nextStep = revision == null
        ? (pendingReviews > 0
              ? const NextStep(
                  kind: NextStepKind.awaitReview,
                  title: 'Work is with your mentor',
                  message: 'You will see feedback here when it is ready.',
                )
              : null)
        : NextStep(
            kind: NextStepKind.reviseTask,
            title: 'Update a task',
            message: 'Your mentor requested a change to one of your tasks.',
            route: '/task/${revision.data()['taskId'] ?? ''}',
          );

    return HomeSummary(
      approvedTasks: approvedTasks,
      pendingReviews: pendingReviews,
      projectCount: results[2].size,
      publishedOpportunityCount: results[3].size,
      nextStep: nextStep,
    );
  }
}
