import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vacancy_notification.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  static final provider = Provider<NotificationRepository>((ref) {
    return NotificationRepository(
      firestore: FirebaseFirestore.instance,
    );
  });

  Future<void> addNotification(VacancyNotification notification) async {
    try {
      await _firestore.collection('notifications').add({
        ...notification.toMap(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding notification: $e');
      rethrow;
    }
  }

  Stream<List<VacancyNotification>> getNotifications() {
    return _firestore
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return VacancyNotification.fromMap(data);
      }).toList();
    });
  }
} 