// Provides injectable Firebase Auth, Firestore, and repository instances.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:upbridge/shared/services/firebase/auth_service.dart';
import 'package:upbridge/shared/services/firebase/upbridge_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(auth: ref.watch(firebaseAuthProvider)),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => Firebase.apps.isEmpty
      ? Stream<User?>.value(null)
      : ref.watch(firebaseAuthProvider).authStateChanges(),
);

final repositoryProvider = Provider<UpBridgeRepository>(
  (ref) => UpBridgeRepository(db: ref.watch(firestoreProvider)),
);
