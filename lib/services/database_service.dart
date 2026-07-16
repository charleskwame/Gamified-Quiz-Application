import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/avatar_options.dart';
import '../models/question.dart';
import '../models/rank_history.dart';
import '../models/user_rank.dart';
import '../models/badge.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _db.collection('users').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> _publicProfileDoc(String uid) {
    return _db.collection('publicProfiles').doc(uid);
  }

  Map<String, dynamic> _publicProfileData({
    required String displayName,
    required int score,
    required int computerArchitecturePoints,
    required int computerNetworkingPoints,
    required int softwareEngineeringPoints,
    required int streakNumber,
    required List<String> badges,
    required List<String> selectedBadges,
    required String avatarUrl,
  }) {
    return {
      'displayName': displayName,
      'score': score,
      'computerArchitecturePoints': computerArchitecturePoints,
      'computerNetworkingPoints': computerNetworkingPoints,
      'softwareEngineeringPoints': softwareEngineeringPoints,
      'streakNumber': streakNumber,
      'badges': badges,
      'selectedBadges': selectedBadges,
      'avatarUrl': avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> ensurePublicProfileExists(
    String uid, {
    String? fallbackDisplayName,
    String? fallbackAvatarUrl,
  }) async {
    final privateSnap = await _userDoc(uid).get();
    final data = privateSnap.data() ?? <String, dynamic>{};

    await _publicProfileDoc(uid).set(
      _publicProfileData(
        displayName:
            (data['displayName'] as String?) ??
            fallbackDisplayName ??
            'Scholar',
        score: data['score'] as int? ?? 0,
        computerArchitecturePoints:
            data['computerArchitecturePoints'] as int? ?? 0,
        computerNetworkingPoints: data['computerNetworkingPoints'] as int? ?? 0,
        softwareEngineeringPoints:
            data['softwareEngineeringPoints'] as int? ?? 0,
        streakNumber: data['streakNumber'] as int? ?? 0,
        badges: List<String>.from(data['badges'] ?? <String>[]),
        selectedBadges: List<String>.from(data['selectedBadges'] ?? <String>[]),
        avatarUrl: (data['avatarUrl'] as String?) ?? fallbackAvatarUrl ?? '',
      ),
      SetOptions(merge: true),
    );
  }

  // Stream of public user rankings sorted by score descending.
  Stream<List<UserRank>> getRankingsStream() {
    return _db
        .collection('publicProfiles')
        .orderBy('score', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserRank.fromFirestore(doc)).toList(),
        );
  }

  // Initialize user profile and stats tracking document in Firestore
  Future<void> initializeUserStats(
    String uid,
    String displayName,
    String email,
  ) async {
    final values = AvatarOptions.randomize();
    final avatarUrl = AvatarOptions.buildUrl(values);
    final avatarDetails = <String, dynamic>{
      for (final category in AvatarOptions.categories)
        category.key: values[category.key],
      'seed': values['seed'],
    };

    await _userDoc(uid).set({
      'displayName': displayName,
      'email': email,
      'score': 0,
      'quizCoins': 100,
      'shieldCount': 0,
      'skipCount': 0,
      'pauseTimerCount': 0,
      'emailVerified': false,
      'computerArchitecturePoints': 0,
      'caAnswered': 0,
      'caCorrect': 0,
      'computerNetworkingPoints': 0,
      'cnAnswered': 0,
      'cnCorrect': 0,
      'softwareEngineeringPoints': 0,
      'seAnswered': 0,
      'seCorrect': 0,
      'questionsCorrect': 0,
      'questionsAnswered': 0,
      'streakNumber': 0,
      'badges': <String>[],
      'selectedBadges': <String>[],
      'avatarUrl': avatarUrl,
      'avatarDetails': avatarDetails,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _publicProfileDoc(uid).set(
      _publicProfileData(
        displayName: displayName,
        score: 0,
        computerArchitecturePoints: 0,
        computerNetworkingPoints: 0,
        softwareEngineeringPoints: 0,
        streakNumber: 0,
        badges: <String>[],
        selectedBadges: <String>[],
        avatarUrl: avatarUrl,
      ),
      SetOptions(merge: true),
    );
  }

  // Sync user profile updates to Firestore
  Future<void> updateUserInfo(
    String uid,
    String? displayName,
    String? email,
  ) async {
    final Map<String, dynamic> data = {};
    if (displayName != null && displayName.isNotEmpty) {
      data['displayName'] = displayName;
    }
    if (email != null && email.isNotEmpty) {
      data['email'] = email;
    }
    if (data.isNotEmpty) {
      await _userDoc(uid).update(data);
      if (data.containsKey('displayName')) {
        await _publicProfileDoc(uid).set({
          'displayName': data['displayName'],
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  // Update customized avatar URL and options details in Firestore
  Future<void> updateAvatar(
    String uid,
    String avatarUrl,
    Map<String, dynamic> details,
  ) async {
    await _userDoc(
      uid,
    ).update({'avatarUrl': avatarUrl, 'avatarDetails': details});
    await _publicProfileDoc(uid).set({
      'avatarUrl': avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Update email verification status in Firestore
  Future<void> updateEmailVerificationStatus(String uid, bool verified) async {
    await _userDoc(uid).update({'emailVerified': verified});
  }

  // Update user stats after a quiz challenge
  Future<void> updateUserQuizStats({
    required String uid,
    required String category,
    required int scoreIncrement,
    required int correctIncrement,
    required int answeredIncrement,
  }) async {
    final userRef = _userDoc(uid);
    final publicRef = _publicProfileDoc(uid);

    final Map<String, dynamic> updates = {
      'score': FieldValue.increment(scoreIncrement),
      'questionsCorrect': FieldValue.increment(correctIncrement),
      'questionsAnswered': FieldValue.increment(answeredIncrement),
    };

    if (category == 'Computer Architecture') {
      updates['computerArchitecturePoints'] = FieldValue.increment(
        scoreIncrement,
      );
      updates['caAnswered'] = FieldValue.increment(answeredIncrement);
      updates['caCorrect'] = FieldValue.increment(correctIncrement);
    } else if (category == 'Computer Networking') {
      updates['computerNetworkingPoints'] = FieldValue.increment(
        scoreIncrement,
      );
      updates['cnAnswered'] = FieldValue.increment(answeredIncrement);
      updates['cnCorrect'] = FieldValue.increment(correctIncrement);
    } else if (category == 'Software Engineering') {
      updates['softwareEngineeringPoints'] = FieldValue.increment(
        scoreIncrement,
      );
      updates['seAnswered'] = FieldValue.increment(answeredIncrement);
      updates['seCorrect'] = FieldValue.increment(correctIncrement);
    }

    await userRef.update(updates);

    final Map<String, dynamic> publicUpdates = {
      'score': FieldValue.increment(scoreIncrement),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (category == 'Computer Architecture') {
      publicUpdates['computerArchitecturePoints'] = FieldValue.increment(
        scoreIncrement,
      );
    } else if (category == 'Computer Networking') {
      publicUpdates['computerNetworkingPoints'] = FieldValue.increment(
        scoreIncrement,
      );
    } else if (category == 'Software Engineering') {
      publicUpdates['softwareEngineeringPoints'] = FieldValue.increment(
        scoreIncrement,
      );
    }

    await publicRef.set(publicUpdates, SetOptions(merge: true));
  }

  // Processes completion of a quiz challenge using a transaction
  // Updates stats, calculates streaks, evaluates badges, and returns newly unlocked badge ids
  Future<List<String>> processQuizCompletion({
    required String uid,
    required String category,
    required int scoreIncrement,
    required int correctIncrement,
    required int answeredIncrement,
    required bool isTimed,
    int coinsEarned = 0,
    int shieldChange = 0,
    int skipChange = 0,
    int pauseTimerChange = 0,
  }) async {
    final userRef = _userDoc(uid);
    final publicRef = _publicProfileDoc(uid);
    List<String> newlyUnlocked = [];

    await _db.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) {
        return;
      }

      final data = userSnap.data() as Map<String, dynamic>;

      // Get current fields
      int score = data['score'] ?? 0;
      int computerArchitecturePoints = data['computerArchitecturePoints'] ?? 0;
      int computerNetworkingPoints = data['computerNetworkingPoints'] ?? 0;
      int softwareEngineeringPoints = data['softwareEngineeringPoints'] ?? 0;
      int questionsCorrect = data['questionsCorrect'] ?? 0;
      int questionsAnswered = data['questionsAnswered'] ?? 0;
      int streakNumber = data['streakNumber'] ?? 0;
      List<String> badges = List<String>.from(data['badges'] ?? []);

      int caAnswered = data['caAnswered'] ?? 0;
      int caCorrect = data['caCorrect'] ?? 0;
      int cnAnswered = data['cnAnswered'] ?? 0;
      int cnCorrect = data['cnCorrect'] ?? 0;
      int seAnswered = data['seAnswered'] ?? 0;
      int seCorrect = data['seCorrect'] ?? 0;

      // Apply quiz results
      score += scoreIncrement;
      questionsCorrect += correctIncrement;
      questionsAnswered += answeredIncrement;

      if (category == 'Computer Architecture') {
        computerArchitecturePoints += scoreIncrement;
        caAnswered += answeredIncrement;
        caCorrect += correctIncrement;
      } else if (category == 'Computer Networking') {
        computerNetworkingPoints += scoreIncrement;
        cnAnswered += answeredIncrement;
        cnCorrect += correctIncrement;
      } else if (category == 'Software Engineering') {
        softwareEngineeringPoints += scoreIncrement;
        seAnswered += answeredIncrement;
        seCorrect += correctIncrement;
      }

      // Calculate streak: increment if user scored at least half correct
      if (answeredIncrement > 0 &&
          correctIncrement >= (answeredIncrement / 2).ceil()) {
        streakNumber += 1;
      }

      // Evaluate badges
      for (var badgeDef in allBadges) {
        if (!badges.contains(badgeDef.id)) {
          final isUnlocked = badgeDef.checkUnlock(
            score: score,
            computerArchitecturePoints: computerArchitecturePoints,
            computerNetworkingPoints: computerNetworkingPoints,
            softwareEngineeringPoints: softwareEngineeringPoints,
            questionsCorrect: questionsCorrect,
            questionsAnswered: questionsAnswered,
            streakNumber: streakNumber,
            latestCorrect: correctIncrement,
            isTimed: isTimed,
          );
          if (isUnlocked) {
            badges.add(badgeDef.id);
            newlyUnlocked.add(badgeDef.id);
          }
        }
      }

      // Update in transaction
      transaction.update(userRef, {
        'score': score,
        'quizCoins': FieldValue.increment(coinsEarned),
        'shieldCount': FieldValue.increment(shieldChange),
        'skipCount': FieldValue.increment(skipChange),
        'pauseTimerCount': FieldValue.increment(pauseTimerChange),
        'computerArchitecturePoints': computerArchitecturePoints,
        'computerNetworkingPoints': computerNetworkingPoints,
        'softwareEngineeringPoints': softwareEngineeringPoints,
        'caAnswered': caAnswered,
        'caCorrect': caCorrect,
        'cnAnswered': cnAnswered,
        'cnCorrect': cnCorrect,
        'seAnswered': seAnswered,
        'seCorrect': seCorrect,
        'questionsCorrect': questionsCorrect,
        'questionsAnswered': questionsAnswered,
        'streakNumber': streakNumber,
        'badges': badges,
      });

      transaction.set(
        publicRef,
        _publicProfileData(
          displayName: (data['displayName'] as String?) ?? 'Scholar',
          score: score,
          computerArchitecturePoints: computerArchitecturePoints,
          computerNetworkingPoints: computerNetworkingPoints,
          softwareEngineeringPoints: softwareEngineeringPoints,
          streakNumber: streakNumber,
          badges: badges,
          selectedBadges: List<String>.from(data['selectedBadges'] ?? []),
          avatarUrl: (data['avatarUrl'] as String?) ?? '',
        ),
        SetOptions(merge: true),
      );
    });

    return newlyUnlocked;
  }

  // Download up to 50 questions for a category for offline use
  Future<void> downloadQuestionsForOffline(String category) async {
    final collectionName =
        '${category.toLowerCase().replaceAll(' ', '_')}_questions';
    final snapshot = await _db.collection(collectionName).limit(50).get();

    final questionsList = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'questionText': data['questionText'] ?? '',
        'options': List<String>.from(data['options'] ?? []),
        'correctAnswer': data['correctAnswer'] ?? '',
        'explanation': data['explanation'] ?? '',
        'category': category,
      };
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(questionsList);
    final key = 'offline_${category.toLowerCase().replaceAll(' ', '_')}';
    await prefs.setString(key, jsonStr);
  }

  // Load offline questions from SharedPreferences
  Future<List<Question>> loadOfflineQuestions(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'offline_${category.toLowerCase().replaceAll(' ', '_')}';
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return [];

    final List<dynamic> jsonList = json.decode(jsonStr);
    return jsonList.map((item) {
      return Question(
        id: item['id'] ?? '',
        questionText: item['questionText'] ?? '',
        options: List<String>.from(item['options'] ?? []),
        correctAnswer: item['correctAnswer'] ?? '',
        explanation: item['explanation'] ?? '',
        category: item['category'] ?? category,
      );
    }).toList();
  }

  // Check if offline questions are available for a category
  Future<bool> hasOfflineQuestions(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'offline_${category.toLowerCase().replaceAll(' ', '_')}';
    return prefs.containsKey(key);
  }

  // Fetch questions by category from separate collections
  Future<List<Question>> getQuestionsByCategory(String category) async {
    final collectionName =
        '${category.toLowerCase().replaceAll(' ', '_')}_questions';
    final snapshot = await _db.collection(collectionName).get();
    return snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();
  }

  // Seeding method to load and upload JSON question banks into separate collections
  Future<String> seedAllQuestions() async {
    final filesToSeed = {
      'lib/assets/computer_architecture_parsed_questions.json':
          'Computer Architecture',
      'lib/assets/computer_networking_parsed_questions.json':
          'Computer Networking',
      'lib/assets/software_engineering_parsed_questions.json':
          'Software Engineering',
    };

    int totalAdded = 0;
    List<String> details = [];

    for (var entry in filesToSeed.entries) {
      final String filePath = entry.key;
      final String category = entry.value;
      final String collectionName =
          '${category.toLowerCase().replaceAll(' ', '_')}_questions';

      try {
        // Check if category is already seeded
        final check = await _db.collection(collectionName).limit(1).get();

        if (check.docs.isNotEmpty) {
          details.add('$category ($collectionName): Already seeded.');
          continue;
        }

        // Load and parse JSON
        final String jsonString = await rootBundle.loadString(filePath);
        final List<dynamic> jsonList = json.decode(jsonString);

        final batch = _db.batch();
        final collection = _db.collection(collectionName);

        int addedInCategory = 0;
        for (var item in jsonList) {
          final docRef = collection.doc();
          batch.set(docRef, {
            'questionText': item['question'] ?? '',
            'options': List<String>.from(item['options'] ?? []),
            'correctAnswer': item['answerKey'] ?? '',
            'explanation': item['explanation'] ?? '',
            'category': category,
          });
          addedInCategory++;

          // Firestore batch limit is 500 writes
          if (addedInCategory >= 450) {
            break;
          }
        }

        await batch.commit();
        totalAdded += addedInCategory;
        details.add(
          '$category: Seeded $addedInCategory questions into $collectionName.',
        );
      } catch (e) {
        details.add('$category error: $e');
      }
    }

    return 'Seeding Results:\n${details.join('\n')}\nTotal new questions added: $totalAdded';
  }

  // Record a single rank history entry after quiz completion
  Future<void> recordRankHistoryEntry({
    required String uid,
    required String rank,
    required String category,
    required double percentage,
  }) async {
    await _db.collection('users').doc(uid).collection('rankHistory').add({
      'rank': rank,
      'category': category,
      'percentage': percentage,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Stream the user's rank history ordered by timestamp descending
  Stream<List<RankHistoryEntry>> getRankHistoryStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('rankHistory')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RankHistoryEntry.fromFirestore(doc))
              .toList(),
        );
  }

  // Delete all existing rank history entries for cleanup (used to remove bad data from buggy getCurrentRank)
  Future<void> repairRankHistory(String uid) async {
    final historySnap = await _db
        .collection('users')
        .doc(uid)
        .collection('rankHistory')
        .get();

    final batch = _db.batch();
    for (final doc in historySnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Deletes user account data from Firestore and SharedPreferences offline questions
  Future<void> deleteUserAccount(String uid) async {
    // Delete all rank history subcollection documents
    final historySnap = await _db
        .collection('users')
        .doc(uid)
        .collection('rankHistory')
        .get();

    final batch = _db.batch();
    for (final doc in historySnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Delete user document in Firestore
    await _userDoc(uid).delete();
    await _publicProfileDoc(uid).delete();

    // Clear local saved offline questions in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final keysToClear = prefs
        .getKeys()
        .where((key) => key.startsWith('offline_'))
        .toList();
    for (final key in keysToClear) {
      await prefs.remove(key);
    }
  }

  // Updates the list of up to 3 selected badges to display next to user name in rankings
  Future<void> updateSelectedBadges(String uid, List<String> badgeIds) async {
    await _userDoc(uid).update({'selectedBadges': badgeIds});
    await _publicProfileDoc(uid).set({
      'selectedBadges': badgeIds,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get percentage of users who own a specific badge
  Future<double> getBadgeOwnershipPercentage(String badgeId) async {
    try {
      final snapshot = await _db.collection('publicProfiles').get();
      if (snapshot.docs.isEmpty) return 0.0;

      final totalUsers = snapshot.docs.length;
      final badgeCount = snapshot.docs.where((doc) {
        final data = doc.data();
        final badges = List<String>.from(data['badges'] ?? []);
        return badges.contains(badgeId);
      }).length;

      return (badgeCount / totalUsers) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  // Increment the incorrect answer counter for a specific question in the global
  // "[subject]_questions_gotten_incorrectly" collection.
  // Only called for normal and timed (challenge) modes, NOT offline mode.
  Future<void> incrementIncorrectQuestion({
    required String category,
    required String questionId,
  }) async {
    final collectionName =
        '${category.toLowerCase().replaceAll(' ', '_')}_questions_gotten_incorrectly';
    final docRef = _db.collection(collectionName).doc(questionId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        transaction.update(docRef, {
          'number_of_wrong': FieldValue.increment(1),
        });
      } else {
        transaction.set(docRef, {
          'questionId': questionId,
          'number_of_wrong': 1,
        });
      }
    });
  }

  // Purchases an item from the shop using a Firestore transaction.
  // Deducts coins and increments the item count atomically.
  // Returns true on success, false if insufficient coins or at max capacity.
  // maxItems is the maximum number the user can hold (default 3).
  Future<bool> purchaseItem({
    required String uid,
    required String itemId,
    required int price,
    int maxItems = 3,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    bool success = false;

    try {
      await _db.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        if (!userSnap.exists) return;

        final data = userSnap.data() as Map<String, dynamic>;
        final currentCoins = data['quizCoins'] as int? ?? 0;

        if (currentCoins < price) return; // Not enough coins

        // Map item IDs to their Firestore field names
        String countField;
        switch (itemId) {
          case 'shield':
            countField = 'shieldCount';
            break;
          case 'skip_question':
            countField = 'skipCount';
            break;
          case 'no_deductions':
            countField = 'pauseTimerCount';
            break;
          default:
            return; // Unknown item
        }

        final currentCount = data[countField] as int? ?? 0;
        if (currentCount >= maxItems) return; // At max capacity

        transaction.update(userRef, {
          'quizCoins': FieldValue.increment(-price),
          countField: FieldValue.increment(1),
        });

        success = true;
      });
    } catch (e) {
      debugPrint('purchaseItem error: $e');
      success = false;
    }

    return success;
  }

  // One-time migration: grants 100 starting quiz coins to all existing users
  // who have less than 100 coins. Uses pagination to handle large collections.
  // Filters out lecturers in-memory (avoids needing a composite index).
  // Returns the number of users updated.
  Future<int> seedInitialCoinsForAllUsers() async {
    debugPrint(
      'seedInitialCoinsForAllUsers is disabled under the current Firestore rules.',
    );
    return 0;
  }

  // Get percentage of users who have a specific streak or higher
  Future<double> getStreakPercentage(int streakNumber) async {
    if (streakNumber <= 0) return 100.0;

    try {
      final snapshot = await _db.collection('publicProfiles').get();
      if (snapshot.docs.isEmpty) return 0.0;

      final totalUsers = snapshot.docs.length;
      final streakCount = snapshot.docs.where((doc) {
        final data = doc.data();
        final value = data['streakNumber'] as int? ?? 0;
        return value >= streakNumber;
      }).length;

      return (streakCount / totalUsers) * 100;
    } catch (e) {
      return 0.0;
    }
  }
}
