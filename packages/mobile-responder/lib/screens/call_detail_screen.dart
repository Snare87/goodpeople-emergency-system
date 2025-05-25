// lib/screens/call_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:goodpeople_responder/services/call_data_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Position? userPosition; // 클래스 멤버 변수로 이미 선언됨
  double? distanceToSite;
  GoogleMapController? mapController;
  Timer? _timeUpdateTimer;
  DateTime _currentTime = DateTime.now();

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

  // (수락 함수 업데이트 - 임무 제한 기능 추가)
  Future<void> _acceptCall() async {
    setState(() {
      accepting = true;
    });

    try {
      // 위치 정보 확인
      if (userPosition == null) {
        await _getCurrentPosition();
      }

      // 현재 사용자 ID 가져오기
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('로그인 정보를 찾을 수 없습니다.');
      }

      // 1. 먼저 활성 임무가 있는지 확인
      final hasActive = await CallDataService().hasActiveMission(
        currentUser.uid,
      );
      if (hasActive) {
        final activeMission = await CallDataService().getCurrentActiveMission(
          currentUser.uid,
        );

        if (mounted) {
          setState(() {
            accepting = false;
          });

          _showActiveMissionDialog(activeMission, '이미 진행중인 임무가 있습니다');
          return;
        }
      }

      // 2. 사용자 정보 가져오기
      final userSnapshot =
          await FirebaseDatabase.instance.ref('users/${currentUser.uid}').get();

      String userName = "대원";
      String userPositionName = "대원"; // 변수명 변경 (userPosition과 충돌 방지)
      String userRank = "소방사"; // rank 변수 추가

      if (userSnapshot.exists) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        userName = userData['name'] ?? "대원";
        userPositionName = userData['position'] ?? "대원"; // 변수명 변경
        userRank = userData['rank'] ?? "소방사"; // rank 정보 가져오기
      }

      // 3. 일반적인 수락 처리
      final responderRef = db.ref("calls/${widget.callId}");

      await responderRef.update({
        "status": "accepted",
        "acceptedAt": DateTime.now().millisecondsSinceEpoch,
        "responder": {
          "id":
              "resp_${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}",
          "name": userName,
          "position": userPositionName, // 변수명 변경
          "rank": userRank, // rank 추가
          "lat": userPosition?.latitude, // Position 타입의 latitude
          "lng": userPosition?.longitude, // Position 타입의 longitude
          "updatedAt": DateTime.now().millisecondsSinceEpoch,
        },
      });

      if (mounted) {
        setState(() {
          accepting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("콜을 수락했습니다!"),
            backgroundColor: Colors.green,
          ),
        );

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

  // 활성 임무가 있을 때 표시할 다이얼로그
  void _showActiveMissionDialog(dynamic activeMission, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ 진행중인 임무가 있습니다'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              if (activeMission != null) ...[
                const Text(
                  '현재 진행중인 임무:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚨 ${activeMission.eventType}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('📍 ${activeMission.address}'),
                      const SizedBox(height: 4),
                      Text(
                        '⏰ 수락 시간: ${_formatDialogTime(activeMission.acceptedAt)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '기존 임무를 완료한 후 새로운 임무를 수락할 수 있습니다.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
            if (activeMission != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // 활성 임무 화면으로 이동
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ActiveMissionScreen(callId: activeMission.id),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('진행중인 임무 보기'),
              ),
          ],
        );
      },
    );
  }

  // 시간 포맷팅 함수 (다이얼로그용)
  String _formatDialogTime(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timeUpdateTimer?.cancel();
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

                  // 상황 정보를 별도 섹션으로 강조 (새로 추가)
                  if (callDetails?['info'] != null &&
                      callDetails!['info'].toString().isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.red[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '긴급 상황 정보',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[800],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            callDetails!['info'].toString(),
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
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
