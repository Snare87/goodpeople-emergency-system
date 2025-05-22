// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:goodpeople_responder/screens/call_detail_screen.dart';
import 'package:goodpeople_responder/screens/login_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:goodpeople_responder/services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dbRef = FirebaseDatabase.instance.ref("calls");
  List<Map<String, dynamic>> openCalls = [];
  List<Map<String, dynamic>> filteredCalls = [];
  bool _isLoading = true;
  String _filterType = "전체"; // 필터링 타입
  Position? _currentPosition; // 사용자 현재 위치

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
    _loadCalls();
  }

  // 현재 위치 가져오기
  Future<void> _getCurrentPosition() async {
    final position = await LocationService().getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = position;
      });
      _applyFilters();
    } else {
      debugPrint('위치 정보를 가져올 수 없습니다.');
    }
  }

  // 재난 데이터 로드
  void _loadCalls() {
    dbRef.onValue.listen(
      (event) {
        try {
          final data = event.snapshot.value;

          // data가 null이거나 Map이 아닌 경우 처리
          if (data == null) {
            setState(() {
              openCalls = [];
              filteredCalls = [];
              _isLoading = false;
            });
            return;
          }

          // 타입 체크 및 변환
          final Map<dynamic, dynamic> dataMap;
          if (data is Map) {
            dataMap = data;
          } else {
            debugPrint('데이터 형식이 예상과 다릅니다: $data');
            setState(() {
              openCalls = [];
              filteredCalls = [];
              _isLoading = false;
            });
            return;
          }

          final List<Map<String, dynamic>> results = [];

          dataMap.forEach((key, value) {
            try {
              // 타입 체크 및 안전한 변환
              if (value is! Map) {
                debugPrint('항목 데이터 형식이 예상과 다릅니다: $value');
                return; // 이 항목은 건너뛰고 계속 진행
              }

              final Map<dynamic, dynamic> call = value;

              // null 체크 및 기본값 제공
              final status = call['status']?.toString() ?? 'unknown';

              // 상태가 idle 또는 dispatched지만 완료(completed)가 아닌 재난만 표시
              if ((status == 'idle' || status == 'dispatched') &&
                  status != 'completed') {
                // 안전한 데이터 추출
                final double lat = _safeDouble(call['lat'], 0.0);
                final double lng = _safeDouble(call['lng'], 0.0);

                // 가공된 데이터 저장
                results.add({
                  'id': key.toString(),
                  'eventType': call['eventType']?.toString() ?? '알 수 없음',
                  'address': call['address']?.toString() ?? '주소 없음',
                  'lat': lat,
                  'lng': lng,
                  'status': status,
                  'startAt': _safeInt(call['startAt'], 0),
                  'distance': 0.0,
                });
              }
            } catch (e) {
              debugPrint('항목 처리 중 오류 발생: $e');
              // 한 항목에서 오류 발생해도 계속 진행
            }
          });

          if (mounted) {
            setState(() {
              openCalls = results;
              _isLoading = false;
              _applyFilters(); // 필터 적용
            });
          }
        } catch (e) {
          debugPrint('데이터 처리 중 오류 발생: $e');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
      onError: (error) {
        debugPrint('데이터를 불러오는데 실패했습니다: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  // 안전한 Double 변환
  double _safeDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    try {
      return double.parse(value.toString());
    } catch (e) {
      return defaultValue;
    }
  }

  // 안전한 Int 변환
  int _safeInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    try {
      return int.parse(value.toString());
    } catch (e) {
      return defaultValue;
    }
  }

  // 필터 적용
  void _applyFilters() {
    try {
      if (openCalls.isEmpty) {
        setState(() {
          filteredCalls = [];
        });
        return;
      }

      List<Map<String, dynamic>> filtered = List.from(openCalls);

      // 이벤트 타입에 따른 필터
      if (_filterType != "전체") {
        filtered =
            filtered.where((call) {
              return call['eventType'] == _filterType;
            }).toList();
      }

      // 현재 위치가 있으면 거리 계산 및 정렬
      if (_currentPosition != null) {
        for (var call in filtered) {
          try {
            double callLat = _safeDouble(call['lat'], 0.0);
            double callLng = _safeDouble(call['lng'], 0.0);

            double distance = 0.0;
            try {
              distance = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                callLat,
                callLng,
              );
            } catch (e) {
              debugPrint('거리 계산 중 오류: $e');
            }

            call['distance'] = distance;
          } catch (e) {
            debugPrint('거리 계산 항목 처리 중 오류: $e');
            call['distance'] = double.maxFinite; // 오류 시 가장 먼 거리로 설정
          }
        }

        // 거리순 정렬
        try {
          filtered.sort((a, b) {
            double distA = _safeDouble(a['distance'], double.maxFinite);
            double distB = _safeDouble(b['distance'], double.maxFinite);
            return distA.compareTo(distB);
          });
        } catch (e) {
          debugPrint('거리 정렬 중 오류: $e');
        }
      } else {
        // 시간순 정렬 (최근 발생 순)
        try {
          filtered.sort((a, b) {
            int timeA = _safeInt(a['startAt'], 0);
            int timeB = _safeInt(b['startAt'], 0);
            return timeB.compareTo(timeA);
          });
        } catch (e) {
          debugPrint('시간 정렬 중 오류: $e');
        }
      }

      if (mounted) {
        setState(() {
          filteredCalls = filtered;
        });
      }
    } catch (e) {
      debugPrint('필터 적용 중 오류 발생: $e');
      if (mounted) {
        setState(() {
          filteredCalls = [];
        });
      }
    }
  }

  // 이벤트 타입에 따른 아이콘
  IconData _getEventTypeIcon(String eventType) {
    switch (eventType) {
      case '화재':
        return Icons.local_fire_department;
      case '구급':
        return Icons.medical_services;
      case '구조':
        return Icons.support;
      default:
        return Icons.warning;
    }
  }

  // 이벤트 타입에 따른 색상
  Color _getEventTypeColor(String eventType) {
    switch (eventType) {
      case '화재':
        return Colors.red;
      case '구급':
        return Colors.green;
      case '구조':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // 거리 표시 형식
  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  // 로그아웃 함수
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
            onPressed:
                _isLoading
                    ? null
                    : () {
                      setState(() {
                        _isLoading = true;
                      });
                      _getCurrentPosition();
                      _loadCalls();
                    },
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
          // 필터 선택 영역
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("전체"),
                  _buildFilterChip("화재"),
                  _buildFilterChip("구급"),
                  _buildFilterChip("구조"),
                ],
              ),
            ),
          ),

          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredCalls.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '표시할 재난이 없습니다',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                              });
                              _getCurrentPosition();
                              _loadCalls();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('새로고침'),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          _isLoading = true;
                        });
                        await _getCurrentPosition();
                        _loadCalls();
                      },
                      child: ListView.builder(
                        itemCount: filteredCalls.length,
                        itemBuilder: (context, index) {
                          final call = filteredCalls[index];
                          return _buildCallCard(call);
                        },
                      ),
                    ),
          ),
        ],
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
        onSelected: (selected) {
          setState(() {
            _filterType = label;
            _applyFilters();
          });
        },
      ),
    );
  }

  // 재난 카드 위젯
  Widget _buildCallCard(Map<String, dynamic> call) {
    final eventType = call['eventType'] as String;
    final distance = call['distance'] as double;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => CallDetailScreen(
                    callId: call['id'],
                    description: eventType,
                    lat: call['lat'],
                    lng: call['lng'],
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getEventTypeIcon(eventType),
                    color: _getEventTypeColor(eventType),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    eventType,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_currentPosition != null)
                    Text(
                      _formatDistance(distance),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(call['address'], style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    call['status'] == 'idle' ? '대기 중' : '출동 중',
                    style: TextStyle(
                      color:
                          call['status'] == 'idle'
                              ? Colors.orange
                              : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => CallDetailScreen(
                                callId: call['id'],
                                description: eventType,
                                lat: call['lat'],
                                lng: call['lng'],
                              ),
                        ),
                      );
                    },
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
}
