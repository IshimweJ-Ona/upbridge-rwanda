// Owner: Student 4 · Opportunities & applications
// Holds: Implements ApplicationRepository: submit, my applications, withdraw.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/features/applications/data/datasources/application_remote_data_source.dart';
import 'package:upbridge/features/applications/data/models/application_model.dart';
import 'package:upbridge/features/applications/domain/repositories/application_repository.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/firebase/firebase_failure_mapper.dart';

class ApplicationRepositoryImpl implements ApplicationRepository {
  ApplicationRepositoryImpl({required this._dataSource});

  final ApplicationRemoteDataSource _dataSource;

  @override
  Stream<List<Application>> watchMine(String userId) => _dataSource
      .watchMine(userId)
      .map(_toList)
      .transform(
        StreamTransformer<List<Application>, List<Application>>.fromHandlers(
          handleError: (error, stack, sink) =>
              sink.addError(mapFirebaseFailure(error), stack),
        ),
      );

  @override
  Future<Application> submit({
    required String userId,
    required String userName,
    required String opportunityId,
    required List<String> projectIds,
    required String note,
  }) async {
    final fields = <String, dynamic>{
      'userId': userId,
      'userName': userName,
      'opportunityId': opportunityId,
      'projectIds': projectIds,
      'note': note,
      'status': AppStatus.sent.name,
      'ref': _newReference(),
    };
    // One document per person per listing: {uid}_{opportunityId}
    final id = '${userId}_$opportunityId';
    try {
      await _dataSource.submit(id, fields);
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw mapFirebaseFailure(error);
    }
    return ApplicationModel.fromMap(id, fields);
  }

  @override
  Future<void> withdraw(String applicationId) async {
    try {
      await _dataSource.withdraw(applicationId);
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw mapFirebaseFailure(error);
    }
  }

  String _newReference() {
    final now = DateTime.now();
    final tail = (now.millisecondsSinceEpoch % 100000).toString().padLeft(
      5,
      '0',
    );
    return 'UB-${now.year}-$tail';
  }

  // Newest first. A document still waiting for its server time counts as newest
  List<Application> _toList(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final docs = [...snapshot.docs]
      ..sort((a, b) => _sentAt(b).compareTo(_sentAt(a)));
    final applications = <Application>[];
    for (final doc in docs) {
      try {
        applications.add(ApplicationModel.fromMap(doc.id, doc.data()));
      } on ValidationFailure {
        continue;
      } on FormatException {
        continue;
      }
    }
    return applications;
  }

  DateTime _sentAt(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final value = doc.data()['createdAt'];
    return value is Timestamp ? value.toDate() : DateTime.now();
  }
}
