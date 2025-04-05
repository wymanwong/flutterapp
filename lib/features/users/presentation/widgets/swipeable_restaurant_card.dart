import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../restaurant/domain/models/restaurant.dart';
import '../../../restaurant/data/repositories/restaurant_repository.dart';
import '../../../restaurant/domain/utils/restaurant_utils.dart';

class SwipeableRestaurantCard extends ConsumerStatefulWidget {
  final String restaurantId;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const SwipeableRestaurantCard({
    Key? key,
    required this.restaurantId,
    required this.isFavorite,
    required this.onToggleFavorite,
  }) : super(key: key);

  @override
  ConsumerState<SwipeableRestaurantCard> createState() => _SwipeableRestaurantCardState();
}

class _SwipeableRestaurantCardState extends ConsumerState<SwipeableRestaurantCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  Offset _dragStartOffset = Offset.zero;
  double _dragX = 0;
  bool _isLoading = false;
  bool _imageError = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    _dragStartOffset = details.globalPosition;
    _dragX = 0;
    _animationController.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragX = details.globalPosition.dx - _dragStartOffset.dx;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    
    // Threshold for considering as swipe
    const threshold = 100.0;
    
    if (_dragX.abs() > threshold || velocity.abs() > 500) {
      // Swiped far enough or with enough velocity
      if (_dragX > 0) {
        // Swiped right - like
        _animationController.duration = const Duration(milliseconds: 200);
        _animation = Tween<Offset>(
          begin: Offset(_dragX / MediaQuery.of(context).size.width, 0),
          end: const Offset(1.5, 0),
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ));
        
        _animationController.forward().then((_) {
          if (!widget.isFavorite) {
            widget.onToggleFavorite();
          }
        });
      } else {
        // Swiped left - dislike
        _animationController.duration = const Duration(milliseconds: 200);
        _animation = Tween<Offset>(
          begin: Offset(_dragX / MediaQuery.of(context).size.width, 0),
          end: const Offset(-1.5, 0),
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ));
        
        _animationController.forward().then((_) {
          if (widget.isFavorite) {
            widget.onToggleFavorite();
          }
        });
      }
    } else {
      // Not swiped far enough, animate back
      _animationController.duration = const Duration(milliseconds: 200);
      _animation = Tween<Offset>(
        begin: Offset(_dragX / MediaQuery.of(context).size.width, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));
      
      _animationController.forward();
    }
  }

  Future<void> _toggleRestaurantAvailability(Restaurant currentRestaurant) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final repository = ref.read(restaurantRepositoryProvider);
      
      final updatedRestaurant = currentRestaurant.copyWith(
        isActive: !currentRestaurant.isActive,
        updatedAt: DateTime.now(),
      );
      
      await repository.updateRestaurant(updatedRestaurant);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentRestaurant.isActive 
                ? 'Restaurant status changed to Inactive' 
                : 'Restaurant status changed to Active'
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating restaurant: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the stream provider for the specific restaurant ID
    final restaurantAsyncValue = ref.watch(restaurantStreamProvider(widget.restaurantId));

    return restaurantAsyncValue.when(
      data: (restaurant) {
        // Handle case where restaurant data is null (e.g., deleted)
        if (restaurant == null) {
          return const Card(child: Center(child: Text('Restaurant not found')));
        }
        
        // Original Card Build Logic (using the fetched `restaurant`)
        return GestureDetector(
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: _animationController.isAnimating
                    ? Offset(_animation.value.dx * MediaQuery.of(context).size.width, 0)
                    : Offset(_dragX, 0),
                child: child,
              );
            },
            child: SizedBox(
              width: 220,
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 4.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image section
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Use restaurant.imageUrl
                          _imageError || restaurant.imageUrl == null || restaurant.imageUrl!.isEmpty
                            ? Container(
                                color: Colors.blue.shade100,
                                child: const Icon(Icons.restaurant, size: 40, color: Colors.blue),
                              )
                            : Image.network(
                                restaurant.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  Future.microtask(() => setState(() => _imageError = true));
                                  return Container(
                                    color: Colors.blue.shade100,
                                    child: const Icon(Icons.restaurant, size: 40, color: Colors.blue),
                                  );
                                },
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
                              ),
                          
                          // Favorite button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                iconSize: 20,
                                icon: Icon(
                                  widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: widget.isFavorite ? Colors.red : Colors.grey,
                                ),
                                onPressed: widget.onToggleFavorite,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ),
                          
                          // Swipe indicator
                          if (_dragX != 0)
                            Positioned.fill(
                              child: Opacity(
                                opacity: (_dragX.abs() / 100).clamp(0.0, 0.7),
                                child: Container(
                                  color: _dragX > 0 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                                  child: Center(
                                    child: Icon(
                                      _dragX > 0 ? Icons.favorite : Icons.close,
                                      color: Colors.white,
                                      size: 40 * (_dragX.abs() / 100).clamp(0.2, 1.0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                          // Availability indicator
                          Positioned(
                            top: 8,
                            left: 8,
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
                        ],
                      ),
                    ),
                    
                    // Content area
                    SizedBox(
                      height: 120,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Use restaurant.name, restaurant.cuisine, restaurant.address
                            Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14,), maxLines: 1, overflow: TextOverflow.ellipsis,),
                            const SizedBox(height: 2),
                            Text(restaurant.cuisine, style: TextStyle(color: Colors.grey.shade700, fontSize: 12,), maxLines: 1, overflow: TextOverflow.ellipsis,),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(restaurant.address, style: TextStyle(color: Colors.grey.shade600, fontSize: 12,), maxLines: 1, overflow: TextOverflow.ellipsis,),
                                ),
                              ],
                            ),
                            
                            // Occupancy
                            if (restaurant.currentOccupancy != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Occupancy: ${RestaurantUtils.formatOccupancyPercentage(restaurant)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                            // Vacancy status
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    RestaurantUtils.hasVacancy(restaurant) 
                                      ? Icons.check_circle 
                                      : Icons.error,
                                    size: 14,
                                    color: RestaurantUtils.hasVacancy(restaurant)
                                      ? Colors.green
                                      : Colors.red,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    RestaurantUtils.getOccupancyStatusText(restaurant),
                                    style: TextStyle(
                                      color: RestaurantUtils.hasVacancy(restaurant)
                                        ? Colors.green
                                        : Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Book button
                          ElevatedButton.icon(
                            onPressed: restaurant.isActive ? () {
                              Navigator.of(context).pushReplacementNamed(
                                '/reservations',
                                arguments: {
                                  'restaurantId': restaurant.id,
                                  'showDialog': true
                                }
                              );
                            } : null,
                            icon: const Icon(Icons.book_online, size: 14),
                            label: const Text('Reserve', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          
                          // Details button
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/restaurant/detail', arguments: restaurant.id);
                            },
                            icon: const Icon(Icons.info_outline, size: 14),
                            label: const Text('Details', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Card(child: Center(child: CircularProgressIndicator())), // Loading state
      error: (error, stackTrace) => Card(child: Center(child: Text('Error: $error'))), // Error state
    );
  }
} 