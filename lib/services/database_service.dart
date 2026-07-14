import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/avatar_options.dart';
import '../models/question.dart';
import '../models/rank_history.dart';
import '../models/user_rank.dart';
import '../models/badge.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of user rankings sorted by score descending (excludes lecturers)
  Stream<List<UserRank>> getRankingsStream() {
    return _db
        .collection('users')
        .orderBy('score', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) {
                final data = doc.data();
                return data['role'] != 'lecturer';
              })
              .map((doc) => UserRank.fromFirestore(doc))
              .toList(),
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

    await _db.collection('users').doc(uid).set({
      'displayName': displayName,
      'email': email,
      'score': 0,
      'quizCoins': 0,
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
      await _db.collection('users').doc(uid).update(data);
    }
  }

  // Update customized avatar URL and options details in Firestore
  Future<void> updateAvatar(
    String uid,
    String avatarUrl,
    Map<String, dynamic> details,
  ) async {
    await _db.collection('users').doc(uid).update({
      'avatarUrl': avatarUrl,
      'avatarDetails': details,
    });
  }

  // Update email verification status in Firestore
  Future<void> updateEmailVerificationStatus(String uid, bool verified) async {
    await _db.collection('users').doc(uid).update({'emailVerified': verified});
  }

  // Update user stats after a quiz challenge
  Future<void> updateUserQuizStats({
    required String uid,
    required String category,
    required int scoreIncrement,
    required int correctIncrement,
    required int answeredIncrement,
  }) async {
    final userRef = _db.collection('users').doc(uid);

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
    final userRef = _db.collection('users').doc(uid);
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
    await _db.collection('users').doc(uid).delete();

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
    await _db.collection('users').doc(uid).update({'selectedBadges': badgeIds});
  }

  // Get percentage of users who own a specific badge
  Future<double> getBadgeOwnershipPercentage(String badgeId) async {
    try {
      final totalQuery = await _db
          .collection('users')
          .where('role', isNotEqualTo: 'lecturer')
          .count()
          .get();
      final totalUsers = totalQuery.count ?? 1;
      if (totalUsers == 0) return 0.0;

      final badgeQuery = await _db
          .collection('users')
          .where('badges', arrayContains: badgeId)
          .count()
          .get();
      final badgeCount = badgeQuery.count ?? 0;

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

  // Get percentage of users who have a specific streak or higher
  Future<double> getStreakPercentage(int streakNumber) async {
    if (streakNumber == 0) return 100.0;
    try {
      final totalQuery = await _db
          .collection('users')
          .where('role', isNotEqualTo: 'lecturer')
          .count()
          .get();
      final totalUsers = totalQuery.count ?? 1;
      if (totalUsers == 0) return 0.0;

      final streakQuery = await _db
          .collection('users')
          .where('streakNumber', isGreaterThanOrEqualTo: streakNumber)
          .count()
          .get();
      final streakCount = streakQuery.count ?? 0;

      return (streakCount / totalUsers) * 100;
    } catch (e) {
      return 0.0;
    }
  }
}
