import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'local_progress_service.dart';
import 'sync_service.dart';

/// Thrown when Google sign-in fails because an account with the same email
/// already exists under a different sign-in method (e.g. email/password).
/// Carries the pending Google credential + email so the UI can prompt the user
/// to sign in once with their existing email/password and link their Google
/// account (one-time migration path).
class AccountLinkRequiredException implements Exception {
  final AuthCredential pendingCredential;
  final String email;

  const AccountLinkRequiredException({
    required this.pendingCredential,
    required this.email,
  });

  @override
  String toString() =>
      'An account with this email already exists. Please sign in with your '
      'email and password once to link your Google account.';
}

/// Thrown when a Google sign-in flow is cancelled by the user (e.g. they
/// dismissed the Google account picker).
class GoogleSignInAbortedException implements Exception {
  const GoogleSignInAbortedException();

  @override
  String toString() => 'Google sign-in was cancelled.';
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _sessionKey = 'firebase_session_active';

  static bool _googleSignInInitialized = false;

  /// `GoogleSignIn` is a singleton in google_sign_in ^7 and must be initialized
  /// exactly once before any other method is called.
  Future<void> _ensureGoogleInitialized() async {
    if (_googleSignInInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleSignInInitialized = true;
  }

  /// Prompts the user to pick a Google account and returns it, or `null` if
  /// the user explicitly dismissed the Google account picker. Any other
  /// [GoogleSignInException] (interrupted, UI unavailable, configuration
  /// errors, ...) is rethrown so the UI can surface a real message.
  Future<GoogleSignInAccount?> _promptGoogleAccount() async {
    await _ensureGoogleInitialized();
    try {
      return await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      // Log so the real failure is visible in logcat even when the UI shows
      // a friendlier message.
      debugPrint('GoogleSignInException: ${e.code} - ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // User explicitly dismissed the picker.
        return null;
      }
      rethrow;
    }
  }

  /// Builds a Firebase credential from the Google account's ID token.
  AuthCredential _buildGoogleCredential(GoogleSignInAccount googleUser) {
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw Exception('Unable to obtain a Google ID token. Please try again.');
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  /// Wait for Firebase Auth to finish restoring its persisted session from disk.
  ///
  /// On cold start, Firebase Auth loads the encrypted token from the Android
  /// KeyStore-backed SharedPreferences asynchronously.  Calling [currentUser]
  /// immediately may return null even though a valid token exists on disk.
  ///
  /// This method subscribes to [authStateChanges] and waits up to 5 seconds for
  /// the first emission. Google tokens are persisted natively by Firebase Auth,
  /// so no manual credential fallback is needed.
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

    return user;
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
    // Clear any locally cached guest profile/progress so a stale name card
    // doesn't reappear after sign-out or account deletion.
    await LocalProgressService.clearAll();
  }

  /// Repair a stale state left behind by a restored Android backup.
  ///
  /// On reinstall, Android Auto Backup can restore the plaintext
  /// `firebase_session_active` flag and the guest profile, but NOT the
  /// KeyStore-bound Firebase auth token. That leaves the app signed-out yet
  /// still displaying an old guest name card. If the flag says a session was
  /// active but no Firebase user was restored, clear the stale flag and guest
  /// data so the next launch starts fresh.
  Future<void> repairRestoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    final wasSessionActive = prefs.getBool(_sessionKey) ?? false;
    if (wasSessionActive && _auth.currentUser == null) {
      await prefs.remove(_sessionKey);
      await LocalProgressService.clearAll();
    }
  }

  /// Sign in with Google (native). Returns the credential, or `null` if the
  /// user cancelled the Google account picker.
  ///
  /// - New user: initializes the Firestore user document and syncs any local
  ///   guest progress into the account (guest upgrade).
  /// - Returning user: backfills the public profile if missing.
  ///
  /// Throws [AccountLinkRequiredException] when an email/password account with
  /// the same email already exists (the caller should prompt to link it).
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _promptGoogleAccount();
      if (googleUser == null) return null; // cancelled

      final credential = _buildGoogleCredential(googleUser);

      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          // An email/password account already exists with this Google email.
          throw AccountLinkRequiredException(
            pendingCredential: credential,
            email: googleUser.email,
          );
        }
        rethrow;
      }

      final user = userCredential.user;
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (user != null) {
        if (isNewUser) {
          // Create Firestore user document with default stats & progress tracking.
          await DatabaseService().initializeUserStats(
            user.uid,
            user.displayName ?? googleUser.displayName ?? 'Scholar',
            user.email ?? googleUser.email,
            emailVerified: user.emailVerified,
          );
          // Sync local guest progress to remote Firestore (guest upgrade).
          await SyncService.syncGuestProgressToRemote(user.uid);
        } else {
          // Returning user: backfill the public profile if missing.
          await DatabaseService().ensurePublicProfileExists(
            user.uid,
            fallbackDisplayName: user.displayName,
            fallbackAvatarUrl: null,
          );
        }
      }

      await _markSessionActive();
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// One-time migration path (conflict-triggered): signs in with the existing
  /// email/password account, then links the pending Google credential to it.
  Future<UserCredential?> linkPendingGoogleAccount({
    required String email,
    required String password,
    required AuthCredential pendingCredential,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        await user.linkWithCredential(pendingCredential);
      }
      await _markSessionActive();
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Explicit "link an existing account" path: signs in with the existing
  /// email/password account, then prompts for Google and links the Google
  /// credential to it. If the user cancels the Google picker, the temporary
  /// email/password session is cleared and [GoogleSignInAbortedException]
  /// is thrown so the UI can restore the logged-out state.
  Future<void> linkGoogleToExistingAccount({
    required String email,
    required String password,
  }) async {
    // 1. Validate the existing email/password account.
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    // 2. Get a Google credential to link.
    GoogleSignInAccount? googleUser;
    try {
      googleUser = await _promptGoogleAccount();
    } catch (_) {
      // Any failure at this step restores the logged-out state so the
      // temporary email/password session doesn't linger.
      await _auth.signOut();
      rethrow;
    }
    if (googleUser == null) {
      // User cancelled — restore the logged-out state.
      await _auth.signOut();
      throw const GoogleSignInAbortedException();
    }

    final credential = _buildGoogleCredential(googleUser);

    // 3. Link the Google credential to the signed-in user.
    try {
      await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        // The chosen Google account is already linked to another user.
        await _auth.signOut();
      }
      rethrow;
    }

    await _markSessionActive();
  }

  // Update profile info (display name only — Google accounts manage their own
  // email/password, so those cannot be changed through the app).
  Future<void> updateProfile({String? displayName}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in.');
      }

      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }

      // Sync changes to the Firestore database
      await DatabaseService().updateUserInfo(user.uid, displayName, null);

      await user.reload();
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Permanently delete the user account and ALL associated data.
  ///
  /// Reauthenticates via a fresh Google sign-in before deletion for security.
  /// Throws [GoogleSignInAbortedException] if the user cancels the prompt.
  ///
  /// Deletion order (safe — Firestore data deleted FIRST so any failure leaves
  /// Auth intact):
  ///   1. Reauthenticate with a fresh Google credential
  ///   2. Delete Firestore user document & subcollections
  ///   3. Delete Firebase Auth account
  ///   4. Clear local session data
  ///
  /// If step 2 fails, the auth deletion is not attempted, preserving the account.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    // 1. Reauthenticate with a fresh Google credential.
    final googleUser = await _promptGoogleAccount();
    if (googleUser == null) {
      throw const GoogleSignInAbortedException();
    }
    final credential = _buildGoogleCredential(googleUser);
    await user.reauthenticateWithCredential(credential);

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
    // Sign out of Google too so the picker isn't auto-selected next time.
    if (_googleSignInInitialized) {
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }
}
