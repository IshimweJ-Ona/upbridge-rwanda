import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/utils/firestore_parsers.dart';
import 'package:upbridge/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:upbridge/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:upbridge/features/auth/domain/repositories/auth_repository.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

final authDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(auth: ref.watch(firebaseAuthProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(dataSource: ref.watch(authDataSourceProvider)),
);

/// Full professional & mentorship application captured during mentor registration
/// and committed to `mentorApplications/{uid}` right after email verification succeeds.
class MentorRegistrationPayload {
  const MentorRegistrationPayload({
    required this.headline,
    required this.profession,
    required this.education,
    required this.experienceYears,
    required this.expertise,
    required this.skills,
    required this.bio,
    required this.availability,
    required this.mentoringInterests,
    required this.maxMentees,
    this.supportingLinks = const [],
    this.cvAsset,
  });

  final String headline;
  final String profession;
  final String education;
  final int experienceYears;
  final List<String> expertise;
  final List<String> skills;
  final String bio;
  final String availability;
  final String mentoringInterests;
  final int maxMentees;
  final List<String> supportingLinks;
  final MediaAsset? cvAsset;

  Map<String, dynamic> toJson() => {
    'headline': headline,
    'profession': profession,
    'education': education,
    'experienceYears': experienceYears,
    'expertise': expertise,
    'skills': skills,
    'bio': bio,
    'availability': availability,
    'mentoringInterests': mentoringInterests,
    'maxMentees': maxMentees,
    'supportingLinks': supportingLinks,
    'cvAsset': cvAsset?.toJson(),
  };

  factory MentorRegistrationPayload.fromJson(Map<String, dynamic> json) =>
      MentorRegistrationPayload(
        headline: json['headline'] as String? ?? '',
        profession: json['profession'] as String? ?? '',
        education: json['education'] as String? ?? '',
        experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
        expertise: stringListFromJson(json['expertise']),
        skills: stringListFromJson(json['skills']),
        bio: json['bio'] as String? ?? '',
        availability: json['availability'] as String? ?? '',
        mentoringInterests: json['mentoringInterests'] as String? ?? '',
        maxMentees: ((json['maxMentees'] as num?)?.toInt() ?? 5).clamp(1, 50),
        supportingLinks: stringListFromJson(json['supportingLinks']),
        cvAsset: json['cvAsset'] is Map
            ? MediaAsset.fromJson(
                Map<String, dynamic>.from(json['cvAsset'] as Map),
              )
            : null,
      );
}

class RegistrationDraft {
  const RegistrationDraft({
    required this.displayName,
    required this.phone,
    this.wantsMentorApplication = false,
    this.credentialUploadFailed = false,
    this.mentorApplication,
  });

  final String displayName;
  final String phone;
  final bool wantsMentorApplication;
  final bool credentialUploadFailed;
  final MentorRegistrationPayload? mentorApplication;

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'phone': phone,
    'wantsMentorApplication': wantsMentorApplication,
    'credentialUploadFailed': credentialUploadFailed,
    'mentorApplication': mentorApplication?.toJson(),
  };

  factory RegistrationDraft.fromJson(Map<String, dynamic> json) =>
      RegistrationDraft(
        displayName: json['displayName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        wantsMentorApplication:
            json['wantsMentorApplication'] as bool? ?? false,
        credentialUploadFailed:
            json['credentialUploadFailed'] as bool? ?? false,
        mentorApplication: json['mentorApplication'] is Map
            ? MentorRegistrationPayload.fromJson(
                Map<String, dynamic>.from(json['mentorApplication'] as Map),
              )
            : null,
      );
}

class RegistrationDraftController extends Notifier<RegistrationDraft?> {
  static String _storageKey(String uid) => 'upbridge.reg_draft.$uid';
  static String _credentialWarningKey(String uid) => 'upbridge.cred_warn.$uid';

  static Future<void> setCredentialUploadWarning(
    String uid,
    bool value,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value) {
        await prefs.setBool(_credentialWarningKey(uid), true);
      } else {
        await prefs.remove(_credentialWarningKey(uid));
      }
    } catch (_) {}
  }

  static Future<bool> hasCredentialUploadWarning(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_credentialWarningKey(uid)) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  RegistrationDraft? build() => null;

  void setDraft(RegistrationDraft? draft) => state = draft;

  Future<void> persistForUid(String uid, RegistrationDraft draft) async {
    state = draft;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey(uid), jsonEncode(draft.toJson()));
    } catch (_) {}
  }

  Future<RegistrationDraft?> loadForUid(String uid) async {
    if (state != null) return state;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey(uid));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final draft = RegistrationDraft.fromJson(decoded);
        state = draft;
        return draft;
      }
    } catch (_) {}
    return null;
  }

  Future<void> clearForUid(String uid) async {
    state = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey(uid));
    } catch (_) {}
  }
}

final registrationDraftProvider =
    NotifierProvider<RegistrationDraftController, RegistrationDraft?>(
      RegistrationDraftController.new,
    );

final credentialUploadWarningProvider = FutureProvider.autoDispose
    .family<bool, String>(
      (ref, uid) => RegistrationDraftController.hasCredentialUploadWarning(uid),
    );
