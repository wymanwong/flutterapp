import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../providers/restaurant_provider.dart';

class RestaurantDetailPage extends ConsumerStatefulWidget {
  final String restaurantId;

  const RestaurantDetailPage({
    super.key,
    required this.restaurantId,
  });

  @override
  ConsumerState<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends ConsumerState<RestaurantDetailPage> {
  @override
  Widget build(BuildContext context) {
    final restaurantAsync = ref.watch(restaurantProvider(widget.restaurantId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/restaurants/edit',
                arguments: widget.restaurantId,
              );
            },
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: restaurantAsync.isLoading,
        child: restaurantAsync.when(
          data: (restaurant) {
            if (restaurant == null) {
              return const Center(
                child: Text('Restaurant not found'),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      restaurant.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.restaurant,
                            size: 64,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          restaurant.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        _buildInfoSection(
                          context,
                          'Contact Information',
                          [
                            _buildInfoRow(
                              context,
                              Icons.location_on,
                              restaurant.address,
                            ),
                            _buildInfoRow(
                              context,
                              Icons.phone,
                              restaurant.phone,
                            ),
                            _buildInfoRow(
                              context,
                              Icons.email,
                              restaurant.email,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildInfoSection(
                          context,
                          'Capacity & Cuisine',
                          [
                            _buildInfoRow(
                              context,
                              Icons.people,
                              '${restaurant.capacity} seats',
                            ),
                            _buildInfoRow(
                              context,
                              Icons.restaurant_menu,
                              restaurant.cuisineTypes.join(', '),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildInfoSection(
                          context,
                          'Opening Hours',
                          restaurant.openingHours.entries.map((entry) {
                            return _buildInfoRow(
                              context,
                              Icons.access_time,
                              '${entry.key}: ${entry.value}',
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        _buildInfoSection(
                          context,
                          'Pricing',
                          restaurant.pricing.entries.map((entry) {
                            return _buildInfoRow(
                              context,
                              Icons.attach_money,
                              '${entry.key}: ${entry.value}',
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        _buildInfoSection(
                          context,
                          'Amenities',
                          restaurant.amenities.map((amenity) {
                            return _buildInfoRow(
                              context,
                              Icons.check_circle,
                              amenity,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        _buildInfoSection(
                          context,
                          'Status',
                          [
                            _buildInfoRow(
                              context,
                              restaurant.isActive
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              restaurant.isActive ? 'Active' : 'Inactive',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 