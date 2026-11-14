// Riverpod access to dashboard and monthly check-in repositories.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/features/home/data/repositories/check_in_repository_impl.dart';
import 'package:upbridge/features/home/data/repositories/home_repository_impl.dart';
import 'package:upbridge/features/home/domain/entities/check_in.dart';
import 'package:upbridge/features/home/domain/entities/home_summary.dart';
import 'package:upbridge/features/home/domain/repositories/check_in_repository.dart';
import 'package:upbridge/features/home/domain/repositories/home_repository.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(firestore: ref.watch(firestoreProvider)),
);

final checkInRepositoryProvider = Provider<CheckInRepository>(
  (ref) => CheckInRepositoryImpl(firestore: ref.watch(firestoreProvider)),
);

final homeSummaryProvider = FutureProvider.family<HomeSummary, String>(
  (ref, userId) => ref.watch(homeRepositoryProvider).loadSummary(userId),
);

final monthlyCheckInProvider =
    FutureProvider.family<CheckIn?, ({String userId, String monthKey})>(
      (ref, query) => ref
          .watch(checkInRepositoryProvider)
          .getForMonth(query.userId, query.monthKey),
    );
