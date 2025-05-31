# 🔄 다중 후보자 시스템 Quick Reference

## 핵심 변경사항
`responder` → `selectedResponder` + `candidates`

## Firebase 구조
```
calls/
  callId/
    candidates/          # 후보자 목록 (객체)
      userId1/
      userId2/
    selectedResponder/   # 선택된 대원 (단일 객체)
```

## 주요 필드 변경

### 웹 (TypeScript)
```typescript
// 제거
responder?: Responder;

// 추가
candidates?: Record<string, Candidate>;
selectedResponder?: SelectedResponder;
```

### 모바일 (Dart)
```dart
// 변경
final Responder? selectedResponder;  // responder → selectedResponder
final Map<String, Candidate>? candidates;  // 신규
```

## "내 임무" 로직
```dart
// 구 시스템
call.responder!.id.contains(userId)

// 신규 시스템
call.selectedResponder!.userId == userId
```

## 프로세스 흐름
1. 웹: "호출하기" → `status: 'dispatched'`
2. 모바일: "수락" → `candidates`에 추가
3. 웹: "선택" → `selectedResponder` 설정, `status: 'accepted'`
4. 모바일: "내 임무"에 표시

## 테스트 명령어
```bash
# 웹
cd packages/web-dashboard
npm start

# 모바일
cd packages/mobile-responder
flutter run
```

## 주의사항
- `candidates`는 객체 (배열 X)
- `userId`를 키로 사용
- Transaction으로 동시성 처리
