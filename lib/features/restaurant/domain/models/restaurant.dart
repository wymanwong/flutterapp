import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final String address;
  final String phoneNumber;
  final String email;
  final int capacity;
  final bool isActive;
  final String? imageUrl;
  final BusinessHours businessHours;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, String> openingHours;
  final int currentOccupancy;
  final bool hasVacancy;
  final int waitTime; // estimated wait time in minutes

  Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.address,
    required this.phoneNumber,
    required this.email,
    required this.capacity,
    this.isActive = true,
    this.imageUrl,
    required this.businessHours,
    required this.createdAt,
    required this.updatedAt,
    required this.openingHours,
    this.currentOccupancy = 0,
    this.hasVacancy = true,
    this.waitTime = 0,
  });

  // Calculate occupancy percentage
  double getOccupancyPercentage() {
    if (capacity <= 0) return 0.0;
    return (currentOccupancy / capacity * 100).clamp(0.0, 100.0);
  }

  // Get available seats
  int getAvailableSeats() {
    return (capacity - currentOccupancy).clamp(0, capacity);
  }

  // Check if restaurant is at full capacity
  bool isAtFullCapacity() {
    return currentOccupancy >= capacity;
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? cuisine,
    String? address,
    String? phoneNumber,
    String? email,
    int? capacity,
    bool? isActive,
    String? imageUrl,
    BusinessHours? businessHours,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, String>? openingHours,
    int? currentOccupancy,
    bool? hasVacancy,
    int? waitTime,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      cuisine: cuisine ?? this.cuisine,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      capacity: capacity ?? this.capacity,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      businessHours: businessHours ?? this.businessHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      openingHours: openingHours ?? this.openingHours,
      currentOccupancy: currentOccupancy ?? this.currentOccupancy,
      hasVacancy: hasVacancy ?? this.hasVacancy,
      waitTime: waitTime ?? this.waitTime,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'cuisine': cuisine,
      'address': address,
      'phoneNumber': phoneNumber,
      'email': email,
      'capacity': capacity,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'businessHours': businessHours.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'openingHours': openingHours,
      'currentOccupancy': currentOccupancy,
      'hasVacancy': hasVacancy,
      'waitTime': waitTime,
    };
  }

  factory Restaurant.fromJson(Map<String, dynamic> json, {String? id}) {
    return Restaurant(
      id: id ?? json['id'] ?? '',
      name: json['name'] ?? '',
      cuisine: json['cuisine'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      capacity: json['capacity'] ?? 0,
      isActive: json['isActive'] ?? true,
      imageUrl: json['imageUrl'],
      businessHours: BusinessHours.fromJson(json['businessHours'] ?? {}),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      openingHours: _parseOpeningHours(json['openingHours']),
      currentOccupancy: json['currentOccupancy'] ?? 0,
      hasVacancy: json['hasVacancy'] ?? true,
      waitTime: json['waitTime'] ?? 0,
    );
  }

  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Restaurant(
      id: doc.id,
      name: data['name'] ?? '',
      cuisine: data['cuisine'] ?? '',
      address: data['address'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      capacity: data['capacity'] ?? 0,
      isActive: data['isActive'] ?? true,
      imageUrl: data['imageUrl'],
      businessHours: BusinessHours.fromJson(data['businessHours'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      openingHours: _parseOpeningHours(data['openingHours']),
      currentOccupancy: data['currentOccupancy'] ?? 0,
      hasVacancy: data['hasVacancy'] ?? true,
      waitTime: data['waitTime'] ?? 0,
    );
  }
  
  static Map<String, String> _parseOpeningHours(dynamic data) {
    Map<String, String> openingHours = {};
    if (data != null) {
      if (data is Map) {
        data.forEach((key, value) {
          openingHours[key.toString()] = value.toString();
        });
      }
    } else {
      // Default opening hours
      openingHours = {
        'Monday': '9:00-17:00',
        'Tuesday': '9:00-17:00',
        'Wednesday': '9:00-17:00',
        'Thursday': '9:00-17:00',
        'Friday': '9:00-17:00',
        'Saturday': '10:00-15:00',
        'Sunday': 'Closed',
      };
    }
    return openingHours;
  }
}

class BusinessHours {
  final Map<String, DayHours> schedule;

  BusinessHours({
    required this.schedule,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    schedule.forEach((key, value) {
      json[key] = value.toJson();
    });
    return json;
  }

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    final Map<String, DayHours> schedule = {};
    json.forEach((key, value) {
      schedule[key] = DayHours.fromJson(value);
    });
    return BusinessHours(schedule: schedule);
  }
}

class DayHours {
  final bool isOpen;
  final String? openTime;
  final String? closeTime;

  DayHours({
    required this.isOpen,
    this.openTime,
    this.closeTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
    };
  }

  factory DayHours.fromJson(Map<String, dynamic> json) {
    return DayHours(
      isOpen: json['isOpen'] ?? false,
      openTime: json['openTime'],
      closeTime: json['closeTime'],
    );
  }
} 