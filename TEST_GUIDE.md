# 🚀 다중 후보자 시스템 테스트 가이드

## 현재 상태 ✅
- callService.ts에 selectResponder, deselectResponder 함수 구현 완료
- 모든 컴포넌트가 새로운 시스템 사용하도록 업데이트됨
- Firebase 규칙은 이미 업데이트되었다고 가정

## 테스트 순서

### 1. 웹 대시보드 재시작
```bash
cd C:\goodpeople-emergency-system\packages\web-dashboard
npm start
```

### 2. 브라우저에서 확인
- http://localhost:3000 접속
- admin@korea.kr로 로그인

### 3. 테스트 시나리오

#### A. 호출하기
1. 재난 선택
2. "호출하기" 버튼 클릭
3. Firebase Console에서 확인:
   - `status` → `dispatched`
   - `dispatchedAt` 생성됨

#### B. 후보자 추가 (Firebase Console)
1. Firebase Console → Realtime Database
2. `calls/[재난ID]/candidates/TestUser001` 추가:
```json
{
  "id": "TestUser001",
  "userId": "TestUser001",
  "name": "박민수",
  "position": "화재진압대원",
  "rank": "소방사",
  "acceptedAt": 1748700000000,
  "routeInfo": {
    "distance": 2300,
    "distanceText": "2.3km",
    "duration": 420,
    "durationText": "7분",
    "calculatedAt": 1748700000000
  }
}
```

#### C. 대원 선택
1. 웹 대시보드 새로고침 (F5)
2. 후보자 목록 확인
3. "선택" 버튼 클릭
4. Firebase Console에서 확인:
   - `selectedResponder` 생성됨
   - `status` → `accepted`
   - `acceptedAt` 생성됨

### 4. 모바일 앱 테스트

#### "내 임무" 표시 확인
모바일 앱에서 확인할 사항:
- `selectedResponder.userId === 현재로그인사용자ID`인 호출만 표시
- 구 시스템: `call.responder.id`
- 신 시스템: `call.selectedResponder.userId`

## 🔍 디버깅

### 콘솔 로그 확인 (F12)
- `[selectResponder] 시작`
- `[selectResponder] 선택 성공`

### Firebase Console에서 데이터 구조 확인
```
calls/
  call1/
    status: "accepted"
    candidates/
      TestUser001/
        userId: "TestUser001"
        name: "박민수"
        ...
    selectedResponder/
      userId: "TestUser001"
      name: "박민수"
      selectedAt: 1748700100000
      ...
```

## ⚠️ 주의사항
1. candidates는 객체 형태 (배열 X)
2. userId를 키로 사용
3. selectedResponder는 단일 객체
4. 호출취소 시 candidates도 삭제됨

## 문제 해결
- "선택" 버튼 안 눌림 → Firebase 규칙 확인
- 후보자 안 보임 → 새로고침 (F5)
- 타입 에러 → npm start 재실행
