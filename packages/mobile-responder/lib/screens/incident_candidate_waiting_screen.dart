// lib/screens/incident_candidate_waiting_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:goodpeople_responder/services/incident_candidate_service.dart';
import 'package:goodpeople_responder/screens/navigation_screen.dart';
import 'package:goodpeople_responder/models/incident.dart';
import 'dart:async';

class IncidentCandidateWaitingScreen extends StatefulWidget {
  final String incidentId;
  final Incident incident;
  
  const IncidentCandidateWaitingScreen({
    Key? key,
    required this.incidentId,
    required this.incident,
  }) : super(key: key);
  
  @override
  State<IncidentCandidateWaitingScreen> createState() => 
      _IncidentCandidateWaitingScreenState();
}

class _IncidentCandidateWaitingScreenState 
    extends State<IncidentCandidateWaitingScreen> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  Timer? _countdownTimer;
  int _remainingSeconds = 5; // holdWindow 기본값
  
  @override
  void initState() {
    super.initState();
    
    // 대기 애니메이션 설정
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // 카운트다운 시작
    _startCountdown();
  }
  
  void _startCountdown() {
    _remainingSeconds = widget.incident.holdWindowSec;
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
        
        if (_remainingSeconds <= 0) {
          timer.cancel();
        }
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    return WillPopScope(
      onWillPop: () async {
        // 뒤로가기 시 취소 확인
        final shouldCancel = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('수락 취소'),
            content: const Text('정말로 수락을 취소하시겠습니까?'),
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
          ),
        );
        
        if (shouldCancel == true) {
          await IncidentCandidateService.cancelCandidacy(widget.incidentId);
        }
        
        return shouldCancel ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('배정 대기 중'),
          backgroundColor: Colors.orange,
        ),
        body: StreamBuilder<CandidateAssignmentStatus>(
          stream: IncidentCandidateService.watchAssignmentStatus(
            widget.incidentId,
            userId,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final status = snapshot.data!;
            
            switch (status.status) {
              case AssignmentStatus.waiting:
                return _buildWaitingUI(status);
              case AssignmentStatus.assigned:
                _navigateToMission();
                return _buildAssignedUI();
              case AssignmentStatus.notAssigned:
                return _buildNotAssignedUI(status);
              case AssignmentStatus.error:
                return _buildErrorUI(status);
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildWaitingUI(CandidateAssignmentStatus status) {
    return Column(
      children: [
        // 진행 상태 바
        LinearProgressIndicator(
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 32),
                
                // 대기 중 아이콘
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.access_time,
                          size: 60,
                          color: Colors.orange,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // 상태 메시지
                const Text(
                  '최적의 대원을 선정하고 있습니다',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  '현재 ${status.totalCandidates ?? 0}명의 대원이 대기 중입니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 자동 배정 카운트다운
                if (_remainingSeconds > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '자동 배정까지',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_remainingSeconds초',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // 내 정보 카드
                _buildMyInfoCard(status),
                
                const Spacer(),
                
                // 취소 버튼
                OutlinedButton(
                  onPressed: () async {
                    final shouldCancel = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('수락 취소'),
                        content: const Text('정말로 수락을 취소하시겠습니까?'),
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
                      ),
                    );
                    
                    if (shouldCancel == true) {
                      await IncidentCandidateService.cancelCandidacy(
                        widget.incidentId,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('수락 취소'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMyInfoCard(CandidateAssignmentStatus status) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  '내 예상 정보',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (status.myEtaSec != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('예상 도착 시간:'),
                  Text(
                    status.etaText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Text(
                '거리 계산 중...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildAssignedUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            '출동이 확정되었습니다!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '곧 네비게이션이 시작됩니다...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotAssignedUI(CandidateAssignmentStatus status) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline,
              size: 40,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '다른 대원이 배정되었습니다',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status.message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorUI(CandidateAssignmentStatus status) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              status.message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToMission() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => NavigationScreen(
              callId: widget.incidentId,
              missionData: widget.incident,
            ),
          ),
        );
      }
    });
  }
}
