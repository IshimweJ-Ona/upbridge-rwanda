// Provides injectable Firebase Auth, Firestore, session, and repository instances.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/cloudinary_storage_service.dart';
import 'package:upbridge/shared/services/firebase/auth_service.dart';
import 'package:upbridge/shared/services/firebase/upbridge_repository.dart';
import 'package:upbridge/shared/services/storage_service.dart';

/// Maps a trusted Firebase Auth custom role claim to an application role.
Role trustedRoleFromClaim(Object? claim) => switch (claim) {
  'admin' => Role.admin,
  'mentor' => Role.mentor,
  _ => Role.youth,
};

/// Authenticated session state backed by Firebase Auth claims and users/{uid}.
class VerifiedSession {
  const VerifiedSession({
    required this.firebaseInitialized,
    required this.signedIn,
    required this.emailVerified,
    this.uid,
    this.email,
    this.displayName,
    this.role = Role.youth,
    this.onboarded = false,
    this.profileLoaded = true,
    this.profileExists = false,
    this.accountStatus,
  });

  const VerifiedSession.uninitialized()
    : firebaseInitialized = false,
      signedIn = false,
      emailVerified = false,
      uid = null,
      email = null,
      displayName = null,
      role = Role.youth,
      onboarded = false,
      profileLoaded = true,
      profileExists = false,
      accountStatus = null;

  const VerifiedSession.signedOut()
    : firebaseInitialized = true,
      signedIn = false,
      emailVerified = false,
      uid = null,
      email = null,
      displayName = null,
      role = Role.youth,
      onboarded = false,
      profileLoaded = true,
      profileExists = false,
      accountStatus = null;

  final bool firebaseInitialized;
  final bool signedIn;
  final bool emailVerified;
  final String? uid;
  final String? email;
  final String? displayName;
  final Role role;
  final bool onboarded;
  final bool profileLoaded;
  final bool profileExists;
  final String? accountStatus;

  String get firstName {
    final clean = (displayName ?? '').trim();
    if (clean.isNotEmpty) return clean.split(RegExp(r'\s+')).first;
    final address = (email ?? '').trim();
    if (address.contains('@')) return address.split('@').first;
    return 'Friend';
  }

  String get displayLabel {
    final clean = (displayName ?? '').trim();
    if (clean.isNotEmpty) return clean;
    final address = (email ?? '').trim();
    if (address.isNotEmpty) return address;
    return role.label;
  }

  String get initials => initialsOf(displayLabel);
}

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    auth: Firebase.apps.isEmpty ? null : ref.watch(firebaseAuthProvider),
  ),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => Firebase.apps.isEmpty
      ? Stream<User?>.value(null)
      : ref.watch(firebaseAuthProvider).authStateChanges(),
);

final authUserChangesProvider = StreamProvider<User?>(
  (ref) => Firebase.apps.isEmpty
      ? Stream<User?>.value(null)
      : ref.watch(authServiceProvider).userChanges,
);

final repositoryProvider = Provider<UpBridgeRepository>(
  (ref) => UpBridgeRepository(db: ref.watch(firestoreProvider)),
);

/// Watches Firebase Auth userChanges, trusted role claims, and users/{uid}.
final verifiedSessionProvider = StreamProvider<VerifiedSession>((ref) async* {
  if (Firebase.apps.isEmpty) {
    yield const VerifiedSession.uninitialized();
    return;
  }

  final authState = ref.watch(authUserChangesProvider);
  final user = authState.asData?.value ?? FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const VerifiedSession.signedOut();
    return;
  }

  if (!user.emailVerified) {
    yield VerifiedSession(
      firebaseInitialized: true,
      signedIn: true,
      emailVerified: false,
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
    return;
  }

  Role role = Role.youth;
  try {
    final tokenResult = await user.getIdTokenResult();
    role = trustedRoleFromClaim(tokenResult.claims?['role']);
  } catch (_) {
    role = Role.youth;
  }

  yield VerifiedSession(
    firebaseInitialized: true,
    signedIn: true,
    emailVerified: true,
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    role: role,
    onboarded: role != Role.youth,
    profileLoaded: false,
  );

  final repository = ref.watch(repositoryProvider);
  final controller = StreamController<VerifiedSession>();
  final sub = repository
      .watchProfile(user.uid)
      .listen(
        (snapshot) {
          final data = snapshot.data();
          final exists = snapshot.exists && data != null;
          final rawName = data?['displayName'];
          final cleanName = rawName is String && rawName.trim().isNotEmpty
              ? rawName.trim()
              : user.displayName;
          controller.add(
            VerifiedSession(
              firebaseInitialized: true,
              signedIn: true,
              emailVerified: true,
              uid: user.uid,
              email: user.email,
              displayName: cleanName,
              role: role,
              onboarded: role != Role.youth || data?['onboarded'] == true,
              profileLoaded: true,
              profileExists: exists,
              accountStatus: data?['accountStatus'] as String?,
            ),
          );
        },
        onError: (_) {
          controller.add(
            VerifiedSession(
              firebaseInitialized: true,
              signedIn: true,
              emailVerified: true,
              uid: user.uid,
              email: user.email,
              displayName: user.displayName,
              role: role,
              onboarded: role != Role.youth,
              profileLoaded: true,
              profileExists: false,
            ),
          );
        },
      );
  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });
  yield* controller.stream;
});

/// Uses Cloudinary only when its public image-upload settings are supplied.
final storageServiceProvider = Provider<StorageService>((ref) {
  final config = CloudinaryConfig.fromEnvironment();
  if (!config.isConfigured) return const StorageUnavailable();
  final service = CloudinaryPublicImageStorageService(config: config);
  ref.onDispose(service.close);
  return service;
});
