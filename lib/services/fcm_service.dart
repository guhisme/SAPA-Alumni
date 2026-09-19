import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'user_service.dart';

/// Handler pesan saat aplikasi berada di background/terminated.
/// Harus berupa top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.messageId}');
}

/// Registrasi izin notifikasi, penyimpanan token, dan listener pesan.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _initializedUid;
  String? _initializingUid;
  StreamSubscription<String>? _tokenSubscription;
  bool _foregroundListenerAttached = false;

  /// Dipanggil setelah user login.
  Future<void> initForUser(String uid) async {
    if (_initializedUid == uid || _initializingUid == uid) return;
    _initializingUid = uid;
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await _messaging.getToken();
      if (token != null) {
        await UserService.instance.saveFcmToken(uid, token);
      }

      await _tokenSubscription?.cancel();
      _tokenSubscription = _messaging.onTokenRefresh.listen((newToken) {
        UserService.instance.saveFcmToken(uid, newToken);
      });

      // Topik broadcast untuk pengumuman/beasiswa/pelatihan baru.
      await _messaging.subscribeToTopic('alumni');
      _initializedUid = uid;
    } catch (e) {
      debugPrint('FCM init gagal: $e');
    } finally {
      if (_initializedUid != uid) _initializingUid = null;
    }
  }

  /// Menampilkan snackbar ketika notifikasi masuk saat aplikasi terbuka.
  void listenForeground(GlobalKey<ScaffoldMessengerState> messengerKey) {
    if (_foregroundListenerAttached) return;
    _foregroundListenerAttached = true;
    FirebaseMessaging.onMessage.listen((message) {
      final notif = message.notification;
      if (notif == null) return;
      messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('${notif.title ?? ''}\n${notif.body ?? ''}'.trim()),
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  Future<void> clearForUser(String uid) async {
    try {
      await _messaging.unsubscribeFromTopic('alumni');
      await UserService.instance.removeFcmToken(uid);
      await _messaging.deleteToken();
      if (_initializedUid == uid) {
        _initializedUid = null;
        await _tokenSubscription?.cancel();
        _tokenSubscription = null;
      }
    } catch (e) {
      debugPrint('FCM clear gagal: $e');
    }
  }
}
