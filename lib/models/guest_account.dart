import 'avatar_options.dart';
import 'guest_user.dart';

/// Versioned, device-bound local account for guest (unauthenticated) users.
///
/// A guest account is a superset of the legacy [GuestUser] profile and the
/// [GuestProgress] session list. It adds the economy (coins + power-ups),
/// avatar, badges, and a session/purchase ledger so every feature that a
/// registered user enjoys is available locally and can be uploaded exactly
/// once to Firestore when the user links a Google account.
class GuestAccount {
  static const int currentSchemaVersion = 2;

  /// Coins a brand-new local account starts with (matches the remote grant).
  static const int startingCoins = 100;

  /// Maximum number of each power-up a user can hold (matches Firestore).
  static const int maxItemCount = 3;

  /// Maximum number of badges a user can select for display.
  static const int maxSelectedBadges = 3;

  /// Stable local identity. Never uploaded or discoverable before auth.
  final String id;

  /// Original guest username (kept for legacy compatibility).
  final String username;

  /// Display name shown across the app.
  final String displayName;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// DiceBear avatar URL and its trait details.
  final String avatarUrl;
  final Map<String, dynamic> avatarDetails;

  /// Cached economy balances. The [sessions] and [purchases] ledgers are the
  /// source of truth used during remote merge; these fields exist for display.
  final int quizCoins;
  final int shieldCount;
  final int skipCount;
  final int pauseTimerCount;
  final int noDeductionsCount;

  /// Unlocked badge IDs and the user's badge display selection.
  final List<String> badges;
  final List<String> selectedBadges;

  /// Immutable session ledger (one entry per completed quiz).
  final List<GuestSession> sessions;

  /// Immutable purchase ledger (one entry per shop purchase).
  final List<GuestPurchase> purchases;

  final int schemaVersion;

  /// UID this account was last successfully merged into (null until linked).
  final String? linkedUid;

  /// True once the local account has been fully uploaded and can be cleared.
  final bool migrationCompleted;

  const GuestAccount({
    required this.id,
    required this.username,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
    required this.avatarUrl,
    required this.avatarDetails,
    required this.quizCoins,
    required this.shieldCount,
    required this.skipCount,
    required this.pauseTimerCount,
    required this.noDeductionsCount,
    required this.badges,
    required this.selectedBadges,
    required this.sessions,
    required this.purchases,
    this.schemaVersion = currentSchemaVersion,
    this.linkedUid,
    this.migrationCompleted = false,
  });

  /// Creates a brand-new account with the starting coin grant and a
  /// deterministic random avatar.
  factory GuestAccount.create({
    required String id,
    required String username,
    DateTime? now,
  }) {
    final values = AvatarOptions.randomize();
    final avatarUrl = AvatarOptions.buildUrl(values);
    final details = <String, dynamic>{
      for (final cat in AvatarOptions.categories) cat.key: values[cat.key],
      'seed': values['seed'],
    };
    return GuestAccount(
      id: id,
      username: username,
      displayName: username,
      createdAt: now ?? DateTime.now(),
      updatedAt: now ?? DateTime.now(),
      avatarUrl: avatarUrl,
      avatarDetails: details,
      quizCoins: startingCoins,
      shieldCount: 0,
      skipCount: 0,
      pauseTimerCount: 0,
      noDeductionsCount: 0,
      badges: const [],
      selectedBadges: const [],
      sessions: const [],
      purchases: const [],
    );
  }

  /// Migrates a legacy guest profile + session list into a full account.
  /// Legacy sessions carry no economy or rank data, so they are imported with
  /// zero coin/item deltas. The local account still receives the starting coin
  /// grant for continued local play, but that grant is NOT re-migrated when
  /// merging into an existing remote account (see SyncService).
  factory GuestAccount.fromLegacy({
    required GuestUser? user,
    required List<GuestProgress> progress,
  }) {
    final id = user?.id ??
        'guest_${DateTime.now().microsecondsSinceEpoch}';
    final username = user?.username ?? 'Guest';
    final now = DateTime.now();
    final values = AvatarOptions.randomize();
    final avatarUrl = AvatarOptions.buildUrl(values);
    final details = <String, dynamic>{
      for (final cat in AvatarOptions.categories) cat.key: values[cat.key],
      'seed': values['seed'],
    };

    final sessions = <GuestSession>[];
    for (var i = 0; i < progress.length; i++) {
      final p = progress[i];
      final percentage = p.totalQuestions > 0
          ? (p.correctAnswers / p.totalQuestions) * 100
          : 0.0;
      sessions.add(
        GuestSession(
          sessionId:
              'legacy_${id}_${i}_${p.playedAt.microsecondsSinceEpoch}',
          challengeId: p.challengeId,
          category: p.category,
          score: p.score,
          correctAnswers: p.correctAnswers,
          totalQuestions: p.totalQuestions,
          playedAt: p.playedAt,
          isTimed: p.isTimed,
          coinsEarned: 0,
          rank: GuestSession.rankForPercentage(percentage),
          percentage: percentage,
        ),
      );
    }

    return GuestAccount(
      id: id,
      username: username,
      displayName: username,
      createdAt: user?.createdAt ?? now,
      updatedAt: now,
      avatarUrl: avatarUrl,
      avatarDetails: details,
      quizCoins: startingCoins,
      shieldCount: 0,
      skipCount: 0,
      pauseTimerCount: 0,
      noDeductionsCount: 0,
      badges: const [],
      selectedBadges: const [],
      sessions: sessions,
      purchases: const [],
      schemaVersion: 1,
    );
  }

  GuestAccount copyWith({
    String? displayName,
    DateTime? updatedAt,
    String? avatarUrl,
    Map<String, dynamic>? avatarDetails,
    int? quizCoins,
    int? shieldCount,
    int? skipCount,
    int? pauseTimerCount,
    int? noDeductionsCount,
    List<String>? badges,
    List<String>? selectedBadges,
    List<GuestSession>? sessions,
    List<GuestPurchase>? purchases,
    String? linkedUid,
    bool? migrationCompleted,
  }) {
    return GuestAccount(
      id: id,
      username: username,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarDetails: avatarDetails ?? this.avatarDetails,
      quizCoins: quizCoins ?? this.quizCoins,
      shieldCount: shieldCount ?? this.shieldCount,
      skipCount: skipCount ?? this.skipCount,
      pauseTimerCount: pauseTimerCount ?? this.pauseTimerCount,
      noDeductionsCount: noDeductionsCount ?? this.noDeductionsCount,
      badges: badges ?? this.badges,
      selectedBadges: selectedBadges ?? this.selectedBadges,
      sessions: sessions ?? this.sessions,
      purchases: purchases ?? this.purchases,
      schemaVersion: schemaVersion,
      linkedUid: linkedUid ?? this.linkedUid,
      migrationCompleted: migrationCompleted ?? this.migrationCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'avatarUrl': avatarUrl,
      'avatarDetails': avatarDetails,
      'quizCoins': quizCoins,
      'shieldCount': shieldCount,
      'skipCount': skipCount,
      'pauseTimerCount': pauseTimerCount,
      'noDeductionsCount': noDeductionsCount,
      'badges': badges,
      'selectedBadges': selectedBadges,
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'purchases': purchases.map((p) => p.toJson()).toList(),
      'schemaVersion': schemaVersion,
      'linkedUid': linkedUid,
      'migrationCompleted': migrationCompleted,
    };
  }

  factory GuestAccount.fromJson(Map<String, dynamic> json) {
    return GuestAccount(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? 'Guest',
      displayName: json['displayName'] as String? ??
          json['username'] as String? ??
          'Guest',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      avatarUrl: json['avatarUrl'] as String? ?? '',
      avatarDetails: json['avatarDetails'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['avatarDetails'] as Map)
          : <String, dynamic>{},
      quizCoins: (json['quizCoins'] as num?)?.toInt() ?? startingCoins,
      shieldCount: (json['shieldCount'] as num?)?.toInt() ?? 0,
      skipCount: (json['skipCount'] as num?)?.toInt() ?? 0,
      pauseTimerCount: (json['pauseTimerCount'] as num?)?.toInt() ?? 0,
      noDeductionsCount: (json['noDeductionsCount'] as num?)?.toInt() ?? 0,
      badges: List<String>.from(json['badges'] ?? const []),
      selectedBadges: List<String>.from(json['selectedBadges'] ?? const []),
      sessions: (json['sessions'] as List? ?? const [])
          .map((e) => GuestSession.fromJson(e as Map<String, dynamic>))
          .toList(),
      purchases: (json['purchases'] as List? ?? const [])
          .map((e) => GuestPurchase.fromJson(e as Map<String, dynamic>))
          .toList(),
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      linkedUid: json['linkedUid'] as String?,
      migrationCompleted: json['migrationCompleted'] as bool? ?? false,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

/// A single completed quiz session, retained as an immutable ledger entry.
class GuestSession {
  /// Stable, unique identifier used as the deterministic Firestore doc ID
  /// during migration (idempotency key).
  final String sessionId;

  final String challengeId;
  final String category;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final DateTime playedAt;
  final bool isTimed;

  /// Economy deltas recorded for this session (coins earned and power-ups
  /// consumed). Consumption is stored as a negative delta.
  final int coinsEarned;
  final int shieldChange;
  final int skipChange;
  final int pauseTimerChange;
  final int noDeductionsChange;

  final String rank;
  final double percentage;

  const GuestSession({
    required this.sessionId,
    required this.challengeId,
    required this.category,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.playedAt,
    required this.isTimed,
    this.coinsEarned = 0,
    this.shieldChange = 0,
    this.skipChange = 0,
    this.pauseTimerChange = 0,
    this.noDeductionsChange = 0,
    required this.rank,
    required this.percentage,
  });

  /// Maps a session percentage to the same rank letter used by Firestore.
  static String rankForPercentage(double percentage) {
    if (percentage >= 90) return 'S';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'E';
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'challengeId': challengeId,
      'category': category,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'playedAt': playedAt.toIso8601String(),
      'isTimed': isTimed,
      'coinsEarned': coinsEarned,
      'shieldChange': shieldChange,
      'skipChange': skipChange,
      'pauseTimerChange': pauseTimerChange,
      'noDeductionsChange': noDeductionsChange,
      'rank': rank,
      'percentage': percentage,
    };
  }

  factory GuestSession.fromJson(Map<String, dynamic> json) {
    final totalQuestions = (json['totalQuestions'] as num?)?.toInt() ?? 0;
    final correctAnswers = (json['correctAnswers'] as num?)?.toInt() ?? 0;
    final percentage = (json['percentage'] as num?)?.toDouble() ??
        (totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0);
    return GuestSession(
      sessionId: json['sessionId'] as String? ?? '',
      challengeId: json['challengeId'] as String? ?? '',
      category: json['category'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      playedAt: GuestAccount._parseDate(json['playedAt']),
      isTimed: json['isTimed'] as bool? ?? false,
      coinsEarned: (json['coinsEarned'] as num?)?.toInt() ?? 0,
      shieldChange: (json['shieldChange'] as num?)?.toInt() ?? 0,
      skipChange: (json['skipChange'] as num?)?.toInt() ?? 0,
      pauseTimerChange: (json['pauseTimerChange'] as num?)?.toInt() ?? 0,
      noDeductionsChange: (json['noDeductionsChange'] as num?)?.toInt() ?? 0,
      rank: json['rank'] as String? ?? 'E',
      percentage: percentage,
    );
  }
}

/// A single shop purchase, retained as an immutable ledger entry so coins and
/// item counts can be applied exactly once during remote merge.
class GuestPurchase {
  final String eventId;
  final String itemId;
  final int price;
  final DateTime timestamp;

  const GuestPurchase({
    required this.eventId,
    required this.itemId,
    required this.price,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'itemId': itemId,
      'price': price,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GuestPurchase.fromJson(Map<String, dynamic> json) {
    return GuestPurchase(
      eventId: json['eventId'] as String? ?? '',
      itemId: json['itemId'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      timestamp: GuestAccount._parseDate(json['timestamp']),
    );
  }
}
