import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../restaurant/data/repositories/restaurant_repository.dart';
import '../../../restaurant/domain/models/restaurant.dart';
import '../../../settings/data/localization/app_localizations.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../domain/models/reservation.dart';
import 'reservation_form_page.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../auth/domain/models/user.dart';

class ReservationsListPage extends ConsumerStatefulWidget {
  const ReservationsListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ReservationsListPage> createState() => _ReservationsListPageState();
}

class _ReservationsListPageState extends ConsumerState<ReservationsListPage> {
  // Selected index for navigation
  int _selectedIndex = 2;
  
  // Filter state
  bool _showRestaurantFilter = false;
  String? _selectedRestaurantId;
  
  // Reservations data
  bool _isLoading = true;
  List<Reservation> _allReservations = [];
  List<Reservation> _filteredReservations = [];
  
  // New reservation dialog state
  bool _hasShownReservationDialog = false;

  // Get current user ID from auth state provider
  String? get currentUserId {
    final user = ref.watch(currentUserProvider);
    return user?.id;
  }

  @override
  void initState() {
    super.initState();
    // No need to load reservations here as we'll use a stream
  }

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) return;

    final routes = [
      '/dashboard',
      '/restaurants',
      '/reservations',
      '/users',
      '/analytics',
      '/settings',
    ];

    if (index >= 0 && index < routes.length) {
      Navigator.of(context).pushReplacementNamed(routes[index]);
    }
  }

  Future<void> _refreshReservations() async {
    // This will re-trigger the stream
    setState(() {});
    return Future.value();
  }

  void _showNewReservationDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ReservationFormPage(),
      ),
    ).then((_) {
      _refreshReservations();
    });
  }

  void _editReservation(Reservation reservation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReservationFormPage(reservation: reservation),
      ),
    ).then((_) {
      _refreshReservations();
    });
  }

  Future<void> _confirmStatusChange(
    Reservation reservation,
    ReservationStatus newStatus,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Status to ${newStatus.toString().split('.').last}?'),
        content: Text('Are you sure you want to change this reservation status?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final updatedReservation = reservation.copyWith(status: newStatus);
        await ref.read(reservationRepositoryProvider).updateReservation(updatedReservation);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reservation status updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating reservation: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(Reservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reservation?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(reservationRepositoryProvider).deleteReservation(reservation.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reservation deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting reservation: $e')),
          );
        }
      }
    }
  }

  void _toggleFavorite(String restaurantId) async {
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) {
      _showLoginPrompt();
      return;
    }

    try {
      await ref.read(restaurantRepositoryProvider).toggleFavoriteRestaurant(
        userId,
        restaurantId,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: FutureBuilder<bool>(
            future: ref.read(restaurantRepositoryProvider).isFavoriteRestaurant(
              userId,
              restaurantId,
            ),
            builder: (context, snapshot) {
              final isFavorite = snapshot.data ?? false;
              return Text(
                isFavorite
                    ? 'Added to favorites'
                    : 'Removed from favorites',
              );
            },
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update favorites'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLoginPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please sign in to add favorites'),
        action: SnackBarAction(
          label: 'Sign In',
          onPressed: () => Navigator.of(context).pushNamed('/login'),
        ),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushNamed('/login');
  }

  // Show status options in a bottom sheet
  void _showStatusOptionsMenu(BuildContext context, Reservation reservation) {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Update Reservation Status',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(),
            // Show Confirm option only for pending reservations
            if (reservation.status == ReservationStatus.pending)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                title: const Text('Confirm Reservation'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _confirmStatusChange(reservation, ReservationStatus.confirmed);
                },
              ),
            
            // Show Complete option for pending or confirmed reservations
            if (reservation.status == ReservationStatus.pending || 
                reservation.status == ReservationStatus.confirmed)
              ListTile(
                leading: const Icon(Icons.done_all, color: Colors.blue, size: 28),
                title: const Text('Mark as Completed'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _confirmStatusChange(reservation, ReservationStatus.completed);
                },
              ),
            
            // Show No-Show option for pending or confirmed reservations
            if (reservation.status == ReservationStatus.pending || 
                reservation.status == ReservationStatus.confirmed)
              ListTile(
                leading: const Icon(Icons.person_off, color: Colors.purple, size: 28),
                title: const Text('Mark as No-Show'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _confirmStatusChange(reservation, ReservationStatus.noShow);
                },
              ),
            
            // Show Cancel option for pending or confirmed reservations
            if (reservation.status == ReservationStatus.pending || 
                reservation.status == ReservationStatus.confirmed)
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.orange, size: 28),
                title: const Text('Cancel Reservation'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _confirmStatusChange(reservation, ReservationStatus.cancelled);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildStatusChip(ReservationStatus status) {
    Color chipColor;
    String statusText;
    
    switch (status) {
      case ReservationStatus.pending:
        chipColor = Colors.orange;
        statusText = 'Pending';
        break;
      case ReservationStatus.confirmed:
        chipColor = Colors.green;
        statusText = 'Confirmed';
        break;
      case ReservationStatus.cancelled:
        chipColor = Colors.red;
        statusText = 'Cancelled';
        break;
      case ReservationStatus.completed:
        chipColor = Colors.blue;
        statusText = 'Completed';
        break;
      case ReservationStatus.noShow:
        chipColor = Colors.purple;
        statusText = 'No-Show';
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(left: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservationsStream = ref.watch(reservationRepositoryProvider).getReservations();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filtering logic
            },
            tooltip: 'Filter by Restaurant',
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        elevation: 1,
        backgroundColor: Theme.of(context).colorScheme.surface,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.restaurant,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Restaurant System',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
              ],
            ),
          ),
          NavigationDrawerDestination(
            icon: Icon(
              Icons.dashboard,
              color: _selectedIndex == 0 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            label: Text(
              'Dashboard',
              style: TextStyle(
                color: _selectedIndex == 0 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          NavigationDrawerDestination(
            icon: Icon(
              Icons.restaurant_menu,
              color: _selectedIndex == 1 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            label: Text(
              'Restaurants',
              style: TextStyle(
                color: _selectedIndex == 1 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          NavigationDrawerDestination(
            icon: Icon(
              Icons.book_online,
              color: _selectedIndex == 2 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            label: Text(
              'Reservations',
              style: TextStyle(
                color: _selectedIndex == 2 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          NavigationDrawerDestination(
            icon: Icon(
              Icons.people,
              color: _selectedIndex == 3 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            label: Text(
              'Users',
              style: TextStyle(
                color: _selectedIndex == 3 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          NavigationDrawerDestination(
            icon: Icon(
              Icons.analytics,
              color: _selectedIndex == 4 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            label: Text(
              'Analytics',
              style: TextStyle(
                color: _selectedIndex == 4 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Divider(height: 1),
          ),
          NavigationDrawerDestination(
            icon: Icon(
              Icons.settings,
              color: _selectedIndex == 5 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            label: Text(
              'Settings',
              style: TextStyle(
                color: _selectedIndex == 5 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Reservation>>(
        stream: reservationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reservations = snapshot.data ?? [];
          
          if (reservations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No reservations found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Create a new reservation to get started'),
                ],
              ),
            );
          }

          // Sort reservations by date
          final today = DateTime.now();
          final upcomingReservations = reservations
              .where((r) => r.dateTime.isAfter(today))
              .toList()
              ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
          
          final pastReservations = reservations
              .where((r) => r.dateTime.isBefore(today))
              .toList()
              ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

          // Calculate statistics
          final totalReservations = reservations.length;
          final confirmedReservations = reservations
              .where((r) => r.status == ReservationStatus.confirmed)
              .length;
          final pendingReservations = reservations
              .where((r) => r.status == ReservationStatus.pending)
              .length;
          final cancelledReservations = reservations
              .where((r) => r.status == ReservationStatus.cancelled)
              .length;
          final completedReservations = reservations
              .where((r) => r.status == ReservationStatus.completed)
              .length;
          final noShowReservations = reservations
              .where((r) => r.status == ReservationStatus.noShow)
              .length;
          
          // Calculate total guests
          final totalGuests = reservations.fold<int>(
            0, 
            (sum, reservation) => sum + reservation.numberOfGuests
          );
          
          // Calculate average guests per reservation
          final avgGuestsPerReservation = totalReservations > 0 
              ? (totalGuests / totalReservations).toStringAsFixed(1)
              : '0';

          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              // Statistics Panel
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reservation Statistics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total',
                            totalReservations.toString(),
                            Icons.calendar_today,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Confirmed',
                            confirmedReservations.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Pending',
                            pendingReservations.toString(),
                            Icons.schedule,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Guests',
                            totalGuests.toString(),
                            Icons.people,
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Avg Guests',
                            avgGuestsPerReservation,
                            Icons.person,
                            Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'No Shows',
                            noShowReservations.toString(),
                            Icons.person_off,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              if (upcomingReservations.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Upcoming Reservations',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...upcomingReservations.map((reservation) => 
                  _buildReservationCard(reservation)),
                const Divider(height: 32),
              ],
              
              if (pastReservations.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Past Reservations',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...pastReservations.map((reservation) => 
                  _buildReservationCard(reservation)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewReservationDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add Reservation',
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final today = DateTime.now();
    final isUpcoming = reservation.dateTime.isAfter(today);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant name and guest name row
                  Row(
                    children: [
                      FutureBuilder<Restaurant?>(
                        future: ref.read(restaurantRepositoryProvider).getRestaurantById(reservation.restaurantId),
                        builder: (context, snapshot) {
                          final restaurant = snapshot.data;
                          if (restaurant == null) {
                            return const Text(
                              'Loading...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            );
                          }
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                restaurant.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (currentUserId != null)
                                StreamBuilder<List<String>>(
                                  stream: ref.watch(restaurantRepositoryProvider).getFavoriteRestaurantIds(currentUserId!),
                                  builder: (context, favSnapshot) {
                                    if (favSnapshot.connectionState == ConnectionState.waiting) {
                                      return const SizedBox();
                                    }
                                    
                                    final isFavorite = favSnapshot.data?.contains(restaurant.id) ?? false;
                                    if (!isFavorite) return const SizedBox();
                                    
                                    return const Icon(
                                      Icons.favorite,
                                      size: 14,
                                      color: Colors.red,
                                    );
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                      const Text(' • ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        reservation.guestInfo?['name'] ?? 'Guest',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dateFormat.format(reservation.dateTime)} at ${timeFormat.format(reservation.dateTime)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            // Status chip
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showStatusOptionsMenu(context, reservation),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: _buildStatusChip(reservation.status),
              ),
            ),
          ],
        ),
        // Action buttons - improved spacing and hitbox size
        trailing: SizedBox(
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Edit button
              Material(
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _editReservation(reservation),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.edit, color: Colors.blue),
                  ),
                ),
              ),
              
              // Delete button
              Material(
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _confirmDelete(reservation),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.delete, color: Colors.red),
                  ),
                ),
              ),
              
              // More options button
              Material(
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _showStatusOptionsMenu(context, reservation),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.more_vert),
                  ),
                ),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<Restaurant?>(
              future: ref.read(restaurantRepositoryProvider).getRestaurantById(reservation.restaurantId),
              builder: (context, snapshot) {
                final restaurant = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (restaurant != null) ...[
                      Row(
                        children: [
                          if (restaurant.cuisine.isNotEmpty)
                            Expanded(
                              child: Text('Cuisine: ${restaurant.cuisine}'),
                            ),
                          // Favorite toggle
                          if (currentUserId != null)
                            StreamBuilder<List<String>>(
                              stream: ref.watch(restaurantRepositoryProvider).getFavoriteRestaurantIds(currentUserId!),
                              builder: (context, favSnapshot) {
                                if (favSnapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                }
                                
                                final isFavorite = favSnapshot.data?.contains(restaurant.id) ?? false;
                                return Material(
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () => _toggleFavorite(restaurant.id),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: Colors.red,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      if (restaurant.address.isNotEmpty)
                        Text('Address: ${restaurant.address}'),
                      if (restaurant.phoneNumber.isNotEmpty)
                        Text('Phone: ${restaurant.phoneNumber}'),
                      const SizedBox(height: 8),
                    ],
                    Text('Guests: ${reservation.numberOfGuests}'),
                    if (reservation.specialRequests.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Special Requests: ${reservation.specialRequests}'),
                    ],
                    const SizedBox(height: 4),
                    Text('Last Updated: ${dateFormat.format(reservation.updatedAt)}'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
} 