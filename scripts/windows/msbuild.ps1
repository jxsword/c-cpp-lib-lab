# msbuild.ps1 —— ② MSBuild 组·Windows（F-04-02 初版；vmath.vcxproj 与 8 组合在 M5/F-05-03 实装）
param([string]$Variant = 'x64_MD', [string]$Cfg = 'Release', [string]$Kind = 'shared')
. "$PSScriptRoot\..\common.ps1"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$proj = Join-Path $root 'vmath.vcxproj'
if (-not (Test-Path $proj)) {
    Write-Note "vmath.vcxproj not present yet — placeholder for M5 (F-05-03)"
    exit 3
}
$msbuild = Get-Command msbuild -ErrorAction SilentlyContinue
if (-not $msbuild) { Write-Note 'msbuild not in PATH (VS environment required)'; exit 3 }
& msbuild $proj "/p:Configuration=$Cfg" "/p:Platform=$(if ($Variant -match 'x64') { 'x64' } else { 'Win32' })" "/p:OutDir=$(Join-Path $root "build\make\msbuild\win_msbuild_${Variant}_${Cfg}\$Kind")"
exit $LASTEXITCODE
