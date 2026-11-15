@echo off
rem cmake.bat - thin entry (F-04-02; three-OS CMake closes in M6/F-06-01)
setlocal
set "SCRIPT_DIR=%~dp0"
where pwsh >nul 2>nul
if errorlevel 1 (
  echo [cmake.bat] pwsh not found
  exit /b 1
)
pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%cmake.ps1" %1 %2 %3 %4
exit /b %errorlevel%
