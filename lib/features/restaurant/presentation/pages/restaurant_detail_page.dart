import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/restaurant.dart';
import '../../../settings/data/localization/app_localizations.dart';
import 'restaurant_form_page.dart';

class RestaurantDetailPage extends ConsumerWidget {
  final Restaurant restaurant;

  const RestaurantDetailPage({Key? key, required this.restaurant}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Restaurant',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RestaurantFormPage(restaurant: restaurant),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (restaurant.imageUrl != null && restaurant.imageUrl!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 200,
                child: Image.network(
                  restaurant.imageUrl!,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.restaurant, size: 64, color: Colors.black45),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
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
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: Text(translations.translate('edit_restaurant')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RestaurantFormPage(restaurant: restaurant),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle(translations.translate('basic_information')),
                  _buildInfoItem(Icons.restaurant, translations.translate('cuisine'), restaurant.cuisine),
                  _buildInfoItem(Icons.location_on, translations.translate('address'), restaurant.address),
                  _buildInfoItem(Icons.phone, translations.translate('phone'), restaurant.phoneNumber),
                  _buildInfoItem(Icons.email, translations.translate('email'), restaurant.email),
                  _buildInfoItem(Icons.people, translations.translate('capacity'), restaurant.capacity.toString()),
                  
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle('Vacancy Information'),
                  _buildInfoItem(
                    Icons.people_alt, 
                    'Current Occupancy', 
                    '${restaurant.currentOccupancy} / ${restaurant.capacity} (${restaurant.getOccupancyPercentage().toStringAsFixed(1)}%)'
                  ),
                  _buildInfoItem(
                    Icons.event_seat,
                    'Available Seats',
                    '${restaurant.getAvailableSeats()} seats available'
                  ),
                  _buildInfoItem(
                    Icons.timer, 
                    'Wait Time', 
                    '${restaurant.waitTime} minutes'
                  ),
                  _buildInfoItem(
                    Icons.chair, 
                    'Has Vacancy', 
                    restaurant.hasVacancy ? 'Yes' : 'No'
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle(translations.translate('opening_hours')),
                  _buildBusinessHoursTable(restaurant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _calculateOccupancyPercentage(Restaurant restaurant) {
    if (restaurant.capacity == 0) return '0';
    final percentage = (restaurant.currentOccupancy / restaurant.capacity * 100).toStringAsFixed(1);
    return percentage;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessHoursTable(Restaurant restaurant) {
    return Table(
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 1,
        borderRadius: BorderRadius.circular(8),
      ),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(4),
      },
      children: restaurant.openingHours.entries.map((entry) {
        return TableRow(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(entry.value),
            ),
          ],
        );
      }).toList(),
    );
  }
} 