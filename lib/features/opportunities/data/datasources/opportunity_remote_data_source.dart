// Owner: Student 4 · Opportunities & applications
// Holds: Reads open listings through UpBridgeRepository.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upbridge/shared/services/firebase/upbridge_repository.dart';

class OpportunityRemoteDataSource {
  OpportunityRemoteDataSource({required this._repository});

  final UpBridgeRepository _repository;

  // Reuse the shared query so I don't write a second one
  Stream<QuerySnapshot<Map<String, dynamic>>> watchOpen() =>
      _repository.watchOpportunities();
}