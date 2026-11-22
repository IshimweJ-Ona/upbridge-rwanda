// Provides core Firebase Auth, Firestore, and auth-state stream providers.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upbridge/shared/services/firebase/auth_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final firebaseAppInitializedProvider = Provider<bool>(
  (ref) => Firebase.apps.isNotEmpty,
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
