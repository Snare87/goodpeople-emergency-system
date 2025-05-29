// lib/screens/navigation_screen.dart - 실제 네비게이션 화면
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:goodpeople_responder/services/directions_service.dart';
import 'package:goodpeople_responder/models/call.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:math' as math;

class NavigationScreen extends StatefulWidget {
  final String callId;
  final Call missionData;

  const NavigationScreen({
    super.key,
    required this.callId,
    required this.missionData,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> with TickerProviderStateMixin {
  GoogleMapController? mapController;
  Position? currentPosition;
  DirectionsResult? directionsResult;
  StreamSubscription<Position>? positionStreamSubscription;
  
  bool isNavigating = false;
  int currentStepIndex = 0;
  double? bearing;
  double distanceToNextStep = 0;
  
  // 카메라 설정
  static const double NAVIGATION_ZOOM = 18.0;
  static const double NAVIGATION_TILT = 60.0;
  static const double CAMERA_BEARING_OFFSET = 0.0;
  
  // UI 상태
  bool showFullDirections = false;
  
  @override
  void initState() {
    super.initState();
    // 화면을 가로 모드로 고정 (선택사항)
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.landscapeRight,
    // ]);
    _startNavigation();
  }

  @override
  void dispose() {
    // 화면 방향 제한 해제
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    positionStreamSubscription?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _startNavigation() async {
    setState(() {
      isNavigating = true;
    });

    // 초기 위치 가져오기
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        currentPosition = position;
      });

      // 경로 계산
      await _calculateRoute();

      // 실시간 위치 추적 시작
      _startLocationTracking();
    } catch (e) {
      debugPrint('네비게이션 시작 실패: $e');
    }
  }

  Future<void> _calculateRoute() async {
    if (currentPosition == null) return;

    // 거리 계산 (디버깅용)
    final distance = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      widget.missionData.lat,
      widget.missionData.lng,
    );
    
    debugPrint('[NavigationScreen] 목적지까지 거리: ${distance.toStringAsFixed(0)}m');
    
    // 항상 Google Directions API 먼저 시도
    DirectionsResult? result = await DirectionsService.getDirections(
      origin: LatLng(currentPosition!.latitude, currentPosition!.longitude),
      destination: LatLng(widget.missionData.lat, widget.missionData.lng),
    );
    
    // API가 경로를 찾지 못한 경우에만 직선 경로 사용
    if (result == null) {
      debugPrint('[NavigationScreen] 경로 검색 실패, 직선 경로 사용');
      result = DirectionsService.createStraightLineRoute(
        origin: LatLng(currentPosition!.latitude, currentPosition!.longitude),
        destination: LatLng(widget.missionData.lat, widget.missionData.lng),
      );
    } else {
      debugPrint('[NavigationScreen] 경로 검색 성공, 도로 경로 사용');
    }

    if (result != null) {
      setState(() {
        directionsResult = result;
        currentStepIndex = 0;
      });
      _updateCameraPosition();
    }
  }

  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // 5미터마다 업데이트
    );

    positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        currentPosition = position;
        bearing = position.heading;
      });

      _updateNavigationState();
      _updateCameraPosition();
      _checkIfOffRoute();
    });
  }

  void _updateNavigationState() {
    if (directionsResult == null || currentPosition == null) return;

    // 다음 단계까지의 거리 계산
    if (currentStepIndex < directionsResult!.steps.length) {
      final currentStep = directionsResult!.steps[currentStepIndex];
      distanceToNextStep = Geolocator.distanceBetween(
        currentPosition!.latitude,
        currentPosition!.longitude,
        currentStep.endLocation.latitude,
        currentStep.endLocation.longitude,
      );

      // 다음 단계에 가까워지면 단계 증가
      if (distanceToNextStep < 30) {
        if (currentStepIndex < directionsResult!.steps.length - 1) {
          setState(() {
            currentStepIndex++;
          });
          
          // 음성 안내 (TTS 추가 시)
          _speakInstruction(directionsResult!.steps[currentStepIndex].instruction);
        }
      }
    }

    // 목적지 도착 확인
    final distanceToDestination = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      widget.missionData.lat,
      widget.missionData.lng,
    );

    if (distanceToDestination < 30) {
      _onArrival();
    }
  }

  void _updateCameraPosition() {
    if (mapController == null || currentPosition == null) return;

    final cameraPosition = CameraPosition(
      target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
      zoom: NAVIGATION_ZOOM,
      tilt: 0,  // 2D 지도 유지
      bearing: bearing ?? 0,
    );

    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );
  }

  void _checkIfOffRoute() {
    // 경로 이탈 확인 로직
    // 필요시 재계산
  }

  void _speakInstruction(String instruction) {
    // TTS 구현 (향후 추가)
    debugPrint('음성 안내: $instruction');
  }

  void _onArrival() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎯 목적지 도착'),
        content: const Text('재난 현장에 도착했습니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // 네비게이션 종료
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 지도 (전체 화면)
          if (currentPosition != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
                zoom: NAVIGATION_ZOOM,
                tilt: 0,  // 2D 지도로 변경
              ),
              tiltGesturesEnabled: false,  // 3D 제스처 비활성화
              onMapCreated: (controller) {
                mapController = controller;
                // 다크 모드 스타일 적용
                controller.setMapStyle('''
                  [
                    {
                      "elementType": "geometry",
                      "stylers": [{"color": "#242f3e"}]
                    },
                    {
                      "elementType": "labels.text.stroke",
                      "stylers": [{"color": "#242f3e"}]
                    },
                    {
                      "elementType": "labels.text.fill",
                      "stylers": [{"color": "#746855"}]
                    }
                  ]
                ''');
              },
              polylines: directionsResult != null
                  ? {
                      Polyline(
                        polylineId: const PolylineId('route'),
                        points: directionsResult!.polylinePoints,
                        color: Colors.blue,
                        width: 8,
                      ),
                    }
                  : {},
              markers: {
                // 목적지 마커
                Marker(
                  markerId: const MarkerId('destination'),
                  position: LatLng(widget.missionData.lat, widget.missionData.lng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
            ),

          // 상단 네비게이션 정보
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.0),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // 다음 방향 안내
                    if (directionsResult != null && currentStepIndex < directionsResult!.steps.length)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                directionsResult!.steps[currentStepIndex].getManeuverIcon(),
                                size: 60,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDistance(distanceToNextStep),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    directionsResult!.steps[currentStepIndex].instruction,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 다음 다음 단계 미리보기
                    if (directionsResult != null && currentStepIndex < directionsResult!.steps.length - 1)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              directionsResult!.steps[currentStepIndex + 1].getManeuverIcon(),
                              color: Colors.white54,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '다음: ${directionsResult!.steps[currentStepIndex + 1].instruction}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 하단 정보 패널
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 도착 정보
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoItem(
                            Icons.location_on,
                            directionsResult?.distanceText ?? '-',
                            '남은 거리',
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white24,
                          ),
                          _buildInfoItem(
                            Icons.access_time,
                            directionsResult?.durationText ?? '-',
                            '예상 시간',
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white24,
                          ),
                          _buildInfoItem(
                            Icons.speed,
                            '${currentPosition?.speed.toStringAsFixed(0) ?? '0'} km/h',
                            '현재 속도',
                          ),
                        ],
                      ),
                    ),

                    // 네비게이션 종료 버튼
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '네비게이션 종료',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 로딩 표시
          if (!isNavigating)
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    } else if (meters >= 100) {
      return '${(meters / 100).round() * 100}m';
    } else {
      return '${meters.round()}m';
    }
  }
}
