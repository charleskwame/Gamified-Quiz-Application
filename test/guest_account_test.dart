import 'package:flutter_test/flutter_test.dart';
import 'package:gamified_quiz_app/models/guest_account.dart';
import 'package:gamified_quiz_app/models/guest_user.dart';

void main() {
  group('GuestAccount', () {
    test('create seeds starting coins and empty ledgers', () {
      final account = GuestAccount.create(id: 'g1', username: 'Ada');

      expect(account.id, 'g1');
      expect(account.displayName, 'Ada');
      expect(account.quizCoins, GuestAccount.startingCoins);
      expect(account.shieldCount, 0);
      expect(account.skipCount, 0);
      expect(account.pauseTimerCount, 0);
      expect(account.noDeductionsCount, 0);
      expect(account.sessions, isEmpty);
      expect(account.purchases, isEmpty);
      expect(account.badges, isEmpty);
      expect(account.selectedBadges, isEmpty);
      expect(account.schemaVersion, GuestAccount.currentSchemaVersion);
      expect(account.migrationCompleted, isFalse);
    });

    test('JSON round-trip preserves all fields', () {
      final account = GuestAccount.create(id: 'g1', username: 'Ada');
      final enriched = account.copyWith(
        quizCoins: 130,
        shieldCount: 2,
        badges: ['first_steps'],
        selectedBadges: ['first_steps'],
        sessions: [
          GuestSession(
            sessionId: 's1',
            challengeId: 'challenge_ca_1',
            category: 'Computer Architecture',
            score: 40,
            correctAnswers: 8,
            totalQuestions: 10,
            playedAt: DateTime(2026, 1, 1),
            isTimed: true,
            coinsEarned: 12,
            shieldChange: -1,
            rank: 'A',
            percentage: 80.0,
          ),
        ],
        purchases: [
          GuestPurchase(
            eventId: 'p1',
            itemId: 'shield',
            price: 50,
            timestamp: DateTime(2026, 1, 2),
          ),
        ],
        linkedUid: 'uid1',
        migrationCompleted: true,
      );

      final decoded = GuestAccount.fromJson(enriched.toJson());

      expect(decoded.id, 'g1');
      expect(decoded.quizCoins, 130);
      expect(decoded.shieldCount, 2);
      expect(decoded.badges, ['first_steps']);
      expect(decoded.selectedBadges, ['first_steps']);
      expect(decoded.sessions, hasLength(1));
      expect(decoded.sessions.first.sessionId, 's1');
      expect(decoded.sessions.first.coinsEarned, 12);
      expect(decoded.sessions.first.shieldChange, -1);
      expect(decoded.sessions.first.rank, 'A');
      expect(decoded.purchases, hasLength(1));
      expect(decoded.purchases.first.eventId, 'p1');
      expect(decoded.linkedUid, 'uid1');
      expect(decoded.migrationCompleted, isTrue);
    });

    test('fromLegacy imports sessions with zero economy and schema 1', () {
      final legacyUser = GuestUser(
        id: 'legacy-id',
        username: 'LegacyUser',
        createdAt: DateTime(2025, 5, 1),
      );
      final progress = [
        GuestProgress(
          challengeId: 'challenge_ca_1',
          category: 'Computer Architecture',
          score: 25,
          correctAnswers: 5,
          totalQuestions: 10,
          playedAt: DateTime(2025, 6, 1),
          isTimed: false,
        ),
      ];

      final account = GuestAccount.fromLegacy(
        user: legacyUser,
        progress: progress,
      );

      expect(account.id, 'legacy-id');
      expect(account.username, 'LegacyUser');
      expect(account.sessions, hasLength(1));
      expect(account.sessions.first.coinsEarned, 0);
      expect(account.sessions.first.score, 25);
      expect(account.sessions.first.percentage, 50.0);
      expect(account.sessions.first.rank, 'D');
      expect(account.quizCoins, GuestAccount.startingCoins);
      expect(account.schemaVersion, 1);
    });

    test('rankForPercentage maps to the Firestore rank letters', () {
      expect(GuestSession.rankForPercentage(95), 'S');
      expect(GuestSession.rankForPercentage(85), 'A');
      expect(GuestSession.rankForPercentage(75), 'B');
      expect(GuestSession.rankForPercentage(65), 'C');
      expect(GuestSession.rankForPercentage(55), 'D');
      expect(GuestSession.rankForPercentage(10), 'E');
    });

    test('fromJson tolerates missing optional fields', () {
      final account = GuestAccount.fromJson({
        'id': 'g2',
        'username': 'Bob',
        'displayName': 'Bob',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
        'avatarUrl': '',
        'avatarDetails': <String, dynamic>{},
        'quizCoins': 100,
      });

      expect(account.id, 'g2');
      expect(account.badges, isEmpty);
      expect(account.sessions, isEmpty);
      expect(account.purchases, isEmpty);
      expect(account.shieldCount, 0);
    });
  });
}
