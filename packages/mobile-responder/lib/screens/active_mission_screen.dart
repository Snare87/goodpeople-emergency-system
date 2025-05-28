// lib/screens/active_mission_screen.dart - Provider 적용 버전
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goodpeople_responder/providers/active_mission_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:goodpeople_responder/constants/constants.dart';

class ActiveMissionScreen extends StatefulWidget {
  final String callId;

  const ActiveMissionScreen({super.key, required this.callId});

  @override
  State<ActiveMissionScreen> createState() => _ActiveMissionScreenState();
}

class _ActiveMissionScreenState extends State<ActiveMissionScreen> {
  GoogleMapController? mapController;
  late ActiveMissionProvider provider;

  @override
  void initState() {
    super.initState();
    // Provider 생성 및 초기화
    provider = ActiveMissionProvider();
    provider.initializeMission(widget.callId);
  }

  @override
  void dispose() {
    mapController = null;
    provider.dispose();
    super.dispose();
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
                        ],
                      ),
                    ),

                    SizedBox(
                      height: 350,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(missionData.lat, missionData.lng),
                          zoom: 15,
                        ),
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
                              missionData.eventType,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              missionData.address,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 상황 정보 - 조건식 그대로 유지
                            if (missionData.info != null &&
                                missionData.info!.isNotEmpty) ...[
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
                                      missionData.info!,
                                      style: TextStyle(color: Colors.red[700]),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // 수락 시간 - 조건식 그대로 유지
                            if (missionData.acceptedAt != null)
                              Row(
                                children: [
                                  const Icon(Icons.timer, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    '수락 후 경과 시간: ${provider.getElapsedTime(missionData.acceptedAt!)}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 24),

                            // 수락 취소 버튼
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: provider.isProcessing ? null : _cancelAcceptance,
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
                                onPressed: provider.isProcessing ? null : _completeMission,
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
