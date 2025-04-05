class VacancyNotification {
  final String restaurantId;
  final String restaurantName;
  final double occupancyPercentage;
  final DateTime timestamp;

  VacancyNotification({
    required this.restaurantId,
    required this.restaurantName,
    required this.occupancyPercentage,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'occupancyPercentage': occupancyPercentage,
      'timestamp': timestamp,
    };
  }

  factory VacancyNotification.fromMap(Map<String, dynamic> map) {
    return VacancyNotification(
      restaurantId: map['restaurantId'] as String,
      restaurantName: map['restaurantName'] as String,
      occupancyPercentage: map['occupancyPercentage'] as double,
      timestamp: map['timestamp'] as DateTime,
    );
  }
} 