import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../reservations/data/repositories/reservation_repository.dart';
import '../../../reservations/domain/models/reservation.dart';
import '../../../restaurant/data/repositories/restaurant_repository.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 4; // Analytics index
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();
  String _timeframe = 'week';
  bool _isLoading = false;
  Map<String, int> _dailyReservations = {};
  int _totalReservations = 0;
  double _averageOccupancy = 0;
  int _totalRestaurants = 0;
  
  final _dateFormat = DateFormat('MMMM d, yyyy');
  final _shortDateFormat = DateFormat('MMM d');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  void _changeTimeframe(String timeframe) {
    setState(() {
      _timeframe = timeframe;
      
      switch (timeframe) {
        case 'day':
          _startDate = DateTime.now();
          _endDate = DateTime.now();
          break;
        case 'week':
          _startDate = DateTime.now().subtract(const Duration(days: 6));
          _endDate = DateTime.now();
          break;
        case 'month':
          _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
          _endDate = DateTime.now();
          break;
        case 'quarter':
          _startDate = DateTime.now().subtract(const Duration(days: 90));
          _endDate = DateTime.now();
          break;
        case 'year':
          _startDate = DateTime(DateTime.now().year, 1, 1);
          _endDate = DateTime.now();
          break;
      }
      
      _loadAnalyticsData();
    });
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get daily reservation counts
      final dailyData = await ref
          .read(reservationRepositoryProvider)
          .getDailyReservationsCount(_startDate, _endDate);
      
      // Get total reservations
      final totalReservations = await ref
          .read(reservationRepositoryProvider)
          .getReservationsCount();
      
      // Get restaurant count
      final restaurants = await ref
          .read(restaurantRepositoryProvider)
          .getRestaurantsCount();
      
      // Calculate average occupancy (this would be more complex in a real system)
      // Here we're just using a placeholder calculation
      final averageOccupancy = restaurants > 0 ? (totalReservations / restaurants) * 0.25 : 0.0;
      
      setState(() {
        _dailyReservations = dailyData;
        _totalReservations = totalReservations;
        _totalRestaurants = restaurants;
        _averageOccupancy = averageOccupancy;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<FlSpot> _getReservationSpots() {
    final List<FlSpot> spots = [];
    final dayCount = _endDate.difference(_startDate).inDays + 1;
    
    // Create a date range of days
    for (int i = 0; i < dayCount; i++) {
      final date = _startDate.add(Duration(days: i));
      final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final count = _dailyReservations[dayKey] ?? 0;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }
    
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        centerTitle: true,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Reservations'),
            Tab(text: 'Restaurants'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildReservationsTab(),
                _buildRestaurantsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeframeSelector(),
          const SizedBox(height: 16),
          Text(
            'Analytics Overview: ${_dateFormat.format(_startDate)} - ${_dateFormat.format(_endDate)}',
            style: const TextStyle(
              fontSize: 18,
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
                title: 'Total Reservations',
                value: _totalReservations.toString(),
                icon: Icons.book_online,
                color: Colors.blue,
              ),
              _buildStatCard(
                title: 'Average Occupancy',
                value: '${(_averageOccupancy * 100).toStringAsFixed(1)}%',
                icon: Icons.people,
                color: Colors.green,
              ),
              _buildStatCard(
                title: 'Total Restaurants',
                value: _totalRestaurants.toString(),
                icon: Icons.restaurant,
                color: Colors.orange,
              ),
              _buildStatCard(
                title: 'Active Hours',
                value: '6pm - 9pm',
                icon: Icons.access_time,
                color: Colors.purple,
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
                  const Text(
                    'Reservations by Day',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: _buildReservationsChart(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeframeSelector(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reservation Status Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: 45,
                            title: 'Confirmed',
                            color: Colors.green,
                            radius: 80,
                          ),
                          PieChartSectionData(
                            value: 25,
                            title: 'Pending',
                            color: Colors.orange,
                            radius: 80,
                          ),
                          PieChartSectionData(
                            value: 15,
                            title: 'Completed',
                            color: Colors.blue,
                            radius: 80,
                          ),
                          PieChartSectionData(
                            value: 10,
                            title: 'Cancelled',
                            color: Colors.red,
                            radius: 80,
                          ),
                          PieChartSectionData(
                            value: 5,
                            title: 'No-Show',
                            color: Colors.purple,
                            radius: 80,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reservations by Time of Day',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 20,
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const times = ['12pm', '2pm', '4pm', '6pm', '8pm', '10pm'];
                                if (value.toInt() < 0 || value.toInt() >= times.length) {
                                  return const Text('');
                                }
                                return Text(times[value.toInt()]);
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(toY: 8, color: Colors.blue),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(toY: 10, color: Colors.blue),
                            ],
                          ),
                          BarChartGroupData(
                            x: 2,
                            barRods: [
                              BarChartRodData(toY: 14, color: Colors.blue),
                            ],
                          ),
                          BarChartGroupData(
                            x: 3,
                            barRods: [
                              BarChartRodData(toY: 18, color: Colors.blue),
                            ],
                          ),
                          BarChartGroupData(
                            x: 4,
                            barRods: [
                              BarChartRodData(toY: 16, color: Colors.blue),
                            ],
                          ),
                          BarChartGroupData(
                            x: 5,
                            barRods: [
                              BarChartRodData(toY: 7, color: Colors.blue),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeframeSelector(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Restaurants by Reservations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 40,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.blueGrey,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              const restaurants = ['La Piazza', 'The Garden', 'Ocean Blue', 'Fire & Spice', 'Sakura'];
                              return BarTooltipItem(
                                '${restaurants[groupIndex]}\n${rod.toY.round()} reservations',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const restaurants = ['La Piazza', 'The Garden', 'Ocean Blue', 'Fire & Spice', 'Sakura'];
                                if (value.toInt() < 0 || value.toInt() >= restaurants.length) {
                                  return const Text('');
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: RotatedBox(
                                    quarterTurns: 1,
                                    child: Text(
                                      restaurants[value.toInt()],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 80,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            axisNameWidget: const Text(
                              'Number of Reservations',
                              style: TextStyle(fontSize: 12),
                            ),
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 10,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade200,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                            left: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                        ),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: 35,
                                color: Colors.orange.shade400,
                                width: 20,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: 28,
                                color: Colors.orange.shade400,
                                width: 20,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 2,
                            barRods: [
                              BarChartRodData(
                                toY: 22,
                                color: Colors.orange.shade400,
                                width: 20,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 3,
                            barRods: [
                              BarChartRodData(
                                toY: 19,
                                color: Colors.orange.shade400,
                                width: 20,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 4,
                            barRods: [
                              BarChartRodData(
                                toY: 15,
                                color: Colors.orange.shade400,
                                width: 20,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                        'Current Occupancy by Restaurant',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people, size: 16, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Live Data',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: LineChart(
                      LineChartData(
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: Colors.blueGrey,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                const restaurants = ['La Piazza', 'The Garden', 'Ocean Blue', 'Fire & Spice', 'Sakura'];
                                return LineTooltipItem(
                                  '${restaurants[spot.x.toInt()]}\n${spot.y.toStringAsFixed(0)}% occupied',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 20,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade200,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const restaurants = ['La Piazza', 'The Garden', 'Ocean Blue', 'Fire & Spice', 'Sakura'];
                                if (value.toInt() < 0 || value.toInt() >= restaurants.length) {
                                  return const Text('');
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: RotatedBox(
                                    quarterTurns: 1,
                                    child: Text(
                                      restaurants[value.toInt()],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 80,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            axisNameWidget: const Text(
                              'Occupancy (%)',
                              style: TextStyle(fontSize: 12),
                            ),
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: 20,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}%',
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                            left: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                        ),
                        minX: 0,
                        maxX: 4,
                        minY: 0,
                        maxY: 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 85),
                              FlSpot(1, 65),
                              FlSpot(2, 90),
                              FlSpot(3, 75),
                              FlSpot(4, 70),
                            ],
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 6,
                                  color: Colors.white,
                                  strokeWidth: 3,
                                  strokeColor: spot.y >= 80 ? Colors.red : 
                                             spot.y >= 60 ? Colors.orange : Colors.green,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withOpacity(0.1),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.green.withOpacity(0.2),
                                  Colors.green.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(
                        color: Colors.red,
                        label: 'High Occupancy',
                        value: '≥ 80%',
                      ),
                      const SizedBox(width: 24),
                      _buildLegendItem(
                        color: Colors.orange,
                        label: 'Medium Occupancy',
                        value: '60-79%',
                      ),
                      const SizedBox(width: 24),
                      _buildLegendItem(
                        color: Colors.green,
                        label: 'Low Occupancy',
                        value: '< 60%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Time Period',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTimeframeChip('day', 'Day', Icons.today),
                      _buildTimeframeChip('week', 'Week', Icons.view_week),
                      _buildTimeframeChip('month', 'Month', Icons.calendar_view_month),
                      _buildTimeframeChip('quarter', 'Quarter', Icons.date_range),
                      _buildTimeframeChip('year', 'Year', Icons.calendar_today),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primaryContainer,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_dateFormat.format(_startDate)} - ${_dateFormat.format(_endDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeChip(String value, String label, IconData icon) {
    final isSelected = _timeframe == value;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _changeTimeframe(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationsChart() {
    final spots = _getReservationSpots();
    if (spots.isEmpty) {
      return const Center(child: Text('No reservation data available'));
    }
    
    // Calculate max Y for the chart
    double maxY = 0;
    for (var spot in spots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    maxY = maxY < 5 ? 5 : (maxY * 1.2); // Add some space at the top

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final dayIndex = value.toInt();
                if (dayIndex < 0 || dayIndex >= spots.length) {
                  return const Text('');
                }
                
                final date = _startDate.add(Duration(days: dayIndex));
                return Text(
                  _shortDateFormat.format(date),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
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
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
} 