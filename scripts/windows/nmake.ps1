# nmake.ps1 —— ② nmake 组·Windows（F-05-02 完整化；Makefile.nmake 10 组合）
# 用法: pwsh -File nmake.ps1 -Variant x64_MD -Cfg Release -Kind shared
# 需 vcvarsall 环境（cl/link/lib/nmake）；clang-cl 组合传 -CC clang-cl。
param(
    [string]$Variant = 'x64_MD',
    [string]$Cfg = 'Release',
    [string]$Kind = 'static',
    [string]$CC = 'cl'
)
$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\..\common.ps1"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$tag = "win_nmake_${Variant}_${Cfg}"
$b = Join-Path $root "build\make\nmake\$tag\$Kind"
New-Item -ItemType Directory -Force -Path $b | Out-Null

$nmake = Get-Command nmake -ErrorAction SilentlyContinue
if (-not $nmake) {
    Write-Note 'nmake not in PATH (vcvars environment required) — full run deferred to CI (F-09-02 windows runner)'
    exit 3
}

Push-Location $b
& nmake /f (Join-Path $root 'Makefile.nmake') "SRCDIR=$root" "OUTDIR=$b" "VARIANT=$Variant" "CFG=$Cfg" "KIND=$Kind" "CC=$CC"
$rc = $LASTEXITCODE
Pop-Location
if ($rc -eq 0) { Write-Pass "nmake build: $tag/$Kind -> $b"; exit 0 }
Write-Fail "nmake build failed: $tag/$Kind (exit=$rc)"
exit $rc
