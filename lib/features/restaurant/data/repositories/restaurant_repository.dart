import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/restaurant.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepository();
});

class RestaurantRepository {
  // Static provider for direct access
  static final provider = Provider<RestaurantRepository>((ref) {
    return RestaurantRepository();
  });

  final FirebaseFirestore _firestore;
  final String _collectionPath = 'restaurants';
  final String _favoritesCollection = 'favorite_restaurants';

  RestaurantRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get the total count of restaurants
  Future<int> getRestaurantsCount() async {
    try {
      developer.log('Getting restaurant count');
      final snapshot = await _firestore.collection(_collectionPath).count().get();
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
    return _firestore.collection(_collectionPath).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Restaurant.fromFirestore(doc);
      }).toList();
    });
  }

  // Get a single restaurant by ID
  Future<Restaurant?> getRestaurantById(String id) async {
    try {
      developer.log('Getting restaurant with ID: $id');
      final documentSnapshot = await _firestore.collection(_collectionPath).doc(id).get();
      if (!documentSnapshot.exists) {
        developer.log('Restaurant not found with ID: $id');
        return null;
      }
      
      developer.log('Restaurant found: ${documentSnapshot.id}');
      return Restaurant.fromFirestore(documentSnapshot);
    } catch (e, stackTrace) {
      developer.log('Error getting restaurant by ID: $id',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // Create a new restaurant
  Future<String?> createRestaurant(Restaurant restaurant) async {
    try {
      developer.log('Creating restaurant with data: ${restaurant.toFirestore()}');
      final docRef = _firestore.collection(_collectionPath).doc();
      
      final restaurantWithId = restaurant.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await docRef.set(restaurantWithId.toFirestore());
      developer.log('Restaurant created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      developer.log('Error creating restaurant',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Update an existing restaurant
  Future<void> updateRestaurant(Restaurant restaurant) async {
    try {
      developer.log('Updating restaurant with data: ${restaurant.toFirestore()}');
      
      if (restaurant.id.isEmpty) {
        throw Exception('Restaurant ID cannot be empty');
      }
      
      final docRef = _firestore.collection(_collectionPath).doc(restaurant.id);
      await docRef.update(restaurant.toFirestore());
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
      await _firestore.collection(_collectionPath).doc(id).delete();
      developer.log('Restaurant deleted successfully');
    } catch (e, stackTrace) {
      developer.log('Error deleting restaurant',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<List<Restaurant>> watchRestaurants() {
    try {
      developer.log('Starting restaurant watch stream');
      
      return _firestore
          .collection(_collectionPath)
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
        final restaurants = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Ensure ID is included
          developer.log('Retrieved restaurant document: ${doc.id}');
          return Restaurant.fromJson(data);
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
      
      final doc = await _firestore.collection(_collectionPath).doc(id).get();
      
      if (!doc.exists) {
        developer.log('Restaurant not found');
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id; // Ensure ID is included
      
      developer.log('Restaurant fetched successfully');
      return Restaurant.fromJson(data);
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching restaurant',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to fetch restaurant: $e');
    }
  }

  Stream<List<Restaurant>> searchRestaurants(String query) {
    debugPrint('Searching restaurants with query: $query');
    return _firestore
        .collection(_collectionPath)
        .orderBy('name')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .snapshots()
        .map((snapshot) {
          debugPrint('Found ${snapshot.docs.length} restaurants matching query');
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Restaurant.fromJson(data);
          }).toList();
        });
  }

  Stream<List<Restaurant>> filterRestaurants({
    bool? isActive,
    List<String>? cuisine,
    int? minCapacity,
    int? maxCapacity,
  }) {
    debugPrint('Filtering restaurants with: isActive=$isActive, cuisine=$cuisine, minCapacity=$minCapacity, maxCapacity=$maxCapacity');
    var query = _firestore.collection(_collectionPath).orderBy('name');

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
        return Restaurant.fromJson(data);
      }).toList();
    });
  }

  // Get favorite restaurant IDs for a user
  Stream<List<String>> getFavoriteRestaurantIds(String userId) {
    developer.log('Getting favorite restaurants for user: $userId');
    return _firestore
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
      final docRef = _firestore.collection(_favoritesCollection).doc(userId);
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
      final doc = await _firestore.collection(_favoritesCollection).doc(userId).get();
      
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
} 