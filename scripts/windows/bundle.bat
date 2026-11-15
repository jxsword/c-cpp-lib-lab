@echo off
rem bundle.bat - thin entry (F-04-02; packaging lands in F-09-07)
setlocal
where pwsh >nul 2>nul
if errorlevel 1 (
  echo [bundle.bat] pwsh not found
  exit /b 1
)
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0bundle.ps1"
exit /b %errorlevel%
