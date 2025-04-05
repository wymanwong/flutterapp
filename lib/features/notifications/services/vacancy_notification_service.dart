import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../restaurant/domain/models/restaurant.dart';
import '../../restaurant/domain/utils/restaurant_utils.dart';
import '../../restaurant/data/repositories/restaurant_repository.dart';
import '../../users/domain/models/vip_profile.dart';
import '../../users/data/repositories/vip_profile_repository.dart';
import 'firebase_messaging_service.dart';
import '../models/vacancy_notification.dart';
import '../repositories/notification_repository.dart';

// Remove the import from main.dart
// import '../../../main.dart';

final vacancyNotificationServiceProvider = Provider<VacancyNotificationService>((ref) {
  // Access the providers directly without importing them from main.dart
  final restaurantRepository = ref.read(RestaurantRepository.provider);
  final vipProfileRepository = ref.read(VipProfileRepository.provider);
  final firebaseMessagingService = ref.read(firebaseMessagingServiceProvider);
  final notificationRepository = ref.read(NotificationRepository.provider);
  return VacancyNotificationService(
    restaurantRepository: restaurantRepository,
    vipProfileRepository: vipProfileRepository,
    messagingService: firebaseMessagingService,
    notificationRepository: notificationRepository,
  );
});

class VacancyNotificationService {
  final RestaurantRepository restaurantRepository;
  final VipProfileRepository vipProfileRepository;
  final FirebaseMessagingService messagingService;
  final NotificationRepository notificationRepository;
  final Set<String> _notifiedRestaurants = {};

  VacancyNotificationService({
    required this.restaurantRepository,
    required this.vipProfileRepository,
    required this.messagingService,
    required this.notificationRepository,
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
        
        final occupancyRate = RestaurantUtils.calculateOccupancyPercentage(restaurant);
        return occupancyRate < 50 && RestaurantUtils.hasVacancy(restaurant);
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
          await checkRestaurantOccupancy(restaurant);
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
      
      await _sendVacancyNotification(restaurant, RestaurantUtils.calculateOccupancyPercentage(restaurant));
      
    } catch (e) {
      debugPrint('Error sending test vacancy notification: $e');
    }
  }
  
  // Send a notification about a restaurant vacancy
  Future<void> _sendVacancyNotification(Restaurant restaurant, double occupancyPercentage) async {
    try {
      final notification = VacancyNotification(
        restaurantId: restaurant.id,
        restaurantName: restaurant.name,
        occupancyPercentage: occupancyPercentage,
        timestamp: DateTime.now(),
      );

      await notificationRepository.addNotification(notification);
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

  Future<void> checkRestaurantOccupancy(Restaurant restaurant) async {
    try {
      final occupancyPercentage = RestaurantUtils.calculateOccupancyPercentage(restaurant);
      final isBelowThreshold = occupancyPercentage <= 50;

      if (isBelowThreshold && !_notifiedRestaurants.contains(restaurant.id)) {
        await _sendVacancyNotification(restaurant, occupancyPercentage);
        _notifiedRestaurants.add(restaurant.id);
      }
    } catch (e) {
      debugPrint('Error checking restaurant occupancy: $e');
    }
  }
} 