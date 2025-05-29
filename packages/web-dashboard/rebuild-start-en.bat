@echo off
chcp 65001 > nul
echo ===============================================
echo   GoodPeople Web Dashboard Rebuild and Start
echo ===============================================
echo.

cd /d "C:\goodpeople-emergency-system\packages\web-dashboard"

echo [1/4] Cleaning old build files...
if exist build rmdir /s /q build
if exist node_modules\.cache rmdir /s /q node_modules\.cache

echo.
echo [2/4] Installing dependencies...
call npm install

echo.
echo [3/4] Building project...
call npm run build

echo.
echo [4/4] Starting development server...
echo.
echo ===============================================
echo   Server starting at http://localhost:3000
echo ===============================================
echo.

set DISABLE_ESLINT_PLUGIN=true
set GENERATE_SOURCEMAP=false
set PORT=3000
npm start
