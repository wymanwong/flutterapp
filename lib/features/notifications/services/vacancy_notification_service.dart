import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../restaurant/domain/models/restaurant.dart';
import '../../restaurant/data/repositories/restaurant_repository.dart';
import '../../users/domain/models/vip_profile.dart';
import '../../users/data/repositories/vip_profile_repository.dart';
import 'firebase_messaging_service.dart';

// Remove the import from main.dart
// import '../../../main.dart';

final vacancyNotificationServiceProvider = Provider<VacancyNotificationService>((ref) {
  // Access the providers directly without importing them from main.dart
  final restaurantRepository = ref.read(RestaurantRepository.provider);
  final vipProfileRepository = ref.read(VipProfileRepository.provider);
  final firebaseMessagingService = ref.read(firebaseMessagingServiceProvider);
  return VacancyNotificationService(
    restaurantRepository: restaurantRepository,
    vipProfileRepository: vipProfileRepository,
    messagingService: firebaseMessagingService,
  );
});

class VacancyNotificationService {
  final RestaurantRepository restaurantRepository;
  final VipProfileRepository vipProfileRepository;
  final FirebaseMessagingService messagingService;

  VacancyNotificationService({
    required this.restaurantRepository,
    required this.vipProfileRepository,
    required this.messagingService,
  });

  // Check for low occupancy restaurants and notify users who have low occupancy alerts enabled
  Future<void> checkLowOccupancyRestaurants() async {
    try {
      debugPrint('Checking for low occupancy restaurants...');
      final restaurantsStream = restaurantRepository.getRestaurants();
      final restaurants = await restaurantsStream.first;
      
      // Filter active restaurants with low occupancy
      final lowOccupancyRestaurants = restaurants.where((restaurant) {
        if (!restaurant.isActive) return false;
        
        final occupancyRate = restaurant.capacity > 0 
            ? (restaurant.currentOccupancy / restaurant.capacity) * 100 
            : 0;
            
        return occupancyRate < 50 && restaurant.hasVacancy;
      }).toList();
      
      if (lowOccupancyRestaurants.isEmpty) {
        debugPrint('No low occupancy restaurants found.');
        return;
      }
      
      debugPrint('Found ${lowOccupancyRestaurants.length} low occupancy restaurants.');
      
      // Get all VIP profiles with low occupancy alerts enabled
      final allProfiles = await vipProfileRepository.getAllProfiles();
      final interestedUsers = allProfiles.where(
        (profile) => profile.notificationsEnabled && 
                     profile.notificationPreferences.lowOccupancyAlerts
      ).toList();
      
      if (interestedUsers.isEmpty) {
        debugPrint('No users with low occupancy alerts enabled.');
        return;
      }
      
      debugPrint('Found ${interestedUsers.length} users with low occupancy alerts enabled.');
      
      // For each user, find relevant restaurants based on their preferences
      for (final user in interestedUsers) {
        final relevantRestaurants = _filterRelevantRestaurants(lowOccupancyRestaurants, user);
        
        if (relevantRestaurants.isEmpty) continue;
        
        // Send notification for each relevant restaurant
        for (final restaurant in relevantRestaurants) {
          await _sendVacancyNotification(user, restaurant);
        }
      }
      
    } catch (e) {
      debugPrint('Error checking low occupancy restaurants: $e');
    }
  }
  
  // Test notification for a specific user and restaurant
  Future<void> testVacancyNotification(String userId, Restaurant restaurant) async {
    try {
      debugPrint('Testing vacancy notification for user $userId with restaurant ${restaurant.name}');
      
      // Get the user profile
      final userProfile = await vipProfileRepository.getProfileByUserId(userId);
      
      if (userProfile == null) {
        debugPrint('User profile not found for ID: $userId');
        return;
      }
      
      await _sendVacancyNotification(userProfile, restaurant);
      
    } catch (e) {
      debugPrint('Error sending test vacancy notification: $e');
    }
  }
  
  // Send a notification about a restaurant vacancy
  Future<void> _sendVacancyNotification(VipProfile user, Restaurant restaurant) async {
    try {
      // Get the user's FCM token from preferences (in a real app)
      // For this demo, we'll use a direct notification method
      
      final occupancyRate = restaurant.capacity > 0 
          ? (restaurant.currentOccupancy / restaurant.capacity) * 100 
          : 0;
          
      final notificationData = {
        'title': '${restaurant.name} has available seating!',
        'body': 'Current occupancy is ${occupancyRate.toStringAsFixed(0)}%. Wait time: ${restaurant.waitTime} mins.',
        'data': {
          'restaurantId': restaurant.id,
          'restaurantName': restaurant.name,
          'type': 'vacancy',
          'occupancy': occupancyRate.toString(),
          'waitTime': restaurant.waitTime.toString(),
        }
      };
      
      // In a real app, we'd use FCM to send this to the user's device
      // Firebase.messaging.send(...) 
      
      // For this demo, we'll just log it
      debugPrint('Sending notification to user ${user.userId}: ${notificationData['title']}');
      
      // Save the notification to Firestore for demo purposes
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user.userId,
        'restaurantId': restaurant.id,
        'title': notificationData['title'],
        'body': notificationData['body'],
        'data': notificationData['data'],
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      debugPrint('Error sending vacancy notification: $e');
    }
  }
  
  // Filter restaurants based on user preferences like cuisine, dietary needs, etc.
  List<Restaurant> _filterRelevantRestaurants(List<Restaurant> restaurants, VipProfile user) {
    // Filter based on favorite cuisines if the user has any
    if (user.favoriteCuisines.isNotEmpty) {
      restaurants = restaurants.where(
        (restaurant) => user.favoriteCuisines.contains(restaurant.cuisine)
      ).toList();
    }
    
    // For demo purposes, if no restaurants match the filters, return one random restaurant
    if (restaurants.isEmpty && user.favoriteCuisines.isNotEmpty) {
      debugPrint('No matching restaurants found for user ${user.userId}. Returning a random one.');
      return [restaurants[Random().nextInt(restaurants.length)]];
    }
    
    return restaurants;
  }
} 