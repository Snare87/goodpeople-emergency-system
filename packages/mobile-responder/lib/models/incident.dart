// lib/models/incident.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Incident {
  final String id;
  final String type;
  final String address;
  final double lat;
  final double lng;
  final String status; // broadcasting | assigned | closed
  final String? chosenResponderId;
  final int holdWindowSec;
  final Timestamp createdAt;
  final Timestamp? assignedAt;
  final Map<String, dynamic>? additionalInfo;

  Incident({
    required this.id,
    required this.type,
    required this.address,
    required this.lat,
    required this.lng,
    required this.status,
    this.chosenResponderId,
    this.holdWindowSec = 5,
    required this.createdAt,
    this.assignedAt,
    this.additionalInfo,
  });

  factory Incident.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Incident(
      id: doc.id,
      type: data['type'] ?? '',
      address: data['address'] ?? '',
      lat: (data['lat'] ?? 0).toDouble(),
      lng: (data['lng'] ?? 0).toDouble(),
      status: data['status'] ?? 'broadcasting',
      chosenResponderId: data['chosenResponderId'],
      holdWindowSec: data['holdWindowSec'] ?? 5,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      assignedAt: data['assignedAt'],
      additionalInfo: data['additionalInfo'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'address': address,
      'lat': lat,
      'lng': lng,
      'status': status,
      'chosenResponderId': chosenResponderId,
      'holdWindowSec': holdWindowSec,
      'createdAt': createdAt,
      'assignedAt': assignedAt,
      'additionalInfo': additionalInfo,
    };
  }
}

class IncidentCandidate {
  final String responderId;
  final Timestamp acceptedAt;
  final double lat;
  final double lng;
  final double? distanceKm;
  final int? etaSec;
  final int qualificationScore;
  final String state; // pending | cancel
  final Map<String, dynamic>? responderInfo;

  IncidentCandidate({
    required this.responderId,
    required this.acceptedAt,
    required this.lat,
    required this.lng,
    this.distanceKm,
    this.etaSec,
    this.qualificationScore = 0,
    this.state = 'pending',
    this.responderInfo,
  });

  factory IncidentCandidate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IncidentCandidate(
      responderId: doc.id,
      acceptedAt: data['acceptedAt'] ?? Timestamp.now(),
      lat: (data['lat'] ?? 0).toDouble(),
      lng: (data['lng'] ?? 0).toDouble(),
      distanceKm: data['distanceKm']?.toDouble(),
      etaSec: data['etaSec'],
      qualificationScore: data['qualificationScore'] ?? 0,
      state: data['state'] ?? 'pending',
      responderInfo: data['responderInfo'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'acceptedAt': acceptedAt,
      'lat': lat,
      'lng': lng,
      'distanceKm': distanceKm,
      'etaSec': etaSec,
      'qualificationScore': qualificationScore,
      'state': state,
      'responderInfo': responderInfo,
    };
  }

  // 점수 계산 (낮을수록 좋음)
  double getScore({
    double w1 = 1.0,    // ETA 가중치
    double w2 = 0.0,    // 거리 가중치
    double w3 = 1.0,    // 자격 페널티 가중치
  }) {
    final etaScore = (etaSec ?? 999999) * w1;
    final distanceScore = (distanceKm ?? 999) * w2;
    final qualificationPenalty = _getQualificationPenalty() * w3;
    
    return etaScore + distanceScore + qualificationPenalty;
  }

  // 자격증 페널티 계산
  double _getQualificationPenalty() {
    // 자격증이 없으면 300초 페널티
    // 나중에 더 세밀하게 조정 가능
    return qualificationScore == 0 ? 300 : 0;
  }
}
