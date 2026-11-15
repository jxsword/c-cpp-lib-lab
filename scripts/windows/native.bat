@echo off
rem native.bat - thin entry: vcvarsall/msys2 env switch + delegate to native.ps1 (PLAN 5.10)
rem usage: native.bat <toolset> <variant> <cfg> <kind>
rem msvc 需先在 vcvarsall 环境内（或由 CI setup-env 注入）；msys2 直接用绝对路径工具链。
setlocal
set "SCRIPT_DIR=%~dp0"
where pwsh >nul 2>nul
if errorlevel 1 (
  echo [native.bat] pwsh not found
  exit /b 1
)
pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%native.ps1" -Toolset %1 -Variant %2 -Cfg %3 -Kind %4
exit /b %errorlevel%
