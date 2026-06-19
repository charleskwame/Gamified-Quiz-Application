import 'package:cloud_firestore/cloud_firestore.dart';

class UserRank {
  final String id;
  final String name;
  final int score;

  UserRank({
    required this.id,
    required this.name,
    required this.score,
  });

  factory UserRank.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserRank(
      id: doc.id,
      name: data['displayName'] ?? 'Guest User',
      score: data['score'] ?? 0,
    );
  }
}
