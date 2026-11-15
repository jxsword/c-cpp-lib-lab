# msbuild.ps1 —— ② MSBuild 组·Windows（F-05-03 完整化；vmath.vcxproj 8 组合）
# 用法: pwsh -File msbuild.ps1 -Variant x64_MD -Cfg Release -Kind shared
# 需 VS 环境（msbuild）；8 组合 = 4 配置 × RuntimeLibrary（/MD|/MT 命令行注入），
# ConfigurationType 由 Kind 映射（shared→DynamicLibrary、static→StaticLibrary）。
param(
    [string]$Variant = 'x64_MD',
    [string]$Cfg = 'Release',
    [string]$Kind = 'shared'
)
$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\..\common.ps1"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$proj = Join-Path $root 'vmath.vcxproj'
$msbuild = Get-Command msbuild -ErrorAction SilentlyContinue
if (-not $msbuild) {
    Write-Note 'msbuild not in PATH (VS environment required) — full run deferred to CI (F-09-02 windows runner)'
    exit 3
}
$platform = if ($Variant -match 'x64') { 'x64' } else { 'Win32' }
$rtl = if ($Variant -match 'MD') { 'MultiThreadedDLL' } else { 'MultiThreaded' }
$cfgType = if ($Kind -eq 'shared') { 'DynamicLibrary' } else { 'StaticLibrary' }
$outDir = Join-Path $root "build\make\msbuild\win_msbuild_${Variant}_${Cfg}\$Kind"
$intDir = Join-Path $outDir 'obj\'

& msbuild $proj "/p:Configuration=$Cfg" "/p:Platform=$platform" "/p:RuntimeLibrary=$rtl" "/p:ConfigurationType=$cfgType" "/p:OutDir=$outDir\" "/p:IntDir=$intDir"
$rc = $LASTEXITCODE
if ($rc -eq 0) { Write-Pass "msbuild build: win_msbuild_${Variant}_${Cfg}/$Kind -> $outDir"; exit 0 }
Write-Fail "msbuild build failed (exit=$rc)"
exit $rc
