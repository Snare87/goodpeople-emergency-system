@echo off
echo 🔐 API 키 보안 처리 Quick Fix
echo ================================
echo.

echo 1️⃣ Git에서 민감한 파일 제거 중...
git rm --cached packages/mobile-responder/.env 2>nul
git rm --cached packages/web-dashboard/.env 2>nul
git rm --cached packages/web-dashboard/.env.local 2>nul
git rm --cached packages/web-dashboard/test-scripts/test-google-maps.html 2>nul

echo.
echo 2️⃣ 안전한 파일로 교체 중...
if exist "packages\web-dashboard\test-scripts\test-google-maps.html" (
    move "packages\web-dashboard\test-scripts\test-google-maps.html" "packages\web-dashboard\test-scripts\test-google-maps.html.EXPOSED"
)
copy "packages\web-dashboard\test-scripts\test-google-maps-safe.html" "packages\web-dashboard\test-scripts\test-google-maps.html" 2>nul

echo.
echo 3️⃣ Git 커밋 준비...
git add .gitignore
git add packages/mobile-responder/.env.example
git add packages/web-dashboard/.env.example
git add API_KEY_SECURITY_GUIDE.md
git add packages/web-dashboard/test-scripts/test-google-maps.html

echo.
echo 📋 상태 확인:
git status --short

echo.
echo ⚠️  다음 단계:
echo.
echo 1. 노출된 API 키를 즉시 무효화하세요!
echo    - Google Cloud Console
echo    - Firebase Console
echo    - Kakao Developers
echo    - T Map
echo.
echo 2. 새 API 키를 생성하고 제한을 설정하세요
echo.
echo 3. 다음 명령어로 커밋하세요:
echo    git commit -m "보안: API 키 노출 문제 해결 및 보안 강화"
echo.
echo 4. 팀원들에게 새 API 키를 안전하게 전달하세요
echo.
pause