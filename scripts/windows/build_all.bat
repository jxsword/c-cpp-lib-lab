@echo off
rem build_all.bat - thin entry: delegate to build_all.ps1 (PLAN 5.10)
setlocal
set "SCRIPT_DIR=%~dp0"
where pwsh >nul 2>nul
if errorlevel 1 (
  echo [build_all.bat] pwsh not found
  exit /b 1
)
pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%build_all.ps1" %1
exit /b %errorlevel%
