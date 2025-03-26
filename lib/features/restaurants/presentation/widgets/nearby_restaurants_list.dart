import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/models/restaurant.dart';
import '../../data/services/location_service.dart';
import '../../../notifications/services/notification_service.dart';

final nearbyRestaurantsProvider = FutureProvider.autoDispose<List<Restaurant>>(
  (ref) async {
    // This would typically come from a restaurant repository
    final List<Restaurant> allRestaurants = [];
    
    // Get current location
    final locationService = ref.read(locationServiceProvider);
    
    // Filter and sort by distance
    return locationService.sortRestaurantsByDistance(allRestaurants);
  },
);

class NearbyRestaurantsList extends ConsumerStatefulWidget {
  final List<Restaurant> restaurants;
  final double maxDistance;
  final Function(Restaurant) onRestaurantTap;

  const NearbyRestaurantsList({
    Key? key,
    required this.restaurants,
    this.maxDistance = 10.0, // Default 10km radius
    required this.onRestaurantTap,
  }) : super(key: key);

  @override
  ConsumerState<NearbyRestaurantsList> createState() => _NearbyRestaurantsListState();
}

class _NearbyRestaurantsListState extends ConsumerState<NearbyRestaurantsList> {
  Position? _currentPosition;
  bool _isLoading = true;
  List<Map<String, dynamic>> _restaurantsWithDistance = [];

  @override
  void initState() {
    super.initState();
    _getLocationAndCalculateDistances();
  }

  Future<void> _getLocationAndCalculateDistances() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      _currentPosition = await locationService.getCurrentPosition();
      
      if (_currentPosition != null) {
        // Calculate distance for each restaurant
        final restaurantsWithDistance = widget.restaurants
            .where((restaurant) => 
                restaurant.latitude != null && restaurant.longitude != null)
            .map((restaurant) {
          final distance = locationService.calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            restaurant.latitude!,
            restaurant.longitude!,
          );
          
          return {
            'restaurant': restaurant,
            'distance': distance,
            'isNearby': distance <= widget.maxDistance,
          };
        }).toList();
        
        // Sort by distance
        restaurantsWithDistance.sort((a, b) => 
            (a['distance'] as double).compareTo(b['distance'] as double));
        
        setState(() {
          _restaurantsWithDistance = restaurantsWithDistance;
        });
        
        // Send notification for nearby restaurants
        final nearbyRestaurants = restaurantsWithDistance
            .where((item) => item['isNearby'] as bool)
            .map((item) => item['restaurant'] as Restaurant)
            .toList();
            
        if (nearbyRestaurants.isNotEmpty) {
          final notificationService = ref.read(notificationServiceProvider);
          // In a real app, you'd use the current user's ID
          await notificationService.checkAndNotifyNearbyRestaurants(
              'current-user-id', nearbyRestaurants);
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_currentPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Location services are disabled or permission denied',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getLocationAndCalculateDistances,
              child: const Text('Enable Location'),
            ),
          ],
        ),
      );
    }

    if (_restaurantsWithDistance.isEmpty) {
      return const Center(
        child: Text('No restaurants found with location data'),
      );
    }

    // Filter to only show nearby restaurants if specified
    final displayedRestaurants = widget.maxDistance > 0
        ? _restaurantsWithDistance
            .where((item) => item['isNearby'] as bool)
            .toList()
        : _restaurantsWithDistance;

    if (displayedRestaurants.isEmpty) {
      return Center(
        child: Text(
          'No restaurants found within ${widget.maxDistance} km',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: displayedRestaurants.length,
      itemBuilder: (context, index) {
        final item = displayedRestaurants[index];
        final restaurant = item['restaurant'] as Restaurant;
        final distance = item['distance'] as double;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: InkWell(
            onTap: () => widget.onRestaurantTap(restaurant),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant image
                  if (restaurant.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        restaurant.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.restaurant, size: 40),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant, size: 40),
                    ),
                  const SizedBox(width: 16),
                  
                  // Restaurant details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          restaurant.cuisineTypes.join(', '),
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${distance.toStringAsFixed(1)} km away',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (restaurant.averageRating > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${restaurant.averageRating.toStringAsFixed(1)} (${restaurant.ratingCount})',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}