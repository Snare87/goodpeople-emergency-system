# T Map API 보안 가이드

## 🔒 보안 설정

### 1. T Map 대시보드 설정
1. [T Map API 콘솔](https://tmapapi.sktelecom.com/) 접속
2. 앱 관리 > App Key 탭으로 이동
3. **IPS(IP Security) 설정**:
   - 개발 환경: 개발자 IP 추가
   - 프로덕션: 서버 IP 추가 (필요시)

### 2. 사용량 모니터링
- 대시보드에서 일일 사용량 확인
- 비정상적인 사용 패턴 감지
- 정액제 한도 설정 확인

### 3. 앱 배포 시 주의사항
```dart
// ❌ 하지 말아야 할 것
static const String _tmapApiKey = 'YOUR_API_KEY'; // 하드코딩

// ✅ 권장 방법
static final String _tmapApiKey = dotenv.env['TMAP_API_KEY'] ?? '';
```

### 4. 추가 보안 옵션
1. **Firebase Remote Config 사용** (고급):
   ```dart
   final remoteConfig = FirebaseRemoteConfig.instance;
   final tmapKey = remoteConfig.getString('tmap_api_key');
   ```

2. **네이티브 플랫폼 보안**:
   - Android: `gradle.properties`
   - iOS: `Info.plist` 또는 환경 변수

### 5. 사용량 제한
- T Map 정액제 사용 (자동 차단 기능)
- 앱 내 요청 제한 구현:
  ```dart
  // 예: 분당 요청 제한
  static int _requestCount = 0;
  static DateTime _lastReset = DateTime.now();
  
  static bool _canMakeRequest() {
    final now = DateTime.now();
    if (now.difference(_lastReset).inMinutes >= 1) {
      _requestCount = 0;
      _lastReset = now;
    }
    return _requestCount++ < 30; // 분당 30회 제한
  }
  ```

## ⚠️ 현재 상태
- API 키가 `.env` 파일에 저장됨
- Flutter 앱에서 HTTP 요청으로 사용 (스크립트 문제 없음)
- 정액제 사용 시 자동 차단 기능 활성화

## 📱 모바일 앱 특성
- 웹과 달리 API 키가 앱 내부에 포함됨
- 리버스 엔지니어링 가능성 있음
- **중요**: 민감한 작업은 서버 측에서 처리 권장
