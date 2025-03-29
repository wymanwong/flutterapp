import '../repositories/points_repository.dart';
import '../../domain/models/points.dart';

class PointsService {
  final PointsRepository _repository;

  PointsService({required PointsRepository repository}) : _repository = repository;

  // Add points for various actions
  Future<void> addPointsForVisit(String userId, int points) async {
    await _repository.addPoints(userId, points);
  }

  Future<void> addPointsForReservation(String userId, int points) async {
    await _repository.addPoints(userId, points);
  }

  Future<void> addPointsForReview(String userId, int points) async {
    await _repository.addPoints(userId, points);
  }

  // Use points for rewards
  Future<bool> usePointsForReward(String userId, int points) async {
    return await _repository.usePoints(userId, points);
  }

  // Check points balance
  Future<Points?> checkPointsBalance(String userId) async {
    return await _repository.checkPoints(userId);
  }

  // Get points history
  Future<List<Map<String, dynamic>>> getPointsHistory(String userId) async {
    return await _repository.getPointsHistory(userId);
  }

  // Check VIP status based on points
  Future<bool> checkVIPStatus(String userId) async {
    final points = await _repository.checkPoints(userId);
    if (points == null) return false;
    
    // VIP threshold is 1000 points
    return points.balance >= 1000;
  }

  // Upgrade to VIP if points threshold is met
  Future<bool> upgradeToVIP(String userId) async {
    final isVIP = await checkVIPStatus(userId);
    if (isVIP) {
      // TODO: Implement VIP status update in user profile
      return true;
    }
    return false;
  }
} 