// lib/models 디렉토리에 모델 클래스 추가 구현
// 예: lib/models/user_profile.dart
class UserProfile {
  final String id;
  final String name;
  final String position; // 구조대원, 구급대원, 화재진압대원
  final String department;

  UserProfile({
    required this.id,
    required this.name,
    required this.position,
    required this.department,
  });

  // Firebase에서 데이터 변환 메서드
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      position: map['position'] ?? '',
      department: map['department'] ?? '',
    );
  }

  // Firebase에 저장할 맵 변환 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'department': department,
    };
  }
}
