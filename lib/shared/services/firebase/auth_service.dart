// Wraps shared Firebase Auth state, claims, and email-verification operations.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _injectedAuth = auth;

  final FirebaseAuth? _injectedAuth;
  DateTime? _lastVerificationSentAt;
  String? _lastVerificationUid;

  FirebaseAuth? get _authOrNull =>
      _injectedAuth ?? (Firebase.apps.isEmpty ? null : FirebaseAuth.instance);

  User? get currentUser => _authOrNull?.currentUser;

  Stream<User?> get authStateChanges =>
      _authOrNull?.authStateChanges() ?? const Stream<User?>.empty();

  Stream<User?> get userChanges =>
      _authOrNull?.userChanges() ?? const Stream<User?>.empty();

  String? get currentEmail => _authOrNull?.currentUser?.email;

  bool get isEmailVerified => _authOrNull?.currentUser?.emailVerified ?? false;

  Future<void> sendVerificationEmail({bool force = false}) async {
    final user = _authOrNull?.currentUser;
    if (user == null) throw StateError('No Firebase user is signed in.');
    if (user.emailVerified) return;

    final now = DateTime.now();
    if (!force &&
        _lastVerificationUid == user.uid &&
        _lastVerificationSentAt != null &&
        now.difference(_lastVerificationSentAt!) <
            const Duration(seconds: 30)) {
      return;
    }

    await user.sendEmailVerification();
    _lastVerificationUid = user.uid;
    _lastVerificationSentAt = now;
  }

  Future<bool> reloadAndCheckEmailVerification() async {
    final auth = _authOrNull;
    if (auth == null || auth.currentUser == null) return false;
    await auth.currentUser!.reload();
    final refreshedUser = auth.currentUser;
    if (refreshedUser == null) return false;
    await refreshedUser.getIdToken(true);
    return auth.currentUser?.emailVerified ?? false;
  }

  Future<String?> readRoleClaim({bool forceRefresh = false}) async {
    final user = _authOrNull?.currentUser;
    if (user == null) return null;
    final tokenResult = await user.getIdTokenResult(forceRefresh);
    final role = tokenResult.claims?['role'];
    return role is String ? role : null;
  }

  Future<UserCredential> signIn(String email, String password) {
    final auth = _authOrNull;
    if (auth == null) throw StateError('Firebase has not been initialized.');
    return auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUp(String email, String password) {
    final auth = _authOrNull;
    if (auth == null) throw StateError('Firebase has not been initialized.');
    return auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) {
    final auth = _authOrNull;
    if (auth == null) throw StateError('Firebase has not been initialized.');
    return auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    _lastVerificationSentAt = null;
    _lastVerificationUid = null;
    final auth = _authOrNull;
    if (auth == null) return;
    await auth.signOut();
  }
}
