import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // 초기화
  Future<void> initialize() async {
    // 알림 권한 요청
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // FCM 토큰 가져오기
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    // 로컬 알림 초기화
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _handleNotificationTap(details.payload);
      },
    );

    // 안드로이드 알림 채널 설정
    const androidChannel = AndroidNotificationChannel(
      'emergency_channel',
      '긴급 알림',
      description: '재난 상황 및 긴급 알림',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 앱이 백그라운드에서 시작되는 메시지 처리
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 앱이 종료된 상태에서 시작되는 처리
    final initialMsg = await _messaging.getInitialMessage();
    if (initialMsg != null) {
      _handleInitialMessage(initialMsg);
    }
  }

  // 포그라운드 메시지 처리
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('포그라운드 메시지 수신: ${message.notification?.title}');

    if (message.notification != null) {
      await _showLocalNotification(
        id: message.hashCode,
        title: message.notification?.title ?? '새 알림',
        body: message.notification?.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  // 로컬 알림 표시
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'emergency_channel',
      '긴급 알림',
      channelDescription: '재난 상황 및 긴급 알림',
      importance: Importance.high,
      priority: Priority.high,
      ticker: '알림',
    );

    final iosDetails = DarwinNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // 알림 탭 처리
  void _handleNotificationTap(String? payload) {
    debugPrint('알림 탭: $payload');
    // 여기서 특정 화면으로 이동하는 로직 구현
  }

  // 백그라운드에서 앱이 열릴 때
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('백그라운드에서 앱 열림: ${message.notification?.title}');
    _handleNotificationTap(message.data.toString());
  }

  // 종료된 상태에서 앱이 시작될 때
  void _handleInitialMessage(RemoteMessage message) {
    debugPrint('종료된 상태에서 앱 시작: ${message.notification?.title}');
    _handleNotificationTap(message.data.toString());
  }
}

// 백그라운드 메시지 핸들러 (최상위 함수로 정의해야 함)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('백그라운드 메시지 수신: ${message.notification?.title}');
  // 백그라운드 로직 처리
}
