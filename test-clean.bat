@echo off
REM test-clean.bat - Clean test execution script

echo GoodPeople Emergency System - Running Tests
echo ============================================

REM Navigate to web dashboard
cd packages\web-dashboard

echo.
echo Setting up test environment...
REM Set CI environment
set CI=true

echo.
echo Running all tests...
echo -------------------

REM Run Jest tests quietly
call npm test -- --watchAll=false --verbose=false

echo.
echo -------------------
echo Test execution complete!
echo.
echo Tips:
echo - CallService only: npm test -- callService --watchAll=false
echo - Formatters only: npm test -- formatters --watchAll=false
echo - Verbose output: npm test -- --watchAll=false --verbose

pause
