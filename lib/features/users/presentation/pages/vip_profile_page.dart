import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_availability_system/main.dart';
import '../../domain/models/vip_profile.dart';
import '../../data/repositories/vip_profile_repository.dart';
import '../../../restaurant/domain/models/restaurant.dart';
import '../../../restaurant/data/services/recommendation_service.dart';
import '../widgets/swipeable_restaurant_card.dart';
import '../widgets/preference_selector.dart';
import '../../../settings/data/localization/app_localizations.dart';
import '../../../notifications/services/vacancy_notification_service.dart';
import '../../../restaurant/data/repositories/restaurant_repository.dart';
import '../../../reservations/domain/models/reservation.dart';
import 'dart:math';
import '../../../restaurant/presentation/pages/restaurant_detail_page.dart';
import 'dart:async';

final vipProfileRepositoryProvider = Provider<VipProfileRepository>((ref) {
  return VipProfileRepository(firestore: FirebaseFirestore.instance);
});

final firebaseFirestoreProvider = Provider((ref) => FirebaseFirestore.instance);

class ReservationDialogResult {
  final bool confirmed;
  final DateTime dateTime;
  final int numberOfGuests;

  ReservationDialogResult({
    required this.confirmed,
    required this.dateTime,
    required this.numberOfGuests,
  });

  Map<String, dynamic> toMap() {
    return {
      'confirmed': confirmed,
      'dateTime': dateTime,
      'numberOfGuests': numberOfGuests,
    };
  }

  factory ReservationDialogResult.fromMap(Map<String, dynamic> map) {
    return ReservationDialogResult(
      confirmed: map['confirmed'] as bool,
      dateTime: map['dateTime'] as DateTime,
      numberOfGuests: map['numberOfGuests'] as int,
    );
  }
}

class VipProfilePage extends ConsumerStatefulWidget {
  final String userId;

  const VipProfilePage({
    Key? key,
    this.userId = 'current_user',
  }) : super(key: key);

  @override
  ConsumerState<VipProfilePage> createState() => _VipProfilePageState();
}

// Dialog state management
class _ReservationDialogState {
  DateTime selectedDate;
  TimeOfDay selectedTime;
  int numberOfGuests;
  
  _ReservationDialogState({
    required this.selectedDate,
    required this.selectedTime,
    required this.numberOfGuests,
  });
}

class _VipProfilePageState extends ConsumerState<VipProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isEditing = false;
  VipProfile? _profile;
  final Map<String, List<Restaurant>> _recommendations = {
    'favorites': [],
    'cuisineMatch': [],
    'highlyRated': [],
    'new': []
  };
  
  // Form state
  final _formKey = GlobalKey<FormState>();
  final List<String> _selectedDietaryPreferences = [];
  final List<String> _selectedCuisines = [];
  final Map<String, dynamic> _specialOccasions = {};
  final Map<String, dynamic> _seatingPreferences = {};
  NotificationPreferences _notificationPreferences = NotificationPreferences();
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfile().then((_) {
      if (mounted) {
        _loadRecommendations();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_isEditing && _hasUnsavedChanges) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('DISCARD'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  void _navigateBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // If we can't pop, go to the main dashboard or users page
      Navigator.of(context).pushReplacementNamed('/users');
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.userId.isEmpty) {
        _createDefaultProfile();
        return;
      }

      final repository = ref.read(vipProfileRepositoryProvider);
      final profile = await repository.getProfileByUserId(widget.userId);
      
      if (profile == null) {
        print('No profile found for user ID: ${widget.userId}, creating a default one');
        _createDefaultProfile();
        return;
      }
      
      setState(() {
        _profile = profile;
        _selectedDietaryPreferences.clear();
        _selectedDietaryPreferences.addAll(_profile!.dietaryPreferences);
        _selectedCuisines.clear();
        _selectedCuisines.addAll(_profile!.favoriteCuisines);
        _notificationPreferences = _profile!.notificationPreferences;
        _seatingPreferences.clear();
        _seatingPreferences.addAll(_profile!.seatingPreferences);
        _isLoading = false;
      });
      print('Loaded profile with notification preferences: ${_notificationPreferences.toJson()}');
    } catch (e) {
      print('Error loading profile: $e');
      _createDefaultProfile();
    }
  }
  
  void _createDefaultProfile() {
    setState(() {
      _profile = VipProfile(
        id: '',
        userId: widget.userId,
        isVip: false,
        loyaltyPoints: 0,
        dietaryPreferences: [],
        favoriteCuisines: [],
        favoriteRestaurants: [],
        notificationsEnabled: true,
        notificationPreferences: NotificationPreferences(),
        seatingPreferences: {'location': 'Inside', 'noise': 'Moderate'},
        lastVisit: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _selectedDietaryPreferences.clear();
      _selectedCuisines.clear();
      _notificationPreferences = _profile!.notificationPreferences;
      _seatingPreferences.clear();
      _seatingPreferences.addAll(_profile!.seatingPreferences);
      _isLoading = false;
    });
  }

  Future<void> _loadRecommendations() async {
    if (_profile == null) return;

    try {
      final recommendationService = ref.read(recommendationServiceProvider);
      final recommendations = await recommendationService.getPersonalizedRecommendations(_profile!);
      
      // If we didn't get any recommendations, create some simulated restaurants
      bool isEmpty = true;
      recommendations.forEach((key, value) {
        if (value.isNotEmpty) isEmpty = false;
      });
      
      if (isEmpty) {
        // Create some example restaurants if no real ones exist
        final Map<String, String> defaultOpeningHours = {
          'Monday': '9:00 - 22:00',
          'Tuesday': '9:00 - 22:00',
          'Wednesday': '9:00 - 22:00',
          'Thursday': '9:00 - 22:00',
          'Friday': '9:00 - 23:00',
          'Saturday': '10:00 - 23:00',
          'Sunday': '10:00 - 22:00',
        };
        
        final List<Restaurant> simulatedRestaurants = [
          Restaurant(
            id: 'sim1',
            name: 'Pasta Palace',
            cuisine: 'Italian',
            address: '123 Main St',
            phoneNumber: '555-1234',
            email: 'info@pastapalace.com',
            capacity: 80,
            currentOccupancy: 30,
            waitTime: 10,
            isActive: true,
            hasVacancy: true,
            imageUrl: 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0',
            businessHours: BusinessHours(schedule: {}),
            openingHours: defaultOpeningHours,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Restaurant(
            id: 'sim2',
            name: 'Dragon Wok',
            cuisine: 'Chinese',
            address: '456 Elm St',
            phoneNumber: '555-5678',
            email: 'info@dragonwok.com',
            capacity: 60,
            currentOccupancy: 25,
            waitTime: 15,
            isActive: true,
            hasVacancy: true,
            imageUrl: 'https://images.unsplash.com/photo-1525648199074-cee30ba79a4a',
            businessHours: BusinessHours(schedule: {}),
            openingHours: defaultOpeningHours,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Restaurant(
            id: 'sim3',
            name: 'Sushi Time',
            cuisine: 'Japanese',
            address: '789 Oak St',
            phoneNumber: '555-9012',
            email: 'info@sushitime.com',
            capacity: 50,
            currentOccupancy: 20,
            waitTime: 30,
            isActive: true,
            hasVacancy: false,
            imageUrl: 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c',
            businessHours: BusinessHours(schedule: {}),
            openingHours: defaultOpeningHours,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        
        // Assign simulated restaurants to categories
        recommendations['favorites'] = [simulatedRestaurants[0]];
        recommendations['cuisineMatch'] = [simulatedRestaurants[1]];
        recommendations['highlyRated'] = [simulatedRestaurants[2]];
        recommendations['new'] = simulatedRestaurants;
      }
      
      setState(() {
        // Clear and update each category
        _recommendations.clear();
        recommendations.forEach((key, value) {
          _recommendations[key] = value;
        });
      });
    } catch (e) {
      print('Error loading recommendations: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading recommendations: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    try {
      final repository = ref.read(vipProfileRepositoryProvider);
      
      if (_profile!.id.isEmpty) {
        // Create new profile
        final updatedProfile = _profile!.copyWith(
          dietaryPreferences: _selectedDietaryPreferences,
          favoriteCuisines: _selectedCuisines,
          notificationPreferences: _notificationPreferences,
          seatingPreferences: Map<String, dynamic>.from(_seatingPreferences),
        );
        
        print('Creating profile with notification preferences: ${_notificationPreferences.toJson()}');
        await repository.createProfile(updatedProfile);
      } else {
        // Update existing profile
        final updatedProfile = _profile!.copyWith(
          dietaryPreferences: _selectedDietaryPreferences,
          favoriteCuisines: _selectedCuisines,
          notificationPreferences: _notificationPreferences,
          seatingPreferences: Map<String, dynamic>.from(_seatingPreferences),
        );
        
        print('Updating profile with notification preferences: ${_notificationPreferences.toJson()}');
        await repository.updateProfile(updatedProfile);
      }

      setState(() {
        _isEditing = false;
        _hasUnsavedChanges = false;
        _profile = _profile!.copyWith(
          dietaryPreferences: _selectedDietaryPreferences,
          favoriteCuisines: _selectedCuisines,
          notificationPreferences: _notificationPreferences,
          seatingPreferences: Map<String, dynamic>.from(_seatingPreferences),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  Future<void> _toggleFavoriteRestaurant(Restaurant restaurant) async {
    if (_profile == null) return;

    try {
      final repository = ref.read(vipProfileRepositoryProvider);
      final isFavorite = _profile!.favoriteRestaurants.contains(restaurant.id);
      
      if (isFavorite) {
        await repository.removeFavoriteRestaurant(_profile!.id, restaurant.id);
      } else {
        await repository.addFavoriteRestaurant(_profile!.id, restaurant.id);
      }

      // Update local state
      setState(() {
        final updatedFavorites = List<String>.from(_profile!.favoriteRestaurants);
        if (isFavorite) {
          updatedFavorites.remove(restaurant.id);
        } else {
          updatedFavorites.add(restaurant.id);
        }
        
        _profile = _profile!.copyWith(
          favoriteRestaurants: updatedFavorites,
        );
      });
      
      // Reload recommendations
      await _loadRecommendations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating favorites: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(translations.translate('vip_profile')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateBack,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                _navigateBack();
              }
            },
          ),
          title: Text(translations.translate('vip_profile')),
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
              )
            else
              TextButton(
                onPressed: _saveProfile,
                child: Text(translations.translate('save')),
              ),
          ],
        ),
        body: _profile == null
            ? Center(child: Text(translations.translate('error_loading_profile')))
            : _isEditing
                ? _buildEditProfileForm()
                : _buildProfileView(),
      ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      children: [
        _buildProfileHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRecommendationsTab(),
              _buildPreferencesTab(),
              _buildFavoritesTab(),
              _buildNotificationsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final translations = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.person, 
                size: 40, 
                color: _profile!.isVip ? Colors.amber : Colors.blue
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${translations.translate('status')}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(_profile!.isVip ? 'VIP' : translations.translate('regular')),
                        backgroundColor: _profile!.isVip ? Colors.amber : Colors.grey.shade300,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${translations.translate('loyalty_points')}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${_profile!.loyaltyPoints}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${translations.translate('last_visit')}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${_profile!.lastVisit.day}/${_profile!.lastVisit.month}/${_profile!.lastVisit.year}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final translations = AppLocalizations.of(context);

    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(text: translations.translate('for_you')),
        Tab(text: translations.translate('preferences')),
        Tab(text: translations.translate('favorites')),
        Tab(text: translations.translate('notifications')),
      ],
    );
  }

  Widget _buildRecommendationsTab() {
    final translations = AppLocalizations.of(context);

    // If no recommendations, display a message
    if (_recommendations.values.every((list) => list.isEmpty)) {
      return Center(
        child: Text(translations.translate('set_preferences')),
      );
    }

    return ListView(
      children: [
        if (_recommendations['favorites']!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Your Favorites',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _buildRestaurantGrid(_recommendations['favorites']!),
        ],
        if (_recommendations['cuisineMatch']!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Based on Your Cuisine Preferences',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _buildRestaurantGrid(_recommendations['cuisineMatch']!),
        ],
        if (_recommendations['highlyRated']!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Highly Rated',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _buildRestaurantGrid(_recommendations['highlyRated']!),
        ],
        if (_recommendations['new']!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'New Places',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _buildRestaurantGrid(_recommendations['new']!),
        ],
      ],
    );
  }

  // Helper method to build responsive grid of restaurants
  Widget _buildRestaurantGrid(List<Restaurant> restaurants) {
    // Calculate how many cards fit per row based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = 220.0; // Match SwipeableRestaurantCard width
    final cardsPerRow = (screenWidth / cardWidth).floor();
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cardsPerRow > 0 ? cardsPerRow : 1,
        childAspectRatio: 0.7,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: restaurants.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final restaurant = restaurants[index];
        return SwipeableRestaurantCard(
          restaurant: restaurant,
          isFavorite: _profile!.favoriteRestaurants.contains(restaurant.id),
          onToggleFavorite: () => _toggleFavoriteRestaurant(restaurant),
        );
      },
    );
  }

  Widget _buildPreferencesTab() {
    final translations = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translations.translate('dietary_preferences'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  children: _profile!.dietaryPreferences.map((preference) {
                    return Chip(
                      label: Text(preference),
                      backgroundColor: Colors.blue.shade100,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translations.translate('favorite_cuisines'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  children: _profile!.favoriteCuisines.map((cuisine) {
                    return Chip(
                      label: Text(cuisine),
                      backgroundColor: Colors.blue.shade200,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translations.translate('seating_preferences'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  children: _profile!.seatingPreferences.entries.map((entry) {
                    return Chip(
                      label: Text('${entry.key}: ${entry.value}'),
                      backgroundColor: Colors.blue.shade100,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    final translations = AppLocalizations.of(context);
    
    return StreamBuilder<List<Restaurant>>(
      stream: ref.read(RestaurantRepository.provider).getRestaurants(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final restaurants = snapshot.data ?? [];
        
        if (restaurants.isEmpty) {
          return Center(child: Text(translations.translate('no_restaurants')));
        }
        
        // Filter to show favorite restaurants first, then others
        final favoriteRestaurants = restaurants.where(
          (r) => _profile!.favoriteRestaurants.contains(r.id)
        ).toList();
        
        final otherRestaurants = restaurants.where(
          (r) => !_profile!.favoriteRestaurants.contains(r.id)
        ).toList();

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (favoriteRestaurants.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Your Favorites',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...favoriteRestaurants.map((restaurant) => _buildRestaurantTile(restaurant, true)),
              const Divider(thickness: 2, height: 32),
            ],
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Available Restaurants',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...otherRestaurants.map((restaurant) => _buildRestaurantTile(restaurant, false)),
          ],
        );
      },
    );
  }
  
  Widget _buildRestaurantTile(Restaurant restaurant, bool isFavorite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      clipBehavior: Clip.antiAlias,
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant image with error handling
          AspectRatio(
            aspectRatio: 16/9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (restaurant.imageUrl != null && restaurant.imageUrl!.isNotEmpty)
                  Image.network(
                    restaurant.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.blue.shade100,
                      child: const Center(
                        child: Icon(Icons.restaurant, size: 50, color: Colors.blue),
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.blue.shade50,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        ),
                      );
                    },
                  )
                else
                  Container(
                    color: Colors.blue.shade100,
                    child: const Center(
                      child: Icon(Icons.restaurant, size: 50, color: Colors.blue),
                    ),
                  ),
                  
                // Availability indicator  
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: restaurant.isActive ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      restaurant.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Vacancy badge
                if (restaurant.hasVacancy == true)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Available',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
            
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        restaurant.cuisine,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant.address,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Occupancy info - if available
                      if (restaurant.currentOccupancy != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'Occupancy: ${restaurant.currentOccupancy}%',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                      // Wait time - if available
                      if (restaurant.waitTime != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'Wait: ${restaurant.waitTime} mins',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Favorite toggle button
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                    size: 28,
                  ),
                  onPressed: () => _toggleFavoriteRestaurant(restaurant),
                ),
              ],
            ),
          ),
          
          // Restaurant actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.book_online),
                  label: const Text('Reserve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _reserveRestaurant(restaurant);
                  },
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/restaurant/detail', arguments: restaurant.id);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    final translations = AppLocalizations.of(context);
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Test vacancy notification button
        ElevatedButton.icon(
          icon: const Icon(Icons.notification_important),
          label: Text(translations.translate('test_vacancy_notification')),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          onPressed: _testVacancyNotification,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: Text(translations.translate('enable_notifications')),
          subtitle: Text(translations.translate('notification_alerts')),
          value: _profile!.notificationsEnabled,
          onChanged: _isEditing ? (value) async {
            try {
              final repository = ref.read(vipProfileRepositoryProvider);
              
              if (_profile!.id.isNotEmpty) {
                await repository.toggleNotifications(_profile!.id, value);
              }
              
              setState(() {
                _profile = _profile!.copyWith(notificationsEnabled: value);
                _hasUnsavedChanges = true;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${translations.translate('notifications')} ${value ? translations.translate('on') : translations.translate('off')}')),
              );
            } catch (e) {
              print('Error toggling notifications: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${translations.translate('error_updating_notification')}: $e')),
              );
            }
          } : null,
        ),
        const Divider(),
        _isEditing 
        ? SwitchListTile(
            title: Text(translations.translate('low_occupancy_alerts')),
            subtitle: Text(translations.translate('get_notified_availability')),
            value: _notificationPreferences.lowOccupancyAlerts,
            onChanged: _profile!.notificationsEnabled ? (value) async {
              try {
                setState(() {
                  _notificationPreferences = _notificationPreferences.copyWith(
                    lowOccupancyAlerts: value,
                  );
                  _hasUnsavedChanges = true;
                });
                
                if (_profile!.id.isNotEmpty) {
                  final repository = ref.read(vipProfileRepositoryProvider);
                  await repository.updateNotificationPreferences(_profile!.id, _notificationPreferences);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${translations.translate('low_occupancy_alerts')} ${value ? translations.translate('on') : translations.translate('off')}')),
                  );
                }
              } catch (e) {
                print('Error updating low occupancy alerts: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${translations.translate('error_updating_notification')}: $e')),
                );
              }
            } : null,
          )
        : ListTile(
            title: Text(translations.translate('low_occupancy_alerts')),
            subtitle: Text(translations.translate('get_notified_availability')),
            trailing: Chip(
              label: Text(_profile!.notificationPreferences.lowOccupancyAlerts ? translations.translate('on') : translations.translate('off')),
              backgroundColor: _profile!.notificationPreferences.lowOccupancyAlerts
                  ? Colors.blue.shade100
                  : Colors.grey.shade300,
            ),
          ),
        if (_isEditing && _profile!.notificationsEnabled && _notificationPreferences.lowOccupancyAlerts)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Low Occupancy Threshold: ${_notificationPreferences.lowOccupancyThreshold}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        _notificationPreferences.lowOccupancyThreshold <= 30
                            ? 'High Alert'
                            : 'Normal Alert',
                        style: TextStyle(
                          color: _notificationPreferences.lowOccupancyThreshold <= 30
                              ? Colors.red
                              : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Slider(
                value: _notificationPreferences.lowOccupancyThreshold.toDouble(),
                min: 10,
                max: 50,
                divisions: 8,
                label: '${_notificationPreferences.lowOccupancyThreshold}%',
                onChanged: _profile!.notificationsEnabled && _notificationPreferences.lowOccupancyAlerts
                    ? (value) async {
                        try {
                          setState(() {
                            _notificationPreferences = _notificationPreferences.copyWith(
                              lowOccupancyThreshold: value.toInt(),
                            );
                            _hasUnsavedChanges = true;
                          });
                          
                          if (_profile!.id.isNotEmpty) {
                            final repository = ref.read(vipProfileRepositoryProvider);
                            await repository.updateNotificationPreferences(_profile!.id, _notificationPreferences);
                          }
                        } catch (e) {
                          print('Error updating threshold: $e');
                        }
                      }
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '10%',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(
                      '50%',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          )
        else if (!_isEditing)
          ListTile(
            title: const Text('Low Occupancy Threshold'),
            subtitle: Text('Alert when occupancy is below ${_profile!.notificationPreferences.lowOccupancyThreshold}%'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                '${_profile!.notificationPreferences.lowOccupancyThreshold}%',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        const Divider(),
        _isEditing 
        ? SwitchListTile(
            title: Text(translations.translate('proximity_alerts')),
            subtitle: Text(translations.translate('notifications_near_favorites')),
            value: _notificationPreferences.proximityAlerts,
            onChanged: _profile!.notificationsEnabled ? (value) async {
              try {
                setState(() {
                  _notificationPreferences = _notificationPreferences.copyWith(
                    proximityAlerts: value,
                  );
                  _hasUnsavedChanges = true;
                });
                
                if (_profile!.id.isNotEmpty) {
                  final repository = ref.read(vipProfileRepositoryProvider);
                  await repository.updateNotificationPreferences(_profile!.id, _notificationPreferences);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Proximity alerts ${value ? 'enabled' : 'disabled'}')),
                  );
                }
              } catch (e) {
                print('Error updating proximity alerts: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating notification setting: $e')),
                );
              }
            } : null,
          )
        : ListTile(
            title: Text(translations.translate('proximity_alerts')),
            subtitle: Text(translations.translate('notifications_near_favorites')),
            trailing: Chip(
              label: Text(_profile!.notificationPreferences.proximityAlerts ? translations.translate('on') : translations.translate('off')),
              backgroundColor: _profile!.notificationPreferences.proximityAlerts
                  ? Colors.blue.shade100
                  : Colors.grey.shade300,
            ),
          ),
        _isEditing && _profile!.notificationsEnabled && _notificationPreferences.proximityAlerts
        ? Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Proximity Radius: ${_notificationPreferences.proximityRadius} meters',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        _notificationPreferences.proximityRadius <= 300
                            ? 'Close Range'
                            : _notificationPreferences.proximityRadius <= 600
                                ? 'Medium Range'
                                : 'Long Range',
                        style: TextStyle(
                          color: _notificationPreferences.proximityRadius <= 300
                              ? Colors.green
                              : _notificationPreferences.proximityRadius <= 600
                                  ? Colors.blue
                                  : Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Slider(
                value: _notificationPreferences.proximityRadius.toDouble(),
                min: 100,
                max: 1000,
                divisions: 9,
                label: '${_notificationPreferences.proximityRadius} meters',
                onChanged: _profile!.notificationsEnabled && _notificationPreferences.proximityAlerts
                    ? (value) async {
                        try {
                          setState(() {
                            _notificationPreferences = _notificationPreferences.copyWith(
                              proximityRadius: value.toInt(),
                            );
                            _hasUnsavedChanges = true;
                          });
                          
                          if (_profile!.id.isNotEmpty) {
                            final repository = ref.read(vipProfileRepositoryProvider);
                            await repository.updateNotificationPreferences(_profile!.id, _notificationPreferences);
                          }
                        } catch (e) {
                          print('Error updating proximity radius: $e');
                        }
                      }
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '100m',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(
                      '1000m',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          )
        : ListTile(
            title: const Text('Proximity Radius'),
            subtitle: Row(
              children: [
                Text('${_profile!.notificationPreferences.proximityRadius} meters'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    _profile!.notificationPreferences.proximityRadius <= 300
                        ? 'Close Range'
                        : _profile!.notificationPreferences.proximityRadius <= 600
                            ? 'Medium Range'
                            : 'Long Range',
                    style: TextStyle(
                      color: _profile!.notificationPreferences.proximityRadius <= 300
                          ? Colors.green
                          : _profile!.notificationPreferences.proximityRadius <= 600
                              ? Colors.blue
                              : Colors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _isEditing
        ? SwitchListTile(
            title: Text(translations.translate('reservation_reminders')),
            subtitle: Text(translations.translate('get_reminded_reservations')),
            value: _notificationPreferences.reservationReminders,
            onChanged: _profile!.notificationsEnabled ? (value) async {
              try {
                setState(() {
                  _notificationPreferences = _notificationPreferences.copyWith(
                    reservationReminders: value,
                  );
                  _hasUnsavedChanges = true;
                });
                
                if (_profile!.id.isNotEmpty) {
                  final repository = ref.read(vipProfileRepositoryProvider);
                  await repository.updateNotificationPreferences(_profile!.id, _notificationPreferences);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reservation reminders ${value ? 'enabled' : 'disabled'}')),
                  );
                }
              } catch (e) {
                print('Error updating reservation reminders: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating notification setting: $e')),
                );
              }
            } : null,
          )
        : ListTile(
            title: Text(translations.translate('reservation_reminders')),
            subtitle: Text(translations.translate('get_reminded_reservations')),
            trailing: Chip(
              label: Text(_profile!.notificationPreferences.reservationReminders ? translations.translate('on') : translations.translate('off')),
              backgroundColor: _profile!.notificationPreferences.reservationReminders
                  ? Colors.blue.shade100
                  : Colors.grey.shade300,
            ),
          ),
        if (_isEditing) ...[
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('SAVE NOTIFICATION SETTINGS'),
          ),
        ],
      ],
    );
  }

  Widget _buildEditProfileForm() {
    final translations = AppLocalizations.of(context);

    // Initialize seating preferences with defaults if they don't exist
    if (_seatingPreferences.isEmpty) {
      _seatingPreferences['location'] = 'Inside';
      _seatingPreferences['noise'] = 'Moderate';
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translations.translate('dietary_preferences'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  PreferenceSelector(
                    options: const [
                      'Vegetarian',
                      'Vegan',
                      'Gluten-Free',
                      'Dairy-Free',
                      'Nut-Free',
                      'Halal',
                      'Kosher',
                      'Pescatarian',
                      'Keto',
                      'Paleo',
                    ],
                    selectedValues: _selectedDietaryPreferences,
                    onChanged: (values) {
                      setState(() {
                        _selectedDietaryPreferences.clear();
                        _selectedDietaryPreferences.addAll(values);
                        _hasUnsavedChanges = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translations.translate('favorite_cuisines'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  PreferenceSelector(
                    options: const [
                      'Italian',
                      'Chinese',
                      'Japanese',
                      'Mexican',
                      'Indian',
                      'Thai',
                      'French',
                      'Mediterranean',
                      'American',
                      'Fusion',
                    ],
                    selectedValues: _selectedCuisines,
                    onChanged: (values) {
                      setState(() {
                        _selectedCuisines.clear();
                        _selectedCuisines.addAll(values);
                        _hasUnsavedChanges = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translations.translate('seating_preferences'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _seatingPreferences['location'] as String? ?? 'Inside',
                    items: const [
                      DropdownMenuItem(value: 'Inside', child: Text('Inside')),
                      DropdownMenuItem(value: 'Outside', child: Text('Outside')),
                      DropdownMenuItem(value: 'Bar', child: Text('Bar')),
                      DropdownMenuItem(value: 'Private Room', child: Text('Private Room')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _seatingPreferences['location'] = value;
                          _hasUnsavedChanges = true;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Preferred Location',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _seatingPreferences['noise'] as String? ?? 'Moderate',
                    items: const [
                      DropdownMenuItem(value: 'Quiet', child: Text('Quiet')),
                      DropdownMenuItem(value: 'Moderate', child: Text('Moderate')),
                      DropdownMenuItem(value: 'Lively', child: Text('Lively')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _seatingPreferences['noise'] = value;
                          _hasUnsavedChanges = true;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Preferred Noise Level',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translations.translate('notification_preferences'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    value: _profile!.notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _profile = _profile!.copyWith(notificationsEnabled: value);
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text(translations.translate('low_occupancy_alerts')),
                    subtitle: Text(translations.translate('get_notified_availability')),
                    value: _notificationPreferences.lowOccupancyAlerts,
                    onChanged: _profile!.notificationsEnabled
                        ? (value) {
                            setState(() {
                              _notificationPreferences = _notificationPreferences.copyWith(
                                lowOccupancyAlerts: value,
                              );
                              _hasUnsavedChanges = true;
                            });
                          }
                        : null,
                  ),
                  Slider(
                    value: _notificationPreferences.lowOccupancyThreshold.toDouble(),
                    min: 10,
                    max: 50,
                    divisions: 8,
                    label: '${_notificationPreferences.lowOccupancyThreshold}%',
                    onChanged: _profile!.notificationsEnabled && _notificationPreferences.lowOccupancyAlerts
                        ? (value) {
                            setState(() {
                              _notificationPreferences = _notificationPreferences.copyWith(
                                lowOccupancyThreshold: value.toInt(),
                              );
                              _hasUnsavedChanges = true;
                            });
                          }
                        : null,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text(translations.translate('proximity_alerts')),
                    subtitle: Text(translations.translate('notifications_near_favorites')),
                    value: _notificationPreferences.proximityAlerts,
                    onChanged: _profile!.notificationsEnabled
                        ? (value) {
                            setState(() {
                              _notificationPreferences = _notificationPreferences.copyWith(
                                proximityAlerts: value,
                              );
                              _hasUnsavedChanges = true;
                            });
                          }
                        : null,
                  ),
                  Slider(
                    value: _notificationPreferences.proximityRadius.toDouble(),
                    min: 100,
                    max: 1000,
                    divisions: 9,
                    label: '${_notificationPreferences.proximityRadius} meters',
                    onChanged: _profile!.notificationsEnabled && _notificationPreferences.proximityAlerts
                        ? (value) {
                            setState(() {
                              _notificationPreferences = _notificationPreferences.copyWith(
                                proximityRadius: value.toInt(),
                              );
                              _hasUnsavedChanges = true;
                            });
                          }
                        : null,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text(translations.translate('reservation_reminders')),
                    subtitle: Text(translations.translate('get_reminded_reservations')),
                    value: _notificationPreferences.reservationReminders,
                    onChanged: _profile!.notificationsEnabled
                        ? (value) {
                            setState(() {
                              _notificationPreferences = _notificationPreferences.copyWith(
                                reservationReminders: value,
                              );
                              _hasUnsavedChanges = true;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(translations.translate('save_profile')),
          ),
        ],
      ),
    );
  }

  void _toggleOption(String option, List<String> list, Function(List<String>) onUpdate) {
    setState(() {
      if (list.contains(option)) {
        list.remove(option);
      } else {
        list.add(option);
      }
      _hasUnsavedChanges = true;
      onUpdate(list);
    });
  }

  void _testVacancyNotification() {
    final restaurant = _recommendations['favorites']![0];
    final occupancyPercentage = restaurant.getOccupancyPercentage();
    final availableSeats = restaurant.getAvailableSeats();
    final isBelowThreshold = occupancyPercentage <= _notificationPreferences.lowOccupancyThreshold;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isBelowThreshold ? Icons.notification_important : Icons.info_outline,
              color: isBelowThreshold ? Colors.blue : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(isBelowThreshold ? 'Restaurant Available!' : 'Restaurant Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${restaurant.name} ${isBelowThreshold ? 'has low occupancy!' : 'status update:'}'),
            const SizedBox(height: 8),
            Text(
              'Current Occupancy: ${occupancyPercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isBelowThreshold ? Colors.blue : Colors.orange,
              ),
            ),
            Text('Available Seats: $availableSeats'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isBelowThreshold ? Colors.blue.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isBelowThreshold ? Colors.blue.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isBelowThreshold ? Icons.local_offer : Icons.info_outline,
                    size: 16,
                    color: isBelowThreshold ? Colors.blue : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      isBelowThreshold
                          ? 'Special offer for VIP members!'
                          : 'Occupancy is above threshold (${_notificationPreferences.lowOccupancyThreshold}%)',
                      style: TextStyle(
                        color: isBelowThreshold ? Colors.blue : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (isBelowThreshold)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _reserveRestaurant(restaurant);
              },
              child: const Text('Reserve Now'),
            ),
        ],
      ),
    );
  }

  void _reserveRestaurant(Restaurant restaurant) async {
    try {
      // Pre-calculate initial values to avoid rebuilds
      final initialDate = DateTime.now().add(const Duration(hours: 1));
      final initialTime = TimeOfDay.fromDateTime(initialDate);
      
      final dialogState = _ReservationDialogState(
        selectedDate: initialDate,
        selectedTime: initialTime,
        numberOfGuests: 2,
      );

      // Show confirmation dialog with optimized state management
      final result = await showDialog<ReservationDialogResult>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            // Memoize formatted strings to avoid recalculation
            final formattedDate = '${dialogState.selectedDate.day}/${dialogState.selectedDate.month}/${dialogState.selectedDate.year}';
            final formattedTime = '${dialogState.selectedTime.hour.toString().padLeft(2, '0')}:${dialogState.selectedTime.minute.toString().padLeft(2, '0')}';
            
            return AlertDialog(
              title: const Text('Confirm Reservation'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant info - static, no need to rebuild
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reservation Details:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Restaurant: ${restaurant.name}'),
                        ],
                      ),
                    ),
                    
                    // Date picker - optimized with cached values
                    ListTile(
                      title: const Text('Date'),
                      subtitle: Text(formattedDate),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: dialogState.selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) {
                          setState(() {
                            dialogState.selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              dialogState.selectedTime.hour,
                              dialogState.selectedTime.minute,
                            );
                          });
                        }
                      },
                    ),
                    
                    // Time picker - optimized with cached values
                    ListTile(
                      title: const Text('Time'),
                      subtitle: Text(formattedTime),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: dialogState.selectedTime,
                        );
                        if (time != null) {
                          setState(() {
                            dialogState.selectedTime = time;
                            dialogState.selectedDate = DateTime(
                              dialogState.selectedDate.year,
                              dialogState.selectedDate.month,
                              dialogState.selectedDate.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      },
                    ),
                    
                    // Guest selector - optimized with direct state access
                    ListTile(
                      title: const Text('Number of Guests'),
                      subtitle: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: dialogState.numberOfGuests > 1
                                ? () => setState(() => dialogState.numberOfGuests--)
                                : null,
                          ),
                          Text(
                            dialogState.numberOfGuests.toString(),
                            style: const TextStyle(fontSize: 18),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: dialogState.numberOfGuests < restaurant.capacity
                                ? () => setState(() => dialogState.numberOfGuests++)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Summary box - optimized with cached values
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reservation Summary',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('• Restaurant: ${restaurant.name}'),
                          Text('• Date: $formattedDate'),
                          Text('• Time: ${dialogState.selectedTime.format(context)}'),
                          Text('• Number of guests: ${dialogState.numberOfGuests}'),
                          if (restaurant.hasVacancy)
                            const Text(
                              '• Table availability confirmed',
                              style: TextStyle(color: Colors.green),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(
                      context,
                      ReservationDialogResult(
                        confirmed: true,
                        dateTime: dialogState.selectedDate,
                        numberOfGuests: dialogState.numberOfGuests,
                      ),
                    );
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ),
      );

      if (result != null && result.confirmed) {
        // Show loading indicator using a more efficient approach
        final completer = Completer<String?>();
        
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: const Center(child: CircularProgressIndicator()),
          ),
        );

        // Create reservation asynchronously
        try {
          final now = DateTime.now();
          final reservation = Reservation(
            id: '',
            restaurantId: restaurant.id,
            userId: widget.userId,
            dateTime: result.dateTime,
            numberOfGuests: result.numberOfGuests,
            specialRequests: '',
            status: ReservationStatus.pending,
            createdAt: now,
            updatedAt: now,
          );
          
          // Use Future to handle the async operation
          final reservationId = await ref
              .read(reservationRepositoryProvider)
              .createReservation(reservation)
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  completer.completeError('Reservation timeout');
                  return null;
                },
              );
              
          completer.complete(reservationId);
        } catch (e) {
          completer.completeError(e.toString());
        }

        // Handle the result
        try {
          final reservationId = await completer.future;
          
          if (!mounted) return;
          Navigator.pop(context); // Close loading indicator

          if (reservationId != null && mounted) {
            // Show success dialog with optimized UI
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Reservation Confirmed!'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Date: ${result.dateTime.toString().split('.')[0]}'),
                          Text('Number of guests: ${result.numberOfGuests}'),
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Reservation ID generated',
                                style: TextStyle(color: Colors.green),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your reservation has been confirmed. You can view the details in your reservations page.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushReplacementNamed('/reservations');
                    },
                    child: const Text('View Reservations'),
                  ),
                ],
              ),
            );
          }
        } catch (e) {
          if (!mounted) return;
          Navigator.pop(context); // Close loading indicator
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 