import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../users/domain/models/vip_profile.dart';
import '../../restaurant/domain/models/restaurant.dart';
import '../../restaurant/data/services/recommendation_service.dart';
import '../../users/data/repositories/vip_profile_repository.dart';
import '../../reservations/domain/models/reservation.dart';
import 'firebase_messaging_service.dart';
import '../../restaurants/data/services/location_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final vipProfileRepository = ref.read(vipProfileRepositoryProvider);
  final recommendationService = ref.read(recommendationServiceProvider);
  final firebaseMessagingService = ref.read(firebaseMessagingServiceProvider);
  final locationService = ref.read(locationServiceProvider);
  return NotificationService(
    vipProfileRepository, 
    recommendationService,
    firebaseMessagingService,
    locationService
  );
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final VipProfileRepository _vipProfileRepository;
  final RecommendationService _recommendationService;
  final FirebaseMessagingService _firebaseMessagingService;
  final LocationService _locationService;
  
  NotificationService(
    this._vipProfileRepository, 
    this._recommendationService, 
    this._firebaseMessagingService,
    this._locationService
  ) {
    _initializeNotifications();
  }
  
  Future<void> _initializeNotifications() async {
    tz_data.initializeTimeZones();
    
    // Android initialization settings
    const androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const iosInitializationSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // Initialization settings
    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );
    
    // Initialize
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Initialize Firebase Messaging Service
    await _firebaseMessagingService.initialize();
    
    debugPrint('Notification service initialized');
  }
  
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    debugPrint('Notification tapped: ${notificationResponse.payload}');
    // Handle navigation based on payload
  }
  
  // Subscribe user to restaurant-specific notifications
  Future<void> subscribeToRestaurant(String restaurantId) async {
    await _firebaseMessagingService.subscribeToTopic('restaurant_$restaurantId');
  }
  
  // Unsubscribe from restaurant-specific notifications
  Future<void> unsubscribeFromRestaurant(String restaurantId) async {
    await _firebaseMessagingService.unsubscribeFromTopic('restaurant_$restaurantId');
  }
  
  // Subscribe to nearby restaurant notifications
  Future<void> subscribeToNearbyRestaurants() async {
    await _firebaseMessagingService.subscribeToTopic('nearby_restaurants');
  }
  
  // Send notifications for low occupancy restaurants
  Future<void> sendLowOccupancyNotifications() async {
    try {
      debugPrint('Processing low occupancy notifications');
      
      // Get profiles with low occupancy alerts enabled
      final profiles = await _vipProfileRepository.getProfilesWithLowOccupancyAlerts();
      
      if (profiles.isEmpty) {
        debugPrint('No users have low occupancy alerts enabled');
        return;
      }
      
      for (final profile in profiles) {
        // Skip if notifications are disabled
        if (!profile.notificationsEnabled) continue;
        
        // Skip if low occupancy alerts are disabled
        if (!profile.notificationPreferences.lowOccupancyAlerts) continue;
        
        // Get restaurants with low occupancy
        final lowOccupancyRestaurants = await _recommendationService.getLowOccupancyRestaurants(
          profile.notificationPreferences.lowOccupancyThreshold
        );
        
        if (lowOccupancyRestaurants.isEmpty) {
          debugPrint('No low occupancy restaurants found for threshold ${profile.notificationPreferences.lowOccupancyThreshold}%');
          continue;
        }
        
        // Filter based on user cuisine preferences if available
        List<Restaurant> filteredRestaurants = lowOccupancyRestaurants;
        if (profile.favoriteCuisines.isNotEmpty) {
          filteredRestaurants = lowOccupancyRestaurants.where(
            (r) => profile.favoriteCuisines.contains(r.cuisine)
          ).toList();
          
          // If no matches, use original list
          if (filteredRestaurants.isEmpty) {
            filteredRestaurants = lowOccupancyRestaurants;
          }
        }
        
        // Send notification
        await _sendLowOccupancyNotification(profile, filteredRestaurants);
      }
    } catch (e) {
      debugPrint('Error sending low occupancy notifications: $e');
    }
  }
  
  Future<void> _sendLowOccupancyNotification(VipProfile profile, List<Restaurant> restaurants) async {
    // Limit to 3 restaurants max for the notification
    final limitedRestaurants = restaurants.take(3).toList();
    
    String notificationTitle = 'Restaurant Availability Alert';
    String notificationBody;
    
    if (limitedRestaurants.length == 1) {
      notificationBody = '${limitedRestaurants[0].name} currently has low occupancy!';
    } else {
      final restaurantNames = limitedRestaurants.map((r) => r.name).join(', ');
      notificationBody = 'These restaurants currently have availability: $restaurantNames';
    }
    
    // Restaurant IDs for payload
    final restaurantIds = limitedRestaurants.map((r) => r.id).join(',');
    
    // Build notification details
    final androidDetails = const AndroidNotificationDetails(
      'low_occupancy_channel',
      'Low Occupancy Alerts',
      channelDescription: 'Notifications for restaurant availability',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Send notification
    await _flutterLocalNotificationsPlugin.show(
      profile.userId.hashCode, // Using userId hash as notification ID
      notificationTitle,
      notificationBody,
      notificationDetails,
      payload: restaurantIds,
    );
  }
  
  // Send notification for nearby restaurants
  Future<void> sendNearbyRestaurantsNotification(String userId, List<Restaurant> restaurants) async {
    if (restaurants.isEmpty) return;
    
    // Limit to 3 restaurants max for the notification
    final limitedRestaurants = restaurants.take(3).toList();
    
    String notificationTitle = 'Nearby Restaurants';
    String notificationBody;
    
    if (limitedRestaurants.length == 1) {
      notificationBody = '${limitedRestaurants[0].name} is near you!';
    } else {
      final restaurantNames = limitedRestaurants.map((r) => r.name).join(', ');
      notificationBody = 'These restaurants are near you: $restaurantNames';
    }
    
    // Restaurant IDs for payload
    final restaurantIds = limitedRestaurants.map((r) => r.id).join(',');
    
    // Build notification details
    final androidDetails = const AndroidNotificationDetails(
      'nearby_restaurants_channel',
      'Nearby Restaurants',
      channelDescription: 'Notifications for nearby restaurants',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Send notification
    await _flutterLocalNotificationsPlugin.show(
      'nearby_${userId}'.hashCode, // Using prefix+userId hash as notification ID
      notificationTitle,
      notificationBody,
      notificationDetails,
      payload: restaurantIds,
    );
  }
  
  // Send notification for new review
  Future<void> sendNewReviewNotification(String restaurantOwnerId, String restaurantName, double rating) async {
    String notificationTitle = 'New Review';
    String notificationBody = 'Your restaurant $restaurantName received a new ${rating.toStringAsFixed(1)}-star review';
    
    // Build notification details
    final androidDetails = const AndroidNotificationDetails(
      'reviews_channel',
      'Review Notifications',
      channelDescription: 'Notifications for restaurant reviews',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Send notification
    await _flutterLocalNotificationsPlugin.show(
      'review_${restaurantOwnerId}_${DateTime.now().millisecondsSinceEpoch}'.hashCode,
      notificationTitle,
      notificationBody,
      notificationDetails,
    );
  }
  
  // Check and notify about nearby restaurants
  Future<void> checkAndNotifyNearbyRestaurants(String userId, List<Restaurant> allRestaurants) async {
    try {
      // Find restaurants within 2km radius
      final nearbyRestaurants = await _locationService.findNearbyRestaurants(allRestaurants, 2.0);
      
      if (nearbyRestaurants.isNotEmpty) {
        await sendNearbyRestaurantsNotification(userId, nearbyRestaurants);
      }
    } catch (e) {
      debugPrint('Error sending nearby restaurants notification: $e');
    }
  }
} 