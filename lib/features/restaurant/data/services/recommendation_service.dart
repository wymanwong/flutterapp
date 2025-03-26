import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../users/domain/models/vip_profile.dart';
import '../../domain/models/restaurant.dart';
import '../repositories/restaurant_repository.dart';
import 'package:flutter/material.dart';

// Provider for RecommendationService is now in main.dart

class RecommendationService {
  final RestaurantRepository _restaurantRepository;

  RecommendationService(this._restaurantRepository);

  // Get recommendations based on cuisine preferences
  Future<List<Restaurant>> getRecommendationsByCuisine(
      List<String> cuisinePreferences) async {
    if (cuisinePreferences.isEmpty) {
      return [];
    }

    try {
      debugPrint('Getting restaurant recommendations for cuisines: $cuisinePreferences');
      
      // Get all restaurants and filter client-side
      final restaurants = await _restaurantRepository.getRestaurants().first;
      
      // Filter active restaurants matching preferred cuisines
      final recommendations = restaurants
          .where((restaurant) => 
              restaurant.isActive && 
              cuisinePreferences.contains(restaurant.cuisine))
          .toList();
          
      debugPrint('Found ${recommendations.length} restaurant recommendations');
      return recommendations;
    } catch (e) {
      debugPrint('Error getting recommendations by cuisine: $e');
      return [];
    }
  }

  // Get personalized recommendations based on VIP profile
  Future<Map<String, List<Restaurant>>> getPersonalizedRecommendations(
      VipProfile profile) async {
    final Map<String, List<Restaurant>> recommendations = {
      'favorites': [],
      'cuisineMatch': [],
      'highlyRated': [],
      'new': [],
    };

    try {
      debugPrint('Getting personalized recommendations for user: ${profile.userId}');
      
      // Get all restaurants
      final restaurants = await _restaurantRepository.getRestaurants().first;
      
      // Only include active restaurants
      final activeRestaurants = restaurants.where((r) => r.isActive).toList();
      
      // Filter for favorites
      if (profile.favoriteRestaurants.isNotEmpty) {
        recommendations['favorites'] = activeRestaurants
            .where((restaurant) => profile.favoriteRestaurants.contains(restaurant.id))
            .toList();
      }
      
      // Filter for cuisine matches
      if (profile.favoriteCuisines.isNotEmpty) {
        recommendations['cuisineMatch'] = activeRestaurants
            .where((restaurant) => 
                profile.favoriteCuisines.contains(restaurant.cuisine) && 
                !recommendations['favorites']!.contains(restaurant))
            .toList();
      }
      
      // Add highly rated restaurants (simulated for now)
      recommendations['highlyRated'] = activeRestaurants
          .where((restaurant) => 
              !recommendations['favorites']!.contains(restaurant) && 
              !recommendations['cuisineMatch']!.contains(restaurant))
          .take(5)
          .toList();
          
      // Add new restaurants (simulated by taking the most recently added ones)
      final newRestaurants = List.of(activeRestaurants)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      recommendations['new'] = newRestaurants
          .where((restaurant) => 
              !recommendations['favorites']!.contains(restaurant) && 
              !recommendations['cuisineMatch']!.contains(restaurant) &&
              !recommendations['highlyRated']!.contains(restaurant))
          .take(5)
          .toList();
      
      int totalRecommendations = 0;
      recommendations.forEach((key, value) {
        totalRecommendations += value.length;
      });
      debugPrint('Generated $totalRecommendations total personalized recommendations');
      
      return recommendations;
    } catch (e) {
      debugPrint('Error getting personalized recommendations: $e');
      return recommendations;
    }
  }

  // Get restaurants with low occupancy (for notifications)
  Future<List<Restaurant>> getLowOccupancyRestaurants(int threshold) async {
    try {
      debugPrint('Finding restaurants with low occupancy (threshold: $threshold%)');
      
      // Get all restaurants
      final restaurants = await _restaurantRepository.getRestaurants().first;
      
      // Filter active restaurants
      final activeRestaurants = restaurants.where((r) => r.isActive).toList();
      
      // Simulate occupancy check - in real app this would come from actual data
      final now = DateTime.now();
      final currentHour = now.hour;
      final currentWeekday = _getWeekday(now.weekday);
      
      return activeRestaurants.where((restaurant) {
        // Check if the restaurant is currently open
        final hours = restaurant.openingHours[currentWeekday];
        if (hours == null || hours == 'Closed') return false;
        
        final openingHour = int.tryParse(hours.split('-')[0].split(':')[0].trim()) ?? 0;
        final closingHour = int.tryParse(hours.split('-')[1].split(':')[0].trim()) ?? 0;
        
        if (currentHour < openingHour || currentHour >= closingHour) {
          return false;
        }
        
        // Simulate occupancy (in a real app this would be actual data)
        // We're using the restaurant ID hashcode to create a pseudo-random but consistent value
        final simulatedOccupancy = (restaurant.id.hashCode % 100).abs();
        return simulatedOccupancy < threshold;
      }).toList();
    } catch (e) {
      debugPrint('Error getting low occupancy restaurants: $e');
      return [];
    }
  }
  
  // Get restaurant recommendations based on location
  Future<List<Restaurant>> getNearbyRestaurants(
      double latitude, double longitude, double radiusInKm) async {
    try {
      debugPrint('Finding nearby restaurants at ($latitude, $longitude) within $radiusInKm km');
      
      // In a production app, we'd use geolocation queries
      // For now, just return all active restaurants and note this is simulated
      final restaurants = await _restaurantRepository.getRestaurants().first;
      
      // Filter active restaurants
      final activeRestaurants = restaurants.where((r) => r.isActive).toList();
      
      // In a real app, we would filter by GeoPoint here
      // For now, just return all and imagine they're nearby
      debugPrint('Found ${activeRestaurants.length} active restaurants (geolocation filtering would be applied in production)');
      return activeRestaurants;
    } catch (e) {
      debugPrint('Error getting nearby restaurants: $e');
      return [];
    }
  }

  // Helper method to convert weekday int to string
  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Monday';
    }
  }
} 