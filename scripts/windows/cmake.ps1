# cmake.ps1 —— ③ CMake·Windows（F-04-02 初版；msvc 用 Ninja（S9），三 OS 收口 M6/F-06-01）
# 用法: cmake.ps1 -Toolset msvc|msys2|clang-cl -Variant <v> -Cfg Debug|Release -Kind static|shared
param(
    [Parameter(Mandatory = $true)][string]$Toolset,
    [Parameter(Mandatory = $true)][string]$Variant,
    [Parameter(Mandatory = $true)][string]$Cfg,
    [Parameter(Mandatory = $true)][string]$Kind
)
. "$PSScriptRoot\..\common.ps1"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$tag = Get-ComboTag $Toolset $Variant $Cfg
$b = Join-Path $root "build\cmake\$tag\$Kind"
$sh = if ($Kind -eq 'shared') { 'ON' } else { 'OFF' }
$gen = @()
$rta = @()
if ($Toolset -eq 'msvc' -or $Toolset -eq 'clang-cl') {
    # S9：msvc/clang-cl 强制 Ninja
    $gen = @('-G', 'Ninja')
    $rt = if ($Variant -match 'MD') { 'MultiThreadedDLL' } else { 'MultiThreaded' }
    $rta = @('-DCMAKE_MSVC_RUNTIME_LIBRARY', $rt)
}
cmake -S $root -B $b @gen -DCMAKE_BUILD_TYPE=$Cfg -DBUILD_SHARED_LIBS=$sh @rta
if ($LASTEXITCODE -ne 0) { exit 1 }
cmake --build $b
if ($LASTEXITCODE -ne 0) { exit 1 }
ctest --test-dir $b --output-on-failure
exit $LASTEXITCODE
