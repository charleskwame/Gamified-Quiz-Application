import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gamified_quiz_app/models/guest_account.dart';
import 'package:gamified_quiz_app/services/guest_account_store.dart';
import 'package:gamified_quiz_app/services/local_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GuestAccountStore.instance.invalidate();
  });

  group('GuestAccountStore', () {
    test('create initializes a guest account with starting coins', () async {
      final account = await GuestAccountStore.instance.create(username: 'Ada');

      expect(account.displayName, 'Ada');
      expect(account.quizCoins, 100);
      expect(GuestAccountStore.instance.account?.id, account.id);
    });

    test('purchaseItem decrements coins and increments the item count',
        () async {
      await GuestAccountStore.instance.create(username: 'Ada');

      final success = await GuestAccountStore.instance.purchaseItem(
        itemId: 'shield',
        price: 50,
      );

      expect(success, isTrue);
      final account = GuestAccountStore.instance.account!;
      expect(account.quizCoins, 50);
      expect(account.shieldCount, 1);
      expect(account.purchases, hasLength(1));
      expect(account.purchases.first.itemId, 'shield');
    });

    test('purchaseItem rejects insufficient coins', () async {
      await GuestAccountStore.instance.create(username: 'Ada');

      final success = await GuestAccountStore.instance.purchaseItem(
        itemId: 'pause_timer',
        price: 500,
      );

      expect(success, isFalse);
      expect(GuestAccountStore.instance.account!.quizCoins, 100);
      expect(GuestAccountStore.instance.account!.purchases, isEmpty);
    });

    test('purchaseItem enforces the max capacity of 3', () async {
      final account = GuestAccount.create(id: 'rich', username: 'Rich');
      await LocalProgressService.saveAccount(
        account.copyWith(quizCoins: 500),
      );
      GuestAccountStore.instance.invalidate();
      await GuestAccountStore.instance.load();

      for (var i = 0; i < 3; i++) {
        final ok = await GuestAccountStore.instance.purchaseItem(
          itemId: 'shield',
          price: 50,
        );
        expect(ok, isTrue);
      }

      expect(GuestAccountStore.instance.account!.shieldCount, 3);

      final rejected = await GuestAccountStore.instance.purchaseItem(
        itemId: 'shield',
        price: 50,
      );

      expect(rejected, isFalse);
      expect(GuestAccountStore.instance.account!.shieldCount, 3);
    });

    test('completeSession awards coins, records the session, and unlocks badges',
        () async {
      await GuestAccountStore.instance.create(username: 'Ada');

      final unlocked = await GuestAccountStore.instance.completeSession(
        category: 'Computer Architecture',
        score: 40,
        correctAnswers: 10,
        totalQuestions: 10,
        isTimed: true,
        coinsEarned: 15,
        shieldChange: -1,
      );

      final account = GuestAccountStore.instance.account!;
      expect(account.sessions, hasLength(1));
      expect(account.quizCoins, 115);
      expect(account.shieldCount, 0); // 0 - 1 clamped
      expect(unlocked, contains('first_steps'));
      expect(account.badges, contains('first_steps'));
    });

    test('toggleBadgeSelection caps the selection at 3', () async {
      await GuestAccountStore.instance.create(username: 'Ada');

      final store = GuestAccountStore.instance;
      store.account = store.account!.copyWith(badges: ['a', 'b', 'c', 'd']);

      await store.toggleBadgeSelection('a');
      await store.toggleBadgeSelection('b');
      await store.toggleBadgeSelection('c');
      final rejected = await store.toggleBadgeSelection('d');

      expect(rejected, isNull);
      expect(store.account!.selectedBadges, ['a', 'b', 'c']);
    });

    test('updateDisplayName and saveAvatar persist changes', () async {
      await GuestAccountStore.instance.create(username: 'Ada');

      await GuestAccountStore.instance.updateDisplayName('Grace');
      await GuestAccountStore.instance.saveAvatar(
        'https://example.com/avatar.svg',
        {'seed': '12345678'},
      );

      final account = GuestAccountStore.instance.account!;
      expect(account.displayName, 'Grace');
      expect(account.avatarUrl, 'https://example.com/avatar.svg');
    });
  });
}
