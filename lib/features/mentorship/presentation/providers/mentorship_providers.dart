// Riverpod providers for mentors and sessions. Screens still use AppStore for now.
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

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

final mentorsProvider = StreamProvider<List<Mentor>>(
  (ref) => ref.watch(mentorDirectoryRepositoryProvider).watchMentors(),
);

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

/// Works because the mentor profile ID is the mentor's Auth UID.
final mentorSessionsProvider = StreamProvider<List<Session>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const <Session>[]);
  return ref.watch(sessionRepositoryProvider).watchForMentor(userId);
});
