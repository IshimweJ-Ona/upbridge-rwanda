// Wraps shared Firebase Auth state and email-verification operations.
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String? get currentEmail => _auth.currentUser?.email;

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No Firebase user is signed in.');
    if (!user.emailVerified) await user.sendEmailVerification();
  }

  Future<bool> reloadAndCheckEmailVerification() async {
    if (_auth.currentUser == null) return false;
    await _auth.currentUser!.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null) return false;
    await refreshedUser.getIdToken(true);
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> signOut() => _auth.signOut();
}
