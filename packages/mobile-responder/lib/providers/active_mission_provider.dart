// lib/providers/active_mission_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:goodpeople_responder/models/call.dart';
import 'package:goodpeople_responder/services/location_service.dart';
import 'package:goodpeople_responder/services/call_data_service.dart';
import 'package:goodpeople_responder/services/background_location_service.dart';

class ActiveMissionProvider extends ChangeNotifier {
  final db = FirebaseDatabase.instance;
  final CallDataService _callDataService = CallDataService();
  final LocationService _locationService = LocationService();
  
  // 상태 변수들
  Call? _missionData;
  Position? _userPosition;
  StreamSubscription? _callSubscription;
  StreamSubscription? _positionSubscription;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  // Getters
  Call? get missionData => _missionData;
  Position? get userPosition => _userPosition;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

  // 임무 초기화
  Future<void> initializeMission(String callId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // 미션 데이터 로드
      _loadMissionData(callId);
      
      // 현재 위치 가져오기
      await _getCurrentPosition();
      
      // 위치 추적 시작
      _startTracking(callId);
      
      // 활성 임무 중에는 30초마다 위치 업데이트
      BackgroundLocationService().startActiveMissionTracking();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '임무 초기화 실패: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // 미션 데이터 로드
  void _loadMissionData(String callId) {
    _callSubscription = db.ref("calls/$callId").onValue.listen(
      (event) {
        if (event.snapshot.exists) {
          final data = Map<String, dynamic>.from(
            event.snapshot.value as Map,
          );
          _missionData = Call.fromMap(callId, data);
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('임무 데이터를 불러오는데 실패했습니다: $error');
        _errorMessage = '임무 데이터를 불러오는데 실패했습니다';
        notifyListeners();
      },
    );
  }

  // 현재 위치 가져오기
  Future<void> _getCurrentPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
      _userPosition = position;
      notifyListeners();
    } catch (e) {
      debugPrint('위치 정보를 가져오는데 실패했습니다: $e');
      _errorMessage = '위치 정보를 가져오는데 실패했습니다';
      notifyListeners();
    }
  }

  // 위치 추적 시작
  void _startTracking(String callId) {
    _locationService.startLocationStream(callId, 'responder_id');
    
    // 실시간 위치 업데이트 리스너
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _userPosition = position;
      notifyListeners();
    });
  }

  // 임무 완료
  Future<bool> completeMission() async {
    if (_missionData == null) return false;
    
    _isProcessing = true;
    notifyListeners();
    
    try {
      _locationService.stopTracking();
      final success = await _callDataService.completeCall(_missionData!.id);
      
      _isProcessing = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      debugPrint('임무 완료 처리 중 오류: $e');
      _errorMessage = '임무 완료 처리 중 오류가 발생했습니다';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  // 수락 취소
  Future<bool> cancelAcceptance() async {
    if (_missionData == null) return false;
    
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      _errorMessage = '사용자 정보를 찾을 수 없습니다';
      notifyListeners();
      return false;
    }
    
    _isProcessing = true;
    notifyListeners();
    
    try {
      _locationService.stopTracking();
      final success = await _callDataService.cancelAcceptance(
        _missionData!.id,
        currentUserId,
      );
      
      _isProcessing = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      debugPrint('수락 취소 처리 중 오류: $e');
      _errorMessage = '수락 취소 처리 중 오류가 발생했습니다';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  // 상태 텍스트 가져오기
  String getMissionStatusText(String status) {
    switch (status) {
      case 'accepted':
        return '임무 수락됨';
      case 'dispatched':
        return '출동 중';
      case 'completed':
        return '임무 완료';
      default:
        return '알 수 없음';
    }
  }

  // 경과 시간 계산
  String getElapsedTime(int timestamp) {
    final diff = DateTime.now().millisecondsSinceEpoch - timestamp;
    final seconds = diff ~/ 1000;

    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;

    if (hours > 0) {
      return '$hours시간 ${minutes % 60}분';
    } else if (minutes > 0) {
      return '$minutes분 ${seconds % 60}초';
    } else {
      return '$seconds초';
    }
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    _callSubscription?.cancel();
    _positionSubscription?.cancel();
    // 일반 백그라운드 추적으로 돌아가기 (3분 간격)
    BackgroundLocationService().startBackgroundTracking();
    super.dispose();
  }
}
