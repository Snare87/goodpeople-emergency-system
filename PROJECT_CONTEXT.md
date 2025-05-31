# 🧭 프로젝트 컨텍스트 (Claude와 함께 작업하기)

> 이 문서는 새로운 Claude 세션에서 프로젝트를 이어서 작업할 때 필요한 모든 정보를 담고 있습니다.

## 👋 나에 대해
- **개발 경험**: 초보자 (TypeScript, React, Flutter 경험 부족)
- **선호 방식**: 
  - 자세한 설명과 함께 코드 제공 필요
  - 에러 발생 시 전체 파일 내용 확인 선호
  - 테스트 가이드 필요
- **주의사항**: 
  - 타입 관련 에러가 자주 발생함
  - Git 사용법 가이드 필요할 수 있음

## 🏗️ 프로젝트 구조

### 전체 구조
```
C:\goodpeople-emergency-system\
├── packages/
│   ├── web-dashboard/        # React + TypeScript 웹 대시보드
│   └── mobile-responder/     # Flutter + Dart 모바일 앱
├── docs/                     # 문서
├── scripts/                  # 유틸리티 스크립트
└── [설정 파일들]
```

### 주요 파일 위치
- **웹 타입 정의**: `packages/web-dashboard/src/services/callService.ts`
- **웹 컴포넌트**: `packages/web-dashboard/src/components/`
- **모바일 모델**: `packages/mobile-responder/lib/models/call.dart`
- **모바일 서비스**: `packages/mobile-responder/lib/services/`
- **AI 점수 서비스**: `packages/web-dashboard/src/services/aiScoringService.ts`
- **자동 선택 서비스**: `packages/web-dashboard/src/services/autoSelectService.ts`
- **향상된 후보자 패널**: `packages/web-dashboard/src/components/call-detail/EnhancedCandidatesPanel.tsx`

## 💾 데이터베이스 구조 (Firebase Realtime Database)

### 현재 구조 (다중 후보자 시스템)
```json
{
  "calls": {
    "callId": {
      "id": "string",
      "eventType": "화재" | "구조" | "구급" | "기타",
      "address": "string",
      "lat": "number",
      "lng": "number",
      "status": "idle" | "dispatched" | "accepted" | "completed",
      "startAt": "timestamp",
      "dispatchedAt": "timestamp (optional)",
      "acceptedAt": "timestamp (optional)",
      "completedAt": "timestamp (optional)",
      "info": "string (optional)",
      
      // 다중 후보자 시스템 필드
      "candidates": {
        "userId1": {
          "id": "string",
          "userId": "string",
          "name": "string",
          "position": "string",
          "rank": "string (optional)",
          "acceptedAt": "timestamp",
          "routeInfo": {
            "distance": "number",
            "distanceText": "string",
            "duration": "number",
            "durationText": "string"
          }
        },
        "userId2": { ... }
      },
      
      "selectedResponder": {
        "id": "string",
        "userId": "string",
        "name": "string",
        "position": "string",
        "rank": "string (optional)",
        "acceptedAt": "timestamp",
        "selectedAt": "timestamp",
        "routeInfo": { ... }
      }
    }
  },
  
  "users": {
    "userId": {
      "name": "string",
      "email": "string",
      "position": "string",
      "rank": "string",
      "certifications": ["array of strings"],
      "createdAt": "timestamp"
    }
  }
}
```

### 상태 플로우
1. `idle` → `dispatched` (웹에서 "호출하기")
2. `dispatched` → 대원들이 수락하여 `candidates`에 추가
3. 관리자가 선택 → `selectedResponder` 설정, `status: accepted`
4. `accepted` → `completed` (임무 완료)

## 🔑 핵심 변경사항 (2025년 1월 31일)

### responder → selectedResponder + candidates
- **구 시스템**: 단일 `responder` 필드
- **신규 시스템**: `candidates` (후보자 목록) + `selectedResponder` (선택된 대원)

### "내 임무" 로직
```dart
// 구 시스템
call.responder!.id.contains(userId)

// 신규 시스템
call.selectedResponder!.userId == userId
```

## 🤖 AI 대원 선택 시스템 (2025년 2월 1일)

### 재난 종류별 자격증 가중치
- **화재**: 화재대응능력 > 인명구조사 > 기타
- **구조**: 인명구조사 > 화재대응/의료
- **구급**: 간호사/응급구조사 > 기타

### AI 점수 구성 요소
1. **도착 예정 시간** (ETA): 가장 중요한 요소
2. **거리**: 보조 지표
3. **자격증**: 재난 종류별 가중치 적용
4. **계급**: 경험 반영
5. **응답 시간**: 빠른 응답에 가점 (NEW!)

### 자격증 중복 처리
- **상하위 관계**: 1급 보유 시 2급 점수 미반영
- **동등 관계**: 간호사 ≈ 응급구조사 1급 (둘 중 하나만)

### AI 점수 표시
- **경로 정보 있음**: 숫자로 표시 (ex: 275점)
- **경로 정보 없음**: "경로정보 없음" 표시
- **최적 대원**: 상위 1명만 표시 (테스트용)

### 후보자 수락 취소 (NEW!)
- 모바일에서 후보자가 수락 취소 가능
- 취소 시 Firebase에서 후보자 목록에서 제거
- AI 자동 선택에서도 제외됨

## 🛠️ 자주 사용하는 명령어

### 개발 서버 실행
```bash
# 웹 대시보드
cd packages/web-dashboard
npm start

# 모바일 앱
cd packages/mobile-responder
flutter run
```

### 에러 발생 시
```bash
# TypeScript 에러
npm start  # 에러 메시지 확인

# Flutter 에러
flutter clean
flutter pub get
flutter run
```

### Firebase 데이터 확인
1. https://console.firebase.google.com
2. Realtime Database 선택
3. 데이터 구조 확인

## 🐛 자주 발생하는 문제와 해결법

### 1. TypeScript 타입 에러
- **문제**: `Property 'xxx' does not exist on type 'Call'`
- **해결**: `callService.ts`의 Call 인터페이스 확인 및 수정

### 2. Flutter 빌드 에러
- **문제**: `The getter 'xxx' isn't defined`
- **해결**: `call.dart` 모델 파일 확인 및 수정

### 3. Firebase 권한 에러
- **문제**: `Permission denied`
- **해결**: Firebase Rules 확인 (보통 인증 문제)

### 4. AI 점수 문제 (2025.02.01 해결)
- **문제**: 경로 정보가 없는 후보자의 AI 점수가 비정상적으로 높게 표시
- **해결**: 
  - routeInfo 없을 때 기본값: ETA 99999초, 거리 99.999km
  - AI 점수 50000 이상시 "경로정보 없음"으로 표시
  - 추천 이유에서 도착시간은 routeInfo가 있을 때만 표시

## 📝 작업 로그

### 2025년 1월 31일
- ✅ 다중 후보자 시스템 구현
- ✅ responder → selectedResponder 마이그레이션
- ✅ 모바일 "내 임무" 로직 수정
- ✅ 문서화 완료

### 2025년 2월 1일
- ✅ AI 점수 기반 대원 선택 시스템 구현
- ✅ 자동 선택 기능 (60초 카운트다운)
- ✅ 후보자 목록 UI 개선 (최적 배지, AI 점수 표시)
- ✅ 지도 연동 기능 (후보자 클릭 시 위치 이동)
- ✅ Tmap API 연동 (모바일 앱에서 경로 계산)
- ✅ 재난 종류별 자격증 가중치 시스템
- ✅ 자격증 상하위 관계 및 중복 처리
- ✅ 경로 정보 없는 후보자 AI 점수 표시 개선
- ✅ 최적 대원 표시 상위 1명으로 제한 (테스트용)
- ✅ 후보자 목록이 해당 재난에만 표시되도록 수정 (React key prop 추가)
- ✅ 호출 취소/재호출 시 후보자 목록 유지
- ✅ 후보자 수락 취소 기능 추가 (모바일)
- ✅ AI 점수에 응답 시간 가점 추가 (30초 이내 응답 시 '빠른 응답' 표시)
- ✅ 자동선택 시 경로정보 없는 후보자 제외
- ✅ 경로정보 없는 후보자 AI 점수 표시 문제 해결

### 향후 작업 예정
- [ ] Firebase Rules 최적화
- [ ] 푸시 알림 시스템
- [ ] 통계 대시보드
- [ ] 대원 실시간 위치 추적
- [ ] 사후 보고서 기능

## 💡 프로젝트 관련 팁

### Claude에게 요청할 때
1. **파일 전체 보기**: "~파일 전체 내용 보여줘"
2. **에러 해결**: 에러 메시지 전체를 복사해서 전달
3. **기능 추가**: 현재 구조 설명하고 원하는 기능 설명

### 테스트할 때
1. 웹에서 먼저 데이터 생성
2. Firebase Console에서 데이터 확인
3. 모바일에서 동작 확인

### AI 시스템 테스트 팁
1. **최적 대원 표시**: 현재 테스트용으로 1명만 표시 (실제 사용시 3명으로 변경 가능)
2. **경로 정보 없는 후보자**: AI 점수가 50000 이상이면 "경로정보 없음"으로 표시
3. **자격증 중복**: 상하위 관계와 동등 관계 자동 처리

## 🔗 관련 문서
- [다중 후보자 시스템 가이드](docs/MULTI_CANDIDATE_SYSTEM_MIGRATION.md)
- [빠른 참조](docs/MULTI_CANDIDATE_QUICK_REF.md)
- [5분 테스트 가이드](5MIN_TEST.md)
- [문서 전체 목록](DOCUMENT_INDEX.md) ⭐
- [문서 관리 가이드](DOCUMENT_GUIDE.md)

## 🚨 중요 주의사항

1. **타입 동기화**: TypeScript(웹)와 Dart(모바일) 타입을 항상 동일하게 유지
2. **Firebase 실시간**: 데이터 변경은 즉시 모든 클라이언트에 반영됨
3. **Transaction 사용**: 동시성 문제 방지를 위해 중요한 업데이트는 Transaction 사용

## 📞 연락처 및 참고
- Firebase Console: https://console.firebase.google.com
- 프로젝트 경로: `C:\goodpeople-emergency-system`

---

**마지막 업데이트**: 2025년 2월 1일 (오후 - 후보자 취소 및 AI 점수 개선)
