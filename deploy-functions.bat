@echo off
REM deploy-functions.bat - Firebase Functions 배포 스크립트

echo 🚀 Firebase Functions 배포 준비
echo ==============================

cd packages\mobile-responder\functions

echo.
echo 📋 의존성 설치 중...
call npm install

echo.
echo 🔍 코드 검사 중...
call npm run lint

echo.
echo 🚀 Firebase Functions 배포 중...
echo 다음 함수들이 배포됩니다:
echo - sendCallNotification
echo - updateUserLocation
echo - updateFcmToken
echo - testFcmSend
echo - healthCheck
echo - acceptEmergencyCall (NEW)
echo - completeEmergencyCall (NEW)
echo - cancelEmergencyCall (NEW)
echo.

call firebase deploy --only functions

echo.
echo ✅ 배포 완료!
echo.
echo 💡 배포된 함수 확인:
echo firebase functions:list
echo.
echo 📝 로그 확인:
echo firebase functions:log

pause
