import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/review.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(FirebaseFirestore.instance);
});

class ReviewRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'reviews';

  ReviewRepository(this._firestore);

  // Add a new review
  Future<String> addReview(Review review) async {
    try {
      final docRef = await _firestore.collection(_collection).add(review.toFirestore());
      
      // Update restaurant average rating
      await _updateRestaurantRating(review.restaurantId);
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  // Update an existing review
  Future<void> updateReview(Review review) async {
    try {
      await _firestore.collection(_collection).doc(review.id).update(review.toFirestore());
      
      // Update restaurant average rating
      await _updateRestaurantRating(review.restaurantId);
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId, String restaurantId) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).delete();
      
      // Update restaurant average rating
      await _updateRestaurantRating(restaurantId);
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  // Get reviews for a specific restaurant
  Stream<List<Review>> getReviewsForRestaurant(String restaurantId) {
    return _firestore
        .collection(_collection)
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromFirestore(doc))
            .toList());
  }

  // Get reviews by a specific user
  Stream<List<Review>> getReviewsByUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromFirestore(doc))
            .toList());
  }

  // Add or remove a helpful vote
  Future<void> toggleHelpfulVote(String reviewId, String userId) async {
    try {
      final docRef = _firestore.collection(_collection).doc(reviewId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw Exception('Review not found');
      }
      
      final review = Review.fromFirestore(doc);
      final helpfulVotes = List<String>.from(review.helpfulVotes);
      
      if (helpfulVotes.contains(userId)) {
        helpfulVotes.remove(userId);
      } else {
        helpfulVotes.add(userId);
      }
      
      await docRef.update({'helpfulVotes': helpfulVotes});
    } catch (e) {
      throw Exception('Failed to toggle helpful vote: $e');
    }
  }

  // Calculate and update restaurant's average rating
  Future<void> _updateRestaurantRating(String restaurantId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('restaurantId', isEqualTo: restaurantId)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        // Reset ratings if no reviews
        await _firestore.collection('restaurants').doc(restaurantId).update({
          'averageRating': 0.0,
          'ratingCount': 0
        });
        return;
      }
      
      final reviews = querySnapshot.docs
          .map((doc) => Review.fromFirestore(doc))
          .toList();
      
      final totalRating = reviews.fold(0.0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / reviews.length;
      
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'averageRating': averageRating,
        'ratingCount': reviews.length
      });
    } catch (e) {
      throw Exception('Failed to update restaurant rating: $e');
    }
  }
} 