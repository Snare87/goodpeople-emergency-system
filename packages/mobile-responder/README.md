# GoodPeople Emergency Responder App

119 재난 대응 시스템 - 대원용 모바일 앱 (Flutter)

## 프로젝트 구조 및 아키텍처

### 상태 관리 - Provider 패턴

이 앱은 **Provider 패턴**을 사용하여 중앙집중식 상태 관리를 구현합니다.

```
lib/
├── providers/                    # Provider 클래스들
│   ├── call_provider.dart       # 재난 목록 상태 관리
│   └── active_mission_provider.dart  # 활성 임무 상태 관리
├── screens/                     # UI 화면들
│   ├── home_screen.dart        # 홈 화면 (Provider 연결)
│   ├── active_mission_screen.dart  # 임무 진행 화면 (Provider 연결)
│   └── ...
├── services/                    # 비즈니스 로직 서비스
│   ├── call_data_service.dart  # Firebase 데이터 처리
│   ├── location_service.dart   # 위치 서비스
│   └── ...
└── models/                      # 데이터 모델
    └── call.dart               # 재난 정보 모델
```

### 주요 특징

#### 1. **중앙집중식 상태 관리**
- `setState` 대신 `Provider`와 `ChangeNotifier` 사용
- 상태 변경 시 자동으로 UI 업데이트

#### 2. **실시간 데이터 동기화**
- Firebase Realtime Database 리스너를 Provider에 통합
- 데이터 변경 시 자동으로 모든 구독자에게 전파

#### 3. **코드 재사용성 향상**
- 비즈니스 로직을 Provider로 분리
- UI 컴포넌트는 표시 로직에만 집중

#### 4. **테스트 용이성**
- Provider 단위 테스트 가능
- UI와 비즈니스 로직 분리로 독립적 테스트

#### 5. **성능 최적화**
- `Consumer` 위젯으로 필요한 부분만 리빌드
- 불필요한 전체 화면 리빌드 방지

## Provider 사용 예시

### CallProvider (재난 목록 관리)

```dart
// Provider 초기화
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CallProvider()),
      ],
      child: MaterialApp(...),
    );
  }
}

// 화면에서 사용
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return CircularProgressIndicator();
        }
        return ListView.builder(
          itemCount: provider.filteredCalls.length,
          itemBuilder: (context, index) {
            final call = provider.filteredCalls[index];
            return CallCard(call: call);
          },
        );
      },
    );
  }
}
```

### ActiveMissionProvider (활성 임무 관리)

```dart
// 임무 화면 초기화
class ActiveMissionScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    provider = ActiveMissionProvider();
    provider.initializeMission(widget.callId);
  }
}
```

## 개발 가이드

### 새로운 Provider 추가하기

1. `lib/providers/` 디렉토리에 새 Provider 클래스 생성
2. `ChangeNotifier`를 상속받아 구현
3. `main.dart`의 `MultiProvider`에 추가
4. 필요한 화면에서 `Consumer` 또는 `Provider.of`로 사용

### 테스트 작성하기

```dart
// Provider 단위 테스트 예시
test('필터 변경 테스트', () {
  final provider = CallProvider();
  provider.changeFilter("화재");
  expect(provider.filterType, equals("화재"));
});
```

## 의존성

```yaml
dependencies:
  provider: ^6.1.1  # 상태 관리
  firebase_core: ^2.24.2
  firebase_database: ^10.3.8
  geolocator: ^14.0.0
  google_maps_flutter: ^2.12.2
```

## 빌드 및 실행

```bash
# 의존성 설치
flutter pub get

# 개발 모드 실행
flutter run

# 프로덕션 빌드
flutter build apk --release
```

## 주의사항

- 조건식 처리 로직은 기존 코드 그대로 유지됨
- Provider 내부에서 Firebase 리스너 관리
- dispose 메서드에서 반드시 리스너 정리 필요
