# native.ps1 —— Windows 原生构建核心（F-04-02；PLAN 7.1 / F-04-02 要点）
# 用法: pwsh -File native.ps1 -Toolset msvc|msys2|clang-cl -Variant <变体> -Cfg Debug|Release -Kind static|shared
# msvc: cl /LD /DCALC_BUILD_DLL /MD|/MT ... /link /DEF:def\vmath.def；
# msys2: -shared -Wl,--out-implib,libvmath.dll.a；clang-cl 同 MSVC（LLVM 工具）。
# 四环境独立目录不混链（C8）。bat 为薄入口（vcvarsall / msys2 切换后调用本脚本）。
param(
    [Parameter(Mandatory = $true)][string]$Toolset,
    [Parameter(Mandatory = $true)][string]$Variant,
    [Parameter(Mandatory = $true)][string]$Cfg,
    [Parameter(Mandatory = $true)][string]$Kind
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\common.ps1"

$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$tag = Get-ComboTag $Toolset $Variant $Cfg
$out = Join-Path $root "build\native\$tag\$Kind"
New-Item -ItemType Directory -Force -Path $out | Out-Null
$log = Join-Path $out 'compile.log'
Set-Content -LiteralPath $log -Value '' -Encoding UTF8

if (-not (Assert-NoArtifacts $root)) { Write-Fail 'D2 pre: source tree has artifacts'; exit 1 }
if (-not (@('msvc', 'msys2', 'clang-cl') -contains $Toolset)) { Write-Fail "bad toolset: $Toolset"; exit 2 }
if (-not (@('Debug', 'Release') -contains $Cfg)) { Write-Fail "bad cfg: $Cfg"; exit 2 }
if (-not (@('static', 'shared') -contains $Kind)) { Write-Fail "bad kind: $Kind"; exit 2 }

function Invoke-Logged {
    # 数组实参（clCfg/gccCfg）须展平后逐元素传给原生命令（pwsh 不递归展开嵌套数组）
    $flat = foreach ($a in $args) { $a }
    $line = $flat -join ' '
    Add-Content -LiteralPath $log -Value $line
    $rest = @($flat | Select-Object -Skip 1)
    & $flat[0] @rest
    if ($LASTEXITCODE -ne 0) { throw "command failed: $line" }
}

# cfg → cl/gcc 旗标（7.1：Debug /Zi /Od /D_DEBUG + /DEBUG；Release /O2 /DNDEBUG）
# 数组形式：Invoke-Logged 展平后逐元素传递（带空格字符串会被原生命令当作单个 argv）
$clCfg = if ($Cfg -eq 'Debug') { @('/Zi', '/Od', '/D_DEBUG', '/DEBUG') } else { @('/O2', '/DNDEBUG') }
$gccCfg = if ($Cfg -eq 'Debug') { @('-g', '-O0', '-D_DEBUG') } else { @('-O2', '-DNDEBUG') }

$inc = Join-Path $root 'include'
$src = Join-Path $root 'src'

try {
    if ($Toolset -eq 'msvc' -or $Toolset -eq 'clang-cl') {
        $cc = if ($Toolset -eq 'msvc') { 'cl' } else { 'clang-cl' }
        # Git usr/bin 携带 coreutils link(1)（与 VS link.exe 同名不同物）且在 PATH
        # 中先于 VS bin——将 VC 的 Hostx64\<目标> bin 目录前置到 PATH 最前；
        # cl 内部链接不受影响（cl 从自身目录解析 link.exe），独立 link/lib 调用受影响
        $vcarch = if ($Variant.StartsWith('x64')) { 'x64' } else { 'x86' }
        if ($env:VCToolsInstallDir) {
            $vcbin = Join-Path $env:VCToolsInstallDir "bin\Hostx64\$vcarch"
            if (Test-Path $vcbin) { $env:PATH = "$vcbin;$env:PATH" }
        }
        $crt = Get-MsvcCrtFlag $Variant $Cfg
        if ($Kind -eq 'static') {
            Invoke-Logged $cc $clCfg $crt '/DCALC_STATIC' "/I$inc" '/c' "$src\vmath_core.c" "/Fo$out\vmath_core.obj"
            Invoke-Logged $cc $clCfg $crt '/DCALC_STATIC' "/I$inc" '/c' "$src\vmath_report.c" "/Fo$out\vmath_report.obj"
            Invoke-Logged $cc $clCfg $crt '/DCALC_STATIC' "/I$inc" '/c' "$src\calctool.c" "/Fo$out\calctool.obj"
            Invoke-Logged lib "/OUT:$out\vmath.lib" "$out\vmath_core.obj" "$out\vmath_report.obj"
            Invoke-Logged link "$out\calctool.obj" "$out\vmath.lib" "/OUT:$out\calctool.exe"
        }
        else {
            Invoke-Logged $cc $clCfg $crt '/DCALC_BUILD_DLL' '/LD' "/I$inc" "$src\vmath_core.c" "$src\vmath_report.c" "/Fe:$out\vmath.dll" "/link" "/DEF:$root\def\vmath.def" "/IMPLIB:$out\vmath.lib"
            Invoke-Logged $cc $clCfg '/DCALC_USE_DLL' "/I$inc" '/c' "$src\calctool.c" "/Fo$out\calctool.obj"
            Invoke-Logged link "$out\calctool.obj" "$out\vmath.lib" "/OUT:$out\calctool.exe"
        }
    }
    else {
        # msys2 四环境（C8：每环境独立 gcc，产物目录含变体名不混链）
        $gcc = Get-Msys2ToolPrefix $Variant
        if (-not $gcc -or -not (Test-Path $gcc)) { Write-Fail "msys2 toolchain not found: $gcc"; exit 1 }
        # ar 与 gcc 同目录（toolchain 组自带 binutils）；异常时回退 PATH 解析
        $ar = Join-Path (Split-Path -Parent $gcc) 'ar.exe'
        if (-not (Test-Path $ar)) { $ar = 'ar' }
        if ($Kind -eq 'static') {
            Invoke-Logged $gcc $gccCfg -DCALC_STATIC "-I$inc" -c "$src\vmath_core.c" -o "$out\vmath_core.o"
            Invoke-Logged $gcc $gccCfg -DCALC_STATIC "-I$inc" -c "$src\vmath_report.c" -o "$out\vmath_report.o"
            Invoke-Logged $gcc $gccCfg -DCALC_STATIC "-I$inc" -c "$src\calctool.c" -o "$out\calctool.o"
            Invoke-Logged $ar rcs "$out\libvmath.a" "$out\vmath_core.o" "$out\vmath_report.o"
            Invoke-Logged $gcc "$out\calctool.o" -L"$out" -lvmath -o "$out\calctool.exe"
        }
        else {
            Invoke-Logged $gcc $gccCfg -DCALC_BUILD_DLL -shared "-I$inc" "$src\vmath_core.c" "$src\vmath_report.c" -o "$out\vmath.dll" "-Wl,--out-implib,$out\libvmath.dll.a"
            Invoke-Logged $gcc $gccCfg -DCALC_USE_DLL "-I$inc" -c "$src\calctool.c" -o "$out\calctool.o"
            Invoke-Logged $gcc "$out\calctool.o" -L"$out" -lvmath -o "$out\calctool.exe"
        }
    }

    & (Join-Path $out 'calctool.exe') --self-test | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Fail "self-test failed: $tag/$Kind"; exit 1 }
    Write-Pass "build + self-test: $tag/$Kind -> $out"
    exit 0
}
catch {
    Write-Fail $_.Exception.Message
    exit 1
}
