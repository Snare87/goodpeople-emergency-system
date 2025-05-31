// lib/screens/call_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:goodpeople_responder/services/call_data_service.dart';
import 'package:goodpeople_responder/services/directions_service.dart';
import 'package:goodpeople_responder/services/improved_call_acceptance_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'active_mission_screen.dart';
import 'package:goodpeople_responder/screens/navigation_screen.dart';
import 'dart:async';
import 'package:goodpeople_responder/models/call.dart';

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
  Timer? _timeUpdateTimer;
  DateTime _currentTime = DateTime.now();
  StreamSubscription? _callListener;
  
  // 경로 관련 변수
  DirectionsResult? _directionsResult;
  Set<Polyline> _polylines = {};
  bool _showRoutePreview = false;

  @override
  void initState() {
    super.initState();
    // 무거운 작업들을 Future.delayed로 분산
    Future.delayed(Duration.zero, () {
      _loadCallDetails();
      _getCurrentPosition();
      _listenToCallChanges();
    });

    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

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
  
  void _listenToCallChanges() {
    _callListener = db.ref("calls/${widget.callId}").onValue.listen((event) {
      if (event.snapshot.exists && mounted) {
        final newData = Map<String, dynamic>.from(event.snapshot.value as Map);
        final oldStatus = callDetails?['status'];
        final newStatus = newData['status'];
        final currentUser = FirebaseAuth.instance.currentUser;
        
        setState(() {
          callDetails = newData;
        });
        
        // 호출 취소
        if (oldStatus == 'dispatched' && newStatus == 'idle') {
          _showStatusChangeDialog('호출 취소', '이 재난의 호출이 취소되었습니다.');
        }
        // 최종 대원 선택됨
        else if (newData['selectedResponder'] != null && 
                callDetails?['selectedResponder'] == null &&
                currentUser != null) {
          final selectedResponder = Map<String, dynamic>.from(newData['selectedResponder']);
          
          // 내가 선택된 경우
          if (selectedResponder['userId'] == currentUser.uid) {
            _showSelectionDialog(
              '🎉 배정 완료!', 
              '상황실에서 귀하를 선택했습니다. 지금 바로 출동하세요!',
              true
            );
          } 
          // 다른 대원이 선택된 경우
          else {
            final responderName = selectedResponder['name'] ?? '다른 대원';
            _showSelectionDialog(
              '📌 대원 선택 완료', 
              '$responderName님이 이 재난에 배정되었습니다.',
              false
            );
          }
        }
      }
    });
  }
  
  void _showStatusChangeDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🔔 $title'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
  
  void _showSelectionDialog(String title, String message, bool isSelected) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (isSelected) ...
            [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('나중에'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  // 네비게이션 시작
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NavigationScreen(
                        callId: widget.callId,
                        missionData: Call(
                          id: widget.callId,
                          eventType: widget.description,
                          address: callDetails?['address'] ?? '정보 없음',
                          lat: widget.lat,
                          lng: widget.lng,
                          status: 'accepted',
                          startAt: DateTime.now().millisecondsSinceEpoch,
                        ),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('네비게이션 시작'),
              ),
            ] else
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('확인'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _getCurrentPosition() async {
    try {
      // 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('위치 권한이 거부되었습니다');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('위치 권한이 영구적으로 거부되었습니다');
        return;
      }

      // 낮은 정확도로 빠르게 위치 가져오기
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // high -> medium
        timeLimit: const Duration(seconds: 5), // 시간 제한 추가
      );
      
      if (mounted) {
        setState(() {
          userPosition = position;
          distanceToSite = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            widget.lat,
            widget.lng,
          );
        });
        
        // 위치를 가져온 후 경로 미리보기 로드
        _loadDirectionsPreview();
      }
    } catch (e) {
      debugPrint('위치 정보를 가져오는데 실패했습니다: $e');
    }
  }
  
  // 경로 미리보기 로드
  Future<void> _loadDirectionsPreview() async {
    if (userPosition == null) return;
    
    try {
      final result = await DirectionsService.getDirections(
        origin: LatLng(userPosition!.latitude, userPosition!.longitude),
        destination: LatLng(widget.lat, widget.lng),
      );
      
      if (result != null && mounted) {
        setState(() {
          _directionsResult = result;
          _polylines = {
            Polyline(
              polylineId: const PolylineId('preview_route'),
              points: result.polylinePoints,
              color: Colors.blue.withOpacity(0.7),
              width: 4,
              patterns: [
                PatternItem.dash(20),
                PatternItem.gap(10),
              ], // 점선으로 표시
            ),
          };
          _showRoutePreview = true;
        });
        
        // 카메라를 경로에 맞게 조정
        _updateCameraToShowRoute();
      }
    } catch (e) {
      debugPrint('경로 정보를 가져오는데 실패했습니다: $e');
    }
  }
  
  void _updateCameraToShowRoute() {
    if (mapController == null || _directionsResult == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _directionsResult!.polylinePoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
        _directionsResult!.polylinePoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        _directionsResult!.polylinePoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
        _directionsResult!.polylinePoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
      ),
    );

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  Future<void> _acceptCall() async {
    setState(() {
      accepting = true;
    });

    try {
      if (userPosition == null) {
        await _getCurrentPosition();
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('로그인 정보를 찾을 수 없습니다.');
      }

      final currentCallSnapshot = await db.ref("calls/${widget.callId}").get();
      if (!currentCallSnapshot.exists) {
        throw Exception('재난 정보를 찾을 수 없습니다.');
      }
      
      final currentCallData = Map<String, dynamic>.from(currentCallSnapshot.value as Map);
      
      if (currentCallData['status'] == 'accepted' && currentCallData['responder'] != null) {
        if (mounted) {
          setState(() {
            accepting = false;
          });
          
          final responderInfo = Map<String, dynamic>.from(currentCallData['responder']);
          final responderName = responderInfo['name'] ?? '다른 대원';
          
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('⚠️ 이미 수락된 재난'),
                content: Text('$responderName님이 이미 이 재난을 수락했습니다.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('확인'),
                  ),
                ],
              );
            },
          );
          return;
        }
      }

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

      final userSnapshot =
          await FirebaseDatabase.instance.ref('users/${currentUser.uid}').get();

      String userName = "대원";
      String userPositionName = "대원";
      String userRank = "소방사";

      if (userSnapshot.exists) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        userName = userData['name'] ?? "대원";
        userPositionName = userData['position'] ?? "대원";
        userRank = userData['rank'] ?? "소방사";
      }

      final responderRef = db.ref("calls/${widget.callId}");
      
      // 현재 상태 확인 병합 (중복 제거)
      
      // 이미 최종 선택된 대원이 있는지 확인
      if (currentCallData['selectedResponder'] != null) {
        if (mounted) {
          setState(() {
            accepting = false;
          });
          
          final selectedResponder = Map<String, dynamic>.from(currentCallData['selectedResponder']);
          final responderName = selectedResponder['name'] ?? '다른 대원';
          
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('⚠️ 이미 배정된 재난'),
                content: Text('$responderName님이 이미 이 재난에 배정되었습니다.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('확인'),
                  ),
                ],
              );
            },
          );
          return;
        }
      }
      
      // 상태가 idle이면 수락 불가
      if (currentCallData['status'] == 'idle') {
        if (mounted) {
          setState(() {
            accepting = false;
          });
          
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('⚠️ 수락 실패'),
                content: const Text('호출이 취소된 재난입니다.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('확인'),
                  ),
                ],
              );
            },
          );
          return;
        }
      }

      // 🚨 변경: candidates에 추가하는 방식으로 수정
      final candidateData = {
        "id": "cand_${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}",
        "userId": currentUser.uid,
        "name": userName,
        "position": userPositionName,
        "rank": userRank,
        "lat": userPosition?.latitude,
        "lng": userPosition?.longitude,
        "acceptedAt": DateTime.now().millisecondsSinceEpoch,
        "routeInfo": _directionsResult != null ? {
          "distance": _directionsResult!.totalDistance,
          "distanceText": _directionsResult!.distanceText,
          "duration": _directionsResult!.totalDuration,
          "durationText": _directionsResult!.durationText,
          "calculatedAt": DateTime.now().millisecondsSinceEpoch,
        } : null,
      };

      // candidates/{userId}에 저장
      await db.ref("calls/${widget.callId}/candidates/${currentUser.uid}").set(candidateData);
      
      // 상태는 그대로 dispatched 유지 (여러 명이 수락 가능)
      await db.ref("calls/${widget.callId}/status").set('dispatched');
      
      // 첫 번째 후보자인 경우 acceptedAt 기록
      final candidatesSnapshot = await db.ref("calls/${widget.callId}/candidates").get();
      if (candidatesSnapshot.value == null || (candidatesSnapshot.value as Map).length == 1) {
        await db.ref("calls/${widget.callId}/acceptedAt").set(DateTime.now().millisecondsSinceEpoch);
      }

      if (mounted) {
        setState(() {
          accepting = false;
        });

        // 성공 메시지 변경
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text("후보자로 등록되었습니다. 상황실의 최종 선택을 기다리세요."),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );

        // 후보자 대기 정보 표시
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('📌 후보자 등록 완료'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('후보자로 등록되었습니다.'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📢 다음 단계',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('1. 상황실에서 후보자 목록 확인'),
                        const Text('2. 최적 대원 선택'),
                        const Text('3. 선택 시 알림을 받게 됩니다'),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // CallDetailScreen도 닫기
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('확인'),
                ),
              ],
            );
          },
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
                  Navigator.push(
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

  String _formatDialogTime(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timeUpdateTimer?.cancel();
    _callListener?.cancel();
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
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  GoogleMap(
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
                    polylines: _polylines,
                    onMapCreated: (controller) {
                      mapController = controller;
                      // 지도가 준비된 후 경로 표시
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_directionsResult != null && mounted) {
                          _updateCameraToShowRoute();
                        }
                      });
                    },
                    // 성능 최적화 옵션
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    liteModeEnabled: false, // lite mode 비활성화
                  ),
                  // 경로 정보 오버레이
                  if (_directionsResult != null && _showRoutePreview)
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.route, color: Colors.blue[700], size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '예상 경로',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${_directionsResult!.distanceText} · ${_directionsResult!.durationText}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() {
                                  _showRoutePreview = false;
                                  _polylines.clear();
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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

                  // 상황 정보
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

                  // 수락 버튼 표시 조건
                  _buildActionButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
  
  Widget _buildActionButton() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();
    
    // 이미 최종 선택된 대원이 있는 경우
    if (callDetails?['selectedResponder'] != null) {
      final selectedResponder = Map<String, dynamic>.from(callDetails!['selectedResponder']);
      final isMe = selectedResponder['userId'] == currentUser.uid;
      
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMe ? Colors.green[100] : Colors.blue[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isMe ? Colors.green[300]! : Colors.blue[300]!),
        ),
        child: Column(
          children: [
            Icon(
              isMe ? Icons.check_circle : Icons.info,
              color: isMe ? Colors.green[700] : Colors.blue[700],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              isMe 
                ? '귀하가 이 재난에 배정되었습니다' 
                : '${selectedResponder['name']}님이 배정되었습니다',
              style: TextStyle(
                color: isMe ? Colors.green[700] : Colors.blue[700],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (isMe) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NavigationScreen(
                        callId: widget.callId,
                        missionData: Call(
                          id: widget.callId,
                          eventType: widget.description,
                          address: callDetails?['address'] ?? '정보 없음',
                          lat: widget.lat,
                          lng: widget.lng,
                          status: 'accepted',
                          startAt: DateTime.now().millisecondsSinceEpoch,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.navigation),
                label: const Text('네비게이션 시작'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    // 후보자 목록이 있고 내가 이미 후보자인 경우
    if (callDetails?['candidates'] != null) {
      final candidates = Map<String, dynamic>.from(callDetails!['candidates']);
      if (candidates.containsKey(currentUser.uid)) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[300]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '후보자로 등록됨 - 상황실 선택 대기중',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 수락 취소 버튼 추가
              OutlinedButton.icon(
                onPressed: () async {
                  final shouldCancel = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('⚠️ 수락 취소'),
                        content: const Text('정말로 수락을 취소하시겠습니까?\n취소 후에는 AI 자동 선택에서도 제외됩니다.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('아니오'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('취소하기'),
                          ),
                        ],
                      );
                    },
                  );
                  
                  if (shouldCancel == true) {
                    final success = await ImprovedCallAcceptanceService.cancelCandidacy(widget.callId);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('수락이 취소되었습니다.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  }
                },
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('수락 취소'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      }
    }
    
    // 아직 후보자가 아닌 경우 - 수락 버튼 표시
    if (callDetails?['status'] == 'dispatched') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: accepting ? null : _acceptCall,
          icon: accepting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.person_add),
          label: Text(
            accepting 
              ? "등록 중..." 
              : "후보자로 등록하기"
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      );
    }
    
    // 기타 상태
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        callDetails?['status'] == 'idle' 
          ? '호출 대기중'
          : callDetails?['status'] == 'completed'
            ? '종료된 재난'
            : '상태: ${callDetails?['status'] ?? '알 수 없음'}',
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
