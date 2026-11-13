// Read-only admin user queries; account creation and suspension belong to auth/profile contracts.
import 'package:upbridge/shared/models/models.dart';

abstract interface class AdminUsersRepository {
  Future<List<PlatformUser>> listUsers({int limit = 50, String? afterId});
  Future<PlatformUser?> getUser(String userId);
}
