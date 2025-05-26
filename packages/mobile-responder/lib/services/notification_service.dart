import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:typed_data';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // 초기화
  Future<void> initialize() async {
    try {
      // 알림 권한 요청
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false, // iOS에서 임시 권한 대신 명시적 권한 요청
      );

      debugPrint('알림 권한 상태: ${settings.authorizationStatus}');

      // 권한이 거부된 경우
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('알림 권한이 거부되었습니다');
        return;
      }

      // FCM 토큰 가져오기 및 저장
      await updateFcmToken();

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
        playSound: true,
        enableVibration: true,
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

      // 토큰 리프레시 리스너
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM 토큰 리프레시: $newToken');
        _saveFcmToken(newToken);
      });

      debugPrint('NotificationService 초기화 완료');
    } catch (e) {
      debugPrint('NotificationService 초기화 오류: $e');
    }
  }

  // FCM 토큰 업데이트
  Future<void> updateFcmToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _saveFcmToken(token);
      }
    } catch (e) {
      debugPrint('FCM 토큰 가져오기 실패: $e');
    }
  }

  // FCM 토큰 저장
  Future<void> _saveFcmToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Firebase Functions 사용
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('updateFcmToken');

      await callable.call({'token': token});
      debugPrint('FCM 토큰 저장 성공');
    } catch (e) {
      // Functions가 없는 경우 직접 저장
      try {
        await FirebaseDatabase.instance
            .ref('users/${user.uid}/fcmToken')
            .set(token);
        debugPrint('FCM 토큰 직접 저장 성공');
      } catch (error) {
        debugPrint('FCM 토큰 저장 실패: $error');
      }
    }
  }

  // 포그라운드 메시지 처리
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 포그라운드 메시지 수신: ${message.notification?.title}');
    debugPrint('📱 메시지 데이터: ${message.data}');

    // 사용자의 알림 설정 확인
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      debugPrint('🔔 [NotificationService] 알림 수신 - 사용자 설정 확인 중...');

      final snapshot =
          await FirebaseDatabase.instance
              .ref('users/${user.uid}/notificationEnabled')
              .get();
      final isEnabled = snapshot.value as bool? ?? true;

      debugPrint(
        '🔔 [NotificationService] 알림 설정 상태: ${isEnabled ? "켜짐" : "꺼짐"}',
      );

      if (!isEnabled) {
        debugPrint('❌ [NotificationService] 사용자가 알림을 비활성화함 - 알림 표시 안 함');
        return;
      }

      debugPrint('✅ [NotificationService] 알림 표시 진행');
    }

    // notification 또는 data 중 하나라도 있으면 알림 표시
    if (message.notification != null || message.data.isNotEmpty) {
      // 알림 타입에 따른 처리
      final notificationType = message.data['type'] ?? 'new_call';
      final eventType = message.data['eventType'] ?? '재난';
      final address = message.data['address'] ?? '';

      String title =
          message.notification?.title ??
          (notificationType == 'recall' ? '🚨 재난 재호출' : '🚨 긴급 출동');
      String body = message.notification?.body ?? '$eventType - $address';

      debugPrint('🔔 로컬 알림 표시: $title - $body');

      await _showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        payload: message.data.toString(),
      );
    } else {
      debugPrint('⚠️ 알림 데이터가 없습니다');
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
      sound: RawResourceAndroidNotificationSound('default'),
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      enableVibration: true,
      playSound: true,
    );

    final iosDetails = DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

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
    // 예: 재난 상세 화면으로 이동
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

  // 사용자의 백그라운드 알림 설정 확인
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final snapshot =
        await FirebaseDatabase.instance
            .ref('users/${user.uid}/backgroundNotificationEnabled')
            .get();
    final isEnabled = snapshot.value as bool? ?? true;

    if (!isEnabled) {
      debugPrint('사용자가 백그라운드 알림을 비활성화함');
      return;
    }
  }

  // 백그라운드 알림 처리 로직
}
