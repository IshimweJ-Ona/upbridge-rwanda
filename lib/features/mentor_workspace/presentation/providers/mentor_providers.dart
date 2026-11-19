// Owner: Student 3 · Mentorship & mentor workspace
// Holds: Providers for the mentor home, queue, mentees and profile.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/features/mentor_workspace/data/repositories/mentee_repository_impl.dart';
import 'package:upbridge/features/mentor_workspace/data/repositories/mentor_profile_repository_impl.dart';
import 'package:upbridge/features/mentor_workspace/domain/entities/mentee.dart';
import 'package:upbridge/features/mentor_workspace/domain/entities/mentor_profile.dart';
import 'package:upbridge/features/mentor_workspace/domain/repositories/mentee_repository.dart';
import 'package:upbridge/features/mentor_workspace/domain/repositories/mentor_profile_repository.dart';
import 'package:upbridge/features/mentor_workspace/domain/repositories/review_repository.dart';
import 'package:upbridge/features/mentor_workspace/domain/usecases/send_review.dart';
import 'package:upbridge/features/mentorship/domain/entities/session.dart';
import 'package:upbridge/features/mentorship/presentation/providers/mentorship_providers.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

export 'package:upbridge/features/mentorship/presentation/providers/mentorship_providers.dart'
    show currentUserIdProvider, mentorSessionsProvider, mentorshipErrorText;

/// Clock for "quiet" mentees and open slots. Tests override it.
final mentorClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

// ── Sessions (MS1, home) ──

/// The mentor's sessions split into the sections of MS1.
class MentorSessionGroups {
  MentorSessionGroups(List<Session> sessions)
    : requests = [
        for (final s in sessions)
          if (s.state == SessionState.requested) s,
      ],
      upcoming = [
        for (final s in sessions)
          if (s.state == SessionState.upcoming) s,
      ],
      past = [
        for (final s in sessions.reversed)
          if (s.state == SessionState.done) s,
      ];

  final List<Session> requests;
  final List<Session> upcoming;
  final List<Session> past;

  bool get isEmpty => requests.isEmpty && upcoming.isEmpty && past.isEmpty;
}

/// Mentor answers to sessions. State holds the IDs being saved, which
/// blocks double taps. The repository re-checks each change is allowed.
class MentorSessionActionsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// Confirms a request and attaches the mentor's meeting link when set.
  Future<void> accept(String sessionId, {String meetingLink = ''}) => _run(
    sessionId,
    MentorSessionStatus.confirmed,
    meetingLink: meetingLink.trim().isEmpty ? null : meetingLink.trim(),
  );

  Future<void> decline(String sessionId) =>
      _run(sessionId, MentorSessionStatus.declined);

  Future<void> complete(String sessionId) =>
      _run(sessionId, MentorSessionStatus.completed);

  Future<void> cancel(String sessionId) =>
      _run(sessionId, MentorSessionStatus.cancelled);

  Future<void> _run(
    String sessionId,
    String toStatus, {
    String? meetingLink,
  }) async {
    if (state.contains(sessionId)) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw const PermissionFailure('signed-out');

    state = {...state, sessionId};
    try {
      await ref
          .read(sessionRepositoryProvider)
          .changeStatus(
            sessionId,
            toStatus: toStatus,
            by: SessionActor.mentor,
            actorId: userId,
            meetingLink: meetingLink,
          );
    } finally {
      if (ref.mounted) state = {...state}..remove(sessionId);
    }
  }
}

final mentorSessionActionsProvider =
    NotifierProvider<MentorSessionActionsNotifier, Set<String>>(
      MentorSessionActionsNotifier.new,
    );

// ── Mentees (MM1, MM2) ──

final menteeRepositoryProvider = Provider<MenteeRepository>(
  (ref) => MenteeRepositoryImpl(ref.watch(sessionRepositoryProvider)),
);

final menteesProvider = StreamProvider<List<MenteeRecord>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const <MenteeRecord>[]);
  return ref.watch(menteeRepositoryProvider).watchMentees(userId);
});

final menteeProvider = StreamProvider.family<MenteeRecord?, String>((
  ref,
  youthId,
) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  return ref.watch(menteeRepositoryProvider).watchMentee(userId, youthId);
});

/// Search text and chip on the Mentees screen.
class MenteeFilter {
  const MenteeFilter({this.chip = all, this.query = ''});

  static const all = 'All';
  static const needsAttention = 'Needs attention';
  static const onTrack = 'On track';
  static const chips = [all, needsAttention, onTrack];

  final String chip;
  final String query;

  List<MenteeRecord> apply(List<MenteeRecord> mentees, DateTime now) {
    final q = query.trim().toLowerCase();
    return [
      for (final m in mentees)
        if ((switch (chip) {
              needsAttention => m.needsAttentionAt(now),
              onTrack => !m.needsAttentionAt(now),
              _ => true,
            }) &&
            (q.isEmpty || m.name.toLowerCase().contains(q)))
          m,
    ];
  }
}

// ── Profile (MP1) ──

final mentorProfileRepositoryProvider = Provider<MentorProfileRepository>(
  (ref) => MentorProfileRepositoryImpl(
    ref.watch(firestoreProvider),
    clock: ref.watch(mentorClockProvider),
  ),
);

final myMentorProfileProvider = StreamProvider<MentorProfile?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  return ref.watch(mentorProfileRepositoryProvider).watchProfile(userId);
});

/// Edits on MP1 before they are saved. Null draft = nothing changed.
class ProfileEditState {
  const ProfileEditState({this.draft, this.saving = false});

  final MentorProfile? draft;
  final bool saving;
}

class ProfileEditNotifier extends Notifier<ProfileEditState> {
  @override
  ProfileEditState build() => const ProfileEditState();

  void edit(MentorProfile updated) =>
      state = ProfileEditState(draft: updated, saving: state.saving);

  void discard() => state = const ProfileEditState();

  /// Returns false when a save is already running or there is nothing to save.
  Future<bool> save() async {
    final draft = state.draft;
    if (state.saving || draft == null) return false;
    state = ProfileEditState(draft: draft, saving: true);
    try {
      await ref.read(mentorProfileRepositoryProvider).save(draft);
      if (ref.mounted) state = const ProfileEditState();
      return true;
    } catch (_) {
      if (ref.mounted) state = ProfileEditState(draft: draft);
      rethrow;
    }
  }
}

final profileEditProvider =
    NotifierProvider<ProfileEditNotifier, ProfileEditState>(
      ProfileEditNotifier.new,
    );

// ── Reviews (MR1–MR4) ──

/// DEMO ONLY: saves reviews into the in-memory demo store. Nothing is
/// persisted. Replace with a Firestore ReviewRepository once the
/// submissions/reviews contract from Learning exists.
class DemoReviewRepository implements ReviewRepository {
  DemoReviewRepository(this._store);

  final AppStore _store;

  @override
  Future<void> sendReview({
    required String submissionId,
    required List<CriterionResult> results,
    required String summary,
    required bool approved,
  }) async {
    _store.sendReview(submissionId, results, summary);
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => DemoReviewRepository(ref.read(appStoreProvider.notifier)),
);

final sendReviewProvider = Provider<SendReview>(
  (ref) => SendReview(ref.watch(reviewRepositoryProvider)),
);
