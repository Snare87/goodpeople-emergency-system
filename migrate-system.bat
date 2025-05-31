@echo off
echo ========================================
echo Multiple Candidates System Migration
echo ========================================
echo.
echo This script migrates the single responder system
echo to multiple candidates system.
echo.
echo WARNING: Please backup your data before proceeding!
echo.
pause

cd scripts\migration
node migrate-to-candidates-system.js

pause
