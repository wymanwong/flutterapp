import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/reservation.dart';
import '../../domain/repositories/reservation_repository.dart';

final reservationsProvider = StateNotifierProvider<ReservationsNotifier, AsyncValue<List<Reservation>>>((ref) {
  final repository = ref.watch(reservationRepositoryProvider);
  return ReservationsNotifier(repository);
});

final restaurantReservationsProvider = StreamProvider.family<List<Reservation>, String>((ref, restaurantId) {
  final repository = ref.watch(reservationRepositoryProvider);
  return repository.streamRestaurantReservations(restaurantId);
});

final activeReservationsProvider = StreamProvider.family<List<Reservation>, String>((ref, restaurantId) {
  final repository = ref.watch(reservationRepositoryProvider);
  return repository.streamActiveReservations(restaurantId);
});

final reservationProvider = FutureProvider.family<Reservation?, String>((ref, id) async {
  final repository = ref.watch(reservationRepositoryProvider);
  return await repository.getReservation(id);
});

class ReservationsNotifier extends StateNotifier<AsyncValue<List<Reservation>>> {
  final ReservationRepository _repository;

  ReservationsNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadRestaurantReservations(String restaurantId) async {
    try {
      state = const AsyncValue.loading();
      final reservations = await _repository.getRestaurantReservations(restaurantId);
      state = AsyncValue.data(reservations);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadUserReservations(String userId) async {
    try {
      state = const AsyncValue.loading();
      final reservations = await _repository.getUserReservations(userId);
      state = AsyncValue.data(reservations);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadActiveReservations(String restaurantId) async {
    try {
      state = const AsyncValue.loading();
      final reservations = await _repository.getActiveReservations(restaurantId);
      state = AsyncValue.data(reservations);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadPendingReservations(String restaurantId) async {
    try {
      state = const AsyncValue.loading();
      final reservations = await _repository.getPendingReservations(restaurantId);
      state = AsyncValue.data(reservations);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadReservationsByDate(String restaurantId, DateTime date) async {
    try {
      state = const AsyncValue.loading();
      final reservations = await _repository.getReservationsByDate(restaurantId, date);
      state = AsyncValue.data(reservations);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createReservation(Reservation reservation) async {
    try {
      await _repository.createReservation(reservation);
      loadRestaurantReservations(reservation.restaurantId);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateReservation(Reservation reservation) async {
    try {
      await _repository.updateReservation(reservation);
      loadRestaurantReservations(reservation.restaurantId);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> cancelReservation(String id) async {
    try {
      await _repository.cancelReservation(id);
      final reservation = await _repository.getReservation(id);
      if (reservation != null) {
        loadRestaurantReservations(reservation.restaurantId);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markReservationAsCompleted(String id) async {
    try {
      await _repository.markReservationAsCompleted(id);
      final reservation = await _repository.getReservation(id);
      if (reservation != null) {
        loadRestaurantReservations(reservation.restaurantId);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markReservationAsNoShow(String id) async {
    try {
      await _repository.markReservationAsNoShow(id);
      final reservation = await _repository.getReservation(id);
      if (reservation != null) {
        loadRestaurantReservations(reservation.restaurantId);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
} 