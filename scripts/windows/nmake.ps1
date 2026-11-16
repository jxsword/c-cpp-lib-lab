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

# Git usr/bin 的 coreutils link(1) 会遮蔽 VS link.exe——VC bin 前置 PATH（与 native.ps1 同守卫；
# nmake 内部以 PATH 解析 $(LIB)=lib / $(LINK)=link / cl）
$vcarch = if ($Variant.StartsWith('x64')) { 'x64' } else { 'x86' }
if ($env:VCToolsInstallDir) {
    $vcbin = Join-Path $env:VCToolsInstallDir "bin\Hostx64\$vcarch"
    if (Test-Path $vcbin) { $env:PATH = "$vcbin;$env:PATH" }
}

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
