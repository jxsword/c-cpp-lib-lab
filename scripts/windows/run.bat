@echo off
rem run.bat - thin entry: delegate to run.ps1 (RV channel, PLAN 5.7.2 / C18)
setlocal
set "SCRIPT_DIR=%~dp0"
where pwsh >nul 2>nul
if errorlevel 1 (
  echo [run.bat] pwsh not found
  exit /b 1
)
pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%run.ps1" -Tag %1 -Kind %2 -Group %3
exit /b %errorlevel%
