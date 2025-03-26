import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../restaurant/domain/models/restaurant.dart';
import '../../../../main.dart';

class SwipeableRestaurantCard extends ConsumerStatefulWidget {
  final Restaurant restaurant;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const SwipeableRestaurantCard({
    Key? key,
    required this.restaurant,
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

  Future<void> _toggleRestaurantAvailability() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final repository = ref.read(restaurantRepositoryProvider);
      
      // Toggle the isActive status
      final updatedRestaurant = widget.restaurant.copyWith(
        isActive: !widget.restaurant.isActive,
        updatedAt: DateTime.now(),
      );
      
      // Update in Firestore
      await repository.updateRestaurant(updatedRestaurant);
      
      // Show success message
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.restaurant.isActive 
                ? 'Restaurant status changed to Inactive' 
                : 'Restaurant status changed to Active'
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Show error message
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
          width: 220, // Smaller fixed width but responsive layout inside
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
                // Image section - fixed ratio
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Restaurant image with error handling
                      _imageError || widget.restaurant.imageUrl == null || widget.restaurant.imageUrl!.isEmpty
                        ? Container(
                            color: Colors.blue.shade100,
                            child: const Icon(Icons.restaurant, size: 40, color: Colors.blue),
                          )
                        : Image.network(
                            widget.restaurant.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Set error state and show fallback
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
                            color: widget.restaurant.isActive ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.restaurant.isActive ? 'Active' : 'Inactive',
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
                
                // Fixed-height content area
                SizedBox(
                  height: 120,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Restaurant name - max 2 lines
                        Text(
                          widget.restaurant.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        
                        // Cuisine
                        Text(
                          widget.restaurant.cuisine,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        
                        // Location
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                widget.restaurant.address,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        
                        // Occupancy
                        if (widget.restaurant.currentOccupancy != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 2),
                                Text(
                                  'Occupancy: ${widget.restaurant.currentOccupancy}%',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                        // Vacancy
                        if (widget.restaurant.hasVacancy != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  widget.restaurant.hasVacancy! ? Icons.check_circle : Icons.cancel,
                                  size: 14,
                                  color: widget.restaurant.hasVacancy! ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  widget.restaurant.hasVacancy! ? 'Vacancy available' : 'No vacancy',
                                  style: TextStyle(
                                    color: widget.restaurant.hasVacancy! ? Colors.green : Colors.red,
                                    fontSize: 12,
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
                        onPressed: widget.restaurant.isActive ? () {
                          Navigator.of(context).pushReplacementNamed(
                            '/reservations',
                            arguments: {
                              'restaurantId': widget.restaurant.id,
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
                          Navigator.of(context).pushNamed('/restaurant/detail', arguments: widget.restaurant.id);
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
  }
} 