// Owner: Student 4 · Opportunities & applications
// Holds: Abstract contract for listings and reports.

import 'package:upbridge/shared/models/models.dart';

abstract class OpportunityRepository {
  Stream<List<Opportunity>> watchOpen();
}