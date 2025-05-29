// lib/services/directions_service_fallback.dart
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:goodpeople_responder/services/directions_service.dart';

class DirectionsServiceFallback {
  // Google Directions API가 실패할 경우 직선 경로를 생성
  static DirectionsResult createStraightLineRoute({
    required LatLng origin,
    required LatLng destination,
  }) {
    // 직선 경로 생성
    final polylinePoints = [origin, destination];
    
    // 거리 계산 (미터)
    final distance = _calculateDistance(origin, destination);
    
    // 예상 시간 계산 (평균 속도 40km/h 가정)
    final duration = (distance / 40000 * 3600).round(); // 초 단위
    
    return DirectionsResult(
      polylinePoints: polylinePoints,
      totalDistance: distance.round(),
      totalDuration: duration,
      distanceText: _formatDistance(distance),
      durationText: _formatDuration(duration),
      steps: [
        RouteStep(
          instruction: '목적지까지 직선 경로',
          distance: _formatDistance(distance),
          duration: _formatDuration(duration),
          startLocation: origin,
          endLocation: destination,
          maneuver: 'straight',
        ),
      ],
    );
  }
  
  static double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // 미터
    final double dLat = _toRadians(end.latitude - start.latitude);
    final double dLon = _toRadians(end.longitude - start.longitude);
    
    final double a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(start.latitude)) * 
      math.cos(_toRadians(end.latitude)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }
  
  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
  
  static String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
    return '${meters.round()}m';
  }
  
  static String _formatDuration(int seconds) {
    if (seconds >= 3600) {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}시간 ${minutes}분';
    }
    return '${seconds ~/ 60}분';
  }
}
