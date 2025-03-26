import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String restaurantId;
  final String userId;
  final String userName;
  final String? userImageUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> helpfulVotes;
  final bool isVerifiedVisit;

  Review({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    List<String>? helpfulVotes,
    this.isVerifiedVisit = false,
  }) : helpfulVotes = helpfulVotes ?? [];

  factory Review.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Review(
      id: doc.id,
      restaurantId: data['restaurantId'] as String,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      userImageUrl: data['userImageUrl'] as String?,
      rating: (data['rating'] as num).toDouble(),
      comment: data['comment'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      helpfulVotes: data['helpfulVotes'] != null 
          ? List<String>.from(data['helpfulVotes'] as List) 
          : [],
      isVerifiedVisit: data['isVerifiedVisit'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'userId': userId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'helpfulVotes': helpfulVotes,
      'isVerifiedVisit': isVerifiedVisit,
    };
  }

  Review copyWith({
    String? id,
    String? restaurantId,
    String? userId,
    String? userName,
    String? userImageUrl,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? helpfulVotes,
    bool? isVerifiedVisit,
  }) {
    return Review(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImageUrl: userImageUrl ?? this.userImageUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      helpfulVotes: helpfulVotes ?? List.from(this.helpfulVotes),
      isVerifiedVisit: isVerifiedVisit ?? this.isVerifiedVisit,
    );
  }
} 