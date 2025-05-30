@echo off
echo ===================================
echo   Firebase Test User Creation
echo ===================================
echo.

echo Moving to scripts directory...
cd scripts

echo Current directory: %cd%
echo.

if not exist "serviceAccountKey.json" (
    echo ERROR: serviceAccountKey.json not found!
    echo Looking in: %cd%
    echo.
    pause
    exit /b 1
)

echo Found serviceAccountKey.json
echo.

if not exist "node_modules" (
    echo Installing dependencies...
    call npm install
)

echo.
echo Dependencies installed.
echo.
echo Running create-test-users.js...
echo.

node create-test-users.js

echo.
echo Script execution completed.
cd ..

pause
