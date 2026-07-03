import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _sessionKey = 'firebase_session_active';

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if current user's email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Wait for Firebase Auth to finish restoring its persisted session from disk.
  ///
  /// On cold start, Firebase Auth loads the encrypted token from the Android
  /// KeyStore-backed SharedPreferences asynchronously.  Calling [currentUser]
  /// immediately may return null even though a valid token exists on disk.
  ///
  /// This method subscribes to [authStateChanges] and waits up to 5 seconds for
  /// the first emission.  If a user is restored (either via built-in persistence
  /// or the manual SharedPreferences flag) it returns that user; otherwise null.
  Future<User?> waitForSessionRestore() async {
    // Quick path – already resolved (e.g. after the first restore succeeds).
    if (_auth.currentUser != null) return _auth.currentUser;

    // Wait for the first auth state emission.
    // - Guest users: emits null immediately (no timeout).
    // - Signed-in users: emits the restored user once Firebase reads the token.
    // - Fallback: 5-second safety net in case the token read hangs.
    try {
      final user = await _auth
          .authStateChanges()
          .timeout(const Duration(seconds: 5))
          .first;
      return user;
    } catch (_) {
      return null;
    }
  }

  /// Persist the “session active” flag so we know a previous sign-in existed.
  Future<void> _markSessionActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, true);
  }

  /// Clear the “session active” flag.
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await _secureStorage.deleteAll();
  }

  // Sign up with email and password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user != null) {
        // Set display name
        await user.updateDisplayName(displayName);
        // Send email verification
        await user.sendEmailVerification();
        // Create Firestore user document with default stats & progress tracking
        await DatabaseService().initializeUserStats(
          user.uid,
          displayName,
          email,
        );
      }

      await _markSessionActive();

      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Log in with email and password
  Future<UserCredential?> logIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _markSessionActive();

      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Resend email verification
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in.');
    }
    await user.sendEmailVerification();
  }

  // Reload current user to refresh emailVerified status
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  // Check if email is verified by reloading user first
  Future<bool> checkEmailVerification() async {
    await reloadUser();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Update profile info
  Future<void> updateProfile({
    String? displayName,
    String? email,
    String? password,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in.');
      }

      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }

      if (email != null && email.isNotEmpty && email != user.email) {
        // ignore: deprecated_member_use
        await user.updateEmail(email);
        // If email changed, re-send verification
        await user.sendEmailVerification();
      }

      if (password != null && password.isNotEmpty) {
        await user.updatePassword(password);
      }

      // Sync changes to the Firestore database
      await DatabaseService().updateUserInfo(user.uid, displayName, email);

      await user.reload();
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Delete the current user's Firebase Auth account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in.');
    }
    await user.delete();
    await _clearSession();
  }

  // Log out
  Future<void> logOut() async {
    await _clearSession();
    await _auth.signOut();
  }
}
