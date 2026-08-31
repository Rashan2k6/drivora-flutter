import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase Authentication for email/password sign-in.
class AuthService {
  static final _auth = FirebaseAuth.instance;

  /// Stream of auth state changes — null when logged out, a User
  /// object when logged in. Used to decide which screen to show on
  /// app startup and whenever login state changes.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  static Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> signOut() {
    return _auth.signOut();
  }

  /// Converts Firebase's auth exception codes into short, readable
  /// messages instead of showing raw exception text to the user.
  static String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account already exists with that email.';
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'network-request-failed':
          return 'Network error — check your connection and try again.';
        default:
          return 'Something went wrong (${error.code}). Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
