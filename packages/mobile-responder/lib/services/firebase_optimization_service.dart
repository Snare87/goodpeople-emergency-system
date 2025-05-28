// lib/services/firebase_optimization_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class FirebaseOptimizationService {
  static final FirebaseOptimizationService _instance = 
      FirebaseOptimizationService._internal();
  factory FirebaseOptimizationService() => _instance;
  FirebaseOptimizationService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Firebase 연결 최적화 초기화
  Future<void> initialize() async {
    try {
      // 1. 오프라인 지속성 활성화 (이미 main.dart에 있음)
      // _database.setPersistenceEnabled(true);
      
      // 2. 연결 타임아웃 단축
      _database.setLoggingEnabled(kDebugMode);
      
      // 3. 주요 경로 동기화 우선순위 설정
      final callsRef = _database.ref('calls');
      callsRef.keepSynced(true);
      
      // 4. 연결 상태 모니터링
      _monitorConnection();
      
      debugPrint('[FirebaseOptimization] 초기화 완료');
    } catch (e) {
      debugPrint('[FirebaseOptimization] 초기화 오류: $e');
    }
  }

  // 연결 상태 모니터링
  void _monitorConnection() {
    _database.ref('.info/connected').onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      debugPrint('[Firebase] 연결 상태: ${connected ? "연결됨" : "연결 끊김"}');
      
      if (!connected) {
        // 연결이 끊어진 경우 재연결 시도
        _attemptReconnection();
      }
    });
  }

  // 재연결 시도
  Future<void> _attemptReconnection() async {
    try {
      await _database.goOnline();
      debugPrint('[Firebase] 재연결 시도 중...');
    } catch (e) {
      debugPrint('[Firebase] 재연결 실패: $e');
    }
  }

  // 강제 동기화
  Future<void> forceSyncData() async {
    try {
      // 오프라인 -> 온라인 -> 오프라인 사이클로 강제 동기화
      await _database.goOffline();
      await Future.delayed(const Duration(milliseconds: 100));
      await _database.goOnline();
      debugPrint('[Firebase] 강제 동기화 완료');
    } catch (e) {
      debugPrint('[Firebase] 강제 동기화 오류: $e');
    }
  }

  // 서버 시간과의 오프셋 가져오기
  Future<int> getServerTimeOffset() async {
    try {
      final offsetSnapshot = await _database.ref('.info/serverTimeOffset').get();
      return offsetSnapshot.value as int? ?? 0;
    } catch (e) {
      debugPrint('[Firebase] 서버 시간 오프셋 조회 실패: $e');
      return 0;
    }
  }
}
