import '../services/local_progress_service.dart';
import '../services/database_service.dart';
import '../services/guest_account_store.dart';

class SyncService {
  static final DatabaseService _dbService = DatabaseService();

  /// Migrates the local guest account into Firestore for [uid] additively and
  /// exactly once, then clears local guest data only after the merge is
  /// confirmed. Safe to call for new users, returning users, and both
  /// Google-linking paths.
  static Future<void> mergeGuestAccountToRemote(
    String uid, {
    String? email,
    String? fallbackName,
  }) async {
    final account = await LocalProgressService.loadAccount();

    if (account == null) {
      // No local guest data: ensure a remote profile exists for this user.
      final exists = await _dbService.userDocExists(uid);
      if (!exists) {
        await _dbService.initializeUserStats(
          uid,
          fallbackName ?? _nameFromEmail(email),
          email ?? '',
        );
      } else {
        await _dbService.ensurePublicProfileExists(
          uid,
          fallbackDisplayName: fallbackName ?? _nameFromEmail(email),
        );
      }
      return;
    }

    // Merge. On success (no exception) clear the local account.
    await _dbService.mergeGuestAccount(
      uid: uid,
      account: account,
      email: email,
    );

    await GuestAccountStore.instance.clear();
  }

  static String _nameFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'Scholar';
    final local = email.split('@').first;
    return local.isEmpty ? 'Scholar' : local;
  }
}
