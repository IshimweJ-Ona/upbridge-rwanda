// Port for admin listing operations; implementations must follow Kellen's confirmed opportunity fields.
import 'package:upbridge/features/admin/domain/entities/listing_draft.dart';
import 'package:upbridge/shared/models/models.dart';

abstract interface class AdminListingRepository {
  Future<List<Opportunity>> listPublished();
  Future<String> create(ListingDraft draft);
  Future<void> close(String listingId);
  Future<void> remove(String listingId, {required String reason});
  Future<void> dismissReport(String reportId);
}
