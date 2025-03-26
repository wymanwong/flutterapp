import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String name;
  final String description;
  final String address;
  final String phoneNumber;
  final String email;
  final String? imageUrl;
  final int capacity;
  final List<String> cuisineTypes;
  final Map<String, dynamic> openingHours;
  final double priceRange;
  final List<String> amenities;
  final bool isActive;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? latitude;
  final double? longitude;
  final double averageRating;
  final int ratingCount;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.phoneNumber,
    required this.email,
    this.imageUrl,
    required this.capacity,
    required this.cuisineTypes,
    required this.openingHours,
    required this.priceRange,
    required this.amenities,
    this.isActive = true,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.averageRating = 0.0,
    this.ratingCount = 0,
  });

  factory Restaurant.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Restaurant(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      address: data['address'] as String,
      phoneNumber: data['phoneNumber'] as String,
      email: data['email'] as String,
      imageUrl: data['imageUrl'] as String?,
      capacity: data['capacity'] as int,
      cuisineTypes: List<String>.from(data['cuisineTypes'] as List),
      openingHours: Map<String, dynamic>.from(data['openingHours'] as Map),
      priceRange: (data['priceRange'] as num).toDouble(),
      amenities: List<String>.from(data['amenities'] as List),
      isActive: data['isActive'] as bool? ?? true,
      ownerId: data['ownerId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      latitude: data['latitude'] != null ? (data['latitude'] as num).toDouble() : null,
      longitude: data['longitude'] != null ? (data['longitude'] as num).toDouble() : null,
      averageRating: data['averageRating'] != null ? (data['averageRating'] as num).toDouble() : 0.0,
      ratingCount: data['ratingCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'phoneNumber': phoneNumber,
      'email': email,
      'imageUrl': imageUrl,
      'capacity': capacity,
      'cuisineTypes': cuisineTypes,
      'openingHours': openingHours,
      'priceRange': priceRange,
      'amenities': amenities,
      'isActive': isActive,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'latitude': latitude,
      'longitude': longitude,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
    };
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? phoneNumber,
    String? email,
    String? imageUrl,
    int? capacity,
    List<String>? cuisineTypes,
    Map<String, dynamic>? openingHours,
    double? priceRange,
    List<String>? amenities,
    bool? isActive,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    double? averageRating,
    int? ratingCount,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      capacity: capacity ?? this.capacity,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      openingHours: openingHours ?? this.openingHours,
      priceRange: priceRange ?? this.priceRange,
      amenities: amenities ?? this.amenities,
      isActive: isActive ?? this.isActive,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }
} 