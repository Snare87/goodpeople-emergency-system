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
  final Responder? responder;
  final double distance;

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
    this.responder,
    this.distance = 0.0,
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
      responder:
          map['responder'] != null ? Responder.fromMap(map['responder']) : null,
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
    Responder? responder,
    double? distance,
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
      responder: responder ?? this.responder,
      distance: distance ?? this.distance,
    );
  }
}

class Responder {
  final String id;
  final String name;
  final String? position;
  final double? lat;
  final double? lng;

  Responder({
    required this.id,
    required this.name,
    this.position,
    this.lat,
    this.lng,
  });

  factory Responder.fromMap(Map<dynamic, dynamic> map) {
    return Responder(
      id: map['id'] ?? '',
      name: map['name'] ?? '이름 없음',
      position: map['position'],
      lat: map['lat'],
      lng: map['lng'],
    );
  }
}
