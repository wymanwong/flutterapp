import '../../../restaurant/domain/utils/restaurant_utils.dart';

Widget _buildRestaurantCard(Restaurant restaurant) {
  return Card(
    child: Column(
      children: [
        // ... existing code ...
        Text(
          'Occupancy: ${RestaurantUtils.formatOccupancyPercentage(restaurant)}',
          style: TextStyle(fontSize: 14),
        ),
        Text(
          RestaurantUtils.getOccupancyStatusText(restaurant),
          style: TextStyle(
            color: RestaurantUtils.hasVacancy(restaurant) ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        // ... existing code ...
      ],
    ),
  );
} 