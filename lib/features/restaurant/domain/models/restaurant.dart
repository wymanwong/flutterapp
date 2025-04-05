import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/restaurant_utils.dart';
import 'business_hours.dart';

class Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final String address;
  final String phoneNumber;
  final String email;
  final int capacity;
  final int? currentOccupancy;
  final int? waitTime;
  final bool isActive;
  final String? imageUrl;
  final BusinessHours businessHours;
  final Map<String, String> openingHours;
  final DateTime createdAt;
  final DateTime updatedAt;

  Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.address,
    required this.phoneNumber,
    required this.email,
    required this.capacity,
    this.currentOccupancy,
    this.waitTime,
    required this.isActive,
    required this.imageUrl,
    required this.businessHours,
    required this.openingHours,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasVacancy => RestaurantUtils.hasVacancy(this);

  double get occupancyPercentage => RestaurantUtils.calculateOccupancyPercentage(this);

  String get occupancyStatus => RestaurantUtils.getOccupancyStatusText(this);

  Restaurant copyWith({
    String? id,
    String? name,
    String? cuisine,
    String? address,
    String? phoneNumber,
    String? email,
    int? capacity,
    int? currentOccupancy,
    int? waitTime,
    bool? isActive,
    String? imageUrl,
    BusinessHours? businessHours,
    Map<String, String>? openingHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      cuisine: cuisine ?? this.cuisine,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      capacity: capacity ?? this.capacity,
      currentOccupancy: currentOccupancy ?? this.currentOccupancy,
      waitTime: waitTime ?? this.waitTime,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      businessHours: businessHours ?? this.businessHours,
      openingHours: openingHours ?? this.openingHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cuisine': cuisine,
      'address': address,
      'phoneNumber': phoneNumber,
      'email': email,
      'capacity': capacity,
      'currentOccupancy': currentOccupancy,
      'waitTime': waitTime,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'businessHours': businessHours.toMap(),
      'openingHours': openingHours,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'] as String,
      name: map['name'] as String,
      cuisine: map['cuisine'] as String,
      address: map['address'] as String,
      phoneNumber: map['phoneNumber'] as String,
      email: map['email'] as String,
      capacity: map['capacity'] as int,
      currentOccupancy: map['currentOccupancy'] as int?,
      waitTime: map['waitTime'] as int?,
      isActive: map['isActive'] as bool,
      imageUrl: map['imageUrl'] as String?,
      businessHours: BusinessHours.fromMap(map['businessHours'] as Map<String, dynamic>),
      openingHours: Map<String, String>.from(map['openingHours'] as Map),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
} 