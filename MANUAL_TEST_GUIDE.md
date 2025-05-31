# 수동 테스트 가이드

## Firebase Console에서 직접 테스트

### 1. 테스트 재난 만들기
Firebase Console → Realtime Database에서:

1. `calls` 노드 찾기
2. 하위에 새 노드 추가: `test_manual_1`
3. 다음 데이터 입력:
```json
{
  "address": "서울 강남구 테스트로 123",
  "eventType": "화재",
  "info": "테스트 화재",
  "lat": 37.5013,
  "lng": 127.0396,
  "startAt": 1748665200000,
  "status": "idle"
}
```

### 2. 호출하기 테스트
웹 대시보드에서:
1. 로그인
2. "호출하기" 버튼 클릭
3. Firebase Console에서 `status`가 `dispatched`로 변경 확인

### 3. 모바일 앱에서 수락
모바일 앱에서:
1. 여러 계정으로 로그인
2. 재난 알림 수락
3. Firebase Console에서 `candidates` 노드 확인

### 4. 대원 선택
웹 대시보드에서:
1. 후보자 목록 확인
2. 원하는 대원 "선택" 클릭
3. Firebase Console에서 확인:
   - `selectedResponder` 생성
   - `status`가 `accepted`로 변경

### 5. 데이터 구조 확인
최종 데이터 구조:
```json
{
  "test_manual_1": {
    "address": "서울 강남구 테스트로 123",
    "eventType": "화재",
    "status": "accepted",
    "candidates": {
      "TestUser001": {
        "userId": "TestUser001",
        "name": "박민수",
        "position": "화재진압대원",
        "acceptedAt": 1748665300000,
        "routeInfo": {
          "distance": 2300,
          "distanceText": "2.3km",
          "duration": 420,
          "durationText": "7분"
        }
      }
    },
    "selectedResponder": {
      "userId": "TestUser001",
      "name": "박민수",
      "selectedAt": 1748665400000
    }
  }
}
```
