import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if current user's email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

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
        await DatabaseService().initializeUserStats(user.uid, displayName, email);
      }

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
  }

  // Log out
  Future<void> logOut() async {
    await _auth.signOut();
  }
}
