import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/badge.dart';
import '../models/guest_account.dart';
import 'local_progress_service.dart';

/// Reactive, in-memory repository for the current guest account.
///
/// Screens listen to this notifier to rebuild when local mutations occur,
/// matching the app's existing setState/FutureBuilder style without pulling in
/// a heavier state-management framework. All persistence goes through
/// [LocalProgressService].
class GuestAccountStore extends ChangeNotifier {
  GuestAccountStore._();

  static final GuestAccountStore instance = GuestAccountStore._();

  GuestAccount? account;

  /// Whether an in-memory load has been attempted for this process.
  bool _loaded = false;

  /// Loads the account from disk (once) and notifies listeners.
  Future<GuestAccount?> load() async {
    if (_loaded) return account;
    account = await LocalProgressService.loadAccount();
    _loaded = true;
    notifyListeners();
    return account;
  }

  /// Returns the loaded account without forcing a disk read.
  GuestAccount? get current => account;

  /// Creates a new guest account (used by the guest name setup screen).
  Future<GuestAccount> create({required String username}) async {
    final id = const Uuid().v4();
    final created = GuestAccount.create(id: id, username: username);
    account = created;
    _loaded = true;
    await LocalProgressService.saveAccount(created);
    notifyListeners();
    return created;
  }

  /// Resets the in-memory cache so the next [load] re-reads from disk.
  void invalidate() {
    _loaded = false;
    account = null;
  }

  Future<void> _persist(GuestAccount next) async {
    account = next;
    await LocalProgressService.saveAccount(next);
    notifyListeners();
  }

  Future<void> updateDisplayName(String name) async {
    final current = await _ensure();
    if (current == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == current.displayName) return;
    await _persist(
      current.copyWith(displayName: trimmed, updatedAt: DateTime.now()),
    );
  }

  Future<void> saveAvatar(String url, Map<String, dynamic> details) async {
    final current = await _ensure();
    if (current == null) return;
    await _persist(
      current.copyWith(
        avatarUrl: url,
        avatarDetails: details,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Records a completed quiz session, applying coins, power-up consumption,
  /// and badge unlocks atomically. Returns newly unlocked badge IDs.
  Future<List<String>> completeSession({
    required String category,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required bool isTimed,
    int coinsEarned = 0,
    int shieldChange = 0,
    int skipChange = 0,
    int pauseTimerChange = 0,
    int noDeductionsChange = 0,
  }) async {
    final current = await _ensure();
    final newlyUnlocked = <String>[];
    if (current == null) return newlyUnlocked;

    final percentage = totalQuestions > 0
        ? (correctAnswers / totalQuestions) * 100
        : 0.0;
    final session = GuestSession(
      sessionId: const Uuid().v4(),
      challengeId:
          'challenge_${category.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().microsecondsSinceEpoch}',
      category: category,
      score: score,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      playedAt: DateTime.now(),
      isTimed: isTimed,
      coinsEarned: coinsEarned,
      shieldChange: shieldChange,
      skipChange: skipChange,
      pauseTimerChange: pauseTimerChange,
      noDeductionsChange: noDeductionsChange,
      rank: GuestSession.rankForPercentage(percentage),
      percentage: percentage,
    );

    final sessions = List<GuestSession>.from(current.sessions)..add(session);

    // Evaluate badge unlocks from the final aggregated totals, mirroring the
    // authenticated processQuizCompletion path.
    var scoreTotal = 0;
    var answered = 0;
    var correct = 0;
    var caPoints = 0;
    var cnPoints = 0;
    var sePoints = 0;
    for (final s in sessions) {
      scoreTotal += s.score;
      answered += s.totalQuestions;
      correct += s.correctAnswers;
      if (s.category == 'Computer Architecture') {
        caPoints += s.score;
      } else if (s.category == 'Computer Networking') {
        cnPoints += s.score;
      } else if (s.category == 'Software Engineering') {
        sePoints += s.score;
      }
    }

    final badges = List<String>.from(current.badges);
    for (final badge in allBadges) {
      if (badges.contains(badge.id)) continue;
      final unlocked = badge.checkUnlock(
        score: scoreTotal,
        computerArchitecturePoints: caPoints,
        computerNetworkingPoints: cnPoints,
        softwareEngineeringPoints: sePoints,
        questionsCorrect: correct,
        questionsAnswered: answered,
        streakNumber: sessions.length,
        latestCorrect: correctAnswers,
        isTimed: isTimed,
      );
      if (unlocked) {
        badges.add(badge.id);
        newlyUnlocked.add(badge.id);
      }
    }

    await _persist(
      current.copyWith(
        quizCoins: (current.quizCoins + coinsEarned).clamp(0, 1 << 31),
        shieldCount: (current.shieldCount + shieldChange).clamp(0, 1 << 31),
        skipCount: (current.skipCount + skipChange).clamp(0, 1 << 31),
        pauseTimerCount: (current.pauseTimerCount + pauseTimerChange)
            .clamp(0, 1 << 31),
        noDeductionsCount: (current.noDeductionsCount + noDeductionsChange)
            .clamp(0, 1 << 31),
        badges: badges,
        sessions: sessions,
        updatedAt: DateTime.now(),
      ),
    );

    return newlyUnlocked;
  }

  /// Purchases an item locally using the same price/capacity rules as
  /// Firestore. Returns true on success.
  Future<bool> purchaseItem({
    required String itemId,
    required int price,
  }) async {
    final current = await _ensure();
    if (current == null) return false;
    if (current.quizCoins < price) return false;

    final countField = _countFieldFor(itemId);
    if (countField == null) return false;

    final currentCount = _countFor(current, countField);
    if (currentCount >= GuestAccount.maxItemCount) return false;

    final purchase = GuestPurchase(
      eventId: const Uuid().v4(),
      itemId: itemId,
      price: price,
      timestamp: DateTime.now(),
    );

    await _persist(
      current.copyWith(
        quizCoins: current.quizCoins - price,
        shieldCount: countField == 'shieldCount'
            ? current.shieldCount + 1
            : current.shieldCount,
        skipCount: countField == 'skipCount'
            ? current.skipCount + 1
            : current.skipCount,
        pauseTimerCount: countField == 'pauseTimerCount'
            ? current.pauseTimerCount + 1
            : current.pauseTimerCount,
        noDeductionsCount: countField == 'noDeductionsCount'
            ? current.noDeductionsCount + 1
            : current.noDeductionsCount,
        purchases: List<GuestPurchase>.from(current.purchases)..add(purchase),
        updatedAt: DateTime.now(),
      ),
    );

    return true;
  }

  /// Adds or removes a badge from the local selection (max 3), returning the
  /// resulting selection or null if the change was rejected.
  Future<List<String>?> toggleBadgeSelection(String badgeId) async {
    final current = await _ensure();
    if (current == null) return null;
    if (!current.badges.contains(badgeId)) return null;

    final selected = List<String>.from(current.selectedBadges);
    if (selected.contains(badgeId)) {
      selected.remove(badgeId);
    } else {
      if (selected.length >= GuestAccount.maxSelectedBadges) return null;
      selected.add(badgeId);
    }

    await _persist(
      current.copyWith(selectedBadges: selected, updatedAt: DateTime.now()),
    );
    return selected;
  }

  /// Marks the account as merged into a remote UID. The caller is responsible
  /// for deleting local data after confirming the merge elsewhere.
  Future<void> markMerged(String uid) async {
    final current = await _ensure();
    if (current == null) return;
    await _persist(
      current.copyWith(
        linkedUid: uid,
        migrationCompleted: true,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Clears the guest account after a confirmed remote merge.
  Future<void> clear() async {
    account = null;
    await LocalProgressService.deleteGuestAccount();
    notifyListeners();
  }

  /// Explicitly deletes the guest account (user-initiated).
  Future<void> deleteGuest() async {
    account = null;
    await LocalProgressService.deleteGuestAccount();
    notifyListeners();
  }

  Future<GuestAccount?> _ensure() async {
    return await load();
  }

  String? _countFieldFor(String itemId) {
    switch (itemId) {
      case 'shield':
        return 'shieldCount';
      case 'skip_question':
        return 'skipCount';
      case 'no_deductions':
        return 'noDeductionsCount';
      case 'pause_timer':
        return 'pauseTimerCount';
      default:
        return null;
    }
  }

  int _countFor(GuestAccount account, String field) {
    switch (field) {
      case 'shieldCount':
        return account.shieldCount;
      case 'skipCount':
        return account.skipCount;
      case 'noDeductionsCount':
        return account.noDeductionsCount;
      case 'pauseTimerCount':
        return account.pauseTimerCount;
      default:
        return 0;
    }
  }
}
