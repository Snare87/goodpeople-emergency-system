// lib/simulator/mock_data_generator.dart
import 'dart:math';
import 'package:geolocator/geolocator.dart';

class MockDataGenerator {
  static final Random _random = Random();
  
  // 세종시 주요 지점들 (테스트용)
  static final List<Location> sejongLocations = [
    Location('세종시청', 36.4800, 127.2890),
    Location('세종병원', 36.4871, 127.2527),
    Location('첫마을', 36.4789, 127.2612),
    Location('세종고속시외버스터미널', 36.4747, 127.2595),
    Location('세종충남대병원', 36.5038, 127.2654),
    Location('나성동', 36.4516, 127.2574),
    Location('도담동', 36.5167, 127.2589),
    Location('어진동', 36.5074, 127.2814),
  ];
  
  // 가상의 재난 생성
  static Map<String, dynamic> generateIncident() {
    final location = sejongLocations[_random.nextInt(sejongLocations.length)];
    final incidentTypes = ['화재', '구조', '응급환자', '교통사고', '붕괴'];
    
    return {
      'id': 'test_${DateTime.now().millisecondsSinceEpoch}',
      'type': incidentTypes[_random.nextInt(incidentTypes.length)],
      'address': location.name,
      'lat': location.lat,
      'lng': location.lng,
      'status': 'broadcasting',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'info': '테스트 재난 상황입니다.',
    };
  }
  
  // 가상의 대원들 생성 (재난 지점 주변)
  static List<MockResponder> generateResponders({
    required double incidentLat,
    required double incidentLng,
    int count = 5,
  }) {
    final responders = <MockResponder>[];
    
    for (int i = 0; i < count; i++) {
      // 재난 지점에서 0.5~3km 범위에 랜덤 배치
      final distance = 0.5 + _random.nextDouble() * 2.5; // km
      final angle = _random.nextDouble() * 2 * pi; // 랜덤 방향
      
      // 위도/경도 계산 (대략적)
      final lat = incidentLat + (distance / 111) * cos(angle);
      final lng = incidentLng + (distance / 111) * sin(angle) / cos(incidentLat * pi / 180);
      
      // 직선 거리
      final straightDistance = Geolocator.distanceBetween(
        incidentLat, incidentLng, lat, lng,
      );
      
      // 실제 도로 거리/시간 시뮬레이션 (직선 거리의 1.2~1.8배)
      final roadFactor = 1.2 + _random.nextDouble() * 0.6;
      final actualDistance = straightDistance * roadFactor;
      
      // 평균 속도 30~50km/h로 계산
      final speed = 30 + _random.nextDouble() * 20; // km/h
      final etaSec = (actualDistance / 1000 / speed * 3600).round();
      
      responders.add(MockResponder(
        id: 'resp_${i + 1}',
        name: '테스트대원${i + 1}',
        rank: ['소방사', '소방교', '소방장'][_random.nextInt(3)],
        position: ['구조대', '구급대', '화재진압'][_random.nextInt(3)],
        lat: lat,
        lng: lng,
        straightDistance: straightDistance.round(),
        actualDistance: actualDistance.round(),
        etaSec: etaSec,
        qualificationScore: _random.nextInt(30),
        acceptDelay: _random.nextInt(30), // 수락까지 걸리는 시간 (초)
      ));
    }
    
    return responders;
  }
  
  // 시나리오 기반 테스트 데이터
  static TestScenario generateScenario(String type) {
    switch (type) {
      case 'optimal_far':
        // 가장 가까운 사람이 아닌 사람이 최적인 경우
        return TestScenario(
          description: '직선거리는 멀지만 도로가 직통인 대원이 더 빠른 경우',
          incident: {
            'lat': 36.4800,
            'lng': 127.2890,
            'address': '세종시청',
            'type': '화재',
          },
          responders: [
            MockResponder(
              id: 'A',
              name: '가까운대원',
              lat: 36.4850,
              lng: 127.2850,
              straightDistance: 800,
              actualDistance: 2400, // 강 건너야 함
              etaSec: 360, // 6분
            ),
            MockResponder(
              id: 'B', 
              name: '먼대원',
              lat: 36.4700,
              lng: 127.2890,
              straightDistance: 1200,
              actualDistance: 1300, // 직통 도로
              etaSec: 180, // 3분
            ),
          ],
        );
        
      case 'multiple_accept':
        // 여러 명이 거의 동시에 수락하는 경우
        return TestScenario(
          description: '3명이 10초 내에 모두 수락',
          incident: generateIncident(),
          responders: generateResponders(
            incidentLat: 36.4800,
            incidentLng: 127.2890,
            count: 3,
          ).map((r) => r..acceptDelay = _random.nextInt(10)).toList(),
        );
        
      default:
        return TestScenario(
          description: '기본 시나리오',
          incident: generateIncident(),
          responders: generateResponders(
            incidentLat: 36.4800,
            incidentLng: 127.2890,
          ),
        );
    }
  }
}

class Location {
  final String name;
  final double lat;
  final double lng;
  
  Location(this.name, this.lat, this.lng);
}

class MockResponder {
  final String id;
  final String name;
  final String rank;
  final String position;
  final double lat;
  final double lng;
  final int straightDistance;
  final int actualDistance;
  final int etaSec;
  final int qualificationScore;
  int acceptDelay;
  
  MockResponder({
    required this.id,
    required this.name,
    this.rank = '소방사',
    this.position = '구조대',
    required this.lat,
    required this.lng,
    required this.straightDistance,
    required this.actualDistance,
    required this.etaSec,
    this.qualificationScore = 0,
    this.acceptDelay = 0,
  });
  
  String get actualDistanceText => '${(actualDistance / 1000).toStringAsFixed(1)}km';
  String get etaText => '${(etaSec / 60).ceil()}분';
}

class TestScenario {
  final String description;
  final Map<String, dynamic> incident;
  final List<MockResponder> responders;
  
  TestScenario({
    required this.description,
    required this.incident,
    required this.responders,
  });
}
