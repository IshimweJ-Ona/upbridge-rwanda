// Owner: Student 4 · Opportunities & applications
// Holds: Providers for the listings and one listing.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/features/opportunities/data/datasources/opportunity_remote_data_source.dart';
import 'package:upbridge/features/opportunities/data/repositories/opportunity_repository_impl.dart';
import 'package:upbridge/features/opportunities/domain/repositories/opportunity_repository.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

final opportunityRemoteDataSourceProvider =
    Provider<OpportunityRemoteDataSource>(
      (ref) => OpportunityRemoteDataSource(
        repository: ref.watch(repositoryProvider),
      ),
    );

final opportunityRepositoryProvider = Provider<OpportunityRepository>(
  (ref) => OpportunityRepositoryImpl(
    dataSource: ref.watch(opportunityRemoteDataSourceProvider),
  ),
);

final opportunitiesProvider = StreamProvider<List<Opportunity>>(
  (ref) => ref.watch(opportunityRepositoryProvider).watchOpen(),
);

// One listing by id, taken from the same stream so it stays live
final opportunityProvider = Provider.family<AsyncValue<Opportunity?>, String>(
  (ref, id) => ref
      .watch(opportunitiesProvider)
      .whenData((all) => all.where((o) => o.id == id).firstOrNull),
);
