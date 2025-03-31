import 'package:cloud_firestore/cloud_firestore.dart';

enum ReservationStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  noShow,
}

class Reservation {
  final String id;
  final String restaurantId;
  final String userId;
  final DateTime dateTime;
  final int numberOfGuests;
  final String specialRequests;
  final ReservationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? guestInfo;

  Reservation({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.dateTime,
    required this.numberOfGuests,
    required this.specialRequests,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.guestInfo,
  });

  factory Reservation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final dateTime = (data['dateTime'] as Timestamp).toDate();
    final createdAt = (data['createdAt'] as Timestamp).toDate();
    final updatedAt = (data['updatedAt'] as Timestamp).toDate();
    
    return Reservation(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      userId: data['userId'] ?? '',
      dateTime: dateTime,
      numberOfGuests: data['numberOfGuests'] ?? 1,
      specialRequests: data['specialRequests'] ?? '',
      status: ReservationStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => ReservationStatus.pending,
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
      guestInfo: data['guestInfo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'userId': userId,
      'dateTime': Timestamp.fromDate(dateTime),
      'numberOfGuests': numberOfGuests,
      'specialRequests': specialRequests,
      'status': status.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (guestInfo != null) 'guestInfo': guestInfo,
    };
  }

  Reservation copyWith({
    String? id,
    String? restaurantId,
    String? userId,
    DateTime? dateTime,
    int? numberOfGuests,
    String? specialRequests,
    ReservationStatus? status,
    Map<String, dynamic>? guestInfo,
  }) {
    return Reservation(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      userId: userId ?? this.userId,
      dateTime: dateTime ?? this.dateTime,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      specialRequests: specialRequests ?? this.specialRequests,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      guestInfo: guestInfo ?? this.guestInfo,
    );
  }

  bool get isActive => status == ReservationStatus.confirmed;
  bool get isPending => status == ReservationStatus.pending;
  bool get isCancelled => status == ReservationStatus.cancelled;
  bool get isCompleted => status == ReservationStatus.completed;
  bool get isNoShow => status == ReservationStatus.noShow;
  bool get isConfirmed => status == ReservationStatus.confirmed;
} 