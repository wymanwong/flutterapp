import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/review.dart';
import '../../data/repositories/review_repository.dart';
import '../../../notifications/services/notification_service.dart';

class AddReviewForm extends ConsumerStatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String restaurantOwnerId;
  final Function onReviewAdded;

  const AddReviewForm({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantOwnerId,
    required this.onReviewAdded,
  }) : super(key: key);

  @override
  ConsumerState<AddReviewForm> createState() => _AddReviewFormState();
}

class _AddReviewFormState extends ConsumerState<AddReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_formKey.currentState!.validate() && _rating > 0) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // In a real app, these would come from the auth service
        const userId = 'current-user-id';
        const userName = 'John Doe';
        const userImageUrl = null;

        final review = Review(
          id: '', // Will be set by Firestore
          restaurantId: widget.restaurantId,
          userId: userId,
          userName: userName,
          userImageUrl: userImageUrl,
          rating: _rating,
          comment: _commentController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isVerifiedVisit: true, // This could be checked via reservation history
        );

        // Add the review to the database
        final reviewRepository = ref.read(reviewRepositoryProvider);
        final reviewId = await reviewRepository.addReview(review);

        // Send notification to restaurant owner
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.sendNewReviewNotification(
          widget.restaurantOwnerId,
          widget.restaurantName,
          _rating,
        );

        // Call the callback to update the UI
        widget.onReviewAdded();
        
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your review has been added'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Close the form
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add review: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    } else if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a rating'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            'Add Your Review',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          
          // Rating
          Center(
            child: RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Theme.of(context).colorScheme.primary,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          
          // Comment
          TextFormField(
            controller: _commentController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Share your experience...',
              border: OutlineInputBorder(),
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your review';
              }
              if (value.trim().length < 10) {
                return 'Review must be at least 10 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Submit Review'),
            ),
          ),
        ],
      ),
    );
  }
} 