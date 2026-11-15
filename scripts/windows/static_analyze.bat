@echo off
rem static_analyze.bat - thin entry: delegate to static_analyze.ps1 (PLAN 5.10)
setlocal
set "SCRIPT_DIR=%~dp0"
where pwsh >nul 2>nul
if errorlevel 1 (
  echo [static_analyze.bat] pwsh not found
  exit /b 1
)
pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%static_analyze.ps1" -Tag %1 -Kind %2 -Group %3
exit /b %errorlevel%
