// lib/services/test_notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class TestNotificationService {
  static final TestNotificationService _instance =
      TestNotificationService._internal();
  factory TestNotificationService() => _instance;
  TestNotificationService._internal();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // 로컬 알림 테스트
  Future<void> sendTestNotification() async {
    try {
      // 안드로이드 알림 설정
      const androidDetails = AndroidNotificationDetails(
        'emergency_channel',
        '긴급 알림',
        channelDescription: '재난 상황 및 긴급 알림',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      // iOS 알림 설정
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 테스트 알림 표시
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        '🚨 테스트 알림',
        '이것은 테스트 메시지입니다. 알림이 정상적으로 작동합니다!',
        notificationDetails,
      );

      debugPrint('✅ 로컬 테스트 알림 전송 성공');
    } catch (e) {
      debugPrint('❌ 로컬 테스트 알림 전송 실패: $e');
      rethrow;
    }
  }

  // FCM 토큰 확인 및 디버그 정보 출력
  Future<void> debugFCMStatus() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // FCM 토큰 가져오기
      final token = await messaging.getToken();
      debugPrint('🔑 FCM Token: $token');

      // 알림 권한 상태 확인
      final settings = await messaging.getNotificationSettings();
      debugPrint('🔔 Notification Status: ${settings.authorizationStatus}');

      // APNs 토큰 (iOS)
      final apnsToken = await messaging.getAPNSToken();
      debugPrint('🍎 APNs Token: $apnsToken');

      // 알림 채널 확인 (Android)
      debugPrint('📱 Platform: ${Theme.of(_instance._context!).platform}');
    } catch (e) {
      debugPrint('❌ FCM 디버그 정보 가져오기 실패: $e');
    }
  }

  BuildContext? _context;
  void setContext(BuildContext context) {
    _context = context;
  }
}
