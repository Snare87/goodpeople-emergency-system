// lib/models/candidate/candidate.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Candidate {
  final String id;
  final String userId;
  final String name;
  final String position;
  final String rank;
  final List<String> certifications;
  
  // 거리 정보
  final double straightDistance;  // 직선 거리 (미터)
  final double actualDistance;    // 실제 도로 거리 (미터)
  final String actualDistanceText; // "1.2km" 형식
  
  // 시간 정보
  final int estimatedArrival;      // 도착 예상 시간 (초)
  final String estimatedArrivalText; // "5분" 형식
  
  // 경로 정보
  final String? routePolyline;     // 인코딩된 폴리라인
  final String routeApiUsed;       // 'google', 'tmap', 'straight'
  
  // 위치 정보
  final LatLng currentLocation;
  
  // 메타 정보
  final DateTime acceptedAt;
  final double? score;
  final DateTime? lastUpdated;
  
  Candidate({
    required this.id,
    required this.userId,
    required this.name,
    required this.position,
    required this.rank,
    required this.certifications,
    required this.straightDistance,
    required this.actualDistance,
    required this.actualDistanceText,
    required this.estimatedArrival,
    required this.estimatedArrivalText,
    required this.currentLocation,
    required this.acceptedAt,
    this.routePolyline,
    this.routeApiUsed = 'straight',
    this.score,
    this.lastUpdated,
  });
  
  // 경로 효율성 계산 (직선 대비 실제 거리)
  double get routeEfficiency => straightDistance / actualDistance;
  
  // 효율성이 좋은지 판단
  bool get hasEfficientRoute => routeEfficiency > 0.8;
  
  // Firebase에서 데이터 변환
  factory Candidate.fromMap(Map<String, dynamic> map, String id) {
    return Candidate(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      position: map['position'] ?? '',
      rank: map['rank'] ?? '소방사',
      certifications: List<String>.from(map['certifications'] ?? []),
      straightDistance: (map['straightDistance'] ?? 0).toDouble(),
      actualDistance: (map['actualDistance'] ?? 0).toDouble(),
      actualDistanceText: map['actualDistanceText'] ?? '',
      estimatedArrival: map['estimatedArrival'] ?? 0,
      estimatedArrivalText: map['estimatedArrivalText'] ?? '',
      currentLocation: LatLng(
        (map['currentLocation']?['lat'] ?? 0).toDouble(),
        (map['currentLocation']?['lng'] ?? 0).toDouble(),
      ),
      acceptedAt: DateTime.fromMillisecondsSinceEpoch(
        map['acceptedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      routePolyline: map['routePolyline'],
      routeApiUsed: map['routeApiUsed'] ?? 'straight',
      score: (map['score'] ?? 0).toDouble(),
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'])
          : null,
    );
  }
  
  // Firebase 저장용 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'position': position,
      'rank': rank,
      'certifications': certifications,
      'straightDistance': straightDistance,
      'actualDistance': actualDistance,
      'actualDistanceText': actualDistanceText,
      'estimatedArrival': estimatedArrival,
      'estimatedArrivalText': estimatedArrivalText,
      'currentLocation': {
        'lat': currentLocation.latitude,
        'lng': currentLocation.longitude,
      },
      'acceptedAt': acceptedAt.millisecondsSinceEpoch,
      'routePolyline': routePolyline,
      'routeApiUsed': routeApiUsed,
      'score': score,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
    };
  }
  
  // 점수 계산을 위한 copyWith 메서드
  Candidate copyWith({double? score}) {
    return Candidate(
      id: id,
      userId: userId,
      name: name,
      position: position,
      rank: rank,
      certifications: certifications,
      straightDistance: straightDistance,
      actualDistance: actualDistance,
      actualDistanceText: actualDistanceText,
      estimatedArrival: estimatedArrival,
      estimatedArrivalText: estimatedArrivalText,
      currentLocation: currentLocation,
      acceptedAt: acceptedAt,
      routePolyline: routePolyline,
      routeApiUsed: routeApiUsed,
      score: score ?? this.score,
      lastUpdated: lastUpdated,
    );
  }
}
