// packages/mobile-responder/lib/screens/home_screen.dart - Provider 적용 버전
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goodpeople_responder/screens/call_detail_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:goodpeople_responder/models/call.dart';
import 'package:goodpeople_responder/constants/constants.dart';
import 'package:goodpeople_responder/providers/call_provider.dart';

class HomeScreen extends StatefulWidget {
  final bool isTabView;
  final Function(VoidCallback)? onRefreshReady;

  const HomeScreen({super.key, this.isTabView = false, this.onRefreshReady});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('[HomeScreen] initState 호출됨');
    
    // Provider 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CallProvider>();
      provider.initialize();
      
      // 새로고침 콜백 전달
      if (widget.onRefreshReady != null) {
        widget.onRefreshReady!(() => provider.refresh());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, provider, child) {
        return _buildBody(provider);
      },
    );
  }

  // 본문 위젯
  Widget _buildBody(CallProvider provider) {
    return Column(
      children: [
        // 위치 정보 및 반경 표시 추가
        if (provider.currentPosition != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue[50],
            child: Row(
              children: [
                Icon(Icons.my_location, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '현재 위치에서 5km 이내 재난 표시 중',
                    style: TextStyle(color: Colors.blue[700], fontSize: 13),
                  ),
                ),
                Text(
                  '${provider.filteredCalls.length}건',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

        // 필터 영역
        Container(
          color: Colors.grey[50],
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("전체", provider),
                _buildFilterChip("화재", provider),
                _buildFilterChip("구급", provider),
                _buildFilterChip("구조", provider),
                _buildFilterChip("기타", provider),
              ],
            ),
          ),
        ),

        // 재난 목록 영역
        Expanded(child: _buildCallsList(provider)),
      ],
    );
  }

  // 필터 칩 위젯
  Widget _buildFilterChip(String label, CallProvider provider) {
    final isSelected = provider.filterType == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        backgroundColor: Colors.transparent,
        selectedColor: Colors.red[100],
        side: BorderSide(color: isSelected ? Colors.red : Colors.grey[400]!),
        onSelected: (selected) => provider.changeFilter(label),
      ),
    );
  }

  // 재난 목록 위젯
  Widget _buildCallsList(CallProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.filteredCalls.isEmpty) {
      return _buildEmptyState(provider);
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: Container(
        color: Colors.grey[50],
        child: ListView.builder(
          itemCount: provider.filteredCalls.length,
          itemBuilder: (context, index) {
            final call = provider.filteredCalls[index];
            return CallCard(
              call: call,
              currentPosition: provider.currentPosition,
              onTap: () => _navigateToDetail(call),
              hasActiveMission: false,
              onAcceptStateChanged: () {
                // 수락 상태가 변경되면 즉시 새로고침
                provider.refresh();
              },
            );
          },
        ),
      ),
    );
  }

  // 빈 상태 위젯
  Widget _buildEmptyState(CallProvider provider) {
    String message =
        provider.filterType == "전체"
            ? '5km 이내에 표시할 재난이 없습니다'
            : '5km 이내에 ${provider.filterType} 재난이 없습니다';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_on, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            '현재 위치 기준 반경 5km 이내의 재난만 표시됩니다',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (provider.currentPosition == null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '위치 정보를 가져올 수 없습니다',
                      style: TextStyle(color: Colors.orange[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (provider.filterType != "전체") ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => provider.changeFilter("전체"),
              child: const Text('전체 목록 보기'),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: provider.refresh,
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

// CallCard 컴포넌트는 기존 코드 그대로 유지
class CallCard extends StatefulWidget {
  final Call call;
  final Position? currentPosition;
  final VoidCallback onTap;
  final bool hasActiveMission;
  final VoidCallback? onAcceptStateChanged;

  const CallCard({
    super.key,
    required this.call,
    this.currentPosition,
    required this.onTap,
    this.hasActiveMission = false,
    this.onAcceptStateChanged,
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
      color: widget.hasActiveMission ? Colors.grey[100] : null,
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
                    CallConstants.getEventTypeIcon(widget.call.eventType),
                    color:
                        widget.hasActiveMission
                            ? Colors.grey
                            : CallConstants.getEventTypeColor(
                              widget.call.eventType,
                            ),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.call.eventType,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.hasActiveMission ? Colors.grey : null,
                    ),
                  ),
                  const Spacer(),
                  if (widget.currentPosition != null &&
                      widget.call.distance != double.maxFinite)
                    Text(
                      _formatDistance(widget.call.distance),
                      style: TextStyle(
                        color:
                            widget.hasActiveMission
                                ? Colors.grey
                                : Colors.grey[600],
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
                  color: widget.hasActiveMission ? Colors.grey : null,
                ),
              ),

              // 상황 정보 미리보기 추가 - 조건식 그대로 유지
              if (widget.call.info != null && widget.call.info!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        widget.hasActiveMission
                            ? Colors.grey[50]
                            : Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color:
                          widget.hasActiveMission
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
                            widget.hasActiveMission
                                ? Colors.grey
                                : Colors.red[600],
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
                                widget.hasActiveMission
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
                      color: widget.hasActiveMission ? Colors.grey : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getElapsedTime(widget.call.startAt),
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          widget.hasActiveMission
                              ? Colors.grey
                              : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.hasActiveMission ? '다른 임무 진행중' : '수락 대기 중',
                    style: TextStyle(
                      color:
                          widget.hasActiveMission
                              ? Colors.grey
                              : Colors.deepOrangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: widget.hasActiveMission ? null : widget.onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.hasActiveMission ? Colors.grey : Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(widget.hasActiveMission ? '수락불가' : '상세보기'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getElapsedTime(int startAt) {
    final now = _currentTime.millisecondsSinceEpoch;
    final diff = now - startAt;
    final seconds = diff ~/ 1000;

    if (seconds < 60) return '$seconds초 전';
    if (seconds < 3600) return '${seconds ~/ 60}분 전';
    if (seconds < 86400) {
      return '${seconds ~/ 3600}시간 ${(seconds % 3600) ~/ 60}분 전';
    }

    final date = DateTime.fromMillisecondsSinceEpoch(startAt);
    return '${date.month}/${date.day}';
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }
}
