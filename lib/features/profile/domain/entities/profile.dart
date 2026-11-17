import 'package:cloud_firestore/cloud_firestore.dart';

class Profile {
  const Profile({
    required this.uid,
    required this.role,
    required this.accountStatus,
    required this.displayName,
    required this.phone,
    this.photoUrl,
    this.interests = const [],
    this.learningGoal,
    this.onboarded = false,
    this.updatedAt,
  });

  final String uid;
  final String role;
  final String accountStatus;
  final String displayName;
  final String phone;
  final String? photoUrl;
  final List<String> interests;
  final String? learningGoal;
  final bool onboarded;
  final DateTime? updatedAt;

  factory Profile.fromMap(Map<String, dynamic> data, {String? uid}) {
    final timestamp = data['updatedAt'];
    return Profile(
      uid: (data['uid'] as String?) ?? uid ?? '',
      role: (data['role'] as String?) ?? 'youth',
      accountStatus: (data['accountStatus'] as String?) ?? 'active',
      displayName: (data['displayName'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      photoUrl: data['photoUrl'] as String?,
      interests: (data['interests'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      learningGoal: data['learningGoal'] as String?,
      onboarded: data['onboarded'] as bool? ?? false,
      updatedAt: timestamp is Timestamp
          ? timestamp.toDate()
          : timestamp is DateTime
          ? timestamp
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'role': role,
    'accountStatus': accountStatus,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'phone': phone,
    'interests': interests,
    'learningGoal': learningGoal,
    'onboarded': onboarded,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toUpdateMap() => {
    'displayName': displayName,
    'photoUrl': photoUrl,
    'phone': phone,
    'interests': interests,
    'learningGoal': learningGoal,
    'onboarded': onboarded,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Profile copyWith({
    String? displayName,
    String? phone,
    String? photoUrl,
    List<String>? interests,
    String? learningGoal,
    bool? onboarded,
  }) => Profile(
    uid: uid,
    role: role,
    accountStatus: accountStatus,
    displayName: displayName ?? this.displayName,
    phone: phone ?? this.phone,
    photoUrl: photoUrl ?? this.photoUrl,
    interests: interests ?? this.interests,
    learningGoal: learningGoal ?? this.learningGoal,
    onboarded: onboarded ?? this.onboarded,
    updatedAt: updatedAt,
  );
}
