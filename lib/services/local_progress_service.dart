import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/guest_user.dart';

class GuestStats {
  final int score;
  final int questionsAnswered;
  final int questionsCorrect;
  final int streakNumber;
  final int computerArchitecturePoints;
  final int caAnswered;
  final int caCorrect;
  final int computerNetworkingPoints;
  final int cnAnswered;
  final int cnCorrect;
  final int softwareEngineeringPoints;
  final int seAnswered;
  final int seCorrect;

  GuestStats({
    required this.score,
    required this.questionsAnswered,
    required this.questionsCorrect,
    required this.streakNumber,
    required this.computerArchitecturePoints,
    required this.caAnswered,
    required this.caCorrect,
    required this.computerNetworkingPoints,
    required this.cnAnswered,
    required this.cnCorrect,
    required this.softwareEngineeringPoints,
    required this.seAnswered,
    required this.seCorrect,
  });

  factory GuestStats.empty() {
    return GuestStats(
      score: 0,
      questionsAnswered: 0,
      questionsCorrect: 0,
      streakNumber: 0,
      computerArchitecturePoints: 0,
      caAnswered: 0,
      caCorrect: 0,
      computerNetworkingPoints: 0,
      cnAnswered: 0,
      cnCorrect: 0,
      softwareEngineeringPoints: 0,
      seAnswered: 0,
      seCorrect: 0,
    );
  }
}

class LocalProgressService {
  static const String _guestUserKey = 'guest_user';
  static const String _guestProgressKey = 'guest_progress';

  static Future<void> saveGuestUser(GuestUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestUserKey, jsonEncode(user.toJson()));
  }

  static Future<GuestUser?> loadGuestUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_guestUserKey);
    if (jsonStr == null) return null;
    try {
      return GuestUser.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<List<GuestProgress>> getAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_guestProgressKey);
    if (list == null) return [];
    return list.map((item) {
      return GuestProgress.fromJson(jsonDecode(item) as Map<String, dynamic>);
    }).toList();
  }

  static Future<void> addProgress(GuestProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getAllProgress();
    current.add(progress);
    final stringList = current.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_guestProgressKey, stringList);
  }

  static Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestProgressKey);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestUserKey);
    await prefs.remove(_guestProgressKey);
  }

  static Future<GuestStats> getAggregatedStats() async {
    final progressList = await getAllProgress();
    if (progressList.isEmpty) {
      return GuestStats.empty();
    }

    // Sort by playedAt to simulate running streak logic correctly
    final sortedList = List<GuestProgress>.from(progressList)
      ..sort((a, b) => a.playedAt.compareTo(b.playedAt));

    int score = 0;
    int questionsAnswered = 0;
    int questionsCorrect = 0;
    int streakNumber = 0;

    int computerArchitecturePoints = 0;
    int caAnswered = 0;
    int caCorrect = 0;

    int computerNetworkingPoints = 0;
    int cnAnswered = 0;
    int cnCorrect = 0;

    int softwareEngineeringPoints = 0;
    int seAnswered = 0;
    int seCorrect = 0;

    for (final p in sortedList) {
      score += p.score;
      questionsAnswered += p.totalQuestions;
      questionsCorrect += p.correctAnswers;

      // Same streak check logic as DatabaseService:
      // increment if user scored at least half correct; otherwise reset
      if (p.totalQuestions > 0 && p.correctAnswers >= (p.totalQuestions / 2).ceil()) {
        streakNumber += 1;
      } else {
        streakNumber = 0;
      }

      if (p.category == 'Computer Architecture') {
        computerArchitecturePoints += p.score;
        caAnswered += p.totalQuestions;
        caCorrect += p.correctAnswers;
      } else if (p.category == 'Computer Networking') {
        computerNetworkingPoints += p.score;
        cnAnswered += p.totalQuestions;
        cnCorrect += p.correctAnswers;
      } else if (p.category == 'Software Engineering') {
        softwareEngineeringPoints += p.score;
        seAnswered += p.totalQuestions;
        seCorrect += p.correctAnswers;
      }
    }

    return GuestStats(
      score: score,
      questionsAnswered: questionsAnswered,
      questionsCorrect: questionsCorrect,
      streakNumber: streakNumber,
      computerArchitecturePoints: computerArchitecturePoints,
      caAnswered: caAnswered,
      caCorrect: caCorrect,
      computerNetworkingPoints: computerNetworkingPoints,
      cnAnswered: cnAnswered,
      cnCorrect: cnCorrect,
      softwareEngineeringPoints: softwareEngineeringPoints,
      seAnswered: seAnswered,
      seCorrect: seCorrect,
    );
  }
}
