// lib/services/directions_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:goodpeople_responder/services/directions_service_fallback.dart';
import 'package:goodpeople_responder/services/tmap_directions_service.dart';

class DirectionsService {
  // 직선 경로 생성 (가까운 거리용)
  static DirectionsResult createStraightLineRoute({
    required LatLng origin,
    required LatLng destination,
  }) {
    return DirectionsServiceFallback.createStraightLineRoute(
      origin: origin,
      destination: destination,
    );
  }
  
  static final String _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  
  // 경로 정보를 가져오는 메서드
  static Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    bool preferGoogleApi = false, // Google API 우선 사용 옵션
  }) async {
    DirectionsResult? result;
    
    if (preferGoogleApi) {
      // Google API 먼저 시도
      debugPrint('[DirectionsService] Google Directions API를 먼저 시도합니다.');
      result = await _getGoogleDirections(origin, destination);
      
      if (result != null) {
        debugPrint('[DirectionsService] Google API 성공!');
        return result;
      }
    }
    
    // T Map API 시도
    debugPrint('[DirectionsService] T Map API를 사용하여 경로를 검색합니다.');
    result = await TMapDirectionsService.getDirections(
      origin: origin,
      destination: destination,
    );
    
    if (result != null) {
      debugPrint('[DirectionsService] T Map API 성공!');
      return result;
    }
    
    // 둘 다 실패시 Google API 재시도 (preferGoogleApi가 false인 경우)
    if (!preferGoogleApi) {
      debugPrint('[DirectionsService] Google API로 재시도합니다.');
      result = await _getGoogleDirections(origin, destination);
      
      if (result != null) {
        debugPrint('[DirectionsService] Google API 성공!');
        return result;
      }
    }
    
    // 모든 API 실패 시 직선 경로
    debugPrint('[DirectionsService] 모든 API 실패, 직선 경로를 사용합니다.');
    return createStraightLineRoute(origin: origin, destination: destination);
  }
  
  // Google Directions API 호출 (개선된 파싱 로직 적용)
  static Future<DirectionsResult?> _getGoogleDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    debugPrint('[DirectionsService] ========== Google Directions API ==========');
    debugPrint('[DirectionsService] Origin: ${origin.latitude}, ${origin.longitude}');
    debugPrint('[DirectionsService] Destination: ${destination.latitude}, ${destination.longitude}');
    
    String url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=walking'  // 보행자 모드
        '&language=ko'
        '&region=kr'
        '&key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      
      debugPrint('[DirectionsService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint('[DirectionsService] API Status: ${data['status']}');
        
        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          try {
            final result = DirectionsResult.fromMap(data);
            debugPrint('[DirectionsService] ✅ Google route found: ${result.polylinePoints.length} points');
            return result;
          } catch (e) {
            debugPrint('[DirectionsService] Google API 파싱 오류: $e');
            // 파싱 실패 시 null 반환하여 다른 API 시도
          }
        } else {
          debugPrint('[DirectionsService] Google API 상태: ${data['status']}');
          if (data['error_message'] != null) {
            debugPrint('[DirectionsService] 오류 메시지: ${data['error_message']}');
          }
        }
      }
    } catch (e) {
      debugPrint('[DirectionsService] Google API 요청 실패: $e');
    }
    
    return null;
  }

  // 폴리라인 포인트를 디코딩하는 메서드
  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latitude = lat / 1E5;
      double longitude = lng / 1E5;
      points.add(LatLng(latitude, longitude));
    }

    return points;
  }
}

// 경로 결과 모델
class DirectionsResult {
  final List<LatLng> polylinePoints;
  final int totalDistance; // 미터 단위
  final int totalDuration; // 초 단위
  final String distanceText;
  final String durationText;
  final List<RouteStep> steps;

  DirectionsResult({
    required this.polylinePoints,
    required this.totalDistance,
    required this.totalDuration,
    required this.distanceText,
    required this.durationText,
    required this.steps,
  });

  factory DirectionsResult.fromMap(Map<String, dynamic> map) {
    try {
      final route = map['routes'][0];
      final leg = route['legs'][0];
      
      // 폴리라인 포인트 디코딩
      final String encodedPolyline = route['overview_polyline']['points'];
      final List<LatLng> polylinePoints = DirectionsService.decodePolyline(encodedPolyline);
      
      // 각 단계별 정보 파싱 (안전하게)
      final List<RouteStep> steps = [];
      if (leg['steps'] != null) {
        for (var step in leg['steps']) {
          try {
            steps.add(RouteStep.fromMap(step));
          } catch (e) {
            debugPrint('[DirectionsResult] Step 파싱 오류: $e');
          }
        }
      }

      return DirectionsResult(
        polylinePoints: polylinePoints,
        totalDistance: leg['distance']['value'] ?? 0,
        totalDuration: leg['duration']['value'] ?? 0,
        distanceText: leg['distance']['text'] ?? '',
        durationText: leg['duration']['text'] ?? '',
        steps: steps,
      );
    } catch (e) {
      debugPrint('[DirectionsResult] 전체 파싱 오류: $e');
      rethrow;
    }
  }
}

// 경로 단계 모델
class RouteStep {
  final String instruction;
  final String distance;
  final String duration;
  final LatLng startLocation;
  final LatLng endLocation;
  final String? maneuver;

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    this.maneuver,
  });

  factory RouteStep.fromMap(Map<String, dynamic> map) {
    try {
      // HTML 태그 제거
      String instruction = map['html_instructions'] ?? '';
      instruction = instruction.replaceAll(RegExp(r'<[^>]*>'), '');
      instruction = instruction.replaceAll('&nbsp;', ' ');
      
      return RouteStep(
        instruction: instruction,
        distance: map['distance']?['text'] ?? '',
        duration: map['duration']?['text'] ?? '',
        startLocation: LatLng(
          (map['start_location']?['lat'] ?? 0).toDouble(),
          (map['start_location']?['lng'] ?? 0).toDouble(),
        ),
        endLocation: LatLng(
          (map['end_location']?['lat'] ?? 0).toDouble(),
          (map['end_location']?['lng'] ?? 0).toDouble(),
        ),
        maneuver: map['maneuver'],
      );
    } catch (e) {
      debugPrint('[RouteStep] 파싱 오류: $e');
      rethrow;
    }
  }

  // 방향 아이콘 가져오기
  IconData getManeuverIcon() {
    switch (maneuver) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'turn-slight-left':
        return Icons.turn_slight_left;
      case 'turn-slight-right':
        return Icons.turn_slight_right;
      case 'turn-sharp-left':
        return Icons.turn_sharp_left;
      case 'turn-sharp-right':
        return Icons.turn_sharp_right;
      case 'straight':
        return Icons.straight;
      case 'ramp-left':
      case 'fork-left':
        return Icons.fork_left;
      case 'ramp-right':
      case 'fork-right':
        return Icons.fork_right;
      case 'merge':
        return Icons.merge;
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.roundabout_left;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_left;
      default:
        return Icons.navigation;
    }
  }
}
