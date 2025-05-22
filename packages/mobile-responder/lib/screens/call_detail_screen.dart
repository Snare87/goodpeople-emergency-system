// lib/screens/call_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'active_mission_screen.dart';
import 'dart:async';

class CallDetailScreen extends StatefulWidget {
  final String callId;
  final String description;
  final double lat;
  final double lng;

  const CallDetailScreen({
    super.key,
    required this.callId,
    required this.description,
    required this.lat,
    required this.lng,
  });

  @override
  State<CallDetailScreen> createState() => _CallDetailScreenState();
}

class _CallDetailScreenState extends State<CallDetailScreen> {
  bool accepting = false;
  final db = FirebaseDatabase.instance;
  Map<String, dynamic>? callDetails;
  Position? userPosition;
  double? distanceToSite;
  GoogleMapController? mapController;
  Timer? _timeUpdateTimer; // 이 줄 추가
  DateTime _currentTime = DateTime.now(); // 이 줄도 추가

  @override
  void initState() {
    super.initState();
    _loadCallDetails();
    _getCurrentPosition();

    // 60초마다 현재 시간 업데이트
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  // 경과 시간 계산 함수
  String _getElapsedTime(int? timestamp) {
    if (timestamp == null) return '';

    final startTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = _currentTime.difference(startTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 ${difference.inMinutes % 60}분 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '${difference.inSeconds}초 전';
    }
  }

  // 재난 상세정보 불러오기
  Future<void> _loadCallDetails() async {
    try {
      final snapshot = await db.ref("calls/${widget.callId}").get();
      if (snapshot.exists) {
        setState(() {
          callDetails = Map<String, dynamic>.from(snapshot.value as Map);
        });
      }
    } catch (e) {
      debugPrint('재난 정보를 불러오는데 실패했습니다: $e');
    }
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

        // 거리 계산
        distanceToSite = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          widget.lat,
          widget.lng,
        );
      });
    } catch (e) {
      debugPrint('위치 정보를 가져오는데 실패했습니다: $e');
    }
  }

  // 거리 포맷팅
  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  // (수락 함수 업데이트)
  Future<void> _acceptCall() async {
    setState(() {
      accepting = true;
    });

    try {
      // 위치 정보 확인
      if (userPosition == null) {
        await _getCurrentPosition();
      }

      // 대원 정보를 Firebase에 업데이트
      final responderRef = db.ref("calls/${widget.callId}");

      await responderRef.update({
        "status": "accepted",
        "acceptedAt": DateTime.now().millisecondsSinceEpoch,
        "responder": {
          "id": "responder_${DateTime.now().millisecondsSinceEpoch}",
          "name": "테스트대원",
          "position": "구조대원", // 나중에 사용자 정보에서 가져오기
          "lat": userPosition?.latitude,
          "lng": userPosition?.longitude,
        },
      });

      if (mounted) {
        setState(() {
          accepting = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("콜을 수락했습니다!")));

        // 수락 후 임무 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveMissionScreen(callId: widget.callId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          accepting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("오류가 발생했습니다: $e")));
      }
    }
  }

  @override
  void dispose() {
    _timeUpdateTimer?.cancel(); // 타이머 정리
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🚨 ${widget.description} 상세')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 지도 표시
            SizedBox(
              height: 200,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.lat, widget.lng),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('incident'),
                    position: LatLng(widget.lat, widget.lng),
                    infoWindow: InfoWindow(title: widget.description),
                  ),
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
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 재난 정보 카드
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '재난 정보',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildInfoRow('유형', widget.description),
                          _buildInfoRow(
                            '주소',
                            callDetails?['address'] ?? '정보 없음',
                          ),
                          _buildInfoRow(
                            '발생일시',
                            callDetails?['startAt'] != null
                                ? DateTime.fromMillisecondsSinceEpoch(
                                  callDetails!['startAt'],
                                ).toString().substring(0, 16)
                                : '정보 없음',
                          ),
                          _buildInfoRow(
                            '경과시간',
                            _getElapsedTime(callDetails?['startAt']),
                          ),
                          _buildInfoRow(
                            '상황 정보',
                            callDetails?['info'] ?? '상세 정보가 없습니다',
                          ),
                          if (distanceToSite != null)
                            _buildInfoRow(
                              '현장까지 거리',
                              _formatDistance(distanceToSite!),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 수락 버튼
                  if (callDetails?['status'] != 'accepted')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: accepting ? null : _acceptCall,
                        icon:
                            accepting
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.check),
                        label: Text(accepting ? "수락 중..." : "이 콜 수락하기"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),

                  if (callDetails?['status'] == 'accepted')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '이미 수락된 재난입니다',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 정보 행 위젯
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
