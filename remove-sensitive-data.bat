@echo off
echo 🚨 API 키 제거 스크립트 시작...

REM 민감한 파일들을 Git에서 제거
git rm --cached packages/mobile-responder/.env
git rm --cached packages/web-dashboard/.env
git rm --cached packages/web-dashboard/.env.local
git rm --cached packages/web-dashboard/test-scripts/test-google-maps.html

REM 커밋
git commit -m "보안: 노출된 API 키가 포함된 파일 제거"

echo.
echo ⚠️  주의사항:
echo 1. 노출된 모든 API 키를 즉시 무효화하세요!
echo 2. 새 API 키를 생성하고 제한을 설정하세요.
echo 3. .env.example 파일을 참고하여 새 .env 파일을 생성하세요.
echo.
echo 완료되었습니다. 'git push'로 변경사항을 푸시하세요.
pause