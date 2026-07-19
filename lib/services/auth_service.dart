import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'sync_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _sessionKey = 'firebase_session_active';
  static const String _secureEmailKey = 'cached_user_email';
  static const String _securePasswordKey = 'cached_user_password';

  Future<void> _saveCredentials(String email, String password) async {
    await _secureStorage.write(key: _secureEmailKey, value: email);
    await _secureStorage.write(key: _securePasswordKey, value: password);
  }

  Future<void> _clearCredentials() async {
    await _secureStorage.delete(key: _secureEmailKey);
    await _secureStorage.delete(key: _securePasswordKey);
  }

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
    User? user;
    try {
      user = await _auth
          .authStateChanges()
          .timeout(const Duration(seconds: 5))
          .first;
    } catch (_) {
      user = null;
    }

    if (user != null) return user;

    // Fallback: If Firebase token persistence failed but we have cached credentials,
    // perform an automatic silent sign-in.
    try {
      final email = await _secureStorage.read(key: _secureEmailKey);
      final password = await _secureStorage.read(key: _securePasswordKey);
      if (email != null && password != null) {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return credential.user;
      }
    } on FirebaseAuthException catch (e) {
      // If the credentials are invalid (e.g. password changed), clear them.
      if (e.code == 'wrong-password' ||
          e.code == 'user-not-found' ||
          e.code == 'user-disabled' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-email') {
        await _clearCredentials();
      }
    } catch (_) {
      // Ignore other errors (e.g. network timeout) to allow retrying later.
    }

    return null;
  }

  /// Persist the "session active" flag so we know a previous sign-in existed.
  Future<void> _markSessionActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, true);
  }

  /// Clear the "session active" flag.
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await _secureStorage.deleteAll();
    await _clearCredentials();
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
        // Sync local guest progress to remote Firestore
        await SyncService.syncGuestProgressToRemote(user.uid);
      }

      await _saveCredentials(email, password);
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

      final user = userCredential.user;
      if (user != null) {
        await DatabaseService().ensurePublicProfileExists(
          user.uid,
          fallbackDisplayName: user.displayName,
          fallbackAvatarUrl: null,
        );
      }

      await _saveCredentials(email, password);
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

      final currentEmail = user.email ?? '';
      final oldPassword =
          await _secureStorage.read(key: _securePasswordKey) ?? '';

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

      // Update cached credentials if they changed
      final updatedEmail = (email != null && email.isNotEmpty)
          ? email
          : currentEmail;
      final updatedPassword = (password != null && password.isNotEmpty)
          ? password
          : oldPassword;
      if (updatedEmail.isNotEmpty && updatedPassword.isNotEmpty) {
        await _saveCredentials(updatedEmail, updatedPassword);
      }

      // Sync changes to the Firestore database
      await DatabaseService().updateUserInfo(user.uid, displayName, email);

      await user.reload();
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Reauthenticate the current user with their password.
  ///
  /// Throws a [FirebaseAuthException] if reauthentication fails (e.g.,
  /// wrong password, user not found, etc.).
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in.');
    }
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw Exception('No email address associated with this account.');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Permanently delete the user account and ALL associated data.
  ///
  /// [password] is required to reauthenticate before deletion for security.
  ///
  /// Deletion order (safe — Firestore data deleted FIRST so any failure leaves Auth intact):
  ///   1. Reauthenticate (throws if wrong password)
  ///   2. Delete Firestore user document & subcollections
  ///   3. Delete Firebase Auth account
  ///   4. Clear local session data (SharedPreferences + SecureStorage)
  ///
  /// If step 2 fails, the auth deletion is not attempted, preserving the account.
  Future<void> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    // 1. Reauthenticate (will throw on wrong password / expired session)
    await reauthenticate(password);

    final uid = user.uid;

    // 2. Clean up Firestore data first
    await DatabaseService().deleteUserAccount(uid);

    // 3. Delete Firebase Auth account
    await user.delete();

    // 4. Clear local session data
    await _clearSession();
  }

  // Log out
  Future<void> logOut() async {
    await _clearSession();
    await _auth.signOut();
  }
}
