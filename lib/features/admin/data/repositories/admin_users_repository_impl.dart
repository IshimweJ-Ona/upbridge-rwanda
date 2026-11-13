// Maps confirmed user profile fields to the shared admin list model.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:upbridge/features/admin/domain/repositories/admin_users_repository.dart';
import 'package:upbridge/shared/models/models.dart';

class AdminUsersRepositoryImpl implements AdminUsersRepository {
  const AdminUsersRepositoryImpl({required this.dataSource});

  final AdminRemoteDataSource dataSource;

  @override
  Future<List<PlatformUser>> listUsers({
    int limit = 50,
    String? afterId,
  }) async {
    final documents = await dataSource.listUsers(
      limit: limit,
      afterId: afterId,
    );
    return documents
        .map((document) => _toPlatformUser(document.id, document.data()))
        .whereType<PlatformUser>()
        .toList(growable: false);
  }

  @override
  Future<PlatformUser?> getUser(String userId) async {
    final document = await dataSource.getUser(userId);
    final data = document.data();
    if (!document.exists || data == null) return null;
    return _toPlatformUser(document.id, data);
  }

  PlatformUser? _toPlatformUser(String id, Map<String, dynamic> data) {
    final roleName = data['role'];
    final role = Role.values
        .where((value) => value.name == roleName)
        .firstOrNull;
    if (role == null) return null;
    final name = data['displayName'] ?? data['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final createdAt = switch (data['createdAt']) {
      Timestamp timestamp => timestamp.toDate(),
      DateTime date => date,
      _ => null,
    };
    final status = data['accountStatus'] as String? ?? 'unknown';
    return PlatformUser(
      id: id,
      name: name,
      role: role,
      phone: data['phone'] as String? ?? '',
      district:
          data['district'] as String? ?? data['location'] as String? ?? '',
      joined: createdAt == null
          ? 'Date unavailable'
          : '${createdAt.day}/${createdAt.month}/${createdAt.year}',
      status: status == 'active' ? 'Active' : status,
      detail: '',
    );
  }
}
