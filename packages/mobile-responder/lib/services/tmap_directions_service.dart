// lib/services/tmap_directions_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:goodpeople_responder/services/directions_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TMapDirectionsService {
  // T Map API 키 (https://tmapapi.sktelecom.com/ 에서 발급)
  static final String _tmapApiKey = dotenv.env['TMAP_API_KEY'] ?? '';
  
  // 요청 제한을 위한 변수
  static int _requestCount = 0;
  static DateTime _lastReset = DateTime.now();
  static const int _maxRequestsPerMinute = 30;
  
  static Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // API 키 확인
    if (_tmapApiKey.isEmpty) {
      debugPrint('[TMapDirections] ❌ API 키가 설정되지 않았습니다.');
      return null;
    }
    
    // 요청 제한 확인
    final now = DateTime.now();
    if (now.difference(_lastReset).inMinutes >= 1) {
      _requestCount = 0;
      _lastReset = now;
    }
    
    if (_requestCount >= _maxRequestsPerMinute) {
      debugPrint('[TMapDirections] ⚠️ 분당 요청 한도 초과 ($_maxRequestsPerMinute회)');
      return null;
    }
    
    _requestCount++;
    debugPrint('[TMapDirections] ========== T Map API Request ==========');
    debugPrint('[TMapDirections] Origin: ${origin.latitude}, ${origin.longitude}');
    debugPrint('[TMapDirections] Destination: ${destination.latitude}, ${destination.longitude}');
    
    final String url = 'https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1';
    
    final Map<String, dynamic> requestBody = {
      'startX': origin.longitude.toString(),
      'startY': origin.latitude.toString(),
      'endX': destination.longitude.toString(),
      'endY': destination.latitude.toString(),
      'startName': '출발지',
      'endName': '도착지',
      'searchOption': '0', // 0: 추천, 4: 대로우선, 10: 최단거리
      'resCoordType': 'WGS84GEO',
      'reqCoordType': 'WGS84GEO',
      'angle': 0,
      'speed': 0,
      'sort': 'index',
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'appKey': _tmapApiKey,
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      debugPrint('[TMapDirections] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return _parseResponse(response.body);
      } else {
        debugPrint('[TMapDirections] Error response: ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('[TMapDirections] Request Exception: $e');
      debugPrint('[TMapDirections] Stack trace: $stackTrace');
    }
    
    return null;
  }
  
  static DirectionsResult? _parseResponse(String responseBody) {
    try {
      final Map<String, dynamic> data = json.decode(responseBody);
      
      // 응답 타입 확인
      debugPrint('[TMapDirections] Response type: ${data['type']}');
      
      if (data['type'] != 'FeatureCollection' || data['features'] == null) {
        debugPrint('[TMapDirections] Invalid response type or no features');
        return null;
      }
      
      final List features = data['features'];
      if (features.isEmpty) {
        debugPrint('[TMapDirections] No features in response');
        return null;
      }
      
      final List<LatLng> points = [];
      final List<RouteStep> steps = [];
      int totalDistance = 0;
      int totalTime = 0;
      
      debugPrint('[TMapDirections] Features count: ${features.length}');
      
      for (int i = 0; i < features.length; i++) {
        final feature = features[i];
        if (feature == null) continue;
        
        try {
          final properties = feature['properties'] as Map<String, dynamic>?;
          final geometry = feature['geometry'] as Map<String, dynamic>?;
          
          if (properties != null) {
            // 첫 번째 feature에서 전체 경로 정보 추출
            if (i == 0) {
              if (properties['totalDistance'] != null) {
                totalDistance = _toInt(properties['totalDistance']);
              }
              if (properties['totalTime'] != null) {
                totalTime = _toInt(properties['totalTime']);
              }
              debugPrint('[TMapDirections] Total distance: $totalDistance m, time: $totalTime sec');
            }
            
            // 각 단계 정보 처리
            if (geometry != null && properties['description'] != null) {
              final description = properties['description'].toString();
              final distance = _toInt(properties['distance'] ?? 0);
              final time = _toInt(properties['time'] ?? 0);
              
              // 좌표 추출 및 Step 생성
              final coordPair = _extractStepCoordinates(geometry);
              if (coordPair != null) {
                steps.add(RouteStep(
                  instruction: description,
                  distance: distance > 0 ? '${distance}m' : '',
                  duration: time > 0 ? '${time}초' : '',
                  startLocation: coordPair.start,
                  endLocation: coordPair.end,
                  maneuver: _getTurnType(properties['turnType']),
                ));
              }
            }
          }
          
          // 경로 좌표 추출
          if (geometry != null) {
            _extractRoutePoints(geometry, points);
          }
        } catch (e) {
          debugPrint('[TMapDirections] Error parsing feature $i: $e');
          continue;
        }
      }
      
      debugPrint('[TMapDirections] ✅ Route found: ${points.length} points, ${steps.length} steps');
      
      if (points.isEmpty) {
        debugPrint('[TMapDirections] Warning: No points extracted');
        return null;
      }
      
      return DirectionsResult(
        polylinePoints: points,
        totalDistance: totalDistance,
        totalDuration: totalTime,
        distanceText: _formatDistance(totalDistance),
        durationText: _formatDuration(totalTime),
        steps: steps,
      );
    } catch (e, stackTrace) {
      debugPrint('[TMapDirections] Parse Exception: $e');
      debugPrint('[TMapDirections] Stack trace: $stackTrace');
      return null;
    }
  }
  
  // 경로 좌표 추출 (폴리라인용)
  static void _extractRoutePoints(Map<String, dynamic> geometry, List<LatLng> points) {
    final type = geometry['type'] as String?;
    final coordinates = geometry['coordinates'];
    
    if (type == null || coordinates == null) return;
    
    if (type == 'LineString' && coordinates is List) {
      for (var coord in coordinates) {
        if (coord is List && coord.length >= 2) {
          try {
            final lng = _toDouble(coord[0]);
            final lat = _toDouble(coord[1]);
            points.add(LatLng(lat, lng));
          } catch (e) {
            debugPrint('[TMapDirections] Error parsing coordinate: $coord');
          }
        }
      }
    } else if (type == 'Point' && coordinates is List && coordinates.length >= 2) {
      try {
        final lng = _toDouble(coordinates[0]);
        final lat = _toDouble(coordinates[1]);
        points.add(LatLng(lat, lng));
      } catch (e) {
        debugPrint('[TMapDirections] Error parsing point: $coordinates');
      }
    }
  }
  
  // 단계별 좌표 추출 (네비게이션 안내용)
  static _CoordinatePair? _extractStepCoordinates(Map<String, dynamic> geometry) {
    final type = geometry['type'] as String?;
    final coordinates = geometry['coordinates'];
    
    if (type == null || coordinates == null) return null;
    
    try {
      if (type == 'LineString' && coordinates is List && coordinates.isNotEmpty) {
        // LineString: [[lng,lat], [lng,lat], ...]
        final first = coordinates.first as List;
        final last = coordinates.last as List;
        
        if (first.length >= 2 && last.length >= 2) {
          return _CoordinatePair(
            start: LatLng(_toDouble(first[1]), _toDouble(first[0])),
            end: LatLng(_toDouble(last[1]), _toDouble(last[0])),
          );
        }
      } else if (type == 'Point' && coordinates is List && coordinates.length >= 2) {
        // Point: [lng, lat]
        final point = LatLng(_toDouble(coordinates[1]), _toDouble(coordinates[0]));
        return _CoordinatePair(start: point, end: point);
      }
    } catch (e) {
      debugPrint('[TMapDirections] Error extracting step coordinates: $e');
    }
    
    return null;
  }
  
  // 안전한 타입 변환 헬퍼 함수들
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw ArgumentError('Cannot convert $value (${value.runtimeType}) to double');
  }
  
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return 0;
  }
  
  static String _formatDistance(int meters) {
    if (meters < 1000) {
      return '$meters m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }
  
  static String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds초';
    }
    final minutes = seconds ~/ 60;
    if (minutes < 60) {
      return '$minutes분';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes > 0) {
        return '$hours시간 $remainingMinutes분';
      }
      return '$hours시간';
    }
  }
  
  static String? _getTurnType(dynamic turnType) {
    if (turnType == null) return null;
    
    // T Map turnType 코드
    // 11: 직진, 12: 좌회전, 13: 우회전, 14: U턴
    // 16: 8시 방향, 17: 10시 방향, 18: 2시 방향, 19: 4시 방향
    // 125: 육교, 126: 지하보도, 127: 계단
    // 128: 경사로, 129: 계단+경사로
    
    final type = _toInt(turnType);
    
    switch (type) {
      case 11: return 'straight';
      case 12: return 'turn-left';
      case 13: return 'turn-right';
      case 14: return 'uturn-left';
      case 16: return 'turn-sharp-left';
      case 17: return 'turn-slight-left';
      case 18: return 'turn-slight-right';
      case 19: return 'turn-sharp-right';
      case 125: return 'overpass'; // 육교
      case 126: return 'underpass'; // 지하보도
      case 127: return 'stairs'; // 계단
      case 128: return 'ramp'; // 경사로
      case 129: return 'stairs'; // 계단+경사로
      default: return null;
    }
  }
}

// 좌표 쌍을 저장하는 헬퍼 클래스
class _CoordinatePair {
  final LatLng start;
  final LatLng end;
  
  _CoordinatePair({required this.start, required this.end});
}
