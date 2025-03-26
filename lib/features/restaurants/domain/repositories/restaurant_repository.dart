import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant.dart';
import '../../../../core/services/firestore_service.dart';
import '../../restaurants/data/services/restaurant_service.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  final restaurantService = ref.watch(restaurantServiceProvider);
  return RestaurantRepository(restaurantService);
});

abstract class RestaurantRepository {
  Future<List<Restaurant>> getActiveRestaurants();
  Future<List<Restaurant>> searchRestaurants(String query);
  Future<List<Restaurant>> getRestaurantsByCuisine(String cuisineType);
  Future<List<Restaurant>> getRestaurantsByCapacity(int minCapacity);
  Future<Restaurant?> getRestaurant(String id);
  Future<void> createRestaurant(Restaurant restaurant);
  Future<void> updateRestaurant(Restaurant restaurant);
  Future<void> deleteRestaurant(String id);
  Stream<List<Restaurant>> streamActiveRestaurants();
  Future<Map<String, dynamic>> getRestaurantAnalytics(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  );
}

class RestaurantRepositoryImpl implements RestaurantRepository {
  final RestaurantService _restaurantService;

  RestaurantRepositoryImpl(this._restaurantService);

  @override
  Future<List<Restaurant>> getActiveRestaurants() async {
    return await _restaurantService.getActiveRestaurants();
  }

  @override
  Future<List<Restaurant>> searchRestaurants(String query) async {
    return await _restaurantService.searchRestaurants(query);
  }

  @override
  Future<List<Restaurant>> getRestaurantsByCuisine(String cuisineType) async {
    return await _restaurantService.getRestaurantsByCuisine(cuisineType);
  }

  @override
  Future<List<Restaurant>> getRestaurantsByCapacity(int minCapacity) async {
    return await _restaurantService.getRestaurantsByCapacity(minCapacity);
  }

  @override
  Future<Restaurant?> getRestaurant(String id) async {
    return await _restaurantService.get(id);
  }

  @override
  Future<void> createRestaurant(Restaurant restaurant) async {
    await _restaurantService.create(restaurant.toMap());
  }

  @override
  Future<void> updateRestaurant(Restaurant restaurant) async {
    await _restaurantService.update(restaurant.id, restaurant.toMap());
  }

  @override
  Future<void> deleteRestaurant(String id) async {
    await _restaurantService.delete(id);
  }

  @override
  Stream<List<Restaurant>> streamActiveRestaurants() {
    return _restaurantService.streamActiveRestaurants();
  }

  @override
  Future<Map<String, dynamic>> getRestaurantAnalytics(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // TODO: Implement analytics calculation
    return {
      'totalRevenue': 0.0,
      'totalReservations': 0,
      'averageOccupancy': 0.0,
      'peakHours': [],
      'popularDays': [],
    };
  }
} 