# 🚀 5분 안에 테스트하기!

## 1️⃣ Firebase 규칙 업데이트 (1분)
1. [Firebase Console](https://console.firebase.google.com) → Realtime Database → 규칙
2. `firebase-rules-updated.json` 내용 복사/붙여넣기
3. "게시" 클릭

## 2️⃣ 웹 대시보드 실행 (1분)
```bash
cd C:\goodpeople-emergency-system\packages\web-dashboard
npm start
```

## 3️⃣ 테스트 (3분)

### A. 호출하기
1. 웹 대시보드 로그인 (admin@korea.kr)
2. 재난 선택 → "호출하기" 클릭
3. Firebase Console에서 status "dispatched" 확인

### B. 후보자 추가 (Firebase Console)
`calls/[재난ID]/candidates/TestUser001` 추가:
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
    "durationText": "7분"
  }
}
```

### C. 대원 선택
1. 웹 대시보드 새로고침 (F5)
2. 후보자 목록에서 "선택" 클릭
3. 성공! 🎉

## ❌ 안 될 때
- Firebase 규칙 확인
- 브라우저 콘솔 확인 (F12)
- 로그인 사용자 권한 확인

## 📱 모바일 앱 테스트
모바일 앱에서 실제로 수락하면 자동으로 candidates에 추가됩니다!
