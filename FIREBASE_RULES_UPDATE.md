# Firebase 규칙 업데이트 가이드

## 1. Firebase Console 접속
1. https://console.firebase.google.com
2. "goodpeople-95f54" 프로젝트 선택

## 2. Realtime Database 규칙 업데이트
1. 왼쪽 메뉴에서 "Realtime Database" 클릭
2. 상단 탭에서 "규칙" 클릭
3. 현재 규칙 전체 선택 (Ctrl+A)
4. 아래 새 규칙으로 교체:

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

5. "게시" 버튼 클릭
6. 경고 창이 나타나면 "게시" 다시 클릭

## 3. 변경사항 확인
새로 추가된 규칙:
- `candidates`: 모든 인증된 사용자가 쓰기 가능
- `candidates/$userId`: 본인 또는 관리자/감독자만 수정 가능
- `selectedResponder`: 관리자/감독자/배정담당자만 쓰기 가능
- `backups`: 관리자만 읽기/쓰기 가능

## 4. 테스트
1. 웹 대시보드에서 로그인
2. 재난 호출 → 모바일에서 수락 → 대원 선택
3. Firebase Console에서 데이터 변경 확인
