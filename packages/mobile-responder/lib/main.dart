// lib/main.dart - void 오류 수정됨
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:goodpeople_responder/services/notification_service.dart';
import 'package:goodpeople_responder/services/background_location_service.dart';

// 백그라운드 메시지 핸들러 설정 (최상위 함수여야 함)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // void 반환 함수는 await 없이 호출
}

void main() async {
  // Flutter 엔진과 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 시도
  try {
    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase 초기화 성공');

    // Firebase 데이터베이스 설정
    _configureFirebaseDatabase(); // await 제거 (void 오류 방지)

    // 백그라운드 메시지 핸들러 설정
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 알림 서비스 초기화 - Future<void>를 반환하므로 await 사용
    await NotificationService().initialize();
    debugPrint('✅ 알림 서비스 초기화 완료');

    // 초기화 성공 - 정상 앱 실행
    runApp(const MyApp());
  } catch (e) {
    debugPrint('❌ Firebase 초기화 오류: $e');
    // 초기화 실패 - 에러 화면 표시
    runApp(const MyAppErrorFallback());
  }
}

// Firebase Realtime Database 설정 - void 반환 함수는 Future<void>로 선언하지 않음
void _configureFirebaseDatabase() {
  try {
    // 오프라인 지속성 활성화 - void 반환 함수는 await 없이 호출
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    debugPrint('✅ Firebase 데이터베이스 지속성 활성화 완료');

    // 주요 경로 캐싱 설정 - void 반환 함수는 await 없이 호출
    FirebaseDatabase.instance.ref('calls').keepSynced(true);
    FirebaseDatabase.instance.ref('users').keepSynced(true);
    debugPrint('✅ 주요 데이터 경로 캐싱 설정 완료');

    // 연결 상태 확인
    FirebaseDatabase.instance.ref('.info/connected').onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      debugPrint('🔥 Firebase 연결 상태: $connected');
    });

    // 서버 시간 확인
    FirebaseDatabase.instance.ref('.info/serverTimeOffset').onValue.listen((
      event,
    ) {
      final offset = event.snapshot.value;
      debugPrint('🕐 Firebase 서버 시간 오프셋: $offset');
    });
  } catch (e) {
    debugPrint('❌ Firebase 데이터베이스 설정 오류: $e');
    // 오류가 발생해도 앱은 계속 실행 (오프라인 모드)
  }
}

// 기본 앱 클래스
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoodPeople 응답자',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 인증 상태에 따라 화면 분기
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              // 로그인된 상태 - 백그라운드 위치 추적 시작
              _startBackgroundServices();
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

  // 백그라운드 서비스 시작
  void _startBackgroundServices() {
    // 백그라운드 위치 추적 시작
    BackgroundLocationService().startBackgroundTracking();

    // FCM 토큰 업데이트
    NotificationService().updateFcmToken();
  }
}

// 오류 발생 시 보여줄 대체 앱
class MyAppErrorFallback extends StatelessWidget {
  const MyAppErrorFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoodPeople 응답자',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  '앱 초기화 중 오류가 발생했습니다',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '네트워크 연결을 확인하고 앱을 다시 시작해주세요.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // 앱 종료 요청 - 사용자가 직접 앱을 다시 시작하도록 유도
                    SystemNavigator.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('앱 종료'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
