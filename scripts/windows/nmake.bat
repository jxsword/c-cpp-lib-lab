@echo off
rem nmake.bat - thin entry (F-04-02; full Makefile.nmake matrix lands in M5/F-05-02)
setlocal
set "SCRIPT_DIR=%~dp0"
where pwsh >nul 2>nul
if errorlevel 1 (
  echo [nmake.bat] pwsh not found
  exit /b 1
)
pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%nmake.ps1" %1 %2 %3
exit /b %errorlevel%
