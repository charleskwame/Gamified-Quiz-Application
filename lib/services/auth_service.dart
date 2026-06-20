import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

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

  // Log out
  Future<void> logOut() async {
    await _auth.signOut();
  }
}
