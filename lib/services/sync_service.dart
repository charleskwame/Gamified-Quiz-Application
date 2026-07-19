import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/guest_user.dart';
import '../services/local_progress_service.dart';
import '../services/database_service.dart';

class SyncService {
  static final DatabaseService _dbService = DatabaseService();

  /// Pushes all locally accumulated guest progress to the remote database
  /// for the newly signed up user and clears the local database cache.
  static Future<void> syncGuestProgressToRemote(String uid) async {
    try {
      final progressList = await LocalProgressService.getAllProgress();
      if (progressList.isEmpty) return;

      for (final p in progressList) {
        await _dbService.processQuizCompletion(
          uid: uid,
          category: p.category,
          scoreIncrement: p.score,
          correctIncrement: p.correctAnswers,
          answeredIncrement: p.totalQuestions,
          isTimed: p.isTimed,
          // Since it's synced progress from a guest, we do not add/modify shields or skips
          // unless they were acquired by the guest during play. Defaulting to 0.
          coinsEarned: 0, 
        );

        // Record a rank history entry for each synced game if appropriate
        final percentage = p.totalQuestions > 0
            ? (p.correctAnswers / p.totalQuestions) * 100
            : 0.0;
        final String rankLetter;
        if (percentage >= 90) {
          rankLetter = 'S';
        } else if (percentage >= 80) {
          rankLetter = 'A';
        } else if (percentage >= 70) {
          rankLetter = 'B';
        } else if (percentage >= 60) {
          rankLetter = 'C';
        } else if (percentage >= 50) {
          rankLetter = 'D';
        } else {
          rankLetter = 'E';
        }

        await _dbService.recordRankHistoryEntry(
          uid: uid,
          rank: rankLetter,
          category: p.category,
          percentage: percentage,
        );
      }

      // Sync completed successfully. Clear local cache.
      await LocalProgressService.clearProgress();
    } catch (e) {
      // Log or handle sync failures
    }
  }
}
