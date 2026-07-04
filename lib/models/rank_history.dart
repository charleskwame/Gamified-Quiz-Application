import 'package:cloud_firestore/cloud_firestore.dart';

class RankHistoryEntry {
  final String id;
  final String rank;
  final String category;
  final double percentage;
  final DateTime timestamp;

  RankHistoryEntry({
    required this.id,
    required this.rank,
    required this.category,
    required this.percentage,
    required this.timestamp,
  });

  factory RankHistoryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RankHistoryEntry(
      id: doc.id,
      rank: data['rank'] ?? 'E',
      category: data['category'] ?? '',
      percentage: (data['percentage'] ?? 0.0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rank': rank,
      'category': category,
      'percentage': percentage,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
