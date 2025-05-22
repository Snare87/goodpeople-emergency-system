// lib/services/call_data_service.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:goodpeople_responder/models/call.dart';

class CallDataService {
  static final CallDataService _instance = CallDataService._internal();
  factory CallDataService() => _instance;
  CallDataService._internal();

  final DatabaseReference _callsRef = FirebaseDatabase.instance.ref('calls');
  StreamController<List<Call>>? _callsController;

  // 사용 가능한 재난 스트림 가져오기 (기존 필터링 로직 완전 복원)
  Stream<List<Call>> getAvailableCallsStream() {
    _callsController?.close();
    _callsController = StreamController<List<Call>>.broadcast();

    // 서버 우선 정책으로 설정 (기존과 동일)
    _callsRef.keepSynced(true);

    // Firebase에서 데이터 수신
    _callsRef.onValue.listen(
      (event) {
        final data = event.snapshot.value;
        debugPrint('[CallDataService] Firebase 데이터 변경 감지!');
        final calls = _processCallData(data);
        _callsController?.add(calls);
      },
      onError: (error) {
        debugPrint('[CallDataService] Firebase 오류: $error');
        _callsController?.addError(error);
      },
    );

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

  // 재난 데이터 처리 (기존 로직 완전 복원)
  List<Call> _processCallData(dynamic data) {
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

            // 기존 필터링 로직 완전 복원:
            // 1. status가 'dispatched' 이어야 하고 (웹에서 "호출하기"를 누른 상태)
            // 2. responder가 아직 할당되지 않았어야 하며 (다른 대원이 아직 수락하지 않음)
            // 3. status가 'completed'가 아니어야 함 (완료된 건 제외)
            if (status == 'dispatched' &&
                !hasResponder &&
                status != 'completed') {
              debugPrint(
                '[CallDataService] ✅ call $key 최종 필터 통과! 목록에 추가합니다. (${call.eventType} - ${call.address})',
              );
              availableCalls.add(call);
            } else {
              debugPrint(
                '[CallDataService] ❌ call $key 최종 필터 미통과. (status: $status, hasResponder: $hasResponder, isCompleted: ${status == 'completed'}) - ${call.eventType} ${call.address}',
              );
            }
          } catch (e) {
            debugPrint('[CallDataService] 항목 ($key) 처리 중 오류 발생: $e');
          }
        }
      });

      debugPrint('[CallDataService] 처리된 재난 수: ${availableCalls.length}');
      return availableCalls;
    } catch (e) {
      debugPrint('[CallDataService] 데이터 처리 오류: $e');
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

  // 재난 완료 (기존 로직 유지)
  Future<bool> completeCall(String callId) async {
    try {
      await _callsRef.child(callId).update({
        'status': 'completed',
        'completedAt': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('[CallDataService] 재난 완료 성공: $callId');
      return true;
    } catch (e) {
      debugPrint('[CallDataService] completeCall 오류: $e');
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

  // 리소스 정리
  void dispose() {
    _callsController?.close();
    _callsController = null;
    debugPrint('[CallDataService] 리소스 정리 완료');
  }
}
