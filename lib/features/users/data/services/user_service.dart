import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/models/user.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

class UserService extends FirestoreService<User> {
  UserService() : super('users');

  @override
  User fromFirestore(DocumentSnapshot doc) => User.fromFirestore(doc);

  Future<User?> getUserByEmail(String email) async {
    final users = await getWhere('email', isEqualTo: email);
    return users.isEmpty ? null : users.first;
  }

  Future<User?> getUserById(String id) async {
    final snapshot = await collection
        .doc(id)
        .get();

    if (!snapshot.exists) return null;
    return fromFirestore(snapshot);
  }

  Future<List<User>> getActiveUsers() async {
    return getWhere('isActive', isEqualTo: true);
  }

  Future<void> updateUserRole(String userId, UserRole role) async {
    await collection.doc(userId).update({
      'role': role.toString(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    await collection.doc(userId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserProfile(
    String userId, {
    String? name,
    String? phoneNumber,
  }) async {
    await collection.doc(userId).update({
      if (name != null) 'name': name,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<User>> streamActiveUsers() {
    return collection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Future<List<User>> getRestaurantStaff(String restaurantId) async {
    final snapshot = await collection
        .where('restaurantId', isEqualTo: restaurantId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  Future<List<User>> getUsersByRole(UserRole role) async {
    return getWhere('role', isEqualTo: role.toString());
  }

  Future<void> updateLastLogin(String userId) async {
    await collection.doc(userId).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserPermissions(String userId, List<String> permissions) async {
    await collection.doc(userId).update({
      'permissions': permissions,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<User>> streamRestaurantStaff(String restaurantId) {
    return collection
        .where('restaurantId', isEqualTo: restaurantId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => fromFirestore(doc)).toList());
  }

  Future<bool> hasPermission(String userId, String permission) async {
    final user = await get(userId);
    return user?.hasPermission(permission) ?? false;
  }

  Future<bool> isUserActive(String userId) async {
    final user = await get(userId);
    return user?.isActive ?? false;
  }

  Future<void> createUser(User user) async {
    await create(user.toMap());
  }

  Future<void> updateUser(User user) async {
    await update(user.id, user.toMap());
  }

  Future<void> deactivateUser(String userId) async {
    await update(userId, {'isActive': false, 'updatedAt': DateTime.now()});
  }

  Stream<User?> streamUserById(String userId) => streamOne(userId);
} 