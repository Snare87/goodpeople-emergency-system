// lib/services/call_data_service.dart - 5km 반경 제한 적용
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:goodpeople_responder/models/call.dart';
import 'package:geolocator/geolocator.dart';
import 'package:goodpeople_responder/services/location_service.dart';
import 'package:goodpeople_responder/constants/constants.dart';

class CallDataService {
  static final CallDataService _instance = CallDataService._internal();
  factory CallDataService() => _instance;
  CallDataService._internal();

  final DatabaseReference _callsRef = FirebaseDatabase.instance.ref('calls');
  StreamController<List<Call>>? _callsController;

  // 사용자 활성 임무를 관찰하는 전역 컨트롤러 추가
  final StreamController<bool> _activeStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get activeStatusStream => _activeStatusController.stream;

  // 오류 처리 기능 강화
  void _handleError(Object error, StackTrace stackTrace) {
    debugPrint('CallDataService 오류: $error');
    debugPrint('스택 트레이스: $stackTrace');
    _callsController?.addError(error);
  }

  // 사용 가능한 재난 스트림 가져오기 (5km 필터링 추가)
  Stream<List<Call>> getAvailableCallsStream() {
    _callsController?.close();
    _callsController = StreamController<List<Call>>.broadcast();

    try {
      _callsRef.keepSynced(true);
      
      // 실시간 동기화를 위한 우선순위 설정
      _callsRef.ref.setPriority(ServerValue.timestamp);

      _callsRef.onValue.listen(
        (event) async {
          // async 추가
          try {
            final data = event.snapshot.value;
            debugPrint('[CallDataService] Firebase 데이터 변경 감지!');

            // 현재 위치 가져오기 추가
            final currentPosition =
                await LocationService().getCurrentPosition();

            final calls = _processCallData(
              data,
              currentPosition,
            ); // currentPosition 추가
            _callsController?.add(calls);
          } catch (error, stackTrace) {
            _handleError(error, stackTrace);
          }
        },
        onError: (error, stackTrace) {
          _handleError(error, stackTrace);
        },
      );
    } catch (error, stackTrace) {
      _handleError(error, stackTrace);
    }

    return _callsController!.stream;
  }

  // 특정 재난 정보 가져오기
  Future<Call?> getCallById(String callId) async {
    try {
      final snapshot = await _callsRef.child(callId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return Call.fromMap(callId, data);
      }
      return null;
    } catch (e) {
      debugPrint('[CallDataService] getCallById 오류: $e');
      return null;
    }
  }

  // 재난 데이터 처리 (5km 필터링 추가)
  List<Call> _processCallData(dynamic data, Position? currentPosition) {
    // currentPosition 추가
    if (data == null) {
      debugPrint('[CallDataService] 수신 데이터가 null입니다.');
      return [];
    }

    try {
      final Map<dynamic, dynamic> dataMap = data as Map<dynamic, dynamic>;
      final List<Call> availableCalls = [];

      debugPrint('[CallDataService] 수신 데이터 개수: ${dataMap.length}개');

      dataMap.forEach((key, value) {
        if (value is Map) {
          try {
            final call = Call.fromMap(key.toString(), value);
            final status = call.status;
            final hasResponder = call.responder != null;

            debugPrint(
              '[CallDataService] call $key 처리 중: status=$status, hasResponder=$hasResponder, eventType=${call.eventType}, address=${call.address}',
            );

            // 기존 필터링 로직 완전 복원 - 원본 그대로 유지:
            // 1. status가 'dispatched' 이어야 하고 (웹에서 "호출하기"를 누른 상태)
            // 2. responder가 아직 할당되지 않았어야 하며 (다른 대원이 아직 수락하지 않음)
            // 3. status가 'completed'가 아니어야 함 (완료된 건 제외)
            if (status == 'dispatched' &&
                !hasResponder &&
                status != 'completed') {
              // 5km 반경 필터링 추가
              if (currentPosition != null) {
                final distance = Geolocator.distanceBetween(
                  currentPosition.latitude,
                  currentPosition.longitude,
                  call.lat,
                  call.lng,
                );

                // 5km(5000m) 이내인 경우만 추가
                if (distance <= CallConstants.maxDistanceMeters) {
                  debugPrint(
                    '[CallDataService] ✅ call $key ${CallConstants.maxDistanceKm.toInt()}km 이내! 거리: ${distance.toStringAsFixed(0)}m',
                  );
                  availableCalls.add(call.copyWith(distance: distance));
                } else {
                  debugPrint(
                    '[CallDataService] ❌ call $key ${CallConstants.maxDistanceKm.toInt()}km 초과. 거리: ${distance.toStringAsFixed(0)}m',
                  );
                }
              } else {
                // 위치 정보가 없으면 모든 재난 표시 (기존 동작)
                debugPrint('[CallDataService] ⚠️ 위치 정보 없음 - call $key 추가');
                availableCalls.add(call);
              }
            } else {
              debugPrint(
                '[CallDataService] ❌ call $key 최종 필터 미통과. (status: $status, hasResponder: $hasResponder, isCompleted: ${status == 'completed'}) - ${call.eventType} ${call.address}',
              );
            }
          } catch (e, stackTrace) {
            debugPrint('[CallDataService] 항목 ($key) 처리 중 오류 발생: $e');
            debugPrint(stackTrace.toString());
          }
        }
      });

      debugPrint('[CallDataService] 처리된 재난 수: ${availableCalls.length}');
      return availableCalls;
    } catch (e, stackTrace) {
      debugPrint('[CallDataService] 데이터 처리 오류: $e');
      debugPrint(stackTrace.toString());
      return [];
    }
  }

  // 현재 사용자의 활성 임무 스트림 가져오기 (새로 추가)
  Stream<List<Call>> getActiveMissionsStream(String userId) {
    StreamController<List<Call>>? activeMissionsController;
    activeMissionsController = StreamController<List<Call>>.broadcast();

    // 서버 우선 정책으로 설정
    try {
      _callsRef.keepSynced(true);

      // Firebase에서 데이터 수신
      _callsRef.onValue.listen(
        (event) {
          try {
            final data = event.snapshot.value;
            debugPrint('[CallDataService] 활성 임무 데이터 변경 감지!');
            final activeMissions = _processActiveMissionData(data, userId);

            // 활성 임무 유무 상태 전파
            _activeStatusController.add(activeMissions.isNotEmpty);

            activeMissionsController?.add(activeMissions);
          } catch (error, stackTrace) {
            debugPrint('[CallDataService] 활성 임무 처리 오류: $error');
            debugPrint(stackTrace.toString());
            activeMissionsController?.addError(error);
          }
        },
        onError: (error, stackTrace) {
          debugPrint('[CallDataService] 활성 임무 Firebase 오류: $error');
          debugPrint(stackTrace.toString());
          activeMissionsController?.addError(error);
        },
      );
    } catch (e, stackTrace) {
      debugPrint('[CallDataService] 활성 임무 스트림 설정 오류: $e');
      debugPrint(stackTrace.toString());
      activeMissionsController.addError(e);
    }

    return activeMissionsController.stream;
  }

  // 활성 임무 데이터 처리 (수정된 버전)
  List<Call> _processActiveMissionData(dynamic data, String userId) {
    if (data == null) {
      debugPrint('[CallDataService] 활성 임무 수신 데이터가 null입니다.');
      return [];
    }

    try {
      final Map<dynamic, dynamic> dataMap = data as Map<dynamic, dynamic>;
      final List<Call> activeMissions = [];

      debugPrint(
        '[CallDataService] 활성 임무 수신 데이터 개수: ${dataMap.length}개, 사용자 ID: $userId',
      );

      dataMap.forEach((key, value) {
        if (value is Map) {
          try {
            final call = Call.fromMap(key.toString(), value);

            // 응답자가 있고, 상태가 accepted이고, 완료되지 않은 경우
            final hasResponder = call.responder != null;
            final isAccepted = call.status == 'accepted';
            final isNotCompleted = call.status != 'completed';

            debugPrint(
              '[CallDataService] Call $key 검사: hasResponder=$hasResponder, status=${call.status}, responder=${call.responder?.name}, responderId=${call.responder?.id}',
            );

            // 중요: responder의 ID가 현재 사용자 ID를 포함하는지 확인
            if (hasResponder && isAccepted && isNotCompleted) {
              // responder.id는 "resp_userId_timestamp" 형식
              final isMyMission = call.responder!.id.contains(userId);

              debugPrint(
                '[CallDataService] 임무 소유자 확인: responderId=${call.responder!.id}, userId=$userId, isMyMission=$isMyMission',
              );

              if (isMyMission) {
                debugPrint(
                  '[CallDataService] ✅ 내 활성 임무 발견! $key - ${call.eventType} at ${call.address}',
                );
                activeMissions.add(call);
              } else {
                debugPrint('[CallDataService] ❌ 다른 사용자의 임무입니다 - $key');
              }
            }
          } catch (e) {
            debugPrint('[CallDataService] 활성 임무 항목 ($key) 처리 중 오류 발생: $e');
          }
        }
      });

      debugPrint(
        '[CallDataService] 사용자 $userId의 활성 임무 수: ${activeMissions.length}',
      );

      // 수락 시간순으로 정렬 (최근 수락한 것이 위로)
      activeMissions.sort(
        (a, b) => (b.acceptedAt ?? 0).compareTo(a.acceptedAt ?? 0),
      );

      return activeMissions;
    } catch (e) {
      debugPrint('[CallDataService] 활성 임무 데이터 처리 오류: $e');
      return [];
    }
  }

  // 재난 수락 (기존 로직 유지)
  Future<bool> acceptCall(
    String callId,
    String responderId,
    String responderName,
    String position,
  ) async {
    try {
      await _callsRef.child(callId).update({
        'status': 'accepted',
        'acceptedAt': DateTime.now().millisecondsSinceEpoch,
        'responder': {
          'id': responderId,
          'name': responderName,
          'position': position,
        },
      });
      debugPrint('[CallDataService] 재난 수락 성공: $callId');
      return true;
    } catch (e) {
      debugPrint('[CallDataService] acceptCall 오류: $e');
      return false;
    }
  }

  // 재난 완료 (수정됨)
  Future<bool> completeCall(String callId) async {
    try {
      await _callsRef.child(callId).update({
        'status': 'completed',
        'completedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // 완료 후 활성 상태 업데이트 브로드캐스트
      _activeStatusController.add(false);

      debugPrint('[CallDataService] 재난 완료 성공: $callId');
      return true;
    } catch (e) {
      debugPrint('[CallDataService] completeCall 오류: $e');
      return false;
    }
  }

  // 수락 취소 (새로 추가)
  Future<bool> cancelAcceptance(String callId, String currentUserId) async {
    try {
      // 먼저 현재 call 상태 확인
      final snapshot = await _callsRef.child(callId).get();
      if (!snapshot.exists) return false;

      final callData = Map<String, dynamic>.from(snapshot.value as Map);
      final call = Call.fromMap(callId, callData);

      // 자신이 수락한 임무인지 확인
      if (call.responder != null &&
          call.responder!.id.contains(currentUserId)) {
        await _callsRef.child(callId).update({
          'status': 'dispatched',
          'acceptedAt': null,
          'responder': null,
        });

        debugPrint('[CallDataService] 수락 취소 성공: $callId');
        return true;
      } else {
        debugPrint('[CallDataService] 권한 없음: 다른 대원의 임무입니다');
        return false;
      }
    } catch (e) {
      debugPrint('[CallDataService] cancelAcceptance 오류: $e');
      return false;
    }
  }

  // 응답자 위치 업데이트 (기존 로직 유지)
  Future<bool> updateResponderLocation(
    String callId,
    double lat,
    double lng,
  ) async {
    try {
      await _callsRef.child(callId).child('responder').update({
        'lat': lat,
        'lng': lng,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('[CallDataService] 위치 업데이트 성공: $callId');
      return true;
    } catch (e) {
      debugPrint('[CallDataService] updateResponderLocation 오류: $e');
      return false;
    }
  }

  // 연결 상태 확인 (추가 기능)
  Future<bool> checkConnection() async {
    try {
      final connectedRef = FirebaseDatabase.instance.ref('.info/connected');
      final snapshot = await connectedRef.get();
      return snapshot.value == true;
    } catch (e) {
      debugPrint('[CallDataService] 연결 상태 확인 오류: $e');
      return false;
    }
  }

  // 현재 사용자가 활성 임무를 가지고 있는지 확인 (수정된 버전)
  Future<bool> hasActiveMission(String userId) async {
    try {
      debugPrint('[CallDataService] 활성 임무 확인 중: userId=$userId');
      final snapshot = await _callsRef.get(); // _callsRef 사용
      if (!snapshot.exists) return false;

      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

      for (var entry in data.entries) {
        final call = Call.fromMap(entry.key.toString(), entry.value);

        // accepted 상태이고 완료되지 않은 임무가 있는지 확인
        if (call.status == 'accepted' &&
            call.responder != null &&
            call.status != 'completed') {
          // responder.id가 현재 사용자 ID를 포함하는지 확인
          final isMyMission = call.responder!.id.contains(userId);

          if (isMyMission) {
            debugPrint(
              '[CallDataService] 사용자 $userId의 활성 임무 발견: ${call.id} (${call.eventType})',
            );
            return true;
          }
        }
      }

      debugPrint('[CallDataService] 사용자 $userId의 활성 임무 없음');
      return false;
    } catch (e) {
      debugPrint('[CallDataService] 활성 임무 확인 오류: $e');
      return false;
    }
  }

  // 현재 사용자가 활성 임무를 가지고 있는지 여부를 스트림으로 제공
  Stream<bool> hasActiveMissionStream(String userId) {
    // 스트림 변환: 활성 임무 목록 스트림 -> 불리언 스트림
    return getActiveMissionsStream(
      userId,
    ).map((missions) => missions.isNotEmpty);
  }

  // 현재 사용자의 활성 임무 정보 가져오기 (수정된 버전)
  Future<Call?> getCurrentActiveMission(String userId) async {
    try {
      final snapshot = await _callsRef.get(); // _callsRef 사용
      if (!snapshot.exists) return null;

      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

      for (var entry in data.entries) {
        final call = Call.fromMap(entry.key.toString(), entry.value);

        if (call.status == 'accepted' &&
            call.responder != null &&
            call.status != 'completed') {
          // responder.id가 현재 사용자 ID를 포함하는지 확인
          final isMyMission = call.responder!.id.contains(userId);

          if (isMyMission) {
            debugPrint(
              '[CallDataService] 현재 활성 임무 발견: ${call.id} (${call.eventType})',
            );
            return call;
          }
        }
      }

      debugPrint('[CallDataService] 현재 활성 임무 없음');
      return null;
    } catch (e) {
      debugPrint('[CallDataService] 현재 활성 임무 조회 오류: $e');
      return null;
    }
  }

  // 리소스 정리
  void dispose() {
    _callsController?.close();
    _callsController = null;
    _activeStatusController.close();
    debugPrint('[CallDataService] 리소스 정리 완료');
  }
}
