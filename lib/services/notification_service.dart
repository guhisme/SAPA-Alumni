import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';
import '../utils/constants.dart';

/// Notifikasi in-app (dokumen Firestore). Push FCM ditangani fcm_service.dart
/// dan Cloud Functions di sisi server.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(Col.notifications);

  Stream<List<NotificationModel>> watchMyNotifications(String userId) {
    return Stream.fromFuture(_col.where('userId', isEqualTo: userId).get())
        .map((s) {
      final list = s.docs.map(NotificationModel.fromDoc).toList();
      list.sort((a, b) {
        final da = a.createdAt ?? Timestamp(0, 0);
        final db_ = b.createdAt ?? Timestamp(0, 0);
        return db_.compareTo(da);
      });
      return list;
    });
  }

  Stream<int> watchUnreadCount(String userId) => Stream.fromFuture(
        _col
            .where('userId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .count()
            .get(),
      ).map((s) => s.count ?? 0);

  Future<void> create({
    required String userId,
    required String title,
    required String body,
    String type = '',
    String referenceId = '',
  }) async {
    final ref = _col.doc();
    await ref.set(NotificationModel(
      id: ref.id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      referenceId: referenceId,
    ).toMap());
  }

  Future<void> markAsRead(String id) =>
      _col.doc(id).set({'isRead': true}, SetOptions(merge: true));

  Future<void> markAllAsRead(String userId) async {
    final snap = await _col
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;
    for (var i = 0; i < snap.docs.length; i += 500) {
      final batch = _db.batch();
      for (final doc in snap.docs.skip(i).take(500)) {
        batch.set(doc.reference, {'isRead': true}, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  Future<void> delete(String id) => _col.doc(id).delete();
}
