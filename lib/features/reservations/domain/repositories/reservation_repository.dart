import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reservation.dart';
import '../../../../core/services/firestore_service.dart';
import '../../restaurants/data/services/restaurant_service.dart';

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  final reservationService = ref.watch(reservationServiceProvider);
  final restaurantService = ref.watch(restaurantServiceProvider);
  return ReservationRepository(reservationService, restaurantService);
});

class ReservationRepository {
  final FirestoreService<Reservation> _reservationService;
  final RestaurantService _restaurantService;

  ReservationRepository(this._reservationService, this._restaurantService);

  Future<List<Reservation>> getRestaurantReservations(String restaurantId) async {
    return await _reservationService.getRestaurantReservations(restaurantId);
  }

  Future<List<Reservation>> getUserReservations(String userId) async {
    return await _reservationService.getUserReservations(userId);
  }

  Future<List<Reservation>> getActiveReservations(String restaurantId) async {
    return await _reservationService.getActiveReservations(restaurantId);
  }

  Future<List<Reservation>> getPendingReservations(String restaurantId) async {
    return await _reservationService.getPendingReservations(restaurantId);
  }

  Future<List<Reservation>> getReservationsByDate(
    String restaurantId,
    DateTime date,
  ) async {
    return await _reservationService.getReservationsByDate(restaurantId, date);
  }

  Future<Reservation?> getReservation(String id) async {
    return await _reservationService.get(id);
  }

  Future<void> createReservation(Reservation reservation) async {
    final restaurant = await _restaurantService.get(reservation.restaurantId);
    if (restaurant == null) {
      throw Exception('Restaurant not found');
    }

    final isAvailable = await _reservationService.isTimeSlotAvailable(
      reservation.restaurantId,
      reservation.dateTime,
      reservation.numberOfGuests,
    );

    if (!isAvailable) {
      throw Exception('Time slot is not available');
    }

    await _reservationService.create(reservation);
  }

  Future<void> updateReservation(Reservation reservation) async {
    if (reservation.status == ReservationStatus.confirmed) {
      final isAvailable = await _reservationService.isTimeSlotAvailable(
        reservation.restaurantId,
        reservation.dateTime,
        reservation.numberOfGuests,
      );

      if (!isAvailable) {
        throw Exception('Time slot is not available');
      }
    }

    await _reservationService.update(reservation);
  }

  Future<void> cancelReservation(String id) async {
    final reservation = await getReservation(id);
    if (reservation == null) {
      throw Exception('Reservation not found');
    }

    final updatedReservation = reservation.copyWith(
      status: ReservationStatus.cancelled,
    );

    await _reservationService.update(updatedReservation);
  }

  Future<void> markReservationAsCompleted(String id) async {
    final reservation = await getReservation(id);
    if (reservation == null) {
      throw Exception('Reservation not found');
    }

    final updatedReservation = reservation.copyWith(
      status: ReservationStatus.completed,
    );

    await _reservationService.update(updatedReservation);
  }

  Future<void> markReservationAsNoShow(String id) async {
    final reservation = await getReservation(id);
    if (reservation == null) {
      throw Exception('Reservation not found');
    }

    final updatedReservation = reservation.copyWith(
      status: ReservationStatus.noShow,
    );

    await _reservationService.update(updatedReservation);
  }

  Stream<List<Reservation>> streamRestaurantReservations(String restaurantId) {
    return _reservationService.streamRestaurantReservations(restaurantId);
  }

  Stream<List<Reservation>> streamActiveReservations(String restaurantId) {
    return _reservationService.streamActiveReservations(restaurantId);
  }
} 