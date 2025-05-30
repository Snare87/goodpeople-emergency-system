// lib/services/incident_candidate_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class IncidentCandidateService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  
  // 후보자로 등록
  static Future<Map<String, dynamic>> registerAsCandidate({
    required String incidentId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('로그인 정보가 없습니다');
      }
      
      // 1. 현재 위치 가져오기
      final position = await _getCurrentPosition();
      
      // 2. 자격증 점수 계산
      final qualificationScore = _calculateQualificationScore(
        userData['certifications'] ?? [],
      );
      
      // 3. 후보자 데이터 생성
      final candidateData = {
        'acceptedAt': FieldValue.serverTimestamp(),
        'lat': position.latitude,
        'lng': position.longitude,
        'qualificationScore': qualificationScore,
        'state': 'pending',
        'responderInfo': {
          'name': userData['name'] ?? '대원',
          'position': userData['position'] ?? '대원',
          'rank': userData['rank'] ?? '소방사',
          'phone': userData['phone'],
        },
      };
      
      // 4. Firestore에 후보자 등록
      final candidateRef = _firestore
          .collection('incidents')
          .doc(incidentId)
          .collection('candidates')
          .doc(userId);
      
      // 트랜잭션으로 안전하게 등록
      await _firestore.runTransaction((transaction) async {
        // 재난 상태 확인
        final incidentDoc = await transaction.get(
          _firestore.collection('incidents').doc(incidentId),
        );
        
        if (!incidentDoc.exists) {
          throw Exception('재난 정보를 찾을 수 없습니다');
        }
        
        final incidentData = incidentDoc.data()!;
        if (incidentData['status'] != 'broadcasting') {
          throw Exception('이미 배정된 재난입니다');
        }
        
        // 중복 확인
        final existingCandidate = await transaction.get(candidateRef);
        if (existingCandidate.exists) {
          throw Exception('이미 수락한 재난입니다');
        }
        
        // 후보자 등록
        transaction.set(candidateRef, candidateData);
      });
      
      debugPrint('[후보 등록] 성공! ID: $userId');
      
      return {
        'success': true,
        'candidateId': userId,
        'message': '후보자로 등록되었습니다. 배정 결과를 기다려주세요.',
      };
      
    } catch (e) {
      debugPrint('[후보 등록] 오류: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // 배정 상태 실시간 감지
  static Stream<CandidateAssignmentStatus> watchAssignmentStatus(
    String incidentId,
    String userId,
  ) {
    return _firestore
        .collection('incidents')
        .doc(incidentId)
        .snapshots()
        .asyncMap((incidentSnapshot) async {
      if (!incidentSnapshot.exists) {
        return CandidateAssignmentStatus(
          status: AssignmentStatus.error,
          message: '재난 정보를 찾을 수 없습니다',
        );
      }
      
      final incidentData = incidentSnapshot.data()!;
      final chosenResponderId = incidentData['chosenResponderId'];
      final status = incidentData['status'];
      
      // 내가 선정됨
      if (chosenResponderId == userId) {
        return CandidateAssignmentStatus(
          status: AssignmentStatus.assigned,
          message: '출동이 확정되었습니다!',
        );
      }
      
      // 다른 사람이 선정됨
      if (chosenResponderId != null && status == 'assigned') {
        // 선정된 대원 정보 가져오기
        final chosenCandidateDoc = await _firestore
            .collection('incidents')
            .doc(incidentId)
            .collection('candidates')
            .doc(chosenResponderId)
            .get();
        
        final chosenInfo = chosenCandidateDoc.data()?['responderInfo'];
        final chosenName = chosenInfo?['name'] ?? '다른 대원';
        
        return CandidateAssignmentStatus(
          status: AssignmentStatus.notAssigned,
          message: '$chosenName님이 배정되었습니다',
          assignedResponderName: chosenName,
        );
      }
      
      // 아직 대기 중
      // 내 후보 정보와 다른 후보자 수 가져오기
      final candidatesSnapshot = await _firestore
          .collection('incidents')
          .doc(incidentId)
          .collection('candidates')
          .where('state', '==', 'pending')
          .get();
      
      final myCandidateDoc = candidatesSnapshot.docs
          .firstWhere((doc) => doc.id == userId, orElse: () => throw Exception());
      
      final myData = myCandidateDoc.data();
      final etaSec = myData['etaSec'];
      
      return CandidateAssignmentStatus(
        status: AssignmentStatus.waiting,
        message: '배정 대기 중... (${candidatesSnapshot.size}명 경쟁)',
        totalCandidates: candidatesSnapshot.size,
        myEtaSec: etaSec,
      );
    });
  }
  
  // 후보 취소
  static Future<bool> cancelCandidacy(String incidentId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;
      
      await _firestore
          .collection('incidents')
          .doc(incidentId)
          .collection('candidates')
          .doc(userId)
          .update({'state': 'cancel'});
      
      return true;
    } catch (e) {
      debugPrint('[후보 취소] 오류: $e');
      return false;
    }
  }
  
  // 현재 위치 가져오기
  static Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('위치 서비스가 비활성화되어 있습니다');
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('위치 권한이 거부되었습니다');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 영구적으로 거부되었습니다');
    }
    
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
  
  // 자격증 점수 계산
  static int _calculateQualificationScore(List<dynamic> certifications) {
    int score = 0;
    
    for (final cert in certifications) {
      final certStr = cert.toString();
      
      // 심폐소생술 관련
      if (certStr.contains('심폐소생') || certStr.contains('CPR')) {
        score += 10;
      }
      
      // 응급구조사
      if (certStr.contains('응급구조사 1급')) {
        score += 20;
      } else if (certStr.contains('응급구조사 2급')) {
        score += 15;
      }
      
      // 의료 관련
      if (certStr.contains('간호사')) {
        score += 15;
      }
      
      // 구조 관련
      if (certStr.contains('인명구조')) {
        score += 10;
      }
    }
    
    return score;
  }
}

// 배정 상태
class CandidateAssignmentStatus {
  final AssignmentStatus status;
  final String message;
  final String? assignedResponderName;
  final int? totalCandidates;
  final int? myEtaSec;
  
  CandidateAssignmentStatus({
    required this.status,
    required this.message,
    this.assignedResponderName,
    this.totalCandidates,
    this.myEtaSec,
  });
  
  String get etaText {
    if (myEtaSec == null) return '';
    final minutes = (myEtaSec! / 60).ceil();
    return '$minutes분';
  }
}

enum AssignmentStatus {
  waiting,      // 대기 중
  assigned,     // 배정됨
  notAssigned,  // 미배정
  error,        // 오류
}
