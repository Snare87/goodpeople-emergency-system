# GoodPeople Emergency System

119 재난 대응 통합 시스템 모노레포

## 🚀 특징

- **다중 후보자 시스템**: 여러 대원이 후보자로 등록하고 관리자가 최적의 대원을 선택
- **실시간 위치 추적**: 대원의 실시간 위치와 경로 정보 표시
- **통합 대시보드**: 웹과 모바일 앱 연동

## 프로젝트 구조

- `packages/web-dashboard`: 상황실 웹 대시보드 (React + TypeScript)
- `packages/mobile-responder`: 대원용 모바일 앱 (Flutter + Dart)
- `docs/`: 시스템 문서

## 개발 시작하기

### 전체 의존성 설치
```bash
npm run install:all
```

### 개발 서버 실행

#### 웹 대시보드 실행
```bash
npm run dev:web
# 또는
cd packages/web-dashboard
npm start
```

#### 모바일 앱 실행
```bash
npm run dev:mobile
# 또는
cd packages/mobile-responder
flutter run
```

### 빌드

#### 웹 빌드
```bash
npm run build:web
```

#### 모바일 앱 빌드
```bash
npm run build:mobile
```

## 📦 주요 기능

### 웹 대시보드
- 재난 상황 관리
- 대원 후보자 목록 확인 및 선택
- 실시간 지도 모니터링
- 상황 정보 관리

### 모바일 앱
- 재난 알림 수신
- 후보자로 등록
- 내 임무 확인
- 실시간 위치 공유

## 📚 문서

### 개발 가이드
- [다중 후보자 시스템 마이그레이션 가이드](docs/MULTI_CANDIDATE_SYSTEM_MIGRATION.md)
- [빠른 참조 가이드](docs/MULTI_CANDIDATE_QUICK_REF.md)

### Claude와 함께 작업하기
- [프로젝트 컨텍스트](PROJECT_CONTEXT.md) - 프로젝트의 모든 중요 정보
- [Claude 시작 가이드](CLAUDE_START.md) - 새 세션 시작할 때 사용

### 테스트 가이드
- [테스트 가이드](TEST_GUIDE.md)
- [5분 테스트](5MIN_TEST.md)

### 프로젝트 관리
- [문서 전체 목록](DOCUMENT_INDEX.md) 📁
- [문서 관리 가이드](DOCUMENT_GUIDE.md)

## 프로젝트 정보

- **상황실 웹**: React + TypeScript + Firebase
- **대원 앱**: Flutter + Dart + Firebase
- **공통 백엔드**: Firebase Realtime Database

## 개발 환경

- Node.js (v14+)
- Flutter SDK (3.0+)
- Firebase CLI
- TypeScript

## 📄 라이센스

MIT License