// lib/screens/active_mission_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:goodpeople_responder/models/call.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:goodpeople_responder/services/location_service.dart';
import 'package:goodpeople_responder/services/call_data_service.dart';
import 'package:goodpeople_responder/services/background_location_service.dart';
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
  StreamSubscription? _callSubscription;
  final CallDataService _callDataService = CallDataService();

  @override
  void initState() {
    super.initState();
    _loadMissionData();
    _getCurrentPosition();
    _startTracking();
    // 활성 임무 중에는 30초마다 위치 업데이트
    BackgroundLocationService().startActiveMissionTracking();
  }

  @override
  void dispose() {
    LocationService().stopTracking();
    _callSubscription?.cancel();
    mapController = null;
    // 일반 백그라운드 추적으로 돌아가기 (3분 간격)
    BackgroundLocationService().startBackgroundTracking();
    super.dispose();
  }

  void _startTracking() {
    LocationService().startLocationStream(widget.callId, 'responder_id');
  }

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

      _updateMapCamera();
    } catch (e) {
      debugPrint('위치 정보를 가져오는데 실패했습니다: $e');
    }
  }

  void _updateMapCamera() {
    if (mapController == null || missionData == null) return;

    if (userPosition != null) {
      final midLat = (userPosition!.latitude + missionData!.lat) / 2;
      final midLng = (userPosition!.longitude + missionData!.lng) / 2;

      final distance = Geolocator.distanceBetween(
        userPosition!.latitude,
        userPosition!.longitude,
        missionData!.lat,
        missionData!.lng,
      );

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

  Future<void> _completeMission() async {
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

    if (!mounted) return;

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

    LocationService().stopTracking();

    try {
      final success = await _callDataService.completeCall(widget.callId);

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("임무가 완료되었습니다!"),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          Navigator.pop(context);
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("임무 완료 처리 중 오류가 발생했습니다."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("오류가 발생했습니다: $e")));
    }
  }

  Future<void> _cancelAcceptance() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('수락 취소'),
            content: const Text('정말 이 임무를 취소하시겠습니까?\n다른 대원이 수락할 수 있게 됩니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('아니오'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('취소하기'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("사용자 정보를 찾을 수 없습니다.")));
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("수락 취소 처리 중..."),
              ],
            ),
          ),
    );

    LocationService().stopTracking();

    try {
      final success = await _callDataService.cancelAcceptance(
        widget.callId,
        currentUserId,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("임무가 취소되었습니다."),
            backgroundColor: Colors.orange,
          ),
        );

        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("취소 처리 중 오류가 발생했습니다."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("오류가 발생했습니다: $e")));
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

                  SizedBox(
                    height: 350,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(missionData!.lat, missionData!.lng),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('destination'),
                          position: LatLng(missionData!.lat, missionData!.lng),
                          infoWindow: InfoWindow(title: missionData!.eventType),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
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
                        _updateMapCamera();
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                  ),

                  Expanded(
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

                          // 수락 취소 버튼
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _cancelAcceptance,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: const BorderSide(color: Colors.orange),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text(
                                '수락 취소',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

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
