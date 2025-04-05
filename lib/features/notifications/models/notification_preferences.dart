import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationPreferences {
  final bool enabled;
  final double lowOccupancyThreshold;
  final bool notifyOnFavorites;
  final bool notifyOnRecommendations;

  NotificationPreferences({
    this.enabled = true,
    this.lowOccupancyThreshold = 70.0,
    this.notifyOnFavorites = true,
    this.notifyOnRecommendations = true,
  });

  static final provider = Provider<NotificationPreferences>((ref) {
    return NotificationPreferences();
  });

  NotificationPreferences copyWith({
    bool? enabled,
    double? lowOccupancyThreshold,
    bool? notifyOnFavorites,
    bool? notifyOnRecommendations,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      lowOccupancyThreshold: lowOccupancyThreshold ?? this.lowOccupancyThreshold,
      notifyOnFavorites: notifyOnFavorites ?? this.notifyOnFavorites,
      notifyOnRecommendations: notifyOnRecommendations ?? this.notifyOnRecommendations,
    );
  }
} 