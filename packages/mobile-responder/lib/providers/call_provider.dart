// lib/providers/call_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:goodpeople_responder/models/call.dart';
import 'package:goodpeople_responder/services/call_data_service.dart';
import 'package:goodpeople_responder/services/location_service.dart';

class CallProvider extends ChangeNotifier {
  final CallDataService _callDataService = CallDataService();
  final LocationService _locationService = LocationService();

  // 상태 관리 변수들
  List<Call> _allCalls = [];
  List<Call> _filteredCalls = [];
  bool _isLoading = true;
  String _filterType = "전체";
  Position? _currentPosition;
  StreamSubscription? _callsSubscription;
  bool _hasLocationPermission = false;

  // Getters
  List<Call> get allCalls => _allCalls;
  List<Call> get filteredCalls => _filteredCalls;
  bool get isLoading => _isLoading;
  String get filterType => _filterType;
  Position? get currentPosition => _currentPosition;
  bool get hasLocationPermission => _hasLocationPermission;

  // 초기화
  Future<void> initialize() async {
    debugPrint('[CallProvider] 초기화 시작');
    await checkLocationPermission();
    await getCurrentPosition();
    loadCalls();
  }

  // 위치 권한 체크 및 요청
  Future<void> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    _hasLocationPermission = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (!_hasLocationPermission) {
      debugPrint('[CallProvider] 위치 권한 거부됨');
    }
    
    notifyListeners();
  }

  // 현재 위치 가져오기
  Future<void> getCurrentPosition() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        _currentPosition = position;
        notifyListeners();
        // 위치가 업데이트되면 필터링 다시 적용
        _applyCurrentFilter();
      }
    } catch (e) {
      debugPrint('[CallProvider] 위치 정보 가져오기 실패: $e');
    }
  }

  // 재난 데이터 로드
  void loadCalls() {
    debugPrint('[CallProvider] loadCalls 시작');
    _callsSubscription?.cancel();

    _callsSubscription = _callDataService.getAvailableCallsStream().listen(
      (calls) {
        _allCalls = calls;
        _isLoading = false;
        
        // 즉시 업데이트를 위해 먼저 notifyListeners 호출
        notifyListeners();
        
        // 필터링 적용
        _applyCurrentFilter();
      },
      onError: (error) {
        debugPrint('[CallProvider] 데이터 수신 오류: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // 필터 변경
  void changeFilter(String filterType) {
    debugPrint('[CallProvider] 필터 변경: $_filterType -> $filterType');
    _filterType = filterType;
    notifyListeners();
    _applyCurrentFilter();
  }

  // 현재 필터 적용
  void _applyCurrentFilter() {
    debugPrint(
      '[CallProvider] _applyCurrentFilter 시작: $_filterType, 원본 데이터 개수: ${_allCalls.length}',
    );

    List<Call> filtered = List.from(_allCalls);

    // 타입 필터링 - 조건식 그대로 유지
    if (_filterType != "전체") {
      filtered = filtered.where((call) => call.eventType == _filterType).toList();
    }

    debugPrint('[CallProvider] 타입 필터링 후: ${filtered.length}개');

    // 정렬 - 기존 로직 그대로 유지
    if (_currentPosition != null) {
      _sortByDistance(filtered);
    } else {
      _sortByTime(filtered);
    }

    _filteredCalls = filtered;
    notifyListeners();
    debugPrint('[CallProvider] 최종 필터링 결과: ${_filteredCalls.length}개');
  }

  // 거리순 정렬 - 기존 로직 그대로 유지
  void _sortByDistance(List<Call> calls) {
    try {
      if (_currentPosition == null) return;

      for (int i = 0; i < calls.length; i++) {
        final distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          calls[i].lat,
          calls[i].lng,
        );
        calls[i] = calls[i].copyWith(distance: distance);
      }
      calls.sort((a, b) => a.distance.compareTo(b.distance));

      for (var call in calls) {
        debugPrint(
          '[CallProvider] ${call.eventType}: ${call.distance.toStringAsFixed(0)}m',
        );
      }
    } catch (e) {
      debugPrint('[CallProvider] 거리 정렬 오류: $e');
    }
  }

  // 시간순 정렬 - 기존 로직 그대로 유지
  void _sortByTime(List<Call> calls) {
    try {
      calls.sort((a, b) => b.startAt.compareTo(a.startAt));
    } catch (e) {
      debugPrint('[CallProvider] 시간 정렬 오류: $e');
    }
  }

  // 새로고침
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    
    // Firebase 캐시 동기화 강제
    try {
      await FirebaseDatabase.instance.goOnline();
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('[CallProvider] Firebase 동기화 오류: $e');
    }
    
    await getCurrentPosition();
    loadCalls();
  }

  @override
  void dispose() {
    debugPrint('[CallProvider] dispose 호출됨');
    _callsSubscription?.cancel();
    super.dispose();
  }
}
