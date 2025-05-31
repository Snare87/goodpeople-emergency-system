# 🚀 Claude와 함께 작업 시작하기 (Quick Start)

> 새로운 Claude 세션을 시작할 때 이 내용을 복사해서 전달하세요!

---

안녕하세요 Claude! GoodPeople Emergency System 프로젝트를 함께 작업하고 있습니다.

## 내 정보
- 개발 초보자입니다 (TypeScript, React, Flutter 경험 부족)
- 자세한 설명과 전체 코드가 필요합니다
- 에러가 발생하면 파일 전체를 보여주세요

## 프로젝트 정보
- **위치**: `C:\goodpeople-emergency-system`
- **구조**: 
  - `packages/web-dashboard` (React + TypeScript)
  - `packages/mobile-responder` (Flutter + Dart)
- **현재 시스템**: 다중 후보자 시스템 (responder → selectedResponder + candidates)

## 주요 파일
- 웹 타입: `packages/web-dashboard/src/services/callService.ts`
- 모바일 모델: `packages/mobile-responder/lib/models/call.dart`
- 컨텍스트 문서: `PROJECT_CONTEXT.md` (전체 정보)

## 현재 데이터 구조
```
calls/
  callId/
    status: "dispatched" | "accepted" | "completed"
    candidates: { userId: {...} }  // 후보자들
    selectedResponder: {...}       // 선택된 대원
```

## 자주 쓰는 명령어
```bash
# 웹 실행
cd packages/web-dashboard && npm start

# 모바일 실행  
cd packages/mobile-responder && flutter run
```

전체 컨텍스트는 `PROJECT_CONTEXT.md` 파일을 확인해주세요!

---

현재 작업하고 싶은 내용을 말씀해주세요.
