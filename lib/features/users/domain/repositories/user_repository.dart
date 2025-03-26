import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../../../../core/services/firestore_service.dart';
import '../../restaurants/data/services/restaurant_service.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final userService = ref.watch(userServiceProvider);
  final restaurantService = ref.watch(restaurantServiceProvider);
  return UserRepository(userService, restaurantService);
});
class UserRepository {
  final FirestoreService<User> _userService;
  final RestaurantService _restaurantService;

  UserRepository(this._userService, this._restaurantService);

  Future<User?> getUserByEmail(String email) async {
    return await _userService.getUserByEmail(email);
  }

  Future<List<User>> getRestaurantStaff(String restaurantId) async {
    return await _userService.getRestaurantStaff(restaurantId);
  }

  Future<List<User>> getUsersByRole(UserRole role) async {
    return await _userService.getUsersByRole(role);
  }

  Future<User?> getUser(String id) async {
    return await _userService.get(id);
  }

  Future<void> createUser(User user) async {
    if (user.restaurantId != null) {
      final restaurant = await _restaurantService.get(user.restaurantId!);
      if (restaurant == null) {
        throw Exception('Restaurant not found');
      }
    }
    await _userService.create(user);
  }

  Future<void> updateUser(User user) async {
    if (user.restaurantId != null) {
      final restaurant = await _restaurantService.get(user.restaurantId!);
      if (restaurant == null) {
        throw Exception('Restaurant not found');
      }
    }
    await _userService.update(user);
  }

  Future<void> deleteUser(String id) async {
    await _userService.delete(id);
  }

  Future<void> updateLastLogin(String userId) async {
    await _userService.updateLastLogin(userId);
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    await _userService.updateUserStatus(userId, isActive);
  }

  Future<void> updateUserPermissions(String userId, List<String> permissions) async {
    await _userService.updateUserPermissions(userId, permissions);
  }

  Future<bool> hasPermission(String userId, String permission) async {
    return await _userService.hasPermission(userId, permission);
  }

  Future<bool> isUserActive(String userId) async {
    return await _userService.isUserActive(userId);
  }

  Stream<List<User>> streamRestaurantStaff(String restaurantId) {
    return _userService.streamRestaurantStaff(restaurantId);
  }

  Future<List<String>> getUserPermissions(String userId) async {
    final user = await getUser(userId);
    return user?.permissions ?? [];
  }

  Future<bool> canManageRestaurant(String userId, String restaurantId) async {
    final user = await getUser(userId);
    if (user == null) return false;

    if (user.isSuperAdmin) return true;
    if (user.restaurantId == restaurantId && user.isRestaurantManager) return true;

    return false;
  }
} 