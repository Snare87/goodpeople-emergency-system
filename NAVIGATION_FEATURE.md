# 실시간 경로 안내 및 대원 위치 트래킹 기능

## 🚀 새로운 기능

### 1. 응답자 앱 - 실시간 경로 안내
- **Google Directions API** 기반 재난 지점까지 실시간 네비게이션
- 단계별 길안내 및 예상 도착 시간 표시
- 실시간 교통 정보 반영
- 경로 재계산 자동 수행

### 2. 상황실 웹 - 대원 실시간 위치 트래킹
- **Google Maps**로 통합 (기존 카카오맵에서 변경)
- 활성 임무 수행 중인 대원의 실시간 위치 표시
- 대원 위치에서 재난 지점까지 경로 시각화
- 대원 정보 (이름, 직책, 계급) 표시

## 📋 구현 내용

### 모바일 앱 (Flutter)

#### 새로운 파일
- `lib/services/directions_service.dart`: Google Directions API 서비스

#### 수정된 파일
- `lib/screens/active_mission_screen.dart`: 실시간 경로 안내 UI 추가
- `pubspec.yaml`: http 패키지 추가

#### 주요 기능
1. **실시간 경로 안내**
   - 현재 위치에서 재난 지점까지 최적 경로 계산
   - 폴리라인으로 경로 표시
   - 현재 진행 중인 단계 하이라이트

2. **네비게이션 패널**
   - 현재 단계 안내 (방향, 거리)
   - 다음 단계 미리보기
   - 전체 거리 및 예상 시간 표시

3. **위치 업데이트**
   - 10미터 이동 시마다 위치 업데이트
   - 경로 이탈 시 자동 재계산

### 웹 대시보드 (React)

#### 새로운 파일
- `src/components/GoogleMap.tsx`: Google Maps 컴포넌트

#### 수정된 파일
- `src/components/dashboard/DashboardLayout.tsx`: GoogleMap 사용
- `public/index.html`: Google Maps JavaScript API 추가

#### 주요 기능
1. **대원 실시간 위치 표시**
   - 활성 임무 중인 대원 위치 실시간 업데이트
   - 대원 아이콘 (🚑) 표시
   - 클릭 시 대원 정보 팝업

2. **경로 시각화**
   - 대원 현재 위치에서 재난 지점까지 직선 경로
   - 화살표로 방향 표시

3. **지도 상호작용**
   - 재난 선택 시 자동 줌인
   - 전체 보기 시 모든 재난과 대원 포함

### Firebase Functions

#### 수정된 파일
- `functions/src/handlers/location.js`: 활성 임무 응답자 위치 업데이트 추가

#### 새로운 함수
- `updateActiveCallResponderLocation`: 활성 임무의 응답자 위치 실시간 업데이트
- `getActiveRespondersLocations`: 모든 활성 응답자 위치 조회

## 🔧 설정 방법

### 1. 환경 변수 확인
모바일 앱 `.env` 파일에 Google Maps API 키가 있는지 확인:
```
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

### 2. 의존성 설치
```bash
# 모바일 앱
cd packages/mobile-responder
flutter pub get

# 웹 대시보드
cd packages/web-dashboard
npm install
```

### 3. Google Maps API 활성화
Google Cloud Console에서 다음 API 활성화:
- Maps JavaScript API
- Directions API
- Maps SDK for Android
- Maps SDK for iOS

### 4. API 키 제한
보안을 위해 API 키에 다음 제한 설정:
- 애플리케이션 제한: HTTP 리퍼러 (웹) / Android 앱 (모바일)
- API 제한: 위에서 활성화한 API만 허용

## 🚨 주의사항

1. **데이터 사용량**: 실시간 위치 업데이트로 인한 데이터 사용량 증가
2. **배터리 소모**: GPS 지속 사용으로 배터리 소모 증가
3. **개인정보**: 위치 정보는 24시간 후 자동 삭제

## 🔄 향후 개선사항

1. **오프라인 지원**: 경로 캐싱으로 오프라인에서도 기본 네비게이션
2. **음성 안내**: TTS를 활용한 음성 길안내
3. **복수 경로**: 대체 경로 제시
4. **도착 알림**: 재난 지점 근처 도착 시 자동 알림
5. **경로 히스토리**: 이동 경로 기록 및 분석
