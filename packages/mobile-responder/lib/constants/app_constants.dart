class AppConstants {
  // 앱 정보
  static const String appName = 'GoodPeople';
  static const String appTitle = 'GoodPeople 응답자';

  // 타이머 간격
  static const Duration timerInterval = Duration(seconds: 3);
  static const Duration locationUpdateInterval = Duration(seconds: 30);
  static const Duration backgroundLocationInterval = Duration(minutes: 3);

  // 메시지
  static const String loginRequiredMessage = '로그인이 필요합니다.';
  static const String permissionDeniedMessage = '권한이 거부되었습니다.';
  static const String locationPermissionMessage =
      '위치 권한이 필요합니다. 5km 이내 재난만 표시됩니다.';
  static const String notificationPermissionMessage = '알림 권한이 필요합니다.';

  // 오류 메시지
  static const String networkErrorMessage = '네트워크 연결을 확인해주세요.';
  static const String unknownErrorMessage = '알 수 없는 오류가 발생했습니다.';
  static const String initErrorMessage = '앱 초기화 중 오류가 발생했습니다';

  // 기본 위치 (서울시청)
  static const double defaultLat = 37.5665;
  static const double defaultLng = 126.9780;

  // 지도 설정
  static const double defaultMapZoom = 15.0;
  static const double nearZoom = 15.0;
  static const double midZoom = 13.0;
  static const double farZoom = 11.0;
  static const double veryFarZoom = 10.0;
}
