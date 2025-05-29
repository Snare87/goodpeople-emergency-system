@echo off
echo 🔐 Firebase API 키 보안 처리
echo ================================
echo.

echo 📱 Firebase 파일들을 Git에서 제거 중...
echo.

REM Firebase 설정 파일들을 Git 캐시에서 제거
git rm --cached packages/mobile-responder/lib/firebase_options.dart 2>nul
git rm --cached packages/mobile-responder/ios/Runner/GoogleService-Info.plist 2>nul
git rm --cached packages/mobile-responder/android/app/google-services.json 2>nul

echo.
echo 📋 현재 상태:
git status --short

echo.
echo ✅ 완료! 다음 단계를 진행하세요:
echo.
echo 1. Firebase Console에서 Security Rules 설정
echo    https://console.firebase.google.com/project/goodpeople-95f54
echo.
echo 2. Google Cloud Console에서 API 키 제한
echo    https://console.cloud.google.com/apis/credentials?project=goodpeople-95f54
echo.
echo 3. 변경사항 커밋:
echo    git add .
echo    git commit -m "보안: Firebase 설정 파일 Git에서 제거 및 보안 강화"
echo.
echo 4. FIREBASE_SECURITY_GUIDE.md 참고하여 추가 보안 설정
echo.
echo ⚠️  중요: 팀원들에게 flutterfire configure 실행 방법 안내!
echo.
pause