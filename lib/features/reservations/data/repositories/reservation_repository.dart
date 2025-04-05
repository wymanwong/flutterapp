import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/reservation.dart';

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository();
});

class ReservationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final reservationsCollection = 'reservations';

  // Stream list of all reservations
  Stream<List<Reservation>> getReservations() {
    dev.log('Getting all reservations stream');
    return _firestore
        .collection(reservationsCollection)
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) {
      final reservations = snapshot.docs.map((doc) {
        try {
          dev.log('Parsing reservation ${doc.id}');
          return Reservation.fromFirestore(doc);
        } catch (e, stackTrace) {
          dev.log('Error parsing reservation ${doc.id}: $e', error: e, stackTrace: stackTrace);
          return null;
        }
      }).whereType<Reservation>().toList();
      
      // Sort: upcoming first (with closest date first), then past (with most recent first)
      final now = DateTime.now();
      final upcoming = reservations.where((r) => r.dateTime.isAfter(now)).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      final past = reservations.where((r) => r.dateTime.isBefore(now)).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      return [...upcoming, ...past];
    });
  }

  // Stream list of reservations for a specific restaurant
  Stream<List<Reservation>> getRestaurantReservations(String restaurantId) {
    dev.log('Getting restaurant reservations for $restaurantId');
    return _firestore
        .collection(reservationsCollection)
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return Reservation.fromFirestore(doc);
        } catch (e, stackTrace) {
          dev.log('Error parsing restaurant reservation ${doc.id}: $e', error: e, stackTrace: stackTrace);
          return null;
        }
      }).whereType<Reservation>().toList();
    });
  }

  // Stream of recent reservations (for dashboard)
  Stream<List<Reservation>> getRecentReservations({int limit = 5}) {
    dev.log('Getting recent reservations, limit: $limit');
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _firestore
        .collection(reservationsCollection)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('dateTime')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return Reservation.fromFirestore(doc);
        } catch (e) {
          dev.log('Error parsing recent reservation ${doc.id}: $e');
          return null;
        }
      }).whereType<Reservation>().toList();
    });
  }

  // Get reservations count for analytics
  Future<int> getReservationsCount() async {
    try {
      dev.log('Getting reservations count');
      final snapshot = await _firestore
          .collection(reservationsCollection)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e, stackTrace) {
      dev.log('Error getting reservations count: $e', error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  // Get a single reservation by ID
  Future<Reservation?> getReservationById(String id) async {
    try {
      dev.log('Getting reservation by ID: $id');
      final doc = await _firestore.collection(reservationsCollection).doc(id).get();
      if (doc.exists) {
        return Reservation.fromFirestore(doc);
      } else {
        dev.log('Reservation not found: $id');
        return null;
      }
    } catch (e, stackTrace) {
      dev.log('Error getting reservation $id: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // Create a new reservation
  Future<String?> createReservation(Reservation reservation) async {
    try {
      dev.log('Creating reservation for restaurant: ${reservation.restaurantId}');
      dev.log('Reservation dateTime: ${reservation.dateTime}');
      
      final data = reservation.toMap();
      dev.log('Reservation data: $data');
      
      final docRef = _firestore.collection(reservationsCollection).doc();
      final newReservation = reservation.copyWith(id: docRef.id);
      final newData = newReservation.toMap();
      
      dev.log('Attempting to save document to: ${docRef.path}');
      await docRef.set(newData);
      dev.log('Reservation created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      dev.log('Error creating reservation: $e', error: e, stackTrace: stackTrace);
      // Try to get more specific error details
      if (e is FirebaseException) {
        dev.log('Firebase error code: ${e.code}, message: ${e.message}', error: e, stackTrace: stackTrace);
      }
      return null;
    }
  }

  // Update an existing reservation
  Future<bool> updateReservation(Reservation reservation) async {
    try {
      dev.log('Updating reservation: ${reservation.id}');
      final data = reservation.toMap();
      dev.log('Updated reservation data: $data');
      
      await _firestore.collection(reservationsCollection).doc(reservation.id).update(data);
      dev.log('Reservation updated successfully');
      return true;
    } catch (e, stackTrace) {
      dev.log('Error updating reservation: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // Update reservation status
  Future<bool> updateReservationStatus(String id, ReservationStatus status) async {
    try {
      dev.log('Updating reservation status: $id to $status');
      await _firestore.collection(reservationsCollection).doc(id).update({
        'status': status.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      dev.log('Reservation status updated successfully');
      return true;
    } catch (e, stackTrace) {
      dev.log('Error updating reservation status: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // Delete a reservation
  Future<bool> deleteReservation(String id) async {
    try {
      dev.log('Deleting reservation: $id');
      await _firestore.collection(reservationsCollection).doc(id).delete();
      dev.log('Reservation deleted successfully');
      return true;
    } catch (e, stackTrace) {
      dev.log('Error deleting reservation: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // Get daily reservations count for analytics
  Future<Map<String, int>> getDailyReservationsCount(DateTime startDate, DateTime endDate) async {
    try {
      // Ensure we include the full day for both start and end dates
      final adjustedStartDate = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
      final adjustedEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      
      dev.log('Getting daily reservations count from $adjustedStartDate to $adjustedEndDate');
      final snapshot = await _firestore
          .collection(reservationsCollection)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(adjustedStartDate))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(adjustedEndDate))
          .get();

      final Map<String, int> dailyCounts = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['dateTime'] as Timestamp).toDate();
        final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        
        if (dailyCounts.containsKey(dayKey)) {
          dailyCounts[dayKey] = dailyCounts[dayKey]! + 1;
        } else {
          dailyCounts[dayKey] = 1;
        }
      }
      
      dev.log('Daily reservation counts: $dailyCounts');
      return dailyCounts;
    } catch (e, stackTrace) {
      dev.log('Error getting daily reservation counts: $e', error: e, stackTrace: stackTrace);
      return {};
    }
  }
} 