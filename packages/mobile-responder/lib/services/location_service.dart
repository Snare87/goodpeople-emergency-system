// lib/services/location_service.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;
  String? _currentCallId;
  String? _currentResponderId;
  bool _isTracking = false;

  // 위치 추적 시작 - 주기적 타이머 방식
  Future<bool> startTracking(String callId, String responderId) async {
    if (_isTracking) {
      stopTracking();
    }

    try {
      _currentCallId = callId;
      _currentResponderId = responderId;
      _isTracking = true;

      // 즉시 한 번 위치 업데이트
      await _updateLocation();

      // 주기적 위치 업데이트 설정 (30초마다)
      _locationTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _updateLocation(),
      );

      return true;
    } catch (e) {
      debugPrint('위치 추적 시작 오류: $e');
      _isTracking = false;
      return false;
    }
  }

  // 위치 스트림 방식으로 추적 시작 (1번 고려사항)
  Future<bool> startLocationStream(String callId, String responderId) async {
    if (_isTracking) {
      stopTracking();
    }

    try {
      _currentCallId = callId;
      _currentResponderId = responderId;
      _isTracking = true;

      // 위치 스트림 설정 - 간소화된 버전
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // 10미터마다 업데이트
        ),
      ).listen((Position position) {
        // 위치 업데이트 처리
        _updateLocationToFirebase(position);
      });

      return true;
    } catch (e) {
      debugPrint('위치 스트림 시작 오류: $e');
      _isTracking = false;
      return false;
    }
  }

  // Firebase에 위치 업데이트 (스트림용)
  Future<void> _updateLocationToFirebase(Position position) async {
    if (!_isTracking || _currentCallId == null) return;

    try {
      await FirebaseDatabase.instance
          .ref('calls/$_currentCallId/responder')
          .update({
            'lat': position.latitude,
            'lng': position.longitude,
            'updatedAt': ServerValue.timestamp,
          });

      debugPrint('위치 업데이트 성공: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('Firebase 위치 업데이트 오류: $e');
    }
  }

  // 위치 추적 중지
  void stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _positionStream?.cancel();
    _positionStream = null;
    _currentCallId = null;
    _currentResponderId = null;
    _isTracking = false;
    debugPrint('위치 추적 중지됨');
  }

  // 단일 위치 업데이트 함수 (타이머 방식)
  Future<void> _updateLocation() async {
    if (!_isTracking || _currentCallId == null || _currentResponderId == null) {
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('위치 서비스가 비활성화되어 있습니다.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('위치 권한이 없습니다.');
        return;
      }

      // 위치 정보 가져오기 (최신 방식)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('위치 정보 요청 타임아웃');
          throw Exception('위치 정보 요청 타임아웃');
        },
      );

      // Firebase에 위치 업데이트
      await FirebaseDatabase.instance
          .ref('calls/$_currentCallId/responder')
          .update({
            'lat': position.latitude,
            'lng': position.longitude,
            'updatedAt': ServerValue.timestamp,
          });

      debugPrint('위치 업데이트 성공: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('위치 업데이트 오류: $e');
    }
  }

  // 현재 위치 한 번만 가져오기 (외부에서 호출용)
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('현재 위치 가져오기 오류: $e');
      return null;
    }
  }

  // 두 지점 사이의 거리 계산 (유틸리티 함수)
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  // 추적 중인지 여부
  bool get isTracking => _isTracking;
}
