# 🔒 Firebase 보안 가이드

## API 키 노출 대응 방안

GitGuardian에서 5개의 API 키 노출을 감지했습니다. Firebase API 키는 공개되어도 보안 규칙으로 보호되지만, 추가 보안 조치가 필요합니다.

### 📍 노출된 파일 현황

1. ✅ `test-google-maps.html` - 처리 완료
2. 🔥 `GoogleService-Info.plist` - iOS Firebase 설정
3. 🔥 `firebase_options.dart` - Flutter Firebase 설정
4. ❓ `upload-data.js` - 파일 없음 (이미 처리?)

### 1. Firebase Console에서 설정할 보안 규칙

#### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 인증된 대원만 접근 가능
    match /responders/{responderId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == responderId;
    }
    
    // 재난 정보는 인증된 사용자만
    match /emergencies/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.token.role == 'dispatcher';
    }
  }
}
```

#### Realtime Database Rules
```json
{
  "rules": {
    "locations": {
      "$uid": {
        ".read": "auth != null",
        ".write": "$uid === auth.uid"
      }
    },
    "emergencies": {
      ".read": "auth != null",
      ".write": "auth != null && auth.token.role === 'dispatcher'"
    }
  }
}
```

#### Storage Security Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /incident-photos/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.resource.size < 10 * 1024 * 1024; // 10MB 제한
    }
  }
}
```

### 2. API 키 제한 설정 (Google Cloud Console)

1. [Google Cloud Console](https://console.cloud.google.com) 접속
2. APIs & Services → Credentials
3. 각 API 키에 대해:

#### Android 앱 API 키
- **Application restrictions**: Android apps
- **Package name**: `com.example.goodpeople_responder`
- **SHA-1 certificate fingerprint**: (디버그 및 릴리즈 키 추가)

#### iOS 앱 API 키  
- **Application restrictions**: iOS apps
- **Bundle ID**: `com.example.goodpeople-responder`

#### 웹 API 키
- **Application restrictions**: HTTP referrers
- **Website restrictions**:
  - `https://goodpeople-95f54.web.app/*`
  - `https://goodpeople-95f54.firebaseapp.com/*`
  - `http://localhost:3000/*` (개발용)

### 3. 도메인 인증 설정 (Firebase Console)

1. Authentication → Settings → Authorized domains
2. 허용할 도메인만 추가:
   - `localhost` (개발용)
   - `goodpeople-95f54.web.app`
   - `goodpeople-95f54.firebaseapp.com`

### 4. 앱 체크 (App Check) 활성화

```javascript
// Flutter에서 App Check 초기화
import 'package:firebase_app_check/firebase_app_check.dart';

await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.appAttest,
);
```

### 5. 모니터링 및 알림 설정

- **Usage and billing**에서 일일 한도 설정
- **Budget alerts** 설정 (예: $10 초과 시 알림)
- **Firestore 읽기/쓰기** 모니터링

## 📱 개발 환경 설정 가이드

### 새로운 팀원을 위한 설정

```bash
# 1. 저장소 클론
git clone https://github.com/Snare87/goodpeople-emergency-system.git
cd goodpeople-emergency-system

# 2. 의존성 설치
npm install

# 3. Firebase CLI 설치
npm install -g firebase-tools

# 4. FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# 5. Firebase 로그인
firebase login

# 6. Flutter 프로젝트 설정
cd packages/mobile-responder
flutterfire configure

# 7. 환경변수 설정
cp .env.example .env
# .env 파일 편집하여 API 키 입력
```

### iOS 추가 설정
```bash
# GoogleService-Info.plist를 다운로드하여 ios/Runner에 복사
# Xcode에서 프로젝트에 추가 (Add Files to "Runner")
```

### Android 추가 설정
```bash
# google-services.json을 다운로드하여 android/app에 복사
```

## ⚠️ 주의사항

1. **절대 커밋하지 말아야 할 파일들**:
   - `.env`, `.env.local`
   - `GoogleService-Info.plist`
   - `google-services.json`
   - `firebase_options.dart` (선택적)

2. **API 키가 노출되었을 때**:
   - 즉시 Google Cloud Console에서 제한 설정
   - Firebase Security Rules 검토 및 강화
   - 비정상적인 사용 패턴 모니터링

3. **보안 모범 사례**:
   - 최소 권한 원칙 적용
   - 정기적인 보안 규칙 검토
   - 사용자 인증 강화 (2FA 등)

## 🚨 즉시 조치 사항

1. **Firebase Console** 접속하여 Security Rules 업데이트
2. **Google Cloud Console**에서 모든 API 키에 제한 설정
3. **App Check** 활성화
4. **예산 알림** 설정
5. 팀원들에게 새로운 설정 방법 공유

---

마지막 업데이트: 2025-05-30
담당자: 보안팀