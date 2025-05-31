@echo off
echo Starting Web Dashboard...
echo.

cd packages\web-dashboard
start cmd /k npm start

echo.
echo Dashboard will open in browser at http://localhost:3000
echo.
echo Login credentials:
echo - Admin: admin@korea.kr
echo - Test users: test001@korea.kr ~ test010@korea.kr
echo.
pause
