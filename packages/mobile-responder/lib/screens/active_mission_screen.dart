// lib/screens/active_mission_screen.dart - 실시간 경로 안내 기능 추가
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goodpeople_responder/providers/active_mission_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:goodpeople_responder/constants/constants.dart';
import 'package:goodpeople_responder/services/directions_service.dart';
import 'package:goodpeople_responder/screens/navigation_screen.dart';
import 'dart:async';

class ActiveMissionScreen extends StatefulWidget {
  final String callId;

  const ActiveMissionScreen({super.key, required this.callId});

  @override
  State<ActiveMissionScreen> createState() => _ActiveMissionScreenState();
}

class _ActiveMissionScreenState extends State<ActiveMissionScreen> {
  GoogleMapController? mapController;
  late ActiveMissionProvider provider;
  
  // 경로 관련 변수
  DirectionsResult? _directionsResult;
  Set<Polyline> _polylines = {};
  Timer? _directionsUpdateTimer;
  bool _isLoadingDirections = false;
  bool _showNavigationPanel = false;

  @override
  void initState() {
    super.initState();
    provider = ActiveMissionProvider();
    provider.initializeMission(widget.callId);
    
    // 위치가 변경될 때마다 경로 업데이트
    provider.addListener(_onProviderUpdate);
  }

  @override
  void dispose() {
    provider.removeListener(_onProviderUpdate);
    _directionsUpdateTimer?.cancel();
    mapController = null;
    provider.dispose();
    super.dispose();
  }

  void _onProviderUpdate() {
    if (provider.userPosition != null && provider.missionData != null) {
      _loadDirections();
    }
  }

  // 경로 정보 로드
  Future<void> _loadDirections() async {
    if (_isLoadingDirections || provider.userPosition == null || provider.missionData == null) return;
    
    setState(() {
      _isLoadingDirections = true;
    });

    try {
      // 거리 계산 (디버깅용)
      final distance = Geolocator.distanceBetween(
        provider.userPosition!.latitude,
        provider.userPosition!.longitude,
        provider.missionData!.lat,
        provider.missionData!.lng,
      );
      
      debugPrint('[ActiveMissionScreen] 목적지까지 거리: ${distance.toStringAsFixed(0)}m');
      
      // 항상 Google Directions API 먼저 시도
      DirectionsResult? result = await DirectionsService.getDirections(
        origin: LatLng(provider.userPosition!.latitude, provider.userPosition!.longitude),
        destination: LatLng(provider.missionData!.lat, provider.missionData!.lng),
      );
      
      // API가 경로를 찾지 못한 경우에만 직선 경로 사용
      if (result == null) {
        debugPrint('[ActiveMissionScreen] Google Directions API 실패, 직선 경로 사용');
        result = DirectionsService.createStraightLineRoute(
          origin: LatLng(provider.userPosition!.latitude, provider.userPosition!.longitude),
          destination: LatLng(provider.missionData!.lat, provider.missionData!.lng),
        );
      } else {
        debugPrint('[ActiveMissionScreen] Google Directions API 성공, 도로 경로 사용');
      }

      if (result != null && mounted) {
        setState(() {
          _directionsResult = result;
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: result!.polylinePoints,
              color: Colors.blue,
              width: 5,
              patterns: [], // 항상 실선
            ),
          };
        });
        
        // 카메라 위치 업데이트
        _updateMapCameraForRoute();
      }
    } catch (e) {
      debugPrint('경로 로드 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDirections = false;
        });
      }
    }
  }

  // 네비게이션 시작
  void _startNavigation() {
    if (provider.missionData == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigationScreen(
          callId: widget.callId,
          missionData: provider.missionData!,
        ),
      ),
    );
  }

  // 경로를 포함한 카메라 위치 업데이트
  void _updateMapCameraForRoute() {
    if (mapController == null || _directionsResult == null) return;

    // 경로의 모든 포인트를 포함하는 bounds 계산
    double minLat = _directionsResult!.polylinePoints.first.latitude;
    double maxLat = _directionsResult!.polylinePoints.first.latitude;
    double minLng = _directionsResult!.polylinePoints.first.longitude;
    double maxLng = _directionsResult!.polylinePoints.first.longitude;

    for (final point in _directionsResult!.polylinePoints) {
      minLat = minLat > point.latitude ? point.latitude : minLat;
      maxLat = maxLat < point.latitude ? point.latitude : maxLat;
      minLng = minLng > point.longitude ? point.longitude : minLng;
      maxLng = maxLng < point.longitude ? point.longitude : maxLng;
    }

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100, // padding
      ),
    );
  }

  void _updateMapCamera() {
    if (mapController == null || provider.missionData == null) return;

    if (provider.userPosition != null) {
      final midLat = (provider.userPosition!.latitude + provider.missionData!.lat) / 2;
      final midLng = (provider.userPosition!.longitude + provider.missionData!.lng) / 2;

      final distance = Geolocator.distanceBetween(
        provider.userPosition!.latitude,
        provider.userPosition!.longitude,
        provider.missionData!.lat,
        provider.missionData!.lng,
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
            target: LatLng(provider.missionData!.lat, provider.missionData!.lng),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  Future<void> _completeMission() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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

    final success = await provider.completeMission();

    if (!mounted) return;

    if (success) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("임무 완료 처리 중 오류가 발생했습니다."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelAcceptance() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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

    final success = await provider.cancelAcceptance();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("임무가 취소되었습니다."),
          backgroundColor: Colors.orange,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? "취소 처리 중 오류가 발생했습니다."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('진행 중인 임무'),
          backgroundColor: Colors.red,
          actions: [
            // 네비게이션 패널 토글 버튼
            IconButton(
              icon: Icon(_showNavigationPanel ? Icons.info : Icons.info_outline),
              onPressed: () {
                setState(() {
                  _showNavigationPanel = !_showNavigationPanel;
                });
              },
            ),
          ],
        ),
        body: Consumer<ActiveMissionProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.missionData == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage ?? '임무 정보를 불러올 수 없습니다',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            final missionData = provider.missionData!;

            return Stack(
              children: [
                Column(
                  children: [
                    Container(
                      color: _getMissionStatusColor(missionData.status),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getMissionStatusIcon(missionData.status),
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            provider.getMissionStatusText(missionData.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          if (_directionsResult != null) ...[
                            Icon(Icons.directions_car, color: Colors.white, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              _directionsResult!.distanceText,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.schedule, color: Colors.white, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              _directionsResult!.durationText,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ],
                      ),
                    ),

                    Expanded(
                      child: Stack(
                        children: [
                          // 지도
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(missionData.lat, missionData.lng),
                              zoom: 15,
                              tilt: 0, // 2D 지도로 설정
                            ),
                            tiltGesturesEnabled: false, // 사용자가 3D로 변경 불가
                            markers: {
                              Marker(
                                markerId: const MarkerId('destination'),
                                position: LatLng(missionData.lat, missionData.lng),
                                infoWindow: InfoWindow(title: missionData.eventType),
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueRed,
                                ),
                              ),
                              if (provider.userPosition != null)
                                Marker(
                                  markerId: const MarkerId('user'),
                                  position: LatLng(
                                    provider.userPosition!.latitude,
                                    provider.userPosition!.longitude,
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
                              _updateMapCamera();
                              _loadDirections();
                            },
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            trafficEnabled: true, // 실시간 교통 정보
                          ),

                          // 경로 정보 패널
                          if (_showNavigationPanel && _directionsResult != null)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.white.withOpacity(0.95),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '경로 정보',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.directions_car, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_directionsResult!.distanceText} · ${_directionsResult!.durationText}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 하단 정보 및 버튼
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            missionData.eventType,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            missionData.address,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          
                          // 상황 정보
                          if (missionData.info != null && missionData.info!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: Colors.red[700]),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      missionData.info!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // 네비게이션 시작 버튼 추가
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _startNavigation(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.navigation, size: 24),
                              label: const Text(
                                '네비게이션 시작',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 버튼들
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: provider.isProcessing ? null : _cancelAcceptance,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                    side: const BorderSide(color: Colors.orange),
                                  ),
                                  child: const Text('수락 취소'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: provider.isProcessing ? null : _completeMission,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text('임무 완료'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 처리 중 오버레이
                if (provider.isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text("처리 중..."),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
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
}
