import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/models/reservation.dart';

final reservationServiceProvider = Provider<ReservationService>((ref) {
  return ReservationService(FirebaseFirestore.instance);
});

class ReservationService extends FirestoreService<Reservation> {
  ReservationService(FirebaseFirestore firestore) : super(firestore, 'reservations');

  @override
  Reservation fromFirestore(DocumentSnapshot doc) {
    return Reservation.fromFirestore(doc);
  }

  Future<List<Reservation>> getRestaurantReservations(String restaurantId) async {
    final snapshot = await _collection
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('dateTime', descending: true)
        .get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  Future<List<Reservation>> getUserReservations(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: true)
        .get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  Future<List<Reservation>> getActiveReservations(String restaurantId) async {
    final snapshot = await _collection
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', isEqualTo: ReservationStatus.confirmed.toString())
        .orderBy('dateTime')
        .get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  Future<List<Reservation>> getPendingReservations(String restaurantId) async {
    final snapshot = await _collection
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', isEqualTo: ReservationStatus.pending.toString())
        .orderBy('dateTime')
        .get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  Future<List<Reservation>> getReservationsByDate(
    String restaurantId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final snapshot = await _collection
        .where('restaurantId', isEqualTo: restaurantId)
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('dateTime', isLessThan: endOfDay)
        .orderBy('dateTime')
        .get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  Stream<List<Reservation>> streamRestaurantReservations(String restaurantId) {
    return _collection
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => fromFirestore(doc)).toList());
  }

  Stream<List<Reservation>> streamActiveReservations(String restaurantId) {
    return _collection
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', isEqualTo: ReservationStatus.confirmed.toString())
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => fromFirestore(doc)).toList());
  }

  Future<bool> isTimeSlotAvailable(
    String restaurantId,
    DateTime dateTime,
    int numberOfGuests,
  ) async {
    final reservations = await getReservationsByDate(restaurantId, dateTime);
    final restaurant = await get(restaurantId);
    if (restaurant == null) return false;

    final totalGuests = reservations
        .where((r) => r.isActive)
        .fold(0, (sum, r) => sum + r.numberOfGuests);

    return totalGuests + numberOfGuests <= restaurant.capacity;
  }
} 