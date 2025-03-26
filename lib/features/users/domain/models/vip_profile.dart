import 'package:cloud_firestore/cloud_firestore.dart';

class VipProfile {
  final String id;
  final String userId;
  final bool isVip;
  final int loyaltyPoints;
  final List<String> dietaryPreferences;
  final List<String> favoriteCuisines;
  final List<String> favoriteRestaurants;
  final Map<String, dynamic> specialOccasions;
  final Map<String, dynamic> seatingPreferences;
  final Map<String, int> restaurantRatings;
  final DateTime lastVisit;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool notificationsEnabled;
  final NotificationPreferences notificationPreferences;
  final Map<String, dynamic>? additionalInfo;

  VipProfile({
    required this.id,
    required this.userId,
    this.isVip = false,
    this.loyaltyPoints = 0,
    this.dietaryPreferences = const [],
    this.favoriteCuisines = const [],
    this.favoriteRestaurants = const [],
    this.specialOccasions = const {},
    this.seatingPreferences = const {},
    this.restaurantRatings = const {},
    required this.lastVisit,
    required this.createdAt,
    required this.updatedAt,
    this.notificationsEnabled = true,
    required this.notificationPreferences,
    this.additionalInfo,
  });

  factory VipProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VipProfile(
      id: doc.id,
      userId: data['userId'] as String,
      isVip: data['isVip'] as bool? ?? false,
      loyaltyPoints: data['loyaltyPoints'] as int? ?? 0,
      dietaryPreferences: List<String>.from(data['dietaryPreferences'] ?? []),
      favoriteCuisines: List<String>.from(data['favoriteCuisines'] ?? []),
      favoriteRestaurants: List<String>.from(data['favoriteRestaurants'] ?? []),
      specialOccasions: data['specialOccasions'] as Map<String, dynamic>? ?? {},
      seatingPreferences: data['seatingPreferences'] as Map<String, dynamic>? ?? {},
      restaurantRatings: (data['restaurantRatings'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, value as int)),
      lastVisit: (data['lastVisit'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      notificationPreferences: NotificationPreferences.fromMap(
          data['notificationPreferences'] as Map<String, dynamic>? ?? {}),
      additionalInfo: data['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'isVip': isVip,
      'loyaltyPoints': loyaltyPoints,
      'favoriteRestaurants': favoriteRestaurants,
      'dietaryPreferences': dietaryPreferences,
      'favoriteCuisines': favoriteCuisines,
      'specialOccasions': specialOccasions,
      'seatingPreferences': seatingPreferences,
      'restaurantRatings': restaurantRatings,
      'lastVisit': Timestamp.fromDate(lastVisit),
      'notificationsEnabled': notificationsEnabled,
      'notificationPreferences': notificationPreferences.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'additionalInfo': additionalInfo,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  VipProfile copyWith({
    String? id,
    String? userId,
    bool? isVip,
    int? loyaltyPoints,
    List<String>? dietaryPreferences,
    List<String>? favoriteCuisines,
    List<String>? favoriteRestaurants,
    Map<String, dynamic>? specialOccasions,
    Map<String, dynamic>? seatingPreferences,
    Map<String, int>? restaurantRatings,
    DateTime? lastVisit,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? notificationsEnabled,
    NotificationPreferences? notificationPreferences,
    Map<String, dynamic>? additionalInfo,
  }) {
    return VipProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isVip: isVip ?? this.isVip,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      favoriteCuisines: favoriteCuisines ?? this.favoriteCuisines,
      favoriteRestaurants: favoriteRestaurants ?? this.favoriteRestaurants,
      specialOccasions: specialOccasions ?? this.specialOccasions,
      seatingPreferences: seatingPreferences ?? this.seatingPreferences,
      restaurantRatings: restaurantRatings ?? this.restaurantRatings,
      lastVisit: lastVisit ?? this.lastVisit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

class NotificationPreferences {
  final bool lowOccupancyAlerts;
  final int lowOccupancyThreshold; // Percentage
  final bool specialOffers;
  final bool reservationReminders;
  final bool proximityAlerts;
  final int proximityRadius; // in meters
  final bool favoriteRestaurantUpdates;
  final List<String> preferredDays;
  final List<String> preferredTimes;

  NotificationPreferences({
    this.lowOccupancyAlerts = true,
    this.lowOccupancyThreshold = 30,
    this.specialOffers = true,
    this.reservationReminders = true,
    this.proximityAlerts = true,
    this.proximityRadius = 500,
    this.favoriteRestaurantUpdates = true,
    this.preferredDays = const [],
    this.preferredTimes = const [],
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      lowOccupancyAlerts: map['lowOccupancyAlerts'] as bool? ?? true,
      lowOccupancyThreshold: map['lowOccupancyThreshold'] as int? ?? 30,
      specialOffers: map['specialOffers'] as bool? ?? true,
      reservationReminders: map['reservationReminders'] as bool? ?? true,
      proximityAlerts: map['proximityAlerts'] as bool? ?? true,
      proximityRadius: map['proximityRadius'] as int? ?? 500,
      favoriteRestaurantUpdates: map['favoriteRestaurantUpdates'] as bool? ?? true,
      preferredDays: List<String>.from(map['preferredDays'] ?? []),
      preferredTimes: List<String>.from(map['preferredTimes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lowOccupancyAlerts': lowOccupancyAlerts,
      'lowOccupancyThreshold': lowOccupancyThreshold,
      'specialOffers': specialOffers,
      'reservationReminders': reservationReminders,
      'proximityAlerts': proximityAlerts,
      'proximityRadius': proximityRadius,
      'favoriteRestaurantUpdates': favoriteRestaurantUpdates,
      'preferredDays': preferredDays,
      'preferredTimes': preferredTimes,
    };
  }
  
  Map<String, dynamic> toJson() {
    return toMap();
  }

  NotificationPreferences copyWith({
    bool? lowOccupancyAlerts,
    int? lowOccupancyThreshold,
    bool? specialOffers,
    bool? reservationReminders,
    bool? proximityAlerts,
    int? proximityRadius,
    bool? favoriteRestaurantUpdates,
    List<String>? preferredDays,
    List<String>? preferredTimes,
  }) {
    return NotificationPreferences(
      lowOccupancyAlerts: lowOccupancyAlerts ?? this.lowOccupancyAlerts,
      lowOccupancyThreshold: lowOccupancyThreshold ?? this.lowOccupancyThreshold,
      specialOffers: specialOffers ?? this.specialOffers,
      reservationReminders: reservationReminders ?? this.reservationReminders,
      proximityAlerts: proximityAlerts ?? this.proximityAlerts,
      proximityRadius: proximityRadius ?? this.proximityRadius,
      favoriteRestaurantUpdates: favoriteRestaurantUpdates ?? this.favoriteRestaurantUpdates,
      preferredDays: preferredDays ?? this.preferredDays,
      preferredTimes: preferredTimes ?? this.preferredTimes,
    );
  }
} 