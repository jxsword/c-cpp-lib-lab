@echo off
rem env.bat - thin entry: delegates to env.ps1 (PLAN 5.10 windows bat+ps1分工)
where pwsh >nul 2>nul
if errorlevel 1 (
  echo [env.bat] pwsh not found; run env.ps1 manually
  exit /b 1
)
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0env.ps1"
exit /b %errorlevel%
