// lib/services/background_location_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_functions/cloud_functions.dart';

class BackgroundLocationService {
  static final BackgroundLocationService _instance =
      BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;

  // 3분 간격 설정
  static const Duration _updateInterval = Duration(minutes: 3);

  // 백그라운드 위치 추적 시작
  Future<void> startBackgroundTracking() async {
    if (_isTracking) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 사용자 설정 확인
    final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
    final snapshot = await userRef.get();

    if (snapshot.exists) {
      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      final locationEnabled = userData['locationEnabled'] ?? true;
      final backgroundNotificationEnabled =
          userData['backgroundNotificationEnabled'] ?? true;

      if (!locationEnabled || !backgroundNotificationEnabled) {
        debugPrint('[BackgroundLocation] 위치 추적이 비활성화되어 있습니다.');
        return;
      }
    }

    // 위치 권한 확인
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('[BackgroundLocation] 위치 권한이 거부되었습니다.');
      return;
    }

    _isTracking = true;

    // 즉시 한 번 위치 업데이트
    await _updateLocation();

    // 3분마다 위치 업데이트
    _locationTimer = Timer.periodic(_updateInterval, (_) async {
      await _updateLocation();
    });

    debugPrint('[BackgroundLocation] 백그라운드 위치 추적 시작됨');
  }

  // 위치 업데이트
  Future<void> _updateLocation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 사용자 설정 재확인
      final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
      final snapshot = await userRef.get();

      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        final locationEnabled = userData['locationEnabled'] ?? true;

        if (!locationEnabled) {
          debugPrint('[BackgroundLocation] 위치 추적이 사용자에 의해 비활성화됨');
          stopBackgroundTracking();
          return;
        }
      }

      // 현재 위치 가져오기
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
      debugPrint(
        '[BackgroundLocation] 위치 업데이트: ${position.latitude}, ${position.longitude}',
      );

      // Firebase Functions 호출하여 위치 업데이트
      try {
        final functions = FirebaseFunctions.instance;
        final callable = functions.httpsCallable('updateUserLocation');

        await callable.call({
          'lat': position.latitude,
          'lng': position.longitude,
        });

        debugPrint('[BackgroundLocation] Firebase에 위치 업데이트 성공');
      } catch (e) {
        // Functions가 없는 경우 직접 업데이트
        await userRef.child('lastLocation').set({
          'lat': position.latitude,
          'lng': position.longitude,
          'updatedAt': ServerValue.timestamp,
        });
        debugPrint('[BackgroundLocation] 직접 위치 업데이트 성공');
      }
    } catch (e) {
      debugPrint('[BackgroundLocation] 위치 업데이트 실패: $e');
    }
  }

  // 백그라운드 위치 추적 중지
  void stopBackgroundTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    debugPrint('[BackgroundLocation] 백그라운드 위치 추적 중지됨');
  }

  // 추적 중인지 확인
  bool get isTracking => _isTracking;

  // 활성 임무가 있을 때 더 자주 업데이트 (30초마다)
  Future<void> startActiveMissionTracking() async {
    stopBackgroundTracking(); // 기존 추적 중지

    if (_isTracking) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isTracking = true;

    // 즉시 한 번 위치 업데이트
    await _updateLocation();

    // 30초마다 위치 업데이트
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _updateLocation();
    });

    debugPrint('[BackgroundLocation] 활성 임무 위치 추적 시작됨 (30초 간격)');
  }
}
