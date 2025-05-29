// lib/screens/call_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:goodpeople_responder/services/call_data_service.dart';
import 'package:goodpeople_responder/services/directions_service.dart';
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
    _loadCallDetails();
    _getCurrentPosition();
    _listenToCallChanges();

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
        
        setState(() {
          callDetails = newData;
        });
        
        if (oldStatus == 'dispatched' && newStatus == 'idle') {
          _showStatusChangeDialog('호출 취소', '이 재난의 호출이 취소되었습니다.');
        }
        else if (oldStatus == 'dispatched' && newStatus == 'accepted' && newData['responder'] != null) {
          final responderName = newData['responder']['name'] ?? '다른 대원';
          _showStatusChangeDialog('수락 완료', '$responderName님이 이 재난을 수락했습니다.');
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

  Future<void> _getCurrentPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
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
      
      final TransactionResult result = await responderRef.runTransaction((Object? currentData) {
        if (currentData == null) {
          return Transaction.abort();
        }
        
        Map<String, dynamic> callData = Map<String, dynamic>.from(currentData as Map);
        
        if (callData['status'] != 'dispatched') {
          return Transaction.abort();
        }
        
        if (callData['status'] == 'accepted' || callData['responder'] != null) {
          return Transaction.abort();
        }
        
        callData['status'] = 'accepted';
        callData['acceptedAt'] = DateTime.now().millisecondsSinceEpoch;
        callData['responder'] = {
          "id": "resp_${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}",
          "name": userName,
          "position": userPositionName,
          "rank": userRank,
          "lat": userPosition?.latitude,
          "lng": userPosition?.longitude,
          "updatedAt": DateTime.now().millisecondsSinceEpoch,
        };
        
        return Transaction.success(callData);
      });

      if (!result.committed) {
        final latestSnapshot = await db.ref("calls/${widget.callId}").get();
        String errorMessage = '수락할 수 없는 재난입니다.';
        
        if (latestSnapshot.exists) {
          final latestData = Map<String, dynamic>.from(latestSnapshot.value as Map);
          if (latestData['status'] == 'idle') {
            errorMessage = '호출이 취소된 재난입니다.';
          } else if (latestData['status'] == 'accepted' && latestData['responder'] != null) {
            errorMessage = '다른 대원이 이미 이 재난을 수락했습니다.';
          } else if (latestData['status'] == 'completed') {
            errorMessage = '이미 종료된 재난입니다.';
          }
        }
        
        if (mounted) {
          setState(() {
            accepting = false;
          });
          
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('⚠️ 수락 실패'),
                content: Text(errorMessage),
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

      if (mounted) {
        setState(() {
          accepting = false;
        });

        // 성공 메시지와 함께 경로 안내 시작
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text("임무를 수락했습니다!"),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // 네비게이션 사용 여부 선택 다이얼로그
        final useNavigation = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('🗺️ 네비게이션'),
              content: const Text('재난 현장까지 네비게이션을 시작하시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('아니오'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('네비게이션 시작'),
                ),
              ],
            );
          },
        );

        // 화면 이동
        if (useNavigation == true) {
          // 네비게이션 화면으로 바로 이동
          Navigator.pushReplacement(
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
        } else {
          // 기존 임무 화면으로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ActiveMissionScreen(callId: widget.callId),
            ),
          );
        }
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
                      if (_directionsResult != null) {
                        _updateCameraToShowRoute();
                      }
                    },
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

                  // 수락 버튼
                  if (callDetails?['status'] != 'accepted')
                    SizedBox(
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
                            : const Icon(Icons.navigation),
                        label: Text(
                          accepting 
                            ? "수락 중..." 
                            : "임무 수락 및 경로 안내 시작"
                        ),
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
