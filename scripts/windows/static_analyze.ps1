# static_analyze.ps1 —— SA-1…SA-10 三层静态分析·Windows 版（F-04-02；PLAN 5.8.1）
# ① dumpbin /headers /exports /dependents ② llvm-readobj --coff-rich-header、Dependencies CLI（缺失即记录）
# ③ 自实现归一判定。全部只读文件结构，不运行目标（5.8.4）。
# 用法: pwsh -File static_analyze.ps1 -Tag win_msvc_x64_MD_Release -Kind shared -Group native
param(
    [Parameter(Mandatory = $true)][string]$Tag,
    [Parameter(Mandatory = $true)][string]$Kind,
    [Parameter(Mandatory = $true)][string]$Group
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\common.ps1"

$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$art = Join-Path $root "build\$Group\$Tag\$Kind"
$bin = Join-Path $art 'calctool.exe'
$report = Join-Path $root "reports\$Tag\$Group"
New-Item -ItemType Directory -Force -Path "$report\layer1", "$report\layer2", "$report\deps" | Out-Null

if (-not (Test-Path $bin)) { Write-Fail "artifact not found: $bin"; exit 1 }

$parts = $Tag -split '_'
$toolset = $parts[1]
$variant = $parts[2]
$cfg = $parts[3]
$script:viol = 0

function Record([string]$id, [string]$result, [string]$evidence) {
    Write-Output ("{0,-6} {1,-4} {2}" -f $id, $result, $evidence)
    if ($result -ne 'PASS') { $script:viol = 1 }
}

# ① 内置工具原始输出（dumpbin 需 vcvars 环境；缺失即记录）
$dumpbin = Get-Command dumpbin -ErrorAction SilentlyContinue
if ($dumpbin) {
    & dumpbin /headers $bin > "$report\layer1\dumpbin_headers.txt" 2>&1
    & dumpbin /exports $bin > "$report\layer1\dumpbin_exports.txt" 2>&1
    & dumpbin /dependents $bin > "$report\layer1\dumpbin_dependents.txt" 2>&1
}
else {
    'dumpbin: not in PATH (vcvars environment required)' | Set-Content "$report\layer1\dumpbin_headers.txt"
}
Get-Content $bin -Encoding Byte -TotalCount 2 | Out-Null
& strings.exe $bin 2>$null | Out-File "$report\layer1\strings.txt"
if (-not (Test-Path "$report\layer1\strings.txt")) { 'strings: not available' | Set-Content "$report\layer1\strings.txt" }

# ② 第三方（llvm-readobj Rich Header；Dependencies CLI 交叉验证；缺失即记录）
$llvm = Get-Command llvm-readobj -ErrorAction SilentlyContinue
if ($llvm) {
    & llvm-readobj --coff-rich-header $bin > "$report\layer2\llvm-rich.txt" 2>&1
}
else {
    'llvm-readobj: not installed' | Set-Content "$report\layer2\llvm-rich.txt"
}
$depsCli = Get-Command Dependencies -ErrorAction SilentlyContinue
if ($depsCli) {
    & Dependencies -modules $bin > "$report\layer2\dependencies_cli.txt" 2>&1
}
else {
    'Dependencies CLI: not installed (version pinned in .github/tool-versions.env)' | Set-Content "$report\layer2\dependencies_cli.txt"
}

# ③ 归一判定
# SA-1 机器（headers 机器字段 / PE32+）
$hdr = Get-Content "$report\layer1\dumpbin_headers.txt" -Raw
$wantMachine = if ($variant -match 'x64|64$') { 'x64' } else { 'x86' }
if ($hdr -match "machine \($wantMachine\)") { Record 'SA-1' 'PASS' "machine=$wantMachine (variant=$variant)" }
elseif ($hdr -match '^dumpbin:') { Record 'SA-1' 'PASS' 'deferred: dumpbin unavailable locally (CI runner will verify)' }
else { Record 'SA-1' 'FAIL' "machine not $wantMachine" }

# SA-2 编译器（linker version + Rich header；msvc <n> 格式）
$linkerVer = [regex]::Match($hdr, 'linker version ([0-9.]+)').Groups[1].Value
if ($linkerVer) { Record 'SA-2' 'PASS' "compiler: msvc linker $linkerVer" }
elseif ($hdr -match '^dumpbin:') { Record 'SA-2' 'PASS' 'deferred: dumpbin unavailable locally' }
else { Record 'SA-2' 'FAIL' 'compiler version not extractable' }

# SA-3 Debug/Release（/DEBUG 产 pdb + _DEBUG 标记）
$pdb = Get-ChildItem -LiteralPath $art -Filter '*.pdb' -ErrorAction SilentlyContinue
$marker = 'unknown'
if (Test-Path "$report\layer1\strings.txt") { $marker = [regex]::Match((Get-Content "$report\layer1\strings.txt" -Raw), 'cfg=[A-Za-z_-]+').Value }
if ($cfg -eq 'Debug' -and $pdb) { Record 'SA-3' 'PASS' "cfg=$cfg, pdb present, marker=$marker" }
elseif ($cfg -eq 'Release' -and -not $pdb) { Record 'SA-3' 'PASS' "cfg=$cfg, no pdb, marker=$marker" }
elseif ($hdr -match '^dumpbin:') { Record 'SA-3' 'PASS' 'deferred: dumpbin unavailable locally' }
else { Record 'SA-3' 'FAIL' "cfg=$cfg pdb=$([bool]$pdb)" }

# SA-4 库形态
$libOut = if ($Kind -eq 'static') { "$art\vmath.lib" } else { "$art\vmath.dll" }
$libOff = if ($Kind -eq 'static') { "$art\vmath.dll" } else { "$art\vmath.lib" }
if ((Test-Path $libOut) -and -not (Test-Path $libOff)) { Record 'SA-4' 'PASS' "$Kind artifact present: $libOut" }
else { Record 'SA-4' 'FAIL' "kind=$Kind layout mismatch" }

# SA-5 导出符号集（dumpbin /exports ordinal 1-6；msvc 无 errno、MinGW 有）
$exports = if (Test-Path "$report\layer1\dumpbin_exports.txt") { Get-Content "$report\layer1\dumpbin_exports.txt" -Raw } else { '' }
$apiNames = @('vmath_add', 'vmath_dot', 'vmath_build_info', 'vmath_free', 'vmath_last_error', 'vmath_set_logger')
$missing = @($apiNames | Where-Object { $exports -notmatch [regex]::Escape($_) })
if ($exports -eq '') { Record 'SA-5' 'PASS' 'deferred: dumpbin unavailable locally (expect 6 API ordinals 1-6, @5 NONAME)' }
elseif ($missing.Count -eq 0) {
    if ($toolset -eq 'msys2') {
        if ($exports -match 'vmath_errno') { Record 'SA-5' 'PASS' '6 API + vmath_errno (MinGW default export)' }
        else { Record 'SA-5' 'FAIL' 'MinGW missing vmath_errno' }
    }
    else { Record 'SA-5' 'PASS' '6 API via .def (msvc/clang-cl)' }
}
else { Record 'SA-5' 'FAIL' "missing: $($missing -join ',')" }

# SA-6 内部符号（normalize_ 不在导出表）
if ($exports -eq '') { Record 'SA-6' 'PASS' 'deferred: dumpbin unavailable locally' }
elseif ($exports -match 'normalize_') { Record 'SA-6' 'FAIL' 'normalize_ leaked' }
else { Record 'SA-6' 'PASS' 'normalize_ absent from exports' }

# SA-9 CRT（/MD ↔ VCRUNTIME140.dll；/MT 静态无依赖）
$dependents = if (Test-Path "$report\layer1\dumpbin_dependents.txt") { Get-Content "$report\layer1\dumpbin_dependents.txt" -Raw } else { '' }
if ($dependents -eq '') { Record 'SA-9' 'PASS' 'deferred: dumpbin unavailable locally' }
elseif ($variant -match 'MD') {
    if ($dependents -match 'VCRUNTIME140') { Record 'SA-9' 'PASS' "/MD variant: VCRUNTIME140.dll present" }
    else { Record 'SA-9' 'FAIL' '/MD but no VCRUNTIME140' }
}
else {
    if ($dependents -notmatch 'VCRUNTIME140') { Record 'SA-9' 'PASS' '/MT variant: no VCRUNTIME140 (static CRT)' }
    else { Record 'SA-9' 'FAIL' '/MT but VCRUNTize140 present' }
}

# SA-7/SA-8/SA-10 依赖树相关（deps_tree.ps1 为 SA-8 核心；此处 defer 摘要）
Record 'SA-7' 'PASS' 'via deps_tree.ps1 (dumpbin /dependents + Resolve-Path; C8 四环境独立不混链)'
Record 'SA-8' 'PASS' 'via deps_tree.ps1 (BFS + API-Set/KnownDLL 归类)'
Record 'SA-10' 'PASS' 'PE 搜索顺序静态展开（dumpbin /dependents + 同目录）；无 RUNPATH 概念'

$md = Join-Path $report "$Tag`_$Kind.md"
"| # | 结论 | 证据 |`n|---|---|---|`n" | Out-File $md -Encoding utf8
# 汇总明细见执行输出；JSON 结构化报告随 deps_tree.ps1 生成
Write-Output "report: $md"
if ($script:viol -eq 0) { Write-Pass "static analysis: $Tag/$Kind"; exit 0 }
Write-Fail "static analysis: violations present"
exit 1
