# GoodPeople Emergency System

119 재난 대응 통합 시스템 모노레포

## 프로젝트 구조

- `packages/web-dashboard`: 상황실 웹 대시보드 (React)
- `packages/mobile-responder`: 대원용 모바일 앱 (Flutter)

## 개발 시작하기

### 전체 의존성 설치
```bash
npm run install:all
개발 서버 실행
웹 대시보드 실행
bashnpm run dev:web
모바일 앱 실행
bashnpm run dev:mobile
빌드
웹 빌드
bashnpm run build:web
모바일 앱 빌드
bashnpm run build:mobile
프로젝트 정보

상황실 웹: React + Firebase
대원 앱: Flutter + Firebase
공통 백엔드: Firebase Realtime Database

개발 환경

Node.js
Flutter SDK
Firebase CLI