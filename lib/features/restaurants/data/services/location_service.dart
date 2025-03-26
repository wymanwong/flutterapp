import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../domain/models/restaurant.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationService {
  /// Request location permission and check if it's enabled
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return false;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return false;
    }

    // Permissions are granted
    return true;
  }

  /// Get the current user position
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Get coordinates from address
  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return {
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };
      }
      return null;
    } catch (e) {
      print('Error getting coordinates from address: $e');
      return null;
    }
  }

  /// Get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
      }
      return null;
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return null;
    }
  }

  /// Calculate distance between two coordinates in kilometers
  double calculateDistance(double startLatitude, double startLongitude, 
                         double endLatitude, double endLongitude) {
    // Using the haversine formula
    const R = 6371.0; // Earth radius in kilometers
    
    final dLat = _toRadians(endLatitude - startLatitude);
    final dLon = _toRadians(endLongitude - startLongitude);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(_toRadians(startLatitude)) * cos(_toRadians(endLatitude)) *
              sin(dLon / 2) * sin(dLon / 2);
              
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }
  
  /// Sort restaurants by distance from current location
  Future<List<Restaurant>> sortRestaurantsByDistance(
      List<Restaurant> restaurants) async {
    final currentPosition = await getCurrentPosition();
    if (currentPosition == null || restaurants.isEmpty) {
      return restaurants;
    }
    
    // Filter restaurants that have location data
    final restaurantsWithLocation = restaurants.where((restaurant) =>
        restaurant.latitude != null && restaurant.longitude != null).toList();
    
    // Sort by distance
    restaurantsWithLocation.sort((a, b) {
      final distanceA = calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          a.latitude!,
          a.longitude!);
          
      final distanceB = calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          b.latitude!,
          b.longitude!);
          
      return distanceA.compareTo(distanceB);
    });
    
    // Add restaurants without location at the end
    final restaurantsWithoutLocation = restaurants.where((restaurant) =>
        restaurant.latitude == null || restaurant.longitude == null).toList();
        
    return [...restaurantsWithLocation, ...restaurantsWithoutLocation];
  }

  /// Find nearby restaurants within a specified radius (in kilometers)
  Future<List<Restaurant>> findNearbyRestaurants(
      List<Restaurant> restaurants, double radiusInKm) async {
    final currentPosition = await getCurrentPosition();
    if (currentPosition == null) {
      return [];
    }
    
    return restaurants.where((restaurant) {
      if (restaurant.latitude == null || restaurant.longitude == null) {
        return false;
      }
      
      final distance = calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        restaurant.latitude!,
        restaurant.longitude!
      );
      
      return distance <= radiusInKm;
    }).toList();
  }
  
  // Convert degrees to radians
  double _toRadians(double degree) {
    return degree * (pi / 180);
  }
} 