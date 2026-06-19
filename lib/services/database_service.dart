import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../models/user_rank.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of user rankings sorted by score descending
  Stream<List<UserRank>> getRankingsStream() {
    return _db
        .collection('users')
        .orderBy('score', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserRank.fromFirestore(doc)).toList());
  }

  // Initialize user profile and stats tracking document in Firestore
  Future<void> initializeUserStats(String uid, String displayName, String email) async {
    await _db.collection('users').doc(uid).set({
      'displayName': displayName,
      'email': email,
      'score': 0,
      'computerArchitecturePoints': 0,
      'computerNetworkingPoints': 0,
      'softwareEngineeringPoints': 0,
      'questionsCorrect': 0,
      'questionsAnswered': 0,
      'streakNumber': 0,
      'badges': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
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

    final String courseField;
    if (category == 'Computer Architecture') {
      courseField = 'computerArchitecturePoints';
    } else if (category == 'Computer Networking') {
      courseField = 'computerNetworkingPoints';
    } else if (category == 'Software Engineering') {
      courseField = 'softwareEngineeringPoints';
    } else {
      courseField = '';
    }

    final Map<String, dynamic> updates = {
      'score': FieldValue.increment(scoreIncrement),
      'questionsCorrect': FieldValue.increment(correctIncrement),
      'questionsAnswered': FieldValue.increment(answeredIncrement),
    };

    if (courseField.isNotEmpty) {
      updates[courseField] = FieldValue.increment(scoreIncrement);
    }

    await userRef.update(updates);
  }

  // Download up to 50 questions for a category for offline use
  Future<void> downloadQuestionsForOffline(String category) async {
    final collectionName = '${category.toLowerCase().replaceAll(' ', '_')}_questions';
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
    final collectionName = '${category.toLowerCase().replaceAll(' ', '_')}_questions';
    final snapshot = await _db.collection(collectionName).get();
    return snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();
  }

  // Seeding method to load and upload JSON question banks into separate collections
  Future<String> seedAllQuestions() async {
    final filesToSeed = {
      'lib/assets/computer_architecture_parsed_questions.json': 'Computer Architecture',
      'lib/assets/computer_networking_parsed_questions.json': 'Computer Networking',
      'lib/assets/software_engineering_parsed_questions.json': 'Software Engineering',
    };

    int totalAdded = 0;
    List<String> details = [];

    for (var entry in filesToSeed.entries) {
      final String filePath = entry.key;
      final String category = entry.value;
      final String collectionName = '${category.toLowerCase().replaceAll(' ', '_')}_questions';

      try {
        // Check if category is already seeded
        final check = await _db
            .collection(collectionName)
            .limit(1)
            .get();

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
        details.add('$category: Seeded $addedInCategory questions into $collectionName.');
      } catch (e) {
        details.add('$category error: $e');
      }
    }

    return 'Seeding Results:\n${details.join('\n')}\nTotal new questions added: $totalAdded';
  }
}
