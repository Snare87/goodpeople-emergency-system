# Firebase Console 직접 테스트 가이드

## 1. Firebase 규칙 먼저 업데이트! (중요)

Firebase Console → Realtime Database → 규칙 탭에서:

```json
{
  "rules": {
    "users": {
      ".read": "auth != null",
      "$uid": {
        ".write": "$uid === auth.uid || root.child('users').child(auth.uid).child('roles').child('0').val() === 'admin'"
      }
    },
    "calls": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$callId": {
        "responder": {
          ".write": "auth != null"
        },
        "status": {
          ".write": "auth != null"
        },
        "acceptedAt": {
          ".write": "auth != null"
        },
        "candidates": {
          ".write": "auth != null",
          "$userId": {
            ".write": "$userId === auth.uid || root.child('users').child(auth.uid).child('roles').child('0').val() === 'admin' || root.child('users').child(auth.uid).child('roles').child('0').val() === 'supervisor'"
          }
        },
        "selectedResponder": {
          ".write": "root.child('users').child(auth.uid).child('roles').child('0').val() === 'admin' || root.child('users').child(auth.uid).child('roles').child('0').val() === 'supervisor' || root.child('users').child(auth.uid).child('roles').child('0').val() === 'dispatcher'"
        }
      }
    },
    "notification_logs": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "emergencies": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "responders": {
      "$uid": {
        ".read": "auth != null",
        ".write": "$uid === auth.uid"
      }
    },
    "locations": {
      "$uid": {
        ".read": "auth != null",
        ".write": "$uid === auth.uid"
      }
    },
    "backups": {
      ".read": "root.child('users').child(auth.uid).child('roles').child('0').val() === 'admin'",
      ".write": "root.child('users').child(auth.uid).child('roles').child('0').val() === 'admin'"
    }
  }
}
```

"게시" 클릭!

## 2. 웹 대시보드 테스트

### 2-1. 웹 대시보드 실행
```bash
cd packages\web-dashboard
npm start
```

### 2-2. 로그인
- Email: admin@korea.kr
- Password: (관리자 비밀번호)

### 2-3. 테스트 시나리오

#### A. 호출하기 테스트
1. 대시보드에서 재난 선택 (예: call1)
2. "호출하기" 버튼 클릭
3. Firebase Console에서 확인:
   - `calls/call1/status`가 "dispatched"로 변경됨

#### B. 대원 수락 시뮬레이션 (Firebase Console에서)
1. Firebase Console → Realtime Database
2. `calls/call1/candidates` 노드에 마우스 오버 → + 클릭
3. 이름: TestUser001, 값:
```json
{
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
4. 추가 버튼 클릭

5. 더 많은 후보자 추가 (TestUser002, TestUser003...)

#### C. 대원 선택 테스트
1. 웹 대시보드 새로고침 (F5)
2. 후보자 목록이 표시되는지 확인
3. 원하는 대원의 "선택" 버튼 클릭
4. Firebase Console에서 확인:
   - `selectedResponder` 생성됨
   - `status`가 "accepted"로 변경됨

## 3. 성공 확인 체크리스트

✅ Firebase 규칙이 업데이트됨
✅ "호출하기" 클릭 시 status가 "dispatched"로 변경
✅ candidates 노드에 후보자 추가 가능
✅ 웹 대시보드에서 후보자 목록 표시
✅ "선택" 버튼 클릭 시 selectedResponder 생성
✅ 선택 후 status가 "accepted"로 변경

## 4. 주의사항

- candidates는 객체 형태로 저장 (배열 X)
- userId를 키로 사용
- routeInfo의 duration은 초 단위
- acceptedAt, selectedAt은 타임스탬프 (밀리초)

## 5. 문제 해결

### "선택" 버튼이 작동하지 않는다면:
1. Firebase 규칙이 제대로 업데이트되었는지 확인
2. 브라우저 콘솔(F12)에서 에러 메시지 확인
3. 로그인한 사용자의 권한 확인 (admin, supervisor, dispatcher)

### 후보자가 표시되지 않는다면:
1. Firebase Console에서 candidates 구조 확인
2. 웹 대시보드 새로고침 (F5)
3. status가 "dispatched"인지 확인
