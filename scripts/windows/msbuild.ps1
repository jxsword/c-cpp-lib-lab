# msbuild.ps1 —— ② MSBuild 组·Windows（F-05-03 完整化；vmath.vcxproj + calctool.vcxproj 8 组合）
# 用法: pwsh -File msbuild.ps1 -Variant x64_MD -Cfg Release -Kind shared
# 需 VS 环境（msbuild，vcvarsall 置入 PATH）；8 组合 = 4 配置 × RuntimeLibrary（/MD|/MT 命令行注入）。
# vmath.vcxproj 产库（StaticLibrary→vmath.lib / DynamicLibrary→vmath.dll+导入库）；
# calctool.vcxproj 产 calctool.exe（AppDefine=CALC_USE_DLL|CALC_STATIC，与 vmath 同 OutDir）。
param(
    [string]$Variant = 'x64_MD',
    [string]$Cfg = 'Release',
    [string]$Kind = 'shared'
)
$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\..\common.ps1"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$proj = Join-Path $root 'vmath.vcxproj'
$appProj = Join-Path $root 'calctool.vcxproj'
$msbuild = Get-Command msbuild -ErrorAction SilentlyContinue
if (-not $msbuild) {
    Write-Note 'msbuild not in PATH (VS environment required) — full run deferred to CI (F-09-02 windows runner)'
    exit 3
}
$platform = if ($Variant -match 'x64') { 'x64' } else { 'Win32' }
$rtlBase = if ($Variant -match 'MD') { 'MultiThreadedDLL' } else { 'MultiThreaded' }
# MSBuild 无 CMake CMP0091 式自动 *d：Debug 显式注入 MultiThreadedDebug(DLL)（7.1 /MD<->/MDd 联动）
$rtl = if ($Cfg -eq 'Debug') {
    if ($Variant -match 'MD') { 'MultiThreadedDebugDLL' } else { 'MultiThreadedDebug' }
} else { $rtlBase }
$cfgType = if ($Kind -eq 'shared') { 'DynamicLibrary' } else { 'StaticLibrary' }
$appDefine = if ($Kind -eq 'shared') { 'CALC_USE_DLL' } else { 'CALC_STATIC' }
$outDir = Join-Path $root "build\make\msbuild\win_msbuild_${Variant}_${Cfg}\$Kind"

& msbuild $proj "/p:Configuration=$Cfg" "/p:Platform=$platform" "/p:RuntimeLibrary=$rtl" "/p:ConfigurationType=$cfgType" "/p:OutDir=$outDir\" "/p:IntDir=$outDir\obj\"
$rc = $LASTEXITCODE
if ($rc -eq 0) {
    # 消费端 exe（F-05-03 A1「8 组合 x 双形态全绿」需要 calctool.exe）
    & msbuild $appProj "/p:Configuration=$Cfg" "/p:Platform=$platform" "/p:RuntimeLibrary=$rtl" "/p:AppDefine=$appDefine" "/p:OutDir=$outDir\" "/p:IntDir=$outDir\obj\app\"
    $rc = $LASTEXITCODE
}
if ($rc -eq 0) { Write-Pass "msbuild build: win_msbuild_${Variant}_${Cfg}/$Kind -> $outDir"; exit 0 }
Write-Fail "msbuild build failed (exit=$rc)"
exit $rc
