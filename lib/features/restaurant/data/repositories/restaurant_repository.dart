import 'dart:developer' as developer;
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/restaurant.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepository(
    firestore: FirebaseFirestore.instance,
  );
});

// Provider family to watch a single restaurant
final restaurantStreamProvider = StreamProvider.family<Restaurant?, String>((ref, restaurantId) {
  final repository = ref.watch(restaurantRepositoryProvider);
  return repository.watchRestaurant(restaurantId);
});

class RestaurantRepository {
  final FirebaseFirestore firestore;
  final String _collectionPath = 'restaurants';
  final String _favoritesCollection = 'favorite_restaurants';

  RestaurantRepository({required this.firestore});

  // Static provider for direct access
  static final provider = Provider<RestaurantRepository>((ref) {
    return RestaurantRepository(
      firestore: FirebaseFirestore.instance,
    );
  });

  // Get the total count of restaurants
  Future<int> getRestaurantsCount() async {
    try {
      developer.log('Getting restaurant count');
      final snapshot = await firestore.collection(_collectionPath).count().get();
      developer.log('Restaurant count: ${snapshot.count}');
      return snapshot.count ?? 0; // Return 0 if count is null
    } catch (e, stackTrace) {
      developer.log(
        'Error getting restaurant count',
        error: e,
        stackTrace: stackTrace,
      );
      return 0;
    }
  }

  // Get a stream of all restaurants
  Stream<List<Restaurant>> getRestaurants() {
    developer.log('Getting stream of restaurants');
    return firestore.collection(_collectionPath).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Restaurant.fromMap(data);
      }).toList();
    });
  }

  // Get a single restaurant by ID
  Future<Restaurant?> getRestaurantById(String id) async {
    try {
      developer.log('Getting restaurant with ID: $id');
      final documentSnapshot = await firestore.collection(_collectionPath).doc(id).get();
      if (!documentSnapshot.exists) {
        developer.log('Restaurant not found with ID: $id');
        return null;
      }
      
      developer.log('Restaurant found: ${documentSnapshot.id}');
      final data = documentSnapshot.data()!;
      data['id'] = documentSnapshot.id;
      return Restaurant.fromMap(data);
    } catch (e, stackTrace) {
      developer.log('Error getting restaurant by ID: $id',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // Create a new restaurant
  Future<Restaurant> createRestaurant(Restaurant restaurant) async {
    try {
      developer.log('Creating restaurant with data: ${restaurant.toMap()}');
      
      final docRef = firestore.collection(_collectionPath).doc();
      final restaurantWithId = restaurant.copyWith(id: docRef.id);
      
      await docRef.set(restaurantWithId.toMap());
      
      return restaurantWithId;
    } catch (e, stackTrace) {
      developer.log('Error creating restaurant',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Update an existing restaurant
  Future<void> updateRestaurant(Restaurant restaurant) async {
    try {
      developer.log('Updating restaurant with data: ${restaurant.toMap()}');
      
      if (restaurant.id.isEmpty) {
        throw Exception('Restaurant ID cannot be empty');
      }
      
      final docRef = firestore.collection(_collectionPath).doc(restaurant.id);
      await docRef.update(restaurant.toMap());
      developer.log('Restaurant updated successfully');
    } catch (e, stackTrace) {
      developer.log('Error updating restaurant',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Delete a restaurant
  Future<void> deleteRestaurant(String id) async {
    try {
      developer.log('Deleting restaurant with ID: $id');
      await firestore.collection(_collectionPath).doc(id).delete();
      developer.log('Restaurant deleted successfully');
    } catch (e, stackTrace) {
      developer.log('Error deleting restaurant',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Get a stream for a single restaurant by ID
  Stream<Restaurant?> watchRestaurant(String id) {
    developer.log('Watching restaurant with ID: $id');
    return firestore
        .collection(_collectionPath)
        .doc(id)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        developer.log('Watched restaurant not found: $id');
        return null;
      }
      final data = snapshot.data();
      if (data == null) {
        developer.log('Watched restaurant data is null: $id');
        return null;
      }
      data['id'] = snapshot.id; // Ensure ID is included
      developer.log('Received update for watched restaurant: $id');
      return Restaurant.fromMap(data);
    }).handleError((error, stackTrace) {
      developer.log('Error watching restaurant: $id', error: error, stackTrace: stackTrace);
      // Optionally return null or rethrow, depending on desired error handling
      return null; 
    });
  }

  Stream<List<Restaurant>> watchRestaurants() {
    try {
      developer.log('Starting restaurant watch stream');
      
      return firestore
          .collection(_collectionPath)
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
        final restaurants = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Ensure ID is included
          developer.log('Retrieved restaurant document: ${doc.id}');
          return Restaurant.fromMap(data);
        }).toList();
        
        developer.log('Retrieved ${restaurants.length} restaurants from Firestore');
        return restaurants;
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error watching restaurants',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to watch restaurants: $e');
    }
  }

  Future<Restaurant?> getRestaurant(String id) async {
    try {
      developer.log('Fetching restaurant with ID: $id');
      
      final doc = await firestore.collection(_collectionPath).doc(id).get();
      
      if (!doc.exists) {
        developer.log('Restaurant not found');
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id; // Ensure ID is included
      
      developer.log('Restaurant fetched successfully');
      return Restaurant.fromMap(data);
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching restaurant',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to fetch restaurant: $e');
    }
  }

  Future<List<Restaurant>> searchRestaurants(String query) async {
    try {
      final querySnapshot = await firestore
          .collection(_collectionPath)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Restaurant.fromMap(data);
      }).toList();
    } catch (e) {
      developer.log('Error searching restaurants: $e');
      return [];
    }
  }

  Stream<List<Restaurant>> filterRestaurants({
    bool? isActive,
    List<String>? cuisine,
    int? minCapacity,
    int? maxCapacity,
  }) {
    debugPrint('Filtering restaurants with: isActive=$isActive, cuisine=$cuisine, minCapacity=$minCapacity, maxCapacity=$maxCapacity');
    var query = firestore.collection(_collectionPath).orderBy('name');

    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }

    if (cuisine != null && cuisine.isNotEmpty) {
      query = query.where('cuisine', arrayContainsAny: cuisine);
    }

    if (minCapacity != null) {
      query = query.where('capacity', isGreaterThanOrEqualTo: minCapacity);
    }

    if (maxCapacity != null) {
      query = query.where('capacity', isLessThanOrEqualTo: maxCapacity);
    }

    return query.snapshots().map((snapshot) {
      debugPrint('Found ${snapshot.docs.length} restaurants after filtering');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Restaurant.fromMap(data);
      }).toList();
    });
  }

  // Get favorite restaurant IDs for a user
  Stream<List<String>> getFavoriteRestaurantIds(String userId) {
    developer.log('Getting favorite restaurants for user: $userId');
    return firestore
        .collection(_favoritesCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return [];
          final data = doc.data() as Map<String, dynamic>;
          return List<String>.from(data['restaurantIds'] ?? []);
        });
  }

  // Toggle favorite status for a restaurant
  Future<void> toggleFavoriteRestaurant(String userId, String restaurantId) async {
    try {
      developer.log('Toggling favorite status for restaurant: $restaurantId, user: $userId');
      final docRef = firestore.collection(_favoritesCollection).doc(userId);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'restaurantIds': [restaurantId],
          'updatedAt': FieldValue.serverTimestamp(),
        });
        developer.log('Created new favorites document with restaurant: $restaurantId');
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final favorites = List<String>.from(data['restaurantIds'] ?? []);

      if (favorites.contains(restaurantId)) {
        favorites.remove(restaurantId);
        developer.log('Removed restaurant from favorites: $restaurantId');
      } else {
        favorites.add(restaurantId);
        developer.log('Added restaurant to favorites: $restaurantId');
      }

      await docRef.update({
        'restaurantIds': favorites,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error toggling favorite restaurant',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Check if a restaurant is a favorite
  Future<bool> isFavoriteRestaurant(String userId, String restaurantId) async {
    try {
      developer.log('Checking if restaurant is favorite: $restaurantId for user: $userId');
      final doc = await firestore.collection(_favoritesCollection).doc(userId).get();
      
      if (!doc.exists) return false;
      
      final data = doc.data() as Map<String, dynamic>;
      final favorites = List<String>.from(data['restaurantIds'] ?? []);
      return favorites.contains(restaurantId);
    } catch (e, stackTrace) {
      developer.log(
        'Error checking favorite restaurant status',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<List<Restaurant>> getRestaurantsByCuisine(String cuisine) async {
    try {
      final querySnapshot = await firestore
          .collection(_collectionPath)
          .where('cuisine', isEqualTo: cuisine)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Restaurant.fromMap(data);
      }).toList();
    } catch (e) {
      developer.log('Error getting restaurants by cuisine: $e');
      return [];
    }
  }

  Future<List<Restaurant>> getActiveRestaurants() async {
    try {
      final querySnapshot = await firestore
          .collection(_collectionPath)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Restaurant.fromMap(data);
      }).toList();
    } catch (e) {
      developer.log('Error getting active restaurants: $e');
      return [];
    }
  }
} 