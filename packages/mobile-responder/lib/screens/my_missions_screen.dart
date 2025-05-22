// lib/screens/my_missions_screen.dart - info 표시 추가된 최종 버전
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:goodpeople_responder/models/call.dart';
import 'package:goodpeople_responder/services/call_data_service.dart';
import 'package:goodpeople_responder/screens/active_mission_screen.dart';
import 'dart:async';

class MyMissionsScreen extends StatefulWidget {
  const MyMissionsScreen({super.key});

  @override
  State<MyMissionsScreen> createState() => _MyMissionsScreenState();
}

class _MyMissionsScreenState extends State<MyMissionsScreen> {
  final CallDataService _callDataService = CallDataService();
  List<Call> _activeMissions = [];
  bool _isLoading = true;
  StreamSubscription? _missionsSubscription;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadActiveMissions();
  }

  @override
  void dispose() {
    _missionsSubscription?.cancel();
    super.dispose();
  }

  void _loadActiveMissions() {
    if (_currentUserId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _missionsSubscription?.cancel();
    _missionsSubscription = _callDataService
        .getActiveMissionsStream(_currentUserId!)
        .listen(
          (activeMissions) {
            if (mounted) {
              setState(() {
                _activeMissions = activeMissions;
                _isLoading = false;
              });
            }
          },
          onError: (error) {
            debugPrint('[MyMissionsScreen] 활성 임무 스트림 오류: $error');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        );
  }

  void _navigateToActiveMission(Call mission) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveMissionScreen(callId: mission.id),
      ),
    ).then((_) {
      // 임무 화면에서 돌아왔을 때 새로고침
      _loadActiveMissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeMissions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isLoading = true;
        });
        _loadActiveMissions();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeMissions.length,
        itemBuilder: (context, index) {
          final mission = _activeMissions[index];
          return MissionCard(
            mission: mission,
            onTap: () => _navigateToActiveMission(mission),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '진행중인 임무가 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '재난 목록에서 새로운 임무를 수락해보세요',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class MissionCard extends StatefulWidget {
  final Call mission;
  final VoidCallback onTap;

  const MissionCard({super.key, required this.mission, required this.onTap});

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getEventTypeIcon(widget.mission.eventType),
                    color: _getEventTypeColor(widget.mission.eventType),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.mission.eventType,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.mission.address,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),

                        // 상황 정보 추가
                        if (widget.mission.info != null &&
                            widget.mission.info!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Text(
                              widget.mission.info!.length > 25
                                  ? '${widget.mission.info!.substring(0, 25)}...'
                                  : widget.mission.info!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '수락 시간: ${_formatTime(widget.mission.acceptedAt)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    _getElapsedTime(
                      widget.mission.acceptedAt ?? widget.mission.startAt,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '진행중',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getEventTypeIcon(String eventType) {
    switch (eventType) {
      case '화재':
        return Icons.local_fire_department;
      case '구급':
        return Icons.medical_services;
      case '구조':
        return Icons.support;
      case '기타':
        return Icons.warning;
      default:
        return Icons.help_outline;
    }
  }

  Color _getEventTypeColor(String eventType) {
    switch (eventType) {
      case '화재':
        return Colors.red;
      case '구조':
        return Colors.blue;
      case '구급':
        return Colors.green;
      case '기타':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getElapsedTime(int startAt) {
    final now = _currentTime.millisecondsSinceEpoch;
    final diff = now - startAt;
    final seconds = diff ~/ 1000;

    if (seconds < 60) return '${seconds}초 경과';
    if (seconds < 3600) return '${seconds ~/ 60}분 경과';
    return '${seconds ~/ 3600}시간 ${(seconds % 3600) ~/ 60}분 경과';
  }
}
