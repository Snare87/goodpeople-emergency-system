import 'package:flutter/material.dart';

class CallConstants {
  // 재난 유형
  static const String fireType = '화재';
  static const String rescueType = '구조';
  static const String emergencyType = '구급';
  static const String otherType = '기타';

  // 재난 상태
  static const String statusIdle = 'idle';
  static const String statusDispatched = 'dispatched';
  static const String statusAccepted = 'accepted';
  static const String statusCompleted = 'completed';

  // 아이콘 매핑
  static IconData getEventTypeIcon(String eventType) {
    switch (eventType) {
      case fireType:
        return Icons.local_fire_department;
      case emergencyType:
        return Icons.medical_services;
      case rescueType:
        return Icons.support;
      case otherType:
        return Icons.warning;
      default:
        return Icons.help_outline;
    }
  }

  // 색상 매핑
  static Color getEventTypeColor(String eventType) {
    switch (eventType) {
      case fireType:
        return Colors.red;
      case emergencyType:
        return Colors.green;
      case rescueType:
        return Colors.blue;
      case otherType:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // 거리 제한
  static const double maxDistanceKm = 5.0; // 5km
  static const double maxDistanceMeters = 5000.0; // 5000m
}
