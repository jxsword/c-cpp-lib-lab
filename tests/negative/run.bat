@echo off
rem run.bat - negative-case runner for Windows (F-08-04: MSVC-specific reproduction)
rem usage: run.bat stage3_stl_across_crt  (expects vcvarsall environment)
setlocal
set "SCRIPT_DIR=%~dp0"
if /I not "%1"=="stage3_stl_across_crt" (
  echo SKIP: unknown negative case %1
  exit /b 0
)
where cl >nul 2>nul
if errorlevel 1 (
  echo SKIP: MSVC-specific negative case; cl not in PATH
  exit /b 0
)
echo [run.bat] MSVC reproduction goes here (runner-only): build dllexport sample with /MD, consume with /MT, observe CRT mismatch
exit /b 0
