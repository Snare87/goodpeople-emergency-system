// lib/screens/home_screen.dart - 탭 필터링 문제 수정
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:goodpeople_responder/screens/call_detail_screen.dart';
import 'package:goodpeople_responder/screens/login_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:goodpeople_responder/services/location_service.dart';
import 'package:goodpeople_responder/models/call.dart';
import 'package:goodpeople_responder/services/call_data_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CallDataService _callDataService = CallDataService();
  final LocationService _locationService = LocationService();

  List<Call> _allCalls = []; // 새로 추가
  List<Call> _filteredCalls = []; // 기존 유지
  bool _isLoading = true;
  String _filterType = "전체";
  Position? _currentPosition;
  StreamSubscription? _callsSubscription;

  @override
  void initState() {
    super.initState();
    debugPrint('[HomeScreen] initState 호출됨');
    _initializeScreen();
  }

  @override
  void dispose() {
    debugPrint('[HomeScreen] dispose 호출됨');
    _callsSubscription?.cancel();
    super.dispose();
  }

  // 화면 초기화
  Future<void> _initializeScreen() async {
    await _getCurrentPosition();
    _loadCalls();
  }

  // 현재 위치 가져오기
  Future<void> _getCurrentPosition() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = position;
      });
    }
  }

  // 재난 데이터 로드
  void _loadCalls() {
    debugPrint('[HomeScreen] _loadCalls 시작');
    _callsSubscription?.cancel();

    _callsSubscription = _callDataService.getAvailableCallsStream().listen(
      (calls) {
        if (mounted) {
          setState(() {
            _allCalls = calls; // 원본 데이터 저장
            _isLoading = false;
          });
          _applyCurrentFilter(); // 현재 필터 적용
        }
      },
      onError: (error) {
        debugPrint('[HomeScreen] 데이터 수신 오류: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  // 현재 필터 적용 (수정된 함수)
  void _applyCurrentFilter() {
    debugPrint(
      '[HomeScreen] _applyCurrentFilter 시작: $_filterType, 원본 데이터 개수: ${_allCalls.length}',
    );

    List<Call> filtered = List.from(_allCalls); // 항상 원본 데이터에서 시작

    // 이벤트 타입 필터링
    if (_filterType != "전체") {
      filtered =
          filtered.where((call) => call.eventType == _filterType).toList();
    }

    debugPrint('[HomeScreen] 타입 필터링 후: ${filtered.length}개');

    // 위치 기반 정렬 또는 시간순 정렬
    if (_currentPosition != null) {
      _sortByDistance(filtered);
    } else {
      _sortByTime(filtered);
    }

    if (mounted) {
      setState(() {
        _filteredCalls = filtered;
      });
      debugPrint('[HomeScreen] 최종 필터링 결과: ${_filteredCalls.length}개');
    }
  }

  // 거리순 정렬 (수정된 버전)
  void _sortByDistance(List<Call> calls) {
    for (int i = 0; i < calls.length; i++) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        calls[i].lat,
        calls[i].lng,
      );
      calls[i] = calls[i].copyWith(distance: distance); // ✅ 인덱스로 직접 할당
    }
    calls.sort((a, b) => a.distance.compareTo(b.distance));

    // 디버그 로그 추가
    for (var call in calls) {
      debugPrint(
        '[HomeScreen] ${call.eventType}: ${call.distance.toStringAsFixed(0)}m',
      );
    }
  }

  // 시간순 정렬
  void _sortByTime(List<Call> calls) {
    calls.sort((a, b) => b.startAt.compareTo(a.startAt));
  }

  // 필터 변경 (수정된 함수)
  void _changeFilter(String filterType) {
    debugPrint('[HomeScreen] 필터 변경: $_filterType -> $filterType');
    setState(() {
      _filterType = filterType;
    });
    _applyCurrentFilter(); // 원본 데이터에서 새로운 필터 적용
  }

  // 새로고침
  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });
    await _getCurrentPosition();
    _loadCalls();
  }

  // 로그아웃
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('재난 대응 시스템'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refresh,
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 영역
          _buildFilterSection(),

          // 재난 목록 영역
          Expanded(child: _buildCallsList()),
        ],
      ),
    );
  }

  // 필터 섹션 위젯 (기타 탭 추가)
  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip("전체"),
            _buildFilterChip("화재"),
            _buildFilterChip("구급"),
            _buildFilterChip("구조"),
            _buildFilterChip("기타"), // 기타 탭 추가
          ],
        ),
      ),
    );
  }

  // 필터 칩 위젯
  Widget _buildFilterChip(String label) {
    final isSelected = _filterType == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.red[100],
        onSelected: (selected) => _changeFilter(label),
      ),
    );
  }

  // 재난 목록 위젯
  Widget _buildCallsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredCalls.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        itemCount: _filteredCalls.length,
        itemBuilder: (context, index) {
          final call = _filteredCalls[index];
          return CallCard(
            call: call,
            currentPosition: _currentPosition,
            onTap: () => _navigateToDetail(call),
          );
        },
      ),
    );
  }

  // 빈 상태 위젯 (필터별 메시지 개선)
  Widget _buildEmptyState() {
    String message =
        _filterType == "전체" ? '표시할 재난이 없습니다' : '$_filterType 재난이 없습니다';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
          if (_filterType != "전체") ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _changeFilter("전체"),
              child: const Text('전체 목록 보기'),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('새로고침'),
          ),
        ],
      ),
    );
  }

  // 상세 화면 이동
  void _navigateToDetail(Call call) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CallDetailScreen(
              callId: call.id,
              description: call.eventType,
              lat: call.lat,
              lng: call.lng,
            ),
      ),
    );
  }
}

// CallCard 컴포넌트는 그대로 유지 (변경사항 없음)
class CallCard extends StatefulWidget {
  final Call call;
  final Position? currentPosition;
  final VoidCallback onTap;

  const CallCard({
    super.key,
    required this.call,
    this.currentPosition,
    required this.onTap,
  });

  @override
  State<CallCard> createState() => _CallCardState();
}

class _CallCardState extends State<CallCard> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 실시간 경과시간 업데이트 타이머
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getEventTypeIcon(widget.call.eventType),
                    color: _getEventTypeColor(widget.call.eventType),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.call.eventType,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (widget.currentPosition != null &&
                      widget.call.distance != double.maxFinite)
                    Text(
                      _formatDistance(widget.call.distance),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(widget.call.address, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              // 시간 정보
              Row(
                children: [
                  Text(
                    _formatTime(widget.call.startAt),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getElapsedTime(widget.call.startAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '수락 대기 중',
                    style: TextStyle(
                      color: Colors.deepOrangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: widget.onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('상세보기'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 시간 포맷팅
  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // 경과시간 계산
  String _getElapsedTime(int startAt) {
    final now = _currentTime.millisecondsSinceEpoch;
    final diff = now - startAt;
    final seconds = diff ~/ 1000;

    if (seconds < 60) return '${seconds}초 전';
    if (seconds < 3600) return '${seconds ~/ 60}분 전';
    if (seconds < 86400)
      return '${seconds ~/ 3600}시간 ${(seconds % 3600) ~/ 60}분 전';

    final date = DateTime.fromMillisecondsSinceEpoch(startAt);
    return '${date.month}/${date.day}';
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
        return Icons.warning; // 기타 아이콘 추가
      default:
        return Icons.help_outline;
    }
  }

  Color _getEventTypeColor(String eventType) {
    switch (eventType) {
      case '화재':
        return Colors.red;
      case '구급':
        return Colors.green;
      case '구조':
        return Colors.blue;
      case '기타':
        return Colors.orange; // 기타 색상 추가
      default:
        return Colors.grey;
    }
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }
}
