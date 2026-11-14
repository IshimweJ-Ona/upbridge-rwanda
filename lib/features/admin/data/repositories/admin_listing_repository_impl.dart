// Keeps listing persistence injectable until the feature owner confirms the document contract.
import 'package:upbridge/features/admin/domain/entities/listing_draft.dart';
import 'package:upbridge/features/admin/domain/repositories/admin_listing_repository.dart';
import 'package:upbridge/shared/models/models.dart';

class AdminListingRepositoryImpl implements AdminListingRepository {
  const AdminListingRepositoryImpl({
    required this._listPublished,
    required this._create,
    required this._close,
    required this._remove,
    required this._dismissReport,
  });

  final Future<List<Opportunity>> Function() _listPublished;
  final Future<String> Function(ListingDraft draft) _create;
  final Future<void> Function(String id) _close;
  final Future<void> Function(String id, String reason) _remove;
  final Future<void> Function(String reportId) _dismissReport;

  @override
  Future<List<Opportunity>> listPublished() => _listPublished();

  @override
  Future<String> create(ListingDraft draft) => _create(draft);

  @override
  Future<void> close(String listingId) => _close(listingId);

  @override
  Future<void> remove(String listingId, {required String reason}) =>
      _remove(listingId, reason);

  @override
  Future<void> dismissReport(String reportId) => _dismissReport(reportId);
}
