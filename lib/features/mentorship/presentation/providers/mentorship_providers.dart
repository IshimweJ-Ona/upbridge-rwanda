// Riverpod providers for mentors and sessions.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/features/mentorship/data/datasources/mentor_directory_data_source.dart';
import 'package:upbridge/features/mentorship/data/datasources/session_remote_data_source.dart';
import 'package:upbridge/features/mentorship/data/repositories/mentor_directory_repository_impl.dart';
import 'package:upbridge/features/mentorship/data/repositories/session_repository_impl.dart';
import 'package:upbridge/features/mentorship/domain/entities/mentor.dart';
import 'package:upbridge/features/mentorship/domain/entities/session.dart';
import 'package:upbridge/features/mentorship/domain/entities/session_slot.dart';
import 'package:upbridge/features/mentorship/domain/repositories/mentor_directory_repository.dart';
import 'package:upbridge/features/mentorship/domain/repositories/session_repository.dart';
import 'package:upbridge/features/mentorship/domain/usecases/free_slots.dart';
import 'package:upbridge/features/mentorship/domain/usecases/request_session.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

/// Friendly text for validation, repository and raw Firebase errors.
String mentorshipErrorText(Object error) => switch (error) {
  ArgumentError(:final message) => '$message',
  NetworkFailure() => 'You seem to be offline. Check your connection.',
  PermissionFailure() => 'You do not have access to this yet.',
  NotFoundFailure() => 'That information is no longer available.',
  ConflictFailure() => 'This session has changed. Check it and try again.',
  AppFailure() => 'Something went wrong. Please try again.',
  _ => errorMessage(error),
};

final mentorDirectoryDataSourceProvider = Provider<MentorDirectoryDataSource>(
  (ref) => MentorDirectoryDataSource(firestore: ref.watch(firestoreProvider)),
);

final sessionRemoteDataSourceProvider = Provider<SessionRemoteDataSource>(
  (ref) => SessionRemoteDataSource(firestore: ref.watch(firestoreProvider)),
);

final mentorDirectoryRepositoryProvider = Provider<MentorDirectoryRepository>(
  (ref) => MentorDirectoryRepositoryImpl(
    dataSource: ref.watch(mentorDirectoryDataSourceProvider),
  ),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepositoryImpl(
    dataSource: ref.watch(sessionRemoteDataSourceProvider),
  ),
);

final requestSessionProvider = Provider<RequestSession>(
  (ref) => RequestSession(ref.watch(sessionRepositoryProvider)),
);

final freeSlotsProvider = Provider<FreeSlots>((ref) => const FreeSlots());

final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).value?.uid,
);

/// Stored on the session so mentors never need to read users/{uid}.
final currentUserNameProvider = Provider<String>((ref) {
  final user = ref.watch(authStateProvider).value;
  final name = user?.displayName?.trim() ?? '';
  return name.isNotEmpty ? name : user?.email?.split('@').first ?? '';
});

final mentorsProvider = StreamProvider<List<Mentor>>(
  (ref) => ref.watch(mentorDirectoryRepositoryProvider).watchMentors(),
);

/// Search text and area chip on the Mentors screen (M1).
class MentorFilter {
  const MentorFilter({this.area = allAreas, this.query = ''});

  static const allAreas = 'All';

  final String area;
  final String query;

  bool get isActive => area != allAreas || query.trim().isNotEmpty;

  /// Matches name, skill or city, case-insensitive.
  List<Mentor> apply(List<Mentor> mentors) {
    final q = query.trim().toLowerCase();
    return [
      for (final m in mentors)
        if ((area == allAreas || m.area == area) &&
            (q.isEmpty ||
                m.name.toLowerCase().contains(q) ||
                m.city.toLowerCase().contains(q) ||
                m.skills.any((s) => s.toLowerCase().contains(q))))
          m,
    ];
  }

  /// "All" first, then every area the mentors actually have.
  static List<String> areasOf(List<Mentor> mentors) => [
    allAreas,
    ...{for (final m in mentors) m.area}.toList()..sort(),
  ];
}

class MentorFilterNotifier extends Notifier<MentorFilter> {
  @override
  MentorFilter build() => const MentorFilter();

  void setArea(String area) =>
      state = MentorFilter(area: area, query: state.query);

  void setQuery(String query) =>
      state = MentorFilter(area: state.area, query: query);

  void clear() => state = const MentorFilter();
}

final mentorFilterProvider =
    NotifierProvider<MentorFilterNotifier, MentorFilter>(
      MentorFilterNotifier.new,
    );

/// Your mentor is the one you have an upcoming or finished session with.
String? yourMentorId(List<Session> sessions) {
  for (final state in [SessionState.upcoming, SessionState.done]) {
    for (final s in sessions) {
      if (s.state == state && s.mentorId.isNotEmpty) return s.mentorId;
    }
  }
  return null;
}

final mentorProvider = StreamProvider.family<Mentor?, String>(
  (ref, mentorId) =>
      ref.watch(mentorDirectoryRepositoryProvider).watchMentor(mentorId),
);

final mySessionsProvider = StreamProvider<List<Session>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const <Session>[]);
  return ref.watch(sessionRepositoryProvider).watchForYouth(userId);
});

final sessionProvider = StreamProvider.family<Session?, String>(
  (ref, sessionId) =>
      ref.watch(sessionRepositoryProvider).watchSession(sessionId),
);

/// Slots this youth can still book with the mentor.
final freeSlotsForMentorProvider =
    Provider.family<AsyncValue<List<SessionSlot>>, String>((ref, mentorId) {
      final mentor = ref.watch(mentorProvider(mentorId));
      final mine = ref.watch(mySessionsProvider);
      final freeSlots = ref.watch(freeSlotsProvider);
      return switch ((mentor, mine)) {
        (AsyncError(:final error, :final stackTrace), _) ||
        (
          _,
          AsyncError(:final error, :final stackTrace),
        ) => AsyncError(error, stackTrace),
        (AsyncData(:final value), AsyncData(value: final sessions)) =>
          AsyncData(
            value == null || !value.accepting
                ? const <SessionSlot>[]
                : freeSlots(
                    offered: value.slots,
                    mySessions: sessions,
                    now: DateTime.now(),
                  ),
          ),
        _ => const AsyncLoading(),
      };
    });

/// Choices on the Request a session form (M3).
class RequestForm {
  const RequestForm({this.slot, this.topic, this.sending = false});

  final SessionSlot? slot;
  final String? topic;
  final bool sending;
}

class RequestFormNotifier extends Notifier<RequestForm> {
  RequestFormNotifier(this.mentorId);

  final String mentorId;

  @override
  RequestForm build() => const RequestForm();

  void pickSlot(SessionSlot slot) => state = RequestForm(
    slot: slot,
    topic: state.topic,
    sending: state.sending,
  );

  void pickTopic(String topic) => state = RequestForm(
    slot: state.slot,
    topic: topic,
    sending: state.sending,
  );

  /// Returns the new session ID, or null if a send is already running.
  Future<String?> send({required Mentor mentor, required String note}) async {
    final startsAt = state.slot?.startsAt;
    final topic = state.topic;
    if (state.sending || startsAt == null || topic == null) return null;

    state = RequestForm(slot: state.slot, topic: topic, sending: true);
    try {
      return await ref.read(requestSessionProvider)(
        SessionRequest(
          requesterId: ref.read(currentUserIdProvider) ?? '',
          requesterName: ref.read(currentUserNameProvider),
          mentorId: mentor.id,
          mentorName: mentor.name,
          startsAt: startsAt,
          topic: topic,
          note: note,
        ),
      );
    } finally {
      if (ref.mounted) {
        state = RequestForm(slot: state.slot, topic: state.topic);
      }
    }
  }
}

final requestFormProvider = NotifierProvider.autoDispose
    .family<RequestFormNotifier, RequestForm, String>(RequestFormNotifier.new);

/// The sections of My mentorship (M5).
class MySessionGroups {
  MySessionGroups(List<Session> sessions)
    : upcoming = [
        for (final s in sessions)
          if (s.state == SessionState.upcoming) s,
      ],
      requests = [
        for (final s in sessions)
          if (s.state == SessionState.requested ||
              s.state == SessionState.declined)
            s,
      ],
      past = [
        for (final s in sessions.reversed)
          if (s.state == SessionState.done) s,
      ];

  final List<Session> upcoming;
  final List<Session> requests;
  final List<Session> past;

  bool get isEmpty => upcoming.isEmpty && requests.isEmpty && past.isEmpty;
}

/// Youth actions on a session. State holds the IDs being saved, which blocks double taps.
class SessionActionsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  Future<void> cancel(String sessionId) => _run(
    sessionId,
    (repository, userId) => repository.changeStatus(
      sessionId,
      toStatus: MentorSessionStatus.cancelled,
      by: SessionActor.youth,
      actorId: userId,
    ),
  );

  Future<void> withdraw(String sessionId) => _run(
    sessionId,
    (repository, userId) => repository.withdraw(sessionId, youthId: userId),
  );

  Future<void> _run(
    String sessionId,
    Future<void> Function(SessionRepository repository, String userId) action,
  ) async {
    if (state.contains(sessionId)) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw const PermissionFailure('signed-out');

    state = {...state, sessionId};
    try {
      await action(ref.read(sessionRepositoryProvider), userId);
    } finally {
      state = {...state}..remove(sessionId);
    }
  }
}

final sessionActionsProvider =
    NotifierProvider<SessionActionsNotifier, Set<String>>(
      SessionActionsNotifier.new,
    );

/// Works because the mentor profile ID is the mentor's Auth UID.
final mentorSessionsProvider = StreamProvider<List<Session>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const <Session>[]);
  return ref.watch(sessionRepositoryProvider).watchForMentor(userId);
});
