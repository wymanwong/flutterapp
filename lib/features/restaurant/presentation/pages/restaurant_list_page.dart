import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/repositories/restaurant_repository.dart';
import '../../domain/models/restaurant.dart';
import 'restaurant_form_page.dart';
import 'restaurant_detail_page.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../settings/data/localization/app_localizations.dart';

final restaurantsProvider = StreamProvider<List<Restaurant>>((ref) {
  final repository = ref.read(restaurantRepositoryProvider);
  return repository.getRestaurants();
});

class RestaurantListPage extends ConsumerStatefulWidget {
  const RestaurantListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RestaurantListPage> createState() => _RestaurantListPageState();
}

class _RestaurantListPageState extends ConsumerState<RestaurantListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyActive = true;
  bool _isSearchVisible = false;
  String _selectedFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToRestaurantForm({Restaurant? restaurant}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RestaurantFormPage(restaurant: restaurant),
      ),
    );
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  bool _filterRestaurant(Restaurant restaurant) {
    // First, apply the search query filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      if (!restaurant.name.toLowerCase().contains(query) &&
          !restaurant.cuisine.toLowerCase().contains(query) &&
          !restaurant.address.toLowerCase().contains(query)) {
        return false;
      }
    }
    
    // Then apply the status filter (All/Active/Inactive)
    if (_selectedFilter == 'Available' && !restaurant.isActive) {
      return false;
    }
    if (_selectedFilter == 'Unavailable' && restaurant.isActive) {
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final translations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(translations.translate('restaurants')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToDashboard,
        ),
        actions: [
          IconButton(
            icon: Icon(_showOnlyActive ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showOnlyActive = !_showOnlyActive;
              });
            },
            tooltip: _showOnlyActive ? translations.translate('show_all') : translations.translate('show_active_only'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
              });
            },
          ),
        ],
      ),
      drawer: _buildNavigationDrawer(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToRestaurantForm(),
        tooltip: translations.translate('add_restaurant'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_isSearchVisible)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: translations.translate('search_restaurants'),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, right: 4.0),
                    child: Text('Filter:'),
                  ),
                  FilterChip(
                    label: Text(translations.translate('all')),
                    selected: _selectedFilter == 'All',
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = 'All';
                      });
                    },
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    checkmarkColor: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(translations.translate('active')),
                    selected: _selectedFilter == 'Available',
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = 'Available';
                      });
                    },
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    checkmarkColor: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(translations.translate('inactive')),
                    selected: _selectedFilter == 'Unavailable',
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = 'Unavailable';
                      });
                    },
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    checkmarkColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: restaurantsAsync.when(
              data: (restaurants) {
                final filteredRestaurants = restaurants.where(_filterRestaurant).toList();

                if (filteredRestaurants.isEmpty) {
                  return Center(
                    child: Text(translations.translate('no_restaurants_found')),
                  );
                }

                return ListView.builder(
                  itemCount: filteredRestaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = filteredRestaurants[index];
                    return _buildRestaurantCard(restaurant);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    final translations = AppLocalizations.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantDetailPage(restaurant: restaurant),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  restaurant.imageUrl != null
                      ? Image.network(
                          restaurant.imageUrl!,
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
                      : Container(
                          color: Colors.blue.shade100,
                          child: const Center(
                            child: Icon(Icons.restaurant, size: 50, color: Colors.blue),
                          ),
                        ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: restaurant.isActive ? Colors.blue : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        restaurant.isActive ? translations.translate('active') : translations.translate('inactive'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Vacancy badge
                  if (restaurant.hasVacancy == true)
                    Positioned(
                      top: 12,
                      right: 12,
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildAvailabilityToggle(restaurant),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${translations.translate('cuisine')}: ${restaurant.cuisine}',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Theme.of(context).hintColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant.address,
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Theme.of(context).hintColor),
                      const SizedBox(width: 4),
                      Text(
                        '${translations.translate('capacity')}: ${restaurant.capacity}',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
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
                            'Occupancy: ${restaurant.getOccupancyPercentage().toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${restaurant.getAvailableSeats()} seats available',
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.book_online),
                        label: Text(translations.translate('reserve')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: restaurant.isActive ? () {
                          Navigator.of(context).pushReplacementNamed(
                            '/reservations',
                            arguments: {
                              'restaurantId': restaurant.id,
                              'showDialog': true
                            }
                          );
                        } : null,
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.info_outline),
                        label: Text(translations.translate('details')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestaurantDetailPage(restaurant: restaurant),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: translations.translate('edit_restaurant'),
                        onPressed: () => _navigateToRestaurantForm(restaurant: restaurant),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: translations.translate('delete_restaurant'),
                        onPressed: () => _showDeleteConfirmation(restaurant),
                      ),
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

  Widget _buildAvailabilityToggle(Restaurant restaurant) {
    final translations = AppLocalizations.of(context);
    
    return ElevatedButton(
      onPressed: () => _toggleRestaurantAvailability(restaurant),
      style: ElevatedButton.styleFrom(
        backgroundColor: restaurant.isActive ? Colors.red : Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(restaurant.isActive ? translations.translate('set_inactive') : translations.translate('set_active')),
    );
  }

  Future<void> _toggleRestaurantAvailability(Restaurant restaurant) async {
    try {
      final updatedRestaurant = restaurant.copyWith(
        isActive: !restaurant.isActive,
        updatedAt: DateTime.now(),
      );
      
      await ref.read(restaurantRepositoryProvider).updateRestaurant(updatedRestaurant);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            restaurant.isActive 
                ? 'Restaurant status changed to Inactive' 
                : 'Restaurant status changed to Active'
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating restaurant: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showDeleteConfirmation(Restaurant restaurant) {
    final translations = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${restaurant.name}?'),
        content: Text('This action cannot be undone. Are you sure you want to delete this restaurant?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(translations.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(restaurantRepositoryProvider).deleteRestaurant(restaurant.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${restaurant.name} deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting restaurant: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    final translations = AppLocalizations.of(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              translations.translate('restaurant_availability_system'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: Text(translations.translate('dashboard')),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant),
            title: Text(translations.translate('restaurants')),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_available),
            title: Text(translations.translate('reservations')),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reservations');
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: Text(translations.translate('analytics')),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/analytics');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(translations.translate('settings')),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
    );
  }
} 