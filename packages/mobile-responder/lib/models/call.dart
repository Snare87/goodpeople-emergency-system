// lib/models/call.dart
class Call {
  final String id;
  final String eventType;
  final String address;
  final double lat;
  final double lng;
  final String status;
  final int startAt;
  final int? acceptedAt;
  final int? completedAt;
  final Responder? selectedResponder; // 선택된 대원 (신규 시스템)
  final Map<String, Candidate>? candidates; // 후보자 목록 (신규 시스템)
  final double distance;
  final String? info; // 새로 추가

  Call({
    required this.id,
    required this.eventType,
    required this.address,
    required this.lat,
    required this.lng,
    required this.status,
    required this.startAt,
    this.acceptedAt,
    this.completedAt,
    this.selectedResponder,
    this.candidates,
    this.distance = 0.0,
    this.info, // 새로 추가
  });

  factory Call.fromMap(String id, Map<dynamic, dynamic> map) {
    return Call(
      id: id,
      eventType: map['eventType'] ?? '알 수 없음',
      address: map['address'] ?? '주소 없음',
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'unknown',
      startAt: map['startAt'] ?? 0,
      acceptedAt: map['acceptedAt'],
      completedAt: map['completedAt'],
      selectedResponder: map['selectedResponder'] != null 
          ? Responder.fromMap(map['selectedResponder']) 
          : null,
      candidates: map['candidates'] != null
          ? (map['candidates'] as Map).map((key, value) => 
              MapEntry(key.toString(), Candidate.fromMap(value)))
          : null,
      info: map['info'], // 새로 추가
    );
  }

  Call copyWith({
    String? id,
    String? eventType,
    String? address,
    double? lat,
    double? lng,
    String? status,
    int? startAt,
    int? acceptedAt,
    int? completedAt,
    Responder? selectedResponder,
    Map<String, Candidate>? candidates,
    double? distance,
    String? info, // 새로 추가
  }) {
    return Call(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      status: status ?? this.status,
      startAt: startAt ?? this.startAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      selectedResponder: selectedResponder ?? this.selectedResponder,
      candidates: candidates ?? this.candidates,
      distance: distance ?? this.distance,
      info: info ?? this.info, // 새로 추가
    );
  }
}

class Responder {
  final String id;
  final String userId; // 사용자 ID (신규 필드)
  final String name;
  final String? position;
  final String? rank;
  final double? lat;
  final double? lng;
  final int? selectedAt;

  Responder({
    required this.id,
    required this.userId,
    required this.name,
    this.position,
    this.rank,
    this.lat,
    this.lng,
    this.selectedAt,
  });

  factory Responder.fromMap(Map<dynamic, dynamic> map) {
    return Responder(
      id: map['id'] ?? map['userId'] ?? '',
      userId: map['userId'] ?? map['id'] ?? '',
      name: map['name'] ?? '이름 없음',
      position: map['position'],
      rank: map['rank'],
      lat: map['lat'],
      lng: map['lng'],
      selectedAt: map['selectedAt'],
    );
  }
}

// 후보자 모델 (신규)
class Candidate {
  final String id;
  final String userId;
  final String name;
  final String position;
  final String? rank;
  final int acceptedAt;
  final Map<String, dynamic>? routeInfo;

  Candidate({
    required this.id,
    required this.userId,
    required this.name,
    required this.position,
    this.rank,
    required this.acceptedAt,
    this.routeInfo,
  });

  factory Candidate.fromMap(Map<dynamic, dynamic> map) {
    return Candidate(
      id: map['id'] ?? map['userId'] ?? '',
      userId: map['userId'] ?? map['id'] ?? '',
      name: map['name'] ?? '이름 없음',
      position: map['position'] ?? '대원',
      rank: map['rank'],
      acceptedAt: map['acceptedAt'] ?? 0,
      routeInfo: map['routeInfo'] != null 
          ? Map<String, dynamic>.from(map['routeInfo'])
          : null,
    );
  }
}
