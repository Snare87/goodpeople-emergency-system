// lib/services/improved_call_acceptance_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:goodpeople_responder/services/directions_service.dart';
import 'package:flutter/material.dart';

class ImprovedCallAcceptanceService {
  static final _db = FirebaseDatabase.instance;
  
  // 후보자로 등록 (개선된 버전)
  static Future<Map<String, dynamic>> registerAsCandidate({
    required String callId,
    required Map<String, dynamic> callData,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('로그인 정보 없음');
      
      // 1. 현재 위치 가져오기
      final userPosition = await Geolocator.getCurrentPosition();
      
      // 2. 직선 거리 계산
      final straightDistance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        callData['lat'] ?? 0,
        callData['lng'] ?? 0,
      );
      
      // 3. 실제 도로 경로 계산
      debugPrint('[후보 등록] 실제 경로 계산 시작...');
      final directionsResult = await DirectionsService.getDirections(
        origin: LatLng(userPosition.latitude, userPosition.longitude),
        destination: LatLng(callData['lat'] ?? 0, callData['lng'] ?? 0),
      );
      
      // 4. 후보자 데이터 생성
      final candidateData = {
        'id': 'cand_${userId}_${DateTime.now().millisecondsSinceEpoch}',
        'userId': userId,
        'name': userData['name'] ?? '대원',
        'position': userData['position'] ?? '대원',
        'rank': userData['rank'] ?? '소방사',
        'certifications': userData['certifications'] ?? [],
        
        // 거리 정보
        'straightDistance': straightDistance.round(),
        'actualDistance': directionsResult?.totalDistance ?? straightDistance.round(),
        'actualDistanceText': directionsResult?.distanceText ?? '${(straightDistance/1000).toStringAsFixed(1)}km',
        
        // 시간 정보
        'estimatedArrival': directionsResult?.totalDuration ?? (straightDistance / 50).round(),
        'estimatedArrivalText': directionsResult?.durationText ?? '${(straightDistance / 50).round()}분',
        
        // 경로 정보
        'routeApiUsed': directionsResult != null ? 'google' : 'straight',
        
        // 위치 정보
        'currentLocation': {
          'lat': userPosition.latitude,
          'lng': userPosition.longitude,
        },
        
        'acceptedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      // 5. Firebase Transaction으로 안전하게 추가
      final callRef = _db.ref('calls/$callId');
      final result = await callRef.runTransaction((current) {
        if (current == null) {
          return Transaction.abort();
        }
        
        final callMap = Map<String, dynamic>.from(current as Map);
        
        // 상태 확인
        if (callMap['status'] != 'dispatched') {
          return Transaction.abort();
        }
        
        // 후보자 모집 시간 확인 (기본 2분)
        final windowEnd = callMap['candidateWindowEnd'] ?? 
            (callMap['dispatchedAt'] ?? 0) + 120000; // 2분
        
        if (DateTime.now().millisecondsSinceEpoch > windowEnd) {
          return Transaction.abort();
        }
        
        // 이미 후보자인지 확인
        final candidates = List<Map>.from(callMap['candidates'] ?? []);
        if (candidates.any((c) => c['userId'] == userId)) {
          return Transaction.abort();
        }
        
        // 후보자 추가
        callMap['candidates'] = [...candidates, candidateData];
        return Transaction.success(callMap);
      });
      
      if (!result.committed) {
        throw Exception('후보자 등록 실패 - 이미 마감되었거나 중복 등록입니다.');
      }
      
      debugPrint('[후보 등록] 성공! 후보자 ID: ${candidateData['id']}');
      return {
        'success': true,
        'candidateData': candidateData,
        'message': '후보자로 등록되었습니다. 선정 결과를 기다려주세요.',
      };
      
    } catch (e) {
      debugPrint('[후보 등록] 오류: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // 선정 결과 확인
  static Stream<CandidateStatus> watchSelectionStatus(
    String callId,
    String userId,
  ) {
    return _db.ref('calls/$callId').onValue.map((event) {
      if (!event.snapshot.exists) {
        return CandidateStatus(
          status: SelectionStatus.error,
          message: '재난 정보를 찾을 수 없습니다.',
        );
      }
      
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      
      // 선정된 대원 확인
      if (data['selectedResponderId'] == userId) {
        return CandidateStatus(
          status: SelectionStatus.selected,
          message: '축하합니다! 이 임무에 선정되었습니다.',
        );
      }
      
      // 다른 대원이 선정됨
      if (data['selectedResponderId'] != null) {
        final selectedCandidate = (data['candidates'] as List?)
            ?.firstWhere(
              (c) => c['userId'] == data['selectedResponderId'],
              orElse: () => null,
            );
        
        return CandidateStatus(
          status: SelectionStatus.notSelected,
          message: '${selectedCandidate?['name'] ?? '다른 대원'}님이 선정되었습니다.',
          selectedCandidateName: selectedCandidate?['name'],
        );
      }
      
      // 아직 대기 중
      final candidates = List<Map>.from(data['candidates'] ?? []);
      return CandidateStatus(
        status: SelectionStatus.waiting,
        message: '선정 대기 중... (총 ${candidates.length}명 후보)',
        totalCandidates: candidates.length,
      );
    });
  }
  
  // 실시간 경로 업데이트
  static Future<void> updateRouteInfo(
    String callId,
    String candidateId,
  ) async {
    try {
      final position = await Geolocator.getCurrentPosition();
      
      // 재난 위치 가져오기
      final callSnapshot = await _db.ref('calls/$callId').get();
      if (!callSnapshot.exists) return;
      
      final callData = Map<String, dynamic>.from(callSnapshot.value as Map);
      
      // 새로운 경로 계산
      final directions = await DirectionsService.getDirections(
        origin: LatLng(position.latitude, position.longitude),
        destination: LatLng(callData['lat'] ?? 0, callData['lng'] ?? 0),
      );
      
      if (directions != null) {
        // Firebase 업데이트
        await _db.ref('calls/$callId/candidates/$candidateId').update({
          'actualDistance': directions.totalDistance,
          'actualDistanceText': directions.distanceText,
          'estimatedArrival': directions.totalDuration,
          'estimatedArrivalText': directions.durationText,
          'currentLocation': {
            'lat': position.latitude,
            'lng': position.longitude,
          },
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
        
        debugPrint('[경로 업데이트] 성공 - 새 도착 시간: ${directions.durationText}');
      }
    } catch (e) {
      debugPrint('[경로 업데이트] 오류: $e');
    }
  }
}

// 후보자 상태
class CandidateStatus {
  final SelectionStatus status;
  final String message;
  final String? selectedCandidateName;
  final int? totalCandidates;
  
  CandidateStatus({
    required this.status,
    required this.message,
    this.selectedCandidateName,
    this.totalCandidates,
  });
}

enum SelectionStatus {
  waiting,      // 선정 대기 중
  selected,     // 선정됨
  notSelected,  // 선정 안 됨
  error,        // 오류
}
