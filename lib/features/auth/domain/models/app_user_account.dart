import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/utils/firestore_parsers.dart';

/// Core account document stored at users/{uid}.
class AppUserAccount {
  const AppUserAccount({
    required this.id,
    required this.ownerUid,
    required this.email,
    required this.displayName,
    required this.phone,
    required this.role,
    required this.isApproved,
    required this.status,
    required this.onboarded,
    required this.preferredLocale,
    this.photoAsset,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String email;
  final String displayName;
  final String phone;
  final UserRole role;
  final bool isApproved;
  final AccountStatus status;
  final bool onboarded;
  final String preferredLocale;
  final MediaAsset? photoAsset;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == AccountStatus.active;

  factory AppUserAccount.fromJson(Map<String, dynamic> json, {String? id}) {
    final now = DateTime.now().toUtc();
    final uid = (json['ownerUid'] as String?) ?? id ?? '';
    return AppUserAccount(
      id: id ?? uid,
      ownerUid: uid,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: UserRole.fromValue(json['role']),
      isApproved: json['isApproved'] as bool? ?? false,
      status: AccountStatus.fromValue(json['status'] ?? json['accountStatus']),
      onboarded: json['onboarded'] as bool? ?? false,
      preferredLocale: json['preferredLocale'] as String? ?? 'en',
      photoAsset: json['photoAsset'] is Map
          ? MediaAsset.fromJson(
              Map<String, dynamic>.from(json['photoAsset'] as Map),
            )
          : null,
      createdAt: dateTimeFromJson(json['createdAt']) ?? now,
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownerUid': ownerUid,
    'email': email,
    'displayName': displayName,
    'phone': phone,
    'role': role.value,
    'isApproved': isApproved,
    'status': status.value,
    'onboarded': onboarded,
    'preferredLocale': preferredLocale,
    'photoAsset': photoAsset?.toJson(),
    'createdAt': dateTimeToJson(createdAt),
    'updatedAt': dateTimeToJson(updatedAt),
  };

  /// Safe profile fields a user is permitted to update directly under firestore.rules.
  Map<String, dynamic> toSafeProfileUpdateJson() => {
    'displayName': displayName,
    'phone': phone,
    'onboarded': onboarded,
    'preferredLocale': preferredLocale,
    'photoAsset': photoAsset?.toJson(),
    'updatedAt': dateTimeToJson(updatedAt),
  };

  AppUserAccount copyWith({
    String? email,
    String? displayName,
    String? phone,
    UserRole? role,
    bool? isApproved,
    AccountStatus? status,
    bool? onboarded,
    String? preferredLocale,
    MediaAsset? photoAsset,
    bool clearPhotoAsset = false,
    DateTime? updatedAt,
  }) => AppUserAccount(
    id: id,
    ownerUid: ownerUid,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    phone: phone ?? this.phone,
    role: role ?? this.role,
    isApproved: isApproved ?? this.isApproved,
    status: status ?? this.status,
    onboarded: onboarded ?? this.onboarded,
    preferredLocale: preferredLocale ?? this.preferredLocale,
    photoAsset: clearPhotoAsset ? null : (photoAsset ?? this.photoAsset),
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
