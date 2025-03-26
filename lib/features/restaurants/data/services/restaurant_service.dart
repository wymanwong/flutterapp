import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_availability_system/core/services/firestore_service.dart';
import 'package:restaurant_availability_system/features/restaurants/domain/models/restaurant.dart';

class RestaurantService extends FirestoreService<Restaurant> {
  RestaurantService() : super('restaurants');

  @override
  Restaurant fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Restaurant.fromFirestore(doc);
  }

  @override
  Map<String, dynamic> toFirestore(Restaurant restaurant) {
    return restaurant.toFirestore();
  }

  Stream<List<Restaurant>> getActiveRestaurants() {
    return streamQuery(
      where('isActive', isEqualTo: true),
      orderBy: 'name',
    );
  }

  Stream<List<Restaurant>> getRestaurantsByOwner(String ownerId) {
    return streamQuery(
      where('ownerId', isEqualTo: ownerId),
      orderBy: 'name',
    );
  }

  Future<List<Restaurant>> searchRestaurants(String query) async {
    query = query.toLowerCase();
    return this.query(
      where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z'),
      limit: 20,
    );
  }

  Future<List<Restaurant>> getRestaurantsByCuisine(String cuisine) async {
    return this.query(
      where('cuisineTypes', arrayContains: cuisine),
      orderBy: 'name',
    );
  }

  Future<List<Restaurant>> getRestaurantsByCapacity(int minCapacity) async {
    return this.query(
      where('capacity', isGreaterThanOrEqualTo: minCapacity),
      orderBy: 'capacity',
    );
  }

  Future<void> deactivateRestaurant(String id) async {
    await update(id, (await get(id))!.copyWith(isActive: false));
  }

  Future<Map<String, dynamic>> getRestaurantAnalytics(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // TODO: Implement analytics
    return {
      'totalBookings': 0,
      'averageRating': 0.0,
      'revenue': 0.0,
      'popularDishes': [],
    };
  }
} 