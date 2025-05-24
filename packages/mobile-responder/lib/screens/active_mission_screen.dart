// lib/screens/active_mission_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:goodpeople_responder/models/call.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:goodpeople_responder/services/location_service.dart';
import 'package:goodpeople_responder/services/call_data_service.dart'; // CallDataService 추가
import 'dart:async';

class ActiveMissionScreen extends StatefulWidget {
  final String callId;

  const ActiveMissionScreen({super.key, required this.callId});

  @override
  State<ActiveMissionScreen> createState() => _ActiveMissionScreenState();
}

class _ActiveMissionScreenState extends State<ActiveMissionScreen> {
  final db = FirebaseDatabase.instance;
  Call? missionData;
  Position? userPosition;
  GoogleMapController? mapController;
  Timer? _locationUpdateTimer;
  StreamSubscription? _callSubscription;
  final CallDataService _callDataService = CallDataService(); // 서비스 인스턴스 추가

  @override
  void initState() {
    super.initState();
    _loadMissionData();
    _getCurrentPosition();
    _startTracking(); // 위치 추적 시작
  }

  @override
  void dispose() {
    // 화면이 닫힐 때 위치 추적 중지
    LocationService().stopTracking();
    _callSubscription?.cancel(); // 기존 구독 취소 코드가 있는 경우
    mapController = null; // 지도 컨트롤러 해제 코드가 있는 경우
    super.dispose();
  }

  // 위치 추적 시작
  void _startTracking() {
    // 스트림 기반 위치 업데이트 (더 효율적, 더 정확한 실시간 추적)
    LocationService().startLocationStream(widget.callId, 'responder_id');
  }

  // 임무 데이터 불러오기
  void _loadMissionData() {
    _callSubscription = db
        .ref("calls/${widget.callId}")
        .onValue
        .listen(
          (event) {
            if (event.snapshot.exists) {
              final data = Map<String, dynamic>.from(
                event.snapshot.value as Map,
              );
              setState(() {
                missionData = Call.fromMap(widget.callId, data);
              });
            }
          },
          onError: (error) {
            debugPrint('임무 데이터를 불러오는데 실패했습니다: $error');
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
      setState(() {
        userPosition = position;
      });

      // 지도 중심 업데이트
      _updateMapCamera();
    } catch (e) {
      debugPrint('위치 정보를 가져오는데 실패했습니다: $e');
    }
  }

  // 주기적 위치 업데이트 시작
  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (
      _,
    ) async {
      try {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          userPosition = position;
        });

        // 사용자 위치 업데이트
        if (missionData != null) {
          db.ref("calls/${widget.callId}/responder").update({
            "lat": position.latitude,
            "lng": position.longitude,
            "updatedAt": DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('위치 업데이트 실패: $e');
      }
    });
  }

  // 카메라 업데이트
  void _updateMapCamera() {
    if (mapController == null || missionData == null) return;

    // 두 지점 사이의 중간 지점 계산
    if (userPosition != null) {
      final midLat = (userPosition!.latitude + missionData!.lat) / 2;
      final midLng = (userPosition!.longitude + missionData!.lng) / 2;

      // 두 점 사이의 거리 계산
      final distance = Geolocator.distanceBetween(
        userPosition!.latitude,
        userPosition!.longitude,
        missionData!.lat,
        missionData!.lng,
      );

      // 거리에 따른 줌 레벨 조정
      double zoomLevel = 15.0;
      if (distance > 10000) {
        zoomLevel = 10.0;
      } else if (distance > 5000) {
        zoomLevel = 11.0;
      } else if (distance > 1000) {
        zoomLevel = 13.0;
      }

      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(midLat, midLng), zoom: zoomLevel),
        ),
      );
    } else {
      // 사용자 위치가 없으면 목적지만 표시
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(missionData!.lat, missionData!.lng),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  // 임무 완료 처리 - 수정됨
  Future<void> _completeMission() async {
    // 확인 다이얼로그 표시
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('임무 완료'),
            content: const Text('정말 이 임무를 완료하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('완료'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("임무 완료 처리 중..."),
              ],
            ),
          ),
    );

    // 위치 추적 중지
    LocationService().stopTracking();

    try {
      // CallDataService를 통해 완료 처리
      final success = await _callDataService.completeCall(widget.callId);

      // 로딩 다이얼로그 닫기
      if (mounted) Navigator.pop(context);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("임무가 완료되었습니다!"),
              backgroundColor: Colors.green,
            ),
          );

          // 잠시 후 화면 닫기 (성공 메시지 보여줌)
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("임무 완료 처리 중 오류가 발생했습니다."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("오류가 발생했습니다: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('진행 중인 임무'),
        backgroundColor: Colors.red,
      ),
      body:
          missionData == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // 상태 표시 바
                  Container(
                    color: _getMissionStatusColor(missionData!.status),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getMissionStatusIcon(missionData!.status),
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getMissionStatusText(missionData!.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 지도 표시
                  Expanded(
                    flex: 2,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(missionData!.lat, missionData!.lng),
                        zoom: 15,
                      ),
                      markers: {
                        // 목적지 마커
                        Marker(
                          markerId: const MarkerId('destination'),
                          position: LatLng(missionData!.lat, missionData!.lng),
                          infoWindow: InfoWindow(title: missionData!.eventType),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                        // 사용자 위치 마커
                        if (userPosition != null)
                          Marker(
                            markerId: const MarkerId('user'),
                            position: LatLng(
                              userPosition!.latitude,
                              userPosition!.longitude,
                            ),
                            infoWindow: const InfoWindow(title: '내 위치'),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueBlue,
                            ),
                          ),
                      },
                      onMapCreated: (controller) {
                        mapController = controller;
                        _updateMapCamera();
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                  ),

                  // 임무 정보
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            missionData!.eventType,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            missionData!.address,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 상세 정보 표시 (있을 경우)
                          if (missionData!.info != null &&
                              missionData!.info!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '상황 정보:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[800],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    missionData!.info!,
                                    style: TextStyle(color: Colors.red[700]),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 경과 시간
                          if (missionData!.acceptedAt != null)
                            Row(
                              children: [
                                const Icon(Icons.timer, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  '수락 후 경과 시간: ${_getElapsedTime(missionData!.acceptedAt!)}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),

                          const SizedBox(height: 24),

                          // 임무 완료 버튼
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _completeMission,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text(
                                '임무 완료',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  // 상태에 따른 색상
  Color _getMissionStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'dispatched':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // 상태에 따른 아이콘
  IconData _getMissionStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'dispatched':
        return Icons.directions_run;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  // 상태에 따른 텍스트
  String _getMissionStatusText(String status) {
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
  String _getElapsedTime(int timestamp) {
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
}
