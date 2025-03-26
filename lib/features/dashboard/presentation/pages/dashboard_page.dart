import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'dart:async'; // Add import for StreamSubscription
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../reservations/data/repositories/reservation_repository.dart';
import '../../../reservations/domain/models/reservation.dart';
import '../../../restaurant/data/repositories/restaurant_repository.dart';
import '../../../settings/data/localization/app_localizations.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedIndex = 0; // Dashboard index
  bool _isLoading = true;
  int _totalReservations = 0;
  int _activeRestaurants = 0;
  int _totalRestaurants = 0;
  double _occupancyRate = 0;
  double _dailyRevenue = 0;
  
  final _timeFormat = DateFormat('h:mm a');
  final _dateFormat = DateFormat('MMM d, yyyy');
  
  // Add a variable to store subscription
  StreamSubscription? _restaurantsSubscription;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  @override
  void dispose() {
    // Cancel subscription when widget is disposed
    _restaurantsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Setup repository
      final restaurantRepo = ref.read(restaurantRepositoryProvider);
      final reservationRepo = ref.read(reservationRepositoryProvider);
      
      // Get restaurant stream to listen for real-time changes
      _restaurantsSubscription = restaurantRepo.getRestaurants().listen((restaurants) {
        if (mounted) {
          setState(() {
            _totalRestaurants = restaurants.length;
            _activeRestaurants = restaurants.where((r) => r.isActive).length;
            
            // Calculate occupancy (based on active restaurants)
            int totalCapacity = 0;
            for (final restaurant in restaurants) {
              if (restaurant.isActive) {
                totalCapacity += restaurant.capacity;
              }
            }
            
            // Calculate current occupancy based on current occupancy field
            double averageOccupancy = 0;
            int restaurantsWithOccupancy = 0;
            for (final restaurant in restaurants) {
              if (restaurant.isActive && restaurant.currentOccupancy != null) {
                averageOccupancy += restaurant.currentOccupancy!;
                restaurantsWithOccupancy++;
              }
            }
            
            if (restaurantsWithOccupancy > 0) {
              _occupancyRate = averageOccupancy / restaurantsWithOccupancy;
            } else {
              _occupancyRate = 0;
            }
            
            _isLoading = false;
          });
        }
      });
      
      // Get reservation count
      final reservationsCountFuture = reservationRepo.getReservationsCount();
      reservationsCountFuture.then((count) {
        if (mounted) {
          setState(() {
            _totalReservations = count;
            // Calculate estimated revenue (simplified)
            _dailyRevenue = count * 45.75; // Assumes average spend of $45.75 per reservation
          });
        }
      });
      
    } catch (e) {
      developer.log('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  void _navigateToRestaurants() {
    Navigator.of(context).pushReplacementNamed('/restaurants');
  }

  void _navigateToVipProfile() {
    Navigator.of(context).pushReplacementNamed('/vip_profile');
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    
    // Stream of recent reservations
    final recentReservationsStream = ref
        .watch(reservationRepositoryProvider)
        .getRecentReservations(limit: 5);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(translations.translate('dashboard')),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: translations.translate('vip_profile'),
            onPressed: _navigateToVipProfile,
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        children: [
          NavigationDrawerDestination(
            icon: const Icon(Icons.dashboard),
            label: Text(translations.translate('dashboard')),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.restaurant),
            label: Text(translations.translate('restaurants')),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.book_online),
            label: Text(translations.translate('reservations')),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.people),
            label: Text(translations.translate('users')),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.analytics),
            label: Text(translations.translate('analytics')),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.settings),
            label: Text(translations.translate('settings')),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translations.translate('overview'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        title: translations.translate('total_reservations'),
                        value: _totalReservations.toString(),
                        icon: Icons.book_online,
                        color: Colors.blue,
                        onTap: () => Navigator.of(context).pushReplacementNamed('/reservations'),
                      ),
                      _buildStatCard(
                        title: translations.translate('current_occupancy'),
                        value: '${_occupancyRate.toStringAsFixed(1)}%',
                        icon: Icons.people,
                        color: Colors.blue.shade700,
                        onTap: () => Navigator.of(context).pushReplacementNamed('/analytics'),
                      ),
                      _buildStatCard(
                        title: translations.translate('today_revenue'),
                        value: '\$${_dailyRevenue.toStringAsFixed(2)}',
                        icon: Icons.attach_money,
                        color: Colors.blue.shade300,
                        onTap: () => Navigator.of(context).pushReplacementNamed('/analytics'),
                      ),
                      _buildStatCard(
                        title: translations.translate('active_restaurants'),
                        value: _activeRestaurants.toString(),
                        icon: Icons.restaurant,
                        color: Colors.blue.shade500,
                        onTap: _navigateToRestaurants,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Hourly Occupancy',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pushReplacementNamed('/analytics'),
                                child: const Text('View Details'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Hours (x) vs Occupancy % (y)',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 220,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.shade200,
                                      strokeWidth: 1,
                                    );
                                  },
                                  getDrawingVerticalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.shade200,
                                      strokeWidth: 1,
                                    );
                                  },
                                  horizontalInterval: 25,
                                  verticalInterval: 3,
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 24,
                                      interval: 3,
                                      getTitlesWidget: (value, meta) {
                                        // Only show key meal times
                                        if (value == 9) return const Text('9AM');
                                        if (value == 12) return const Text('Noon');
                                        if (value == 15) return const Text('3PM');
                                        if (value == 18) return const Text('6PM');
                                        if (value == 21) return const Text('9PM');
                                        return const Text('');
                                      }
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 25,
                                      reservedSize: 28,
                                      getTitlesWidget: (value, meta) {
                                        if (value == 0) return const Text('0%');
                                        if (value == 50) return const Text('50%');
                                        if (value == 100) return const Text('100%');
                                        return const Text('');
                                      }
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                                    left: BorderSide(color: Colors.grey.shade300, width: 1),
                                    right: BorderSide(color: Colors.grey.shade100, width: 0),
                                    top: BorderSide(color: Colors.grey.shade100, width: 0),
                                  )
                                ),
                                minX: 8,  // Start at 8AM
                                maxX: 23, // End at 11PM
                                minY: 0,
                                maxY: 100,
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    tooltipBgColor: Colors.blueAccent.withOpacity(0.8),
                                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        int hour = spot.x.toInt();
                                        String time = hour < 12 
                                            ? '${hour}AM' 
                                            : '${hour == 12 ? 12 : hour - 12}PM';
                                        return LineTooltipItem(
                                          '$time: ${spot.y.toInt()}%',
                                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        );
                                      }).toList();
                                    }
                                  ),
                                  handleBuiltInTouches: true,
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: const [
                                      FlSpot(9, 30),   // 9AM - 30%
                                      FlSpot(11, 25),  // 11AM - 25%
                                      FlSpot(12, 65),  // 12PM - 65%
                                      FlSpot(13, 90),  // 1PM - 90%
                                      FlSpot(14, 85),  // 2PM - 85%
                                      FlSpot(15, 50),  // 3PM - 50%
                                      FlSpot(17, 40),  // 5PM - 40%
                                      FlSpot(18, 75),  // 6PM - 75%
                                      FlSpot(19, 95),  // 7PM - 95%
                                      FlSpot(20, 90),  // 8PM - 90%
                                      FlSpot(21, 70),  // 9PM - 70%
                                      FlSpot(22, 40),  // 10PM - 40%
                                    ],
                                    isCurved: true,
                                    curveSmoothness: 0.3,
                                    color: Colors.blue.shade500,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (spot, percent, barData, index) {
                                        // Highlight peak times
                                        bool isPeak = [13, 19].contains(spot.x.toInt());
                                        return FlDotCirclePainter(
                                          radius: isPeak ? 5 : 3,
                                          color: isPeak ? Colors.redAccent : Colors.blue.shade500,
                                          strokeWidth: 1.5,
                                          strokeColor: Colors.white,
                                        );
                                      },
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade300.withOpacity(0.5),
                                          Colors.blue.shade300.withOpacity(0.0),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                    shadow: const Shadow(
                                      blurRadius: 5,
                                      color: Colors.black12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Reservations',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pushReplacementNamed('/reservations'),
                                child: const Text('View All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<List<Reservation>>(
                            stream: recentReservationsStream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  heightFactor: 3,
                                  child: CircularProgressIndicator(),
                                );
                              }
                              
                              if (snapshot.hasError) {
                                return Center(
                                  heightFactor: 2,
                                  child: Text('Error: ${snapshot.error}'),
                                );
                              }
                              
                              final reservations = snapshot.data ?? [];
                              
                              if (reservations.isEmpty) {
                                return const Center(
                                  heightFactor: 2,
                                  child: Text('No upcoming reservations'),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: reservations.length,
                                itemBuilder: (context, index) {
                                  final reservation = reservations[index];
                                  final reservationTime = _timeFormat.format(reservation.dateTime);
                                  
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getStatusColor(reservation.status),
                                      child: Text('${reservation.numberOfGuests}'),
                                    ),
                                    title: Text('Res. #${reservation.id.substring(0, 6)}'),
                                    subtitle: Text('${reservation.status.name} • ${reservation.numberOfGuests} Guests'),
                                    trailing: Text(reservationTime),
                                    onTap: () => Navigator.of(context).pushReplacementNamed('/reservations'),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushReplacementNamed('/reservations'),
        icon: const Icon(Icons.add),
        label: const Text('New Reservation'),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Colors.blue.shade300;
      case ReservationStatus.confirmed:
        return Colors.blue.shade700;
      case ReservationStatus.cancelled:
        return Colors.red;
      case ReservationStatus.completed:
        return Colors.blue;
      case ReservationStatus.noShow:
        return Colors.purple;
    }
  }
} 