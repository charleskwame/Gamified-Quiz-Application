class GuestUser {
  final String id;
  final String username;
  final DateTime createdAt;

  GuestUser({
    required this.id,
    required this.username,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GuestUser.fromJson(Map<String, dynamic> json) {
    return GuestUser(
      id: json['id'] as String,
      username: json['username'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class GuestProgress {
  final String challengeId;
  final String category;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final DateTime playedAt;
  final bool isTimed;

  GuestProgress({
    required this.challengeId,
    required this.category,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.playedAt,
    required this.isTimed,
  });

  Map<String, dynamic> toJson() {
    return {
      'challengeId': challengeId,
      'category': category,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'playedAt': playedAt.toIso8601String(),
      'isTimed': isTimed,
    };
  }

  factory GuestProgress.fromJson(Map<String, dynamic> json) {
    return GuestProgress(
      challengeId: json['challengeId'] as String,
      category: json['category'] as String,
      score: json['score'] as int,
      correctAnswers: json['correctAnswers'] as int,
      totalQuestions: json['totalQuestions'] as int,
      playedAt: DateTime.parse(json['playedAt'] as String),
      isTimed: json['isTimed'] as bool? ?? false,
    );
  }
}
