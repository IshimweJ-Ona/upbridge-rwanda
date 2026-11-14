// Reads published opportunities without assuming Kellen's unconfirmed write schema.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/shared/services/firebase/firestore_schema.dart';

class AdminListingDataSource {
  AdminListingDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  Future<QuerySnapshot<Map<String, dynamic>>> listPublished({int limit = 50}) {
    if (limit < 1 || limit > 100) {
      throw RangeError.range(limit, 1, 100, 'limit');
    }
    return firestore
        .collection(Fs.opportunities)
        .where('status', isEqualTo: OpportunityStatus.published)
        .orderBy('deadline')
        .limit(limit)
        .get();
  }
}
