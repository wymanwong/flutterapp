import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/points.dart';

class PointsRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'points';

  PointsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Add points to user's account
  Future<void> addPoints(String userId, int points) async {
    try {
      final docRef = _firestore.collection(_collection).doc(userId);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (!doc.exists) {
          // Create new points document if it doesn't exist
          transaction.set(docRef, {
            'userId': userId,
            'balance': points,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          // Update existing points
          final currentBalance = doc.data()?['balance'] as int;
          transaction.update(docRef, {
            'balance': currentBalance + points,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Error adding points: $e');
      rethrow;
    }
  }

  // Use points from user's account
  Future<bool> usePoints(String userId, int points) async {
    try {
      final docRef = _firestore.collection(_collection).doc(userId);
      bool success = false;

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          final currentBalance = doc.data()?['balance'] as int;
          if (currentBalance >= points) {
            transaction.update(docRef, {
              'balance': currentBalance - points,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
            success = true;
          }
        }
      });

      return success;
    } catch (e) {
      print('Error using points: $e');
      rethrow;
    }
  }

  // Check user's points balance
  Future<Points?> checkPoints(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return Points.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error checking points: $e');
      rethrow;
    }
  }

  // Get points history
  Future<List<Map<String, dynamic>>> getPointsHistory(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('points_history')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      print('Error getting points history: $e');
      rethrow;
    }
  }
} 