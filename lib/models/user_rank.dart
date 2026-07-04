import 'package:cloud_firestore/cloud_firestore.dart';

import 'level_system.dart';

class UserRank {
  final String id;
  final String name;
  final int score;
  final List<String> selectedBadges;
  final int computerArchitecturePoints;
  final int computerNetworkingPoints;
  final int softwareEngineeringPoints;
  final int streakNumber;
  final String? avatarUrl;

  UserRank({
    required this.id,
    required this.name,
    required this.score,
    required this.selectedBadges,
    required this.computerArchitecturePoints,
    required this.computerNetworkingPoints,
    required this.softwareEngineeringPoints,
    required this.streakNumber,
    this.avatarUrl,
  });

  /// The user's current level name based on their score.
  String get levelName => LevelSystem.getLevelName(score);

  /// The user's current level number based on their score.
  int get levelNumber => LevelSystem.getLevelNumber(score);

  factory UserRank.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserRank(
      id: doc.id,
      name: data['displayName'] ?? 'Guest User',
      score: data['score'] ?? 0,
      selectedBadges: List<String>.from(data['selectedBadges'] ?? []),
      computerArchitecturePoints: data['computerArchitecturePoints'] ?? 0,
      computerNetworkingPoints: data['computerNetworkingPoints'] ?? 0,
      softwareEngineeringPoints: data['softwareEngineeringPoints'] ?? 0,
      streakNumber: data['streakNumber'] ?? 0,
      avatarUrl: data['avatarUrl'] as String?,
    );
  }
}
