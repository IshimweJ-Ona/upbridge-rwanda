// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Development placeholder: anonymous sign-in gives every device a stable uid.
  /// Replace with phone sign-in once the product decides how youth log in.
  Future<String> ensureSignedIn() async {
    final current = _auth.currentUser;
    if (current != null) return current.uid;
    final result = await _auth.signInAnonymously();
    return result.user!.uid;
  }
}
