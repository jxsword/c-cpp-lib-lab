@echo off
rem msbuild.bat - thin entry (F-04-02; vmath.vcxproj and 8-combo matrix lands in M5/F-05-03)
setlocal
set "SCRIPT_DIR=%~dp0"
where pwsh >nul 2>nul
if errorlevel 1 (
  echo [msbuild.bat] pwsh not found
  exit /b 1
)
pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%msbuild.ps1" %1 %2 %3
exit /b %errorlevel%
