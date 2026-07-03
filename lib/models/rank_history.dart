import 'package:cloud_firestore/cloud_firestore.dart';

class RankHistoryEntry {
  final String id;
  final int rank;
  final String category;
  final DateTime timestamp;

  RankHistoryEntry({
    required this.id,
    required this.rank,
    required this.category,
    required this.timestamp,
  });

  factory RankHistoryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RankHistoryEntry(
      id: doc.id,
      rank: data['rank'] ?? 0,
      category: data['category'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rank': rank,
      'category': category,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
