// Validates the moderation reason before delegating removal to the repository.
import 'package:upbridge/features/admin/domain/repositories/admin_listing_repository.dart';

class RemoveListing {
  const RemoveListing(this._repository);

  final AdminListingRepository _repository;

  Future<void> call({required String listingId, required String reason}) {
    if (listingId.trim().isEmpty) {
      throw ArgumentError.value(listingId, 'listingId');
    }
    final cleanReason = reason.trim();
    if (cleanReason.length < 10) {
      throw ArgumentError.value(
        reason,
        'reason',
        'Provide at least 10 characters.',
      );
    }
    return _repository.remove(listingId, reason: cleanReason);
  }
}
