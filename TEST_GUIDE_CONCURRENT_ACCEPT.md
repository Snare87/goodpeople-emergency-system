# 동시수락 테스트 가이드

## 🚀 테스트 환경 구성

### 1. Realtime Database 데이터 업로드
1. Firebase Console > Realtime Database
2. 데이터 탭에서 ⋮ 메뉴 > "JSON 가져오기"
3. 생성된 `test-firebase-data.json` 파일 업로드

### 2. Authentication 계정 생성

#### 방법 A: 자동 생성 (권장)
```bash
# 1. 서비스 계정 키 다운로드
# Firebase Console > 프로젝트 설정 > 서비스 계정 > "새 비공개 키 생성"
# 다운로드한 파일을 scripts/serviceAccountKey.json으로 저장

# 2. 스크립트 실행
create-test-accounts.bat
```

#### 방법 B: 수동 생성
Firebase Console > Authentication > Users 탭에서 수동으로 추가

### 3. 생성된 테스트 계정
| 이메일 | 비밀번호 | 이름 | UID |
|--------|----------|------|-----|
| test001@korea.kr | test1234 | 박민수 | TestUser001 |
| test002@korea.kr | test1234 | 이정훈 | TestUser002 |
| test003@korea.kr | test1234 | 김서연 | TestUser003 |
| test004@korea.kr | test1234 | 최강호 | TestUser004 |
| test005@korea.kr | test1234 | 윤재영 | TestUser005 |
| test006@korea.kr | test1234 | 송민지 | TestUser006 |
| test007@korea.kr | test1234 | 장현우 | TestUser007 |
| test008@korea.kr | test1234 | 한도현 | TestUser008 |
| test009@korea.kr | test1234 | 정유진 | TestUser009 |
| test010@korea.kr | test1234 | 오성민 | TestUser010 |

## 🧪 동시수락 테스트 방법

### 1. 여러 디바이스 준비
- 실제 디바이스 여러 대 또는
- Android 에뮬레이터 여러 개 실행

### 2. 각 디바이스에서 다른 테스트 계정으로 로그인

### 3. 테스트 시나리오
1. 웹 대시보드에서 재난 "호출하기" 클릭
2. 여러 모바일 앱에서 동시에 "후보자로 등록하기" 클릭
3. 웹 대시보드에서 후보자 목록 확인
4. 최적 대원 "선택" 클릭
5. 선택된 대원과 선택되지 않은 대원들의 화면 변화 확인

## 📍 테스트 유저 위치
모든 테스트 유저는 서울 시내 다양한 위치에 분산되어 있어 거리 기반 선택 테스트가 가능합니다.

## 🛠️ 디버깅 팁
- Firebase Console > Realtime Database에서 실시간 데이터 변화 확인
- Chrome DevTools > Network 탭에서 Firebase 통신 확인
- 모바일 앱 로그에서 FCM 토큰 및 알림 수신 확인
