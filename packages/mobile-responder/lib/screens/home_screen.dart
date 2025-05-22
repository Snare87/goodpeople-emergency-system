// lib/screens/home_screen.dart
import 'dart:async';
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
  late DatabaseReference dbRef;
  List<Map<String, dynamic>> openCalls = [];
  List<Map<String, dynamic>> filteredCalls = [];
  bool _isLoading = true;
  String _filterType = "전체"; // 필터링 타입
  Position? _currentPosition; // 사용자 현재 위치
  StreamSubscription? _callsSubscription; // <<< StreamSubscription 변수 추가

  @override
  void initState() {
    super.initState();
    // 서버 우선 정책으로 데이터베이스 참조 설정
    dbRef = FirebaseDatabase.instance.ref("calls");
    dbRef.keepSynced(true); // 별도로 호출
    debugPrint('[HomeScreen] initState 호출됨');
    _getCurrentPosition();
    _loadCalls();
  }

  // 스냅샷 데이터 처리 함수
  void _processSnapshotData(DataSnapshot snapshot) {
    debugPrint('[HomeScreen _processSnapshotData] 스냅샷 처리 시작');
    try {
      final data = snapshot.value;
      debugPrint('[HomeScreen _processSnapshotData] 수신 데이터: $data');

      if (data == null) {
        debugPrint('[HomeScreen _processSnapshotData] 수신 데이터가 null입니다.');
        if (mounted) {
          setState(() {
            openCalls = [];
            _isLoading = false;
            _applyFilters();
          });
        }
        return;
      }

      // 기존 데이터 처리 로직을 여기에 복사
      final Map<dynamic, dynamic> dataMap;
      if (data is Map) {
        dataMap = data;
        // 각 call별로 개별 로그 출력
        debugPrint(
          '[HomeScreen _processSnapshotData] 수신 데이터 개수: ${dataMap.length}개',
        );
        dataMap.forEach((key, value) {
          debugPrint('[HomeScreen _processSnapshotData] $key 원본: $value');
        });
      } else {
        debugPrint(
          '[HomeScreen _processSnapshotData] 데이터 형식이 Map이 아닙니다: $data',
        );
        if (mounted) {
          setState(() {
            openCalls = [];
            _isLoading = false;
            _applyFilters();
          });
        }
        return;
      }

      // === 기존 데이터 파싱 로직 복사 ===
      final List<Map<String, dynamic>> results = [];
      debugPrint(
        '[HomeScreen _processSnapshotData] dataMap 순회 시작, 총 ${dataMap.length}개 항목',
      );

      dataMap.forEach((key, value) {
        try {
          if (value is! Map) {
            debugPrint(
              '[HomeScreen _processSnapshotData] 항목 ($key) 데이터 형식이 Map이 아닙니다: $value',
            );
            return;
          }

          final Map<dynamic, dynamic> call = value;
          final status = call['status']?.toString() ?? 'unknown';
          final bool hasResponder = call['responder'] != null;
          debugPrint(
            '[HomeScreen _processSnapshotData] call $key 처리 중: status=$status, hasResponder=$hasResponder, eventType=${call['eventType']}, address=${call['address']}',
          );

          // call8만 특별히 상세 로그
          if (key.toString() == 'call8') {
            debugPrint(
              '[HomeScreen _processSnapshotData] ⚠️ call8 상세 분석: 원본=$value, 파싱된 status=$status',
            );
          }

          debugPrint(
            '[HomeScreen _processSnapshotData] call null 상태 체크: status=$status, hasResponder=$hasResponder',
          );

          if (status == 'dispatched' &&
              !hasResponder &&
              status != 'completed') {
            debugPrint(
              '[HomeScreen _processSnapshotData] ✅ call $key 최종 필터 통과! 목록에 추가합니다. (${call['eventType']} - ${call['address']})',
            );

            final double lat = _safeDouble(call['lat'], 0.0);
            final double lng = _safeDouble(call['lng'], 0.0);

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
          } else {
            debugPrint(
              '[HomeScreen _processSnapshotData] ❌ call $key 최종 필터 미통과. (status: $status, hasResponder: $hasResponder, isCompleted: ${status == 'completed'}) - ${call['eventType']} ${call['address']}',
            );
          }
        } catch (e) {
          debugPrint(
            '[HomeScreen _processSnapshotData] 항목 ($key) 처리 중 오류 발생: $e',
          );
        }
      });

      if (mounted) {
        debugPrint(
          '[HomeScreen _processSnapshotData] setState 호출 전, openCalls: ${results.length}개, isLoading: false',
        );
        setState(() {
          openCalls = results;
          _isLoading = false;
          _applyFilters();
        });
        debugPrint('[HomeScreen _processSnapshotData] setState 호출 완료');
      }
    } catch (e) {
      debugPrint('[HomeScreen _processSnapshotData] 데이터 처리 중 전체 오류 발생: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    debugPrint(
      '[HomeScreen] dispose 호출됨, _callsSubscription 취소 시도',
    ); // dispose 호출 확인
    _callsSubscription?.cancel(); // <<< dispose 시 리스너 구독 취소
    super.dispose();
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

  // 재난 데이터 로드 (단순화 + setState 복원)
  void _loadCalls() {
    debugPrint('[HomeScreen _loadCalls] 함수 시작 - SIMPLIFIED_WITH_SETSTATE');
    _callsSubscription?.cancel();

    // 서버에서 한 번 직접 최신 데이터 가져오기
    dbRef
        .once()
        .then((event) {
          debugPrint('[HomeScreen _loadCalls] 서버 직접 조회 완료');
          if (event.snapshot.exists && mounted) {
            // 서버 데이터로 즉시 업데이트
            _processSnapshotData(event.snapshot);
          }
        })
        .catchError((error) {
          debugPrint('[HomeScreen _loadCalls] 서버 직접 조회 오류: $error');
        });

    // 실시간 리스너도 계속 유지
    _callsSubscription = dbRef.onValue.listen(
      (event) {
        debugPrint('[HomeScreen _loadCalls] Firebase 데이터 변경 감지! (리스너 콜백)');
        _processSnapshotData(event.snapshot);
        try {
          final data = event.snapshot.value;
          debugPrint('[HomeScreen _loadCalls] 수신 데이터: $data');

          if (data == null) {
            debugPrint('[HomeScreen _loadCalls] 수신 데이터가 null입니다.');
            if (mounted) {
              setState(() {
                openCalls = []; // openCalls를 비움
                _isLoading = false;
                _applyFilters(); // 필터 함수 호출
              });
            }
            return;
          }

          final Map<dynamic, dynamic> dataMap;
          if (data is Map) {
            dataMap = data;
            // 각 call별로 개별 로그 출력
            debugPrint('[HomeScreen _loadCalls] 수신 데이터 개수: ${dataMap.length}개');
            dataMap.forEach((key, value) {
              debugPrint('[HomeScreen _loadCalls] $key 원본: $value');
            });
          } else {
            debugPrint('[HomeScreen _loadCalls] 데이터 형식이 Map이 아닙니다: $data');
            if (mounted) {
              setState(() {
                openCalls = [];
                _isLoading = false;
                _applyFilters();
              });
            }
            return;
          }

          // === 데이터 파싱 및 results 리스트 생성 부분 복원 ===
          final List<Map<String, dynamic>> results = [];
          debugPrint(
            '[HomeScreen _loadCalls] dataMap 순회 시작, 총 ${dataMap.length}개 항목',
          );

          dataMap.forEach((key, value) {
            try {
              if (value is! Map) {
                debugPrint(
                  '[HomeScreen _loadCalls] 항목 ($key) 데이터 형식이 Map이 아닙니다: $value',
                );
                return;
              }

              final Map<dynamic, dynamic> call = value;
              final status = call['status']?.toString() ?? 'unknown';
              final bool hasResponder = call['responder'] != null;
              debugPrint(
                '[HomeScreen _loadCalls] call $key 처리 중: status=$status, hasResponder=$hasResponder, eventType=${call['eventType']}, address=${call['address']}',
              );
              // call8만 특별히 상세 로그
              if (key.toString() == 'call8') {
                debugPrint(
                  '[HomeScreen _loadCalls] ⚠️ call8 상세 분석: 원본=$value, 파싱된 status=$status',
                );
              }

              // 수정된 필터링 로직: dispatched 상태이고 responder가 없는 건만 표시
              // 1. status가 'dispatched' 이어야 하고 (웹에서 "호출하기"를 누른 상태)
              // 2. responder가 아직 할당되지 않았어야 하며 (다른 대원이 아직 수락하지 않음)
              // 3. status가 'completed'가 아니어야 함 (완료된 건 제외)
              debugPrint(
                '[HomeScreen _loadCalls] call ${call['id']} 상태 체크: status=$status, hasResponder=$hasResponder',
              );

              if (status == 'dispatched' &&
                  !hasResponder &&
                  status != 'completed') {
                debugPrint(
                  '[HomeScreen _loadCalls] ✅ call $key 최종 필터 통과! 목록에 추가합니다. (${call['eventType']} - ${call['address']})',
                );

                final double lat = _safeDouble(call['lat'], 0.0);
                final double lng = _safeDouble(call['lng'], 0.0);

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
              } else {
                debugPrint(
                  '[HomeScreen _loadCalls] ❌ call $key 최종 필터 미통과. (status: $status, hasResponder: $hasResponder, isCompleted: ${status == 'completed'}) - ${call['eventType']} ${call['address']}',
                );
              }
            } catch (e) {
              debugPrint('[HomeScreen _loadCalls] 항목 ($key) 처리 중 오류 발생: $e');
            }
          });
          // === 데이터 파싱 및 results 리스트 생성 부분 복원 끝 ===

          if (mounted) {
            debugPrint(
              '[HomeScreen _loadCalls] setState 호출 전, openCalls: ${results.length}개, isLoading: false',
            );
            setState(() {
              openCalls = results; // <<< openCalls 상태 업데이트 복원!
              _isLoading = false;
              _applyFilters(); // <<< _applyFilters 호출 복원!
            });
            debugPrint('[HomeScreen _loadCalls] setState 호출 완료');
          }
        } catch (e) {
          debugPrint('[HomeScreen _loadCalls] 데이터 처리 중 전체 오류 발생: $e');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
      onError: (error) {
        debugPrint('[HomeScreen _loadCalls] Firebase 데이터 수신 오류: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
    debugPrint(
      '[HomeScreen _loadCalls] 함수 종료 - 리스너 등록됨 - SIMPLIFIED_WITH_SETSTATE',
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
    debugPrint(
      '[HomeScreen _applyFilters] 함수 시작, 현재 openCalls 개수: ${openCalls.length}, 필터 타입: $_filterType',
    );
    try {
      if (openCalls.isEmpty) {
        debugPrint(
          '[HomeScreen _applyFilters] openCalls가 비어있어 filteredCalls를 비웁니다.',
        );
        if (mounted) {
          // mounted 체크 추가
          setState(() {
            filteredCalls = [];
          });
        }
        return;
      }

      List<Map<String, dynamic>> filtered = List.from(openCalls);
      debugPrint(
        '[HomeScreen _applyFilters] 필터링 전 항목: ${filtered.map((c) => c['id']).toList()}',
      );

      // 이벤트 타입에 따른 필터
      if (_filterType != "전체") {
        filtered =
            filtered.where((call) {
              return call['eventType'] == _filterType;
            }).toList();
        debugPrint(
          '[HomeScreen _applyFilters] 타입 필터링 후 ($_filterType): ${filtered.map((c) => c['id']).toList()}',
        );
      }

      // 현재 위치가 있으면 거리 계산 및 정렬
      if (_currentPosition != null) {
        debugPrint('[HomeScreen _applyFilters] 현재 위치 있음, 거리 계산 및 정렬 시작');
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
              debugPrint(
                '[HomeScreen _applyFilters] 거리 계산 중 오류 (call ${call['id']}): $e',
              );
            }
            call['distance'] = distance;
            debugPrint(
              '[HomeScreen _applyFilters] call ${call['id']} 거리 계산: ${distance}m',
            );
          } catch (e) {
            debugPrint(
              '[HomeScreen _applyFilters] 거리 계산 항목 처리 중 오류 (call ${call['id']}): $e',
            );
            call['distance'] = double.maxFinite;
          }
        }

        try {
          filtered.sort((a, b) {
            double distA = _safeDouble(a['distance'], double.maxFinite);
            double distB = _safeDouble(b['distance'], double.maxFinite);
            return distA.compareTo(distB);
          });
          debugPrint('[HomeScreen _applyFilters] 거리순 정렬 완료');
        } catch (e) {
          debugPrint('[HomeScreen _applyFilters] 거리 정렬 중 오류: $e');
        }
      } else {
        debugPrint('[HomeScreen _applyFilters] 현재 위치 없음, 시간순 정렬 시작');
        try {
          filtered.sort((a, b) {
            int timeA = _safeInt(a['startAt'], 0);
            int timeB = _safeInt(b['startAt'], 0);
            return timeB.compareTo(timeA);
          });
          debugPrint('[HomeScreen _applyFilters] 시간순 정렬 완료');
        } catch (e) {
          debugPrint('[HomeScreen _applyFilters] 시간 정렬 중 오류: $e');
        }
      }

      if (mounted) {
        debugPrint(
          '[HomeScreen _applyFilters] setState 호출 전, filteredCalls: ${filtered.map((c) => c['id']).toList()}',
        );
        setState(() {
          filteredCalls = filtered;
        });
        debugPrint(
          '[HomeScreen _applyFilters] setState 호출 완료, 최종 filteredCalls 개수: ${filteredCalls.length}',
        );
      } else {
        debugPrint('[HomeScreen _applyFilters] mounted가 false라 setState 호출 안함');
      }
    } catch (e) {
      debugPrint('[HomeScreen _applyFilters] 필터 적용 중 전체 오류 발생: $e');
      if (mounted) {
        setState(() {
          filteredCalls = [];
        });
      }
    }
    debugPrint('[HomeScreen _applyFilters] 함수 종료');
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
    final status = call['status'] as String; // status 변수를 명시적으로 사용

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
                  if (_currentPosition != null &&
                      distance != double.maxFinite) // 거리 표시 조건 강화
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
                    '수락 대기 중', // 또는 '새로운 호출', '출동 요청' 등 명확한 용어
                    style: TextStyle(
                      color: Colors.deepOrangeAccent, // 주목도를 높이는 색상
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
