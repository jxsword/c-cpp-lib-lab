# nmake.ps1 —— ② nmake 组·Windows（F-04-02 初版；Makefile.nmake 与 10 组合矩阵在 M5/F-05-02 实装）
param([string]$Variant = 'x64_MD', [string]$Cfg = 'Release', [string]$Kind = 'static')
. "$PSScriptRoot\..\common.ps1"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$b = Join-Path $root "build\make\nmake\win_nmake_${Variant}_${Cfg}\$Kind"
New-Item -ItemType Directory -Force -Path $b | Out-Null
$nmake = Get-Command nmake -ErrorAction SilentlyContinue
if (-not $nmake) {
    Write-Note "nmake not in PATH (vcvars required); placeholder for M5 (F-05-02)"
    exit 3
}
Push-Location $b
& nmake /f (Join-Path $root 'Makefile.nmake') SRCDIR=$root
$rc = $LASTEXITCODE
Pop-Location
exit $rc
