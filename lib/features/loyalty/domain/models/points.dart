class Points {
  final String userId;
  final int balance;
  final DateTime lastUpdated;

  Points({
    required this.userId,
    required this.balance,
    required this.lastUpdated,
  });

  factory Points.fromFirestore(Map<String, dynamic> data) {
    return Points(
      userId: data['userId'] as String,
      balance: data['balance'] as int,
      lastUpdated: (data['lastUpdated'] as DateTime).toLocal(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'balance': balance,
      'lastUpdated': lastUpdated,
    };
  }

  Points copyWith({
    String? userId,
    int? balance,
    DateTime? lastUpdated,
  }) {
    return Points(
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
} 