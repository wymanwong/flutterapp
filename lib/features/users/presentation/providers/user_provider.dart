import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/user_service.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/user_repository.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

final activeUsersProvider = StreamProvider<List<User>>((ref) {
  final userService = ref.watch(userServiceProvider);
  return userService.streamActiveUsers();
});

final userStreamProvider = StreamProvider.family<User?, String>((ref, userId) {
  final userService = ref.watch(userServiceProvider);
  return userService.streamUserById(userId);
});

final userByEmailProvider = FutureProvider.family<User?, String>((ref, email) {
  final userService = ref.watch(userServiceProvider);
  return userService.getUserByEmail(email);
});

final usersByRoleProvider = FutureProvider.family<List<User>, UserRole>((ref, role) {
  final userService = ref.watch(userServiceProvider);
  return userService.getUsersByRole(role);
});

final usersProvider = StateNotifierProvider<UsersNotifier, AsyncValue<List<User>>>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UsersNotifier(repository);
});

final restaurantStaffProvider = StreamProvider.family<List<User>, String>((ref, restaurantId) {
  final repository = ref.watch(userRepositoryProvider);
  return repository.streamRestaurantStaff(restaurantId);
});

final userProvider = FutureProvider.family<User?, String>((ref, id) async {
  final repository = ref.watch(userRepositoryProvider);
  return await repository.getUser(id);
});

class UsersNotifier extends StateNotifier<AsyncValue<List<User>>> {
  final UserRepository _repository;

  UsersNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadRestaurantStaff(String restaurantId) async {
    try {
      state = const AsyncValue.loading();
      final staff = await _repository.getRestaurantStaff(restaurantId);
      state = AsyncValue.data(staff);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadUsersByRole(UserRole role) async {
    try {
      state = const AsyncValue.loading();
      final users = await _repository.getUsersByRole(role);
      state = AsyncValue.data(users);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createUser(User user) async {
    try {
      await _repository.createUser(user);
      if (user.restaurantId != null) {
        loadRestaurantStaff(user.restaurantId!);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _repository.updateUser(user);
      if (user.restaurantId != null) {
        loadRestaurantStaff(user.restaurantId!);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      final user = await _repository.getUser(id);
      if (user != null) {
        await _repository.deleteUser(id);
        if (user.restaurantId != null) {
          loadRestaurantStaff(user.restaurantId!);
        }
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateLastLogin(String userId) async {
    try {
      await _repository.updateLastLogin(userId);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _repository.updateUserStatus(userId, isActive);
      final user = await _repository.getUser(userId);
      if (user?.restaurantId != null) {
        loadRestaurantStaff(user!.restaurantId!);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateUserPermissions(String userId, List<String> permissions) async {
    try {
      await _repository.updateUserPermissions(userId, permissions);
      final user = await _repository.getUser(userId);
      if (user?.restaurantId != null) {
        loadRestaurantStaff(user!.restaurantId!);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> hasPermission(String userId, String permission) async {
    try {
      return await _repository.hasPermission(userId, permission);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<bool> isUserActive(String userId) async {
    try {
      return await _repository.isUserActive(userId);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<List<String>> getUserPermissions(String userId) async {
    try {
      return await _repository.getUserPermissions(userId);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return [];
    }
  }

  Future<bool> canManageRestaurant(String userId, String restaurantId) async {
    try {
      return await _repository.canManageRestaurant(userId, restaurantId);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
} 