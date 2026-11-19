// Owner: Student 4 · Opportunities & applications
// Holds: Implements OpportunityRepository: turns listing documents into Opportunity.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/features/opportunities/data/datasources/opportunity_remote_data_source.dart';
import 'package:upbridge/features/opportunities/data/models/opportunity_model.dart';
import 'package:upbridge/features/opportunities/domain/repositories/opportunity_repository.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/firebase/firebase_failure_mapper.dart';

class OpportunityRepositoryImpl implements OpportunityRepository {
  OpportunityRepositoryImpl({required this._dataSource});

  final OpportunityRemoteDataSource _dataSource;

  @override
  Stream<List<Opportunity>> watchOpen() => _dataSource
      .watchOpen()
      .map(_toList)
      .transform(
        StreamTransformer<List<Opportunity>, List<Opportunity>>.fromHandlers(
          handleError: (error, stack, sink) =>
              sink.addError(mapFirebaseFailure(error), stack),
        ),
      );

  // One bad document is skipped so it cannot hide every other listing
  List<Opportunity> _toList(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final listings = <Opportunity>[];
    for (final doc in snapshot.docs) {
      try {
        listings.add(OpportunityModel.fromMap(doc.id, doc.data()));
      } on ValidationFailure {
        continue;
      } on FormatException {
        continue;
      }
    }
    return listings;
  }
}
