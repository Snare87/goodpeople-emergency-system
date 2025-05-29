@echo off
REM run-tests.bat - Windows용 테스트 실행 스크립트

echo 🧪 GoodPeople Emergency System - 테스트 실행
echo ============================================

REM 웹 대시보드 디렉토리로 이동
cd packages\web-dashboard

echo.
echo 📋 테스트 환경 설정 중...
REM 환경 변수 설정 (CI 환경)
set CI=true

echo.
echo 🚀 테스트 실행 중...
echo -------------------

REM Jest 테스트 실행 (--watchAll=false로 watch 모드 비활성화)
call npm test -- --watchAll=false --verbose

REM 테스트 결과 저장
set TEST_RESULT=%ERRORLEVEL%

echo.
echo -------------------

if %TEST_RESULT%==0 (
    echo ✅ 모든 테스트가 성공했습니다!
) else (
    echo ❌ 일부 테스트가 실패했습니다.
)

echo.
echo 💡 팁:
echo - 특정 테스트만 실행: npm test CallService
echo - 커버리지 확인: npm test -- --coverage
echo - Watch 모드: npm test (CI=false)

exit /b %TEST_RESULT%
