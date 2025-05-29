@echo off
echo ===============================================
echo   굿피플 웹 대시보드 재빌드 및 실행
echo ===============================================
echo.

cd /d "C:\goodpeople-emergency-system\packages\web-dashboard"

echo [1/4] 기존 빌드 파일 삭제 중...
if exist build rmdir /s /q build
if exist node_modules\.cache rmdir /s /q node_modules\.cache

echo.
echo [2/4] 종속성 설치 중...
call npm install

echo.
echo [3/4] 프로젝트 빌드 중...
call npm run build

echo.
echo [4/4] 개발 서버 시작 중...
echo.
echo ===============================================
echo   서버가 시작되면 브라우저에서
echo   http://localhost:3000 으로 접속하세요
echo ===============================================
echo.

set DISABLE_ESLINT_PLUGIN=true
set GENERATE_SOURCEMAP=false
set PORT=3000
npm start
