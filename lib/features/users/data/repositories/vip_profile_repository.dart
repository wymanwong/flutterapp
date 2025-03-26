import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/vip_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VipProfileRepository {
  // Static provider for direct access
  static final provider = Provider<VipProfileRepository>((ref) {
    return VipProfileRepository(firestore: FirebaseFirestore.instance);
  });

  final FirebaseFirestore _firestore;
  final String _collectionPath = 'vip_profiles';

  VipProfileRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  Future<VipProfile?> getProfileByUserId(String userId) async {
    try {
      debugPrint('Getting VIP profile for user ID: $userId');
      
      final querySnapshot = await _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('No VIP profile found for user ID: $userId');
        return null;
      }

      debugPrint('VIP profile found for user ID: $userId');
      return VipProfile.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      debugPrint('Error getting VIP profile: $e');
      rethrow;
    }
  }

  Future<String> createProfile(VipProfile vipProfile) async {
    try {
      debugPrint('Creating VIP profile for user: ${vipProfile.userId}');
      
      // If ID is empty, generate a new document
      final docRef = vipProfile.id.isEmpty 
          ? _firestore.collection(_collectionPath).doc() 
          : _firestore.collection(_collectionPath).doc(vipProfile.id);
          
      // Create data with the profile's toFirestore method
      final profileData = vipProfile.toFirestore();
      
      // Add the generated ID to the data
      final data = {
        ...profileData,
        'id': docRef.id,
      };
      
      // Debug print to verify notification settings are included
      debugPrint('Creating profile with notification preferences: ${profileData['notificationPreferences']}');
      
      await docRef.set(data);
      
      debugPrint('VIP profile created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating VIP profile: $e');
      rethrow;
    }
  }

  Future<void> updateProfile(VipProfile profile) async {
    try {
      print('Updating VIP profile with ID: ${profile.id}');
      print('Updating profile with notification preferences: ${profile.notificationPreferences.toJson()}');
      
      await _firestore
          .collection(_collectionPath)
          .doc(profile.id)
          .update(profile.toFirestore());
      
      print('VIP profile updated successfully with ID: ${profile.id}');
    } catch (e) {
      print('Error updating VIP profile: $e');
      throw e;
    }
  }

  Future<void> updateNotificationPreferences(String profileId, NotificationPreferences preferences) async {
    try {
      print('Updating notification preferences for profile ID: $profileId');
      print('New notification preferences: ${preferences.toJson()}');
      
      await _firestore
          .collection(_collectionPath)
          .doc(profileId)
          .update({
            'notificationPreferences': preferences.toMap(),
            'updatedAt': Timestamp.now(),
          });
      
      print('Notification preferences updated successfully for profile ID: $profileId');
    } catch (e) {
      print('Error updating notification preferences: $e');
      throw e;
    }
  }

  Future<void> toggleNotifications(String profileId, bool enabled) async {
    try {
      print('Toggling notifications for profile ID: $profileId to $enabled');
      
      await _firestore
          .collection(_collectionPath)
          .doc(profileId)
          .update({
            'notificationsEnabled': enabled,
            'updatedAt': Timestamp.now(),
          });
      
      print('Notification toggle updated successfully for profile ID: $profileId');
    } catch (e) {
      print('Error toggling notifications: $e');
      throw e;
    }
  }

  Future<void> addFavoriteRestaurant(String profileId, String restaurantId) async {
    try {
      debugPrint('Adding restaurant $restaurantId to favorites for profile $profileId');
      
      await _firestore.collection(_collectionPath).doc(profileId).update({
        'favoriteRestaurants': FieldValue.arrayUnion([restaurantId]),
      });
      
      debugPrint('Restaurant added to favorites successfully');
    } catch (e) {
      debugPrint('Error adding restaurant to favorites: $e');
      rethrow;
    }
  }

  Future<void> removeFavoriteRestaurant(String profileId, String restaurantId) async {
    try {
      debugPrint('Removing restaurant $restaurantId from favorites for profile $profileId');
      
      await _firestore.collection(_collectionPath).doc(profileId).update({
        'favoriteRestaurants': FieldValue.arrayRemove([restaurantId]),
      });
      
      debugPrint('Restaurant removed from favorites successfully');
    } catch (e) {
      debugPrint('Error removing restaurant from favorites: $e');
      rethrow;
    }
  }

  Future<void> rateRestaurant(String profileId, String restaurantId, double rating) async {
    try {
      debugPrint('Rating restaurant $restaurantId with $rating stars for profile $profileId');
      
      await _firestore.collection(_collectionPath).doc(profileId).update({
        'restaurantRatings.$restaurantId': rating,
      });
      
      debugPrint('Restaurant rated successfully');
    } catch (e) {
      debugPrint('Error rating restaurant: $e');
      rethrow;
    }
  }

  Future<void> updateDietaryPreferences(String profileId, List<String> preferences) async {
    try {
      debugPrint('Updating dietary preferences for profile $profileId');
      
      await _firestore.collection(_collectionPath).doc(profileId).update({
        'dietaryPreferences': preferences,
      });
      
      debugPrint('Dietary preferences updated successfully');
    } catch (e) {
      debugPrint('Error updating dietary preferences: $e');
      rethrow;
    }
  }

  Future<List<VipProfile>> getProfilesWithLowOccupancyAlerts() async {
    try {
      debugPrint('Getting profiles with low occupancy alerts enabled');
      
      final querySnapshot = await _firestore
          .collection(_collectionPath)
          .where('notificationPreferences.lowOccupancyAlerts', isEqualTo: true)
          .get();
          
      debugPrint('Found ${querySnapshot.docs.length} profiles with low occupancy alerts');
      
      return querySnapshot.docs
          .map((doc) => VipProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting profiles with low occupancy alerts: $e');
      rethrow;
    }
  }

  // Get all profiles
  Future<List<VipProfile>> getAllProfiles() async {
    try {
      print('Getting all VIP profiles');
      final snapshot = await _firestore.collection('vip_profiles').get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return VipProfile.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error getting all VIP profiles: $e');
      return [];
    }
  }
} 