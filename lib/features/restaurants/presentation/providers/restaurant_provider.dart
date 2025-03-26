import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_availability_system/features/restaurants/data/services/restaurant_service.dart';
import 'package:restaurant_availability_system/features/restaurants/domain/models/restaurant.dart';
import '../../domain/repositories/restaurant_repository.dart';

final restaurantServiceProvider = Provider<RestaurantService>((ref) {
  return RestaurantService();
});

final restaurantsProvider =
    StateNotifierProvider<RestaurantsNotifier, AsyncValue<List<Restaurant>>>(
  (ref) => RestaurantsNotifier(ref.read(restaurantRepositoryProvider)),
);

final activeRestaurantsProvider = StreamProvider<List<Restaurant>>((ref) {
  final restaurantService = ref.watch(restaurantServiceProvider);
  return restaurantService.getActiveRestaurants();
});

final restaurantStreamProvider = StreamProvider.family<Restaurant?, String>((ref, id) {
  final restaurantService = ref.watch(restaurantServiceProvider);
  return restaurantService.streamOne(id);
});

final restaurantsByOwnerProvider = StreamProvider.family<List<Restaurant>, String>((ref, ownerId) {
  final restaurantService = ref.watch(restaurantServiceProvider);
  return restaurantService.getRestaurantsByOwner(ownerId);
});

final restaurantSearchProvider = FutureProvider.family<List<Restaurant>, String>((ref, query) async {
  final restaurantService = ref.watch(restaurantServiceProvider);
  return restaurantService.searchRestaurants(query);
});

final restaurantsByCuisineProvider = FutureProvider.family<List<Restaurant>, String>((ref, cuisine) async {
  final restaurantService = ref.watch(restaurantServiceProvider);
  return restaurantService.getRestaurantsByCuisine(cuisine);
});

final restaurantsByCapacityProvider = FutureProvider.family<List<Restaurant>, int>((ref, capacity) async {
  final restaurantService = ref.watch(restaurantServiceProvider);
  return restaurantService.getRestaurantsByCapacity(capacity);
});

final restaurantAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, ({String id, DateTime start, DateTime end})>((ref, params) async {
  final restaurantService = ref.watch(restaurantServiceProvider);
  return restaurantService.getRestaurantAnalytics(params.id, params.start, params.end);
});

class RestaurantsNotifier extends StateNotifier<AsyncValue<List<Restaurant>>> {
  final RestaurantRepository _repository;

  RestaurantsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadRestaurants();
  }

  Future<void> loadRestaurants() async {
    try {
      state = const AsyncValue.loading();
      final restaurants = await _repository.getActiveRestaurants();
      state = AsyncValue.data(restaurants);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createRestaurant(Restaurant restaurant) async {
    try {
      await _repository.createRestaurant(restaurant);
      loadRestaurants();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateRestaurant(Restaurant restaurant) async {
    try {
      await _repository.updateRestaurant(restaurant);
      loadRestaurants();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteRestaurant(String id) async {
    try {
      await _repository.deleteRestaurant(id);
      loadRestaurants();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<List<Restaurant>> searchRestaurants(String query) async {
    try {
      return await _repository.searchRestaurants(query);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<List<Restaurant>> getRestaurantsByCuisine(String cuisineType) async {
    try {
      return await _repository.getRestaurantsByCuisine(cuisineType);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<List<Restaurant>> getRestaurantsByCapacity(int minCapacity) async {
    try {
      return await _repository.getRestaurantsByCapacity(minCapacity);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Stream<List<Restaurant>> streamActiveRestaurants() {
    return _repository.streamActiveRestaurants();
  }

  Future<Map<String, dynamic>> getRestaurantAnalytics(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _repository.getRestaurantAnalytics(
        restaurantId,
        startDate,
        endDate,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
} 