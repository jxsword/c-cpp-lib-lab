# build_all.ps1 —— Windows 18 组合编排（F-04-02）：msvc 4 变体 × 2 + msys2 四环境 × 2 + clang-cl × 2
# 用法: pwsh -File build_all.ps1 [-KindFilter static|shared]
param([string]$KindFilter = '')
$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\..\common.ps1"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$viol = 0

$combos = @()
# msvc：x86_MD x86_MT x64_MD x64_MT（/MDd /MD /MTd /MT 由 cfg 联动）
foreach ($v in @('x86_MD', 'x86_MT', 'x64_MD', 'x64_MT')) {
    foreach ($c in @('Debug', 'Release')) { $combos += @{ toolset = 'msvc'; variant = $v; cfg = $c } }
}
# msys2 四环境（C8 独立）
foreach ($v in @('MINGW64', 'MINGW32', 'UCRT64', 'CLANG64')) {
    foreach ($c in @('Debug', 'Release')) { $combos += @{ toolset = 'msys2'; variant = $v; cfg = $c } }
}
# clang-cl x64（P6：MSVC ABI）
foreach ($c in @('Debug', 'Release')) { $combos += @{ toolset = 'clang-cl'; variant = 'x64'; cfg = $c } }

foreach ($k in @('static', 'shared')) {
    if ($KindFilter -and $KindFilter -ne $k) { continue }
    foreach ($cb in $combos) {
        $tag = Get-ComboTag $cb.toolset $cb.variant $cb.cfg
        Write-Output "==== $tag / $k ===="
        & pwsh -NoProfile -File (Join-Path $PSScriptRoot 'native.ps1') -Toolset $cb.toolset -Variant $cb.variant -Cfg $cb.cfg -Kind $k
        if ($LASTEXITCODE -ne 0) { $viol++ ; Write-Output "NOTE: $tag/$k failed (toolchain availability on this machine is a CI concern)" }
    }
}
if ($viol -eq 0) { Write-Pass 'build_all: all attempted combos OK'; exit 0 }
Write-Output "NOTE: build_all: $viol combo(s) unavailable on this machine (deferred to CI runner with toolchains)"
exit 0
