// lib/screens/home_screen.dart - 성능 및 버그 개선
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
  final bool isTabView; // 새로 추가된 매개변수

  const HomeScreen({super.key, this.isTabView = false});

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
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint('[HomeScreen] 위치 정보 가져오기 실패: $e');
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
    try {
      if (_currentPosition == null) return;

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
    } catch (e) {
      debugPrint('[HomeScreen] 거리 정렬 오류: $e');
    }
  }

  // 시간순 정렬
  void _sortByTime(List<Call> calls) {
    try {
      calls.sort((a, b) => b.startAt.compareTo(a.startAt));
    } catch (e) {
      debugPrint('[HomeScreen] 시간 정렬 오류: $e');
    }
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

  // 로그아웃 함수를 조건부로 수정
  Future<void> _logout() async {
    try {
      // 탭뷰 모드일 때는 로그아웃 기능을 비활성화 (MainScreen에서 처리)
      if (widget.isTabView) return;

      await FirebaseAuth.instance.signOut();
      debugPrint('[HomeScreen] 로그아웃 성공');

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('[HomeScreen] 로그아웃 오류: $e');
      // 오류 발생 시 사용자에게 알림
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('로그아웃 중 오류가 발생했습니다: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 탭뷰 모드일 때는 Scaffold 없이 본문만 반환
    if (widget.isTabView) {
      return _buildBody();
    }

    // 기존 독립 화면 모드
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
      body: _buildBody(),
    );
  }

  // 본문 위젯을 별도 메서드로 분리
  Widget _buildBody() {
    return Column(
      children: [
        // 필터 영역
        _buildFilterSection(),

        // 재난 목록 영역
        Expanded(child: _buildCallsList()),
      ],
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

// CallCard 컴포넌트 - info 표시 추가
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
  bool _hasActiveMission = false;

  @override
  void initState() {
    super.initState();
    _checkActiveMission();
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

  // 활성 임무 확인
  void _checkActiveMission() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final hasActive = await CallDataService().hasActiveMission(
          currentUser.uid,
        );
        if (mounted) {
          setState(() {
            _hasActiveMission = hasActive;
          });
        }
      }
    } catch (e) {
      debugPrint('[CallCard] 활성 임무 확인 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // 활성 임무가 있으면 비활성화 표시
      color: _hasActiveMission ? Colors.grey[100] : null,
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
                    color:
                        _hasActiveMission
                            ? Colors.grey
                            : _getEventTypeColor(widget.call.eventType),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.call.eventType,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _hasActiveMission ? Colors.grey : null,
                    ),
                  ),
                  const Spacer(),
                  if (widget.currentPosition != null &&
                      widget.call.distance != double.maxFinite)
                    Text(
                      _formatDistance(widget.call.distance),
                      style: TextStyle(
                        color:
                            _hasActiveMission ? Colors.grey : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.call.address,
                style: TextStyle(
                  fontSize: 16,
                  color: _hasActiveMission ? Colors.grey : null,
                ),
              ),

              // 상황 정보 미리보기 추가
              if (widget.call.info != null && widget.call.info!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _hasActiveMission ? Colors.grey[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color:
                          _hasActiveMission
                              ? Colors.grey[300]!
                              : Colors.red[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color:
                            _hasActiveMission ? Colors.grey : Colors.red[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.call.info!.length > 30
                              ? '${widget.call.info!.substring(0, 30)}...'
                              : widget.call.info!,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                _hasActiveMission
                                    ? Colors.grey
                                    : Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 4),
              // 시간 정보
              Row(
                children: [
                  Text(
                    _formatTime(widget.call.startAt),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _hasActiveMission ? Colors.grey : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getElapsedTime(widget.call.startAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: _hasActiveMission ? Colors.grey : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _hasActiveMission ? '다른 임무 진행중' : '수락 대기 중',
                    style: TextStyle(
                      color:
                          _hasActiveMission
                              ? Colors.grey
                              : Colors.deepOrangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _hasActiveMission ? null : widget.onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _hasActiveMission ? Colors.grey : Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(_hasActiveMission ? '수락불가' : '상세보기'),
                  ),
                ],
              ),

              // 활성 임무가 있을 때 안내 메시지
              if (_hasActiveMission) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '현재 진행중인 임무를 완료한 후 새로운 임무를 수락할 수 있습니다.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
        return Icons.warning;
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
        return Colors.orange;
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
