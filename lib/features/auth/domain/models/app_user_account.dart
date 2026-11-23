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
    ApprovalStatus? approvalStatus,
    this.emailVerified = false,
    this.hasValidRole = true,
    required this.status,
    required this.onboarded,
    required this.preferredLocale,
    this.photoAsset,
    required this.createdAt,
    required this.updatedAt,
  }) : approvalStatus =
           approvalStatus ??
           (role == UserRole.mentor
               ? (isApproved ? ApprovalStatus.approved : ApprovalStatus.pending)
               : (role == UserRole.admin
                     ? ApprovalStatus.approved
                     : ApprovalStatus.notRequired));

  final String id;
  final String ownerUid;
  final String email;
  final String displayName;
  final String phone;
  final UserRole role;
  final bool isApproved;
  final ApprovalStatus approvalStatus;
  final bool emailVerified;
  final bool hasValidRole;
  final AccountStatus status;
  final bool onboarded;
  final String preferredLocale;
  final MediaAsset? photoAsset;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == AccountStatus.active;
  bool get isApprovedMentor =>
      hasValidRole &&
      role == UserRole.mentor &&
      isApproved &&
      approvalStatus == ApprovalStatus.approved;

  factory AppUserAccount.fromJson(Map<String, dynamic> json, {String? id}) {
    final now = DateTime.now().toUtc();
    final uid = (json['ownerUid'] as String?) ?? id ?? '';
    final parsedRole = UserRole.tryFromValue(json['role']);
    final isApproved = json['isApproved'] as bool? ?? false;
    final parsedApproval = ApprovalStatus.tryFromValue(json['approvalStatus']);
    final resolvedApproval =
        parsedApproval ??
        switch (parsedRole) {
          UserRole.mentor =>
            isApproved ? ApprovalStatus.approved : ApprovalStatus.pending,
          UserRole.admin => ApprovalStatus.approved,
          UserRole.student => ApprovalStatus.notRequired,
          null => ApprovalStatus.pending,
        };
    return AppUserAccount(
      id: id ?? uid,
      ownerUid: uid,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: parsedRole ?? UserRole.student,
      hasValidRole: parsedRole != null,
      isApproved: isApproved,
      approvalStatus: resolvedApproval,
      emailVerified: json['emailVerified'] as bool? ?? false,
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
    'approvalStatus': approvalStatus.value,
    'emailVerified': emailVerified,
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
    ApprovalStatus? approvalStatus,
    bool? emailVerified,
    bool? hasValidRole,
    AccountStatus? status,
    bool? onboarded,
    String? preferredLocale,
    MediaAsset? photoAsset,
    bool clearPhotoAsset = false,
    DateTime? updatedAt,
  }) {
    final nextRole = role ?? this.role;
    final nextApproved = isApproved ?? this.isApproved;
    final nextApprovalStatus =
        approvalStatus ??
        ((isApproved != null || role != null)
            ? switch (nextRole) {
                UserRole.mentor =>
                  nextApproved
                      ? ApprovalStatus.approved
                      : ApprovalStatus.pending,
                UserRole.admin => ApprovalStatus.approved,
                UserRole.student => ApprovalStatus.notRequired,
              }
            : this.approvalStatus);
    return AppUserAccount(
      id: id,
      ownerUid: ownerUid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      role: nextRole,
      isApproved: nextApproved,
      approvalStatus: nextApprovalStatus,
      emailVerified: emailVerified ?? this.emailVerified,
      hasValidRole: hasValidRole ?? this.hasValidRole,
      status: status ?? this.status,
      onboarded: onboarded ?? this.onboarded,
      preferredLocale: preferredLocale ?? this.preferredLocale,
      photoAsset: clearPhotoAsset ? null : (photoAsset ?? this.photoAsset),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
