import '../models/restaurant.dart';

class RestaurantUtils {
  /// Calculates the occupancy percentage for a restaurant
  static double calculateOccupancyPercentage(Restaurant restaurant) {
    if (restaurant.capacity <= 0) return 0.0;
    final currentOccupancy = restaurant.currentOccupancy ?? 0;
    return (currentOccupancy / restaurant.capacity * 100).clamp(0.0, 100.0);
  }

  /// Formats the occupancy percentage as a string with one decimal place
  static String formatOccupancyPercentage(Restaurant restaurant) {
    return '${calculateOccupancyPercentage(restaurant).toStringAsFixed(1)}%';
  }

  /// Determines if a restaurant has vacancy available
  static bool hasVacancy(Restaurant restaurant) {
    return calculateOccupancyPercentage(restaurant) < 100.0;
  }

  /// Gets the occupancy status text
  static String getOccupancyStatusText(Restaurant restaurant) {
    final percentage = calculateOccupancyPercentage(restaurant);
    if (percentage >= 90) return 'Full';
    if (percentage >= 70) return 'Busy';
    if (percentage >= 30) return 'Moderate';
    return 'Available';
  }
} 