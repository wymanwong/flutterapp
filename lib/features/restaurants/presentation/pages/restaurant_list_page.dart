import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../providers/restaurant_provider.dart';
import 'restaurant_detail_page.dart';
import 'package:restaurant_availability_system/features/restaurants/presentation/widgets/restaurant_card.dart';
import 'package:restaurant_availability_system/features/restaurants/domain/models/restaurant.dart';

class RestaurantListPage extends ConsumerWidget {
  const RestaurantListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(activeRestaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Restaurants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filters
            },
          ),
        ],
      ),
      body: restaurantsAsync.when(
        data: (restaurants) {
          if (restaurants.isEmpty) {
            return const Center(
              child: Text('No restaurants available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RestaurantCard(restaurant: restaurant),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add restaurant page
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 