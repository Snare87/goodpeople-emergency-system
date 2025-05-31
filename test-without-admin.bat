@echo off
echo ========================================
echo Test Without Firebase Admin Key
echo ========================================
echo.

cd scripts
node test-without-admin.js

echo.
echo Opening guides...
echo.

cd ..
start QUICK_TEST_GUIDE.md
start 5MIN_TEST.md

pause
