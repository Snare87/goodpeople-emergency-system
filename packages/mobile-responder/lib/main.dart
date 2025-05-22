// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart'; // 추가
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:goodpeople_responder/services/notification_service.dart';

// 백그라운드 메시지 핸들러 설정 (최상위 함수여야 함)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await firebaseMessagingBackgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 백그라운드 메시지 핸들러 설정
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 알림 서비스 초기화
  await NotificationService().initialize();

  // Firebase 오프라인 지속성 활성화 (원래대로 복구)
  FirebaseDatabase.instance.setPersistenceEnabled(true);

  // Firebase 연결 상태 및 진단 정보
  FirebaseDatabase.instance.ref('.info/connected').onValue.listen((event) {
    final connected = event.snapshot.value as bool? ?? false;
    debugPrint('🔥 Firebase 연결 상태: $connected');

    if (!connected) {
      debugPrint('❌ Firebase 연결 실패 - 네트워크 또는 설정 문제');
    } else {
      debugPrint('✅ Firebase 연결 성공');
    }
  });

  // 서버 시간으로 연결 테스트
  FirebaseDatabase.instance.ref('.info/serverTimeOffset').onValue.listen((
    event,
  ) {
    final offset = event.snapshot.value;
    debugPrint('🕐 Firebase 서버 시간 오프셋: $offset');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoodPeople 응답자',
      theme: ThemeData(primarySwatch: Colors.red),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 인증 상태에 따라 화면 분기
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              // 로그인된 상태 - MainScreen으로 변경
              return const MainScreen();
            } else {
              // 로그인되지 않은 상태
              return const LoginScreen();
            }
          }
          // 로딩 화면
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
