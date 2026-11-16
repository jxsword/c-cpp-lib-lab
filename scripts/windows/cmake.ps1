# cmake.ps1 —— ③ CMake·Windows（F-04-02 初版；msvc/clang-cl 强制 Ninja（S9），msys2 用
# MinGW Makefiles；三 OS 收口 M6/F-06-01）
# 用法: cmake.ps1 -Toolset msvc|msys2|clang-cl -Variant <v> -Cfg Debug|Release -Kind static|shared
#       [_combo 另附 -DCMAKE_MSVC_RUNTIME_LIBRARY=<基型>（F-09-04 A5 契约）→ 本脚本吸收校验]
param(
    [Parameter(Mandatory = $true)][string]$Toolset,
    [Parameter(Mandatory = $true)][string]$Variant,
    [Parameter(Mandatory = $true)][string]$Cfg,
    [Parameter(Mandatory = $true)][string]$Kind,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$ExtraArgs
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\common.ps1"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$tag = Get-ComboTag $Toolset $Variant $Cfg
$b = Join-Path $root "build\cmake\$tag\$Kind"
$sh = if ($Kind -eq 'shared') { 'ON' } else { 'OFF' }
$gen = @()
$rta = @()

# RTL 基型：变体 _MD → MultiThreadedDLL，其余 → MultiThreaded（P6：clang-cl x64 走 /MT）
$rtlBase = if ($Variant -match 'MD') { 'MultiThreadedDLL' } else { 'MultiThreaded' }

# 吸收 _combo 附带的 -DCMAKE_MSVC_RUNTIME_LIBRARY=<基型>：PowerShell 绑定不识别
# `-D` 开头的裸 token（本地实测终止性报错），必须 ValueFromRemainingArguments；
# 基型须与本脚本按变体推导一致，不一致即失败（防口径漂移）。
foreach ($a in @($ExtraArgs)) {
    if (-not $a) { continue }
    $m = [regex]::Match($a, '^[-/]DCMAKE_MSVC_RUNTIME_LIBRARY=(.+)$')
    if (-not $m.Success) { Write-Output "FAIL: unexpected extra arg: $a"; exit 2 }
    if ($m.Groups[1].Value -ne $rtlBase) {
        Write-Output "FAIL: RTL mismatch (combo=$($m.Groups[1].Value) derived=$rtlBase)"
        exit 2
    }
}

if ($Toolset -eq 'msvc' -or $Toolset -eq 'clang-cl') {
    # S9：msvc/clang-cl 强制 Ninja。windows-latest（windows-2025）镜像预装 Ninja 且在 PATH
    # （runner-images Windows2025-Readme，2026-11-17 查证）；缓存目录 C:\tools\ninja 作兜底。
    $ninja = Get-Command ninja -ErrorAction SilentlyContinue
    if (-not $ninja) {
        if (Test-Path 'C:\tools\ninja\ninja.exe') { $env:PATH = 'C:\tools\ninja;' + $env:PATH }
        else { Write-Output 'FAIL: ninja not found (PATH nor C:\tools\ninja)'; exit 1 }
    }
    $gen = @('-G', 'Ninja')
    # CMP0091：显式值不会随 Debug 自动加 d——用 genex 保持 /MD<->/MDd、/MT<->/MTd 联动（7.1）
    $rtl = 'MultiThreaded$<$<CONFIG:Debug>:Debug>' + $(if ($rtlBase -eq 'MultiThreadedDLL') { 'DLL' } else { '' })
    # cmake -D 只接受单 token 形式 -DVAR=value（双 token 会被当作独立 -D 报错，实测）
    $rta = @("-DCMAKE_MSVC_RUNTIME_LIBRARY=$rtl")
    # clang-cl 必须显式指派编译器：Ninja 生成器在 vcvars 环境默认探到 cl
    if ($Toolset -eq 'clang-cl') { $rta += @("-DCMAKE_C_COMPILER=clang-cl") }
}
else {
    # msys2 四环境（C8）：MinGW Makefiles 生成器 + 环境内 mingw32-make
    # （mingw-w64-<env>-make 仅提供 mingw32-make.exe，无 make.exe；packages.msys2.org 2026-11-17 查证）
    $cc = Get-Msys2ToolPrefix $Variant
    if (-not $cc -or -not (Test-Path $cc)) { Write-Output "FAIL: msys2 toolchain not found: $cc"; exit 1 }
    $envbin = Split-Path -Parent $cc
    # 工具链 bin 前置 PATH：cmake 编译器探测与 ctest 运行期 DLL 解析依赖
    $env:PATH = "$envbin;$env:PATH"
    $make = Join-Path $envbin 'mingw32-make.exe'
    if (-not (Test-Path $make)) { Write-Output "FAIL: mingw32-make not found: $make"; exit 1 }
    $gen = @('-G', 'MinGW Makefiles', "-DCMAKE_MAKE_PROGRAM=$make", "-DCMAKE_C_COMPILER=$cc")
}
cmake -S $root -B $b @gen -DCMAKE_BUILD_TYPE=$Cfg -DBUILD_SHARED_LIBS=$sh @rta
if ($LASTEXITCODE -ne 0) { exit 1 }
cmake --build $b
if ($LASTEXITCODE -ne 0) { exit 1 }
ctest --test-dir $b --output-on-failure
exit $LASTEXITCODE
