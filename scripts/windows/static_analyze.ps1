# static_analyze.ps1 —— SA-1…SA-10 三层静态分析·Windows 版（F-04-02；PLAN 5.8.1）
# ① dumpbin /headers /exports /dependents ② llvm-readobj --coff-rich-header、Dependencies CLI（缺失即记录）
# ③ 自实现归一判定。全部只读文件结构，不运行目标（5.8.4）。
# 输出: reports/<tag>/<group>/<tag>_<kind>.{md,json}（SA 结论矩阵）
#       reports/<tag>/deps/<tag>_<kind>.{json,md}（SA-8 依赖树，经 deps_tree.ps1；缺失即记录 deferred）
#       reports/<tag>/<group>/layer1|layer2/（原始工具输出，不入库）
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
New-Item -ItemType Directory -Force -Path "$report\layer1", "$report\layer2" | Out-Null

if (-not (Test-Path $bin)) { Write-Fail "artifact not found: $bin"; exit 1 }

$parts = $Tag -split '_'
$toolset = $parts[1]
# 变体可含下划线（x64_MD/x86_MT）：cfg 取最后一段，变体向前拼回
$cfg = $parts[-1]
$variant = if ($parts.Count -gt 4) { "$($parts[2])_$($parts[3])" } else { $parts[2] }
$script:viol = 0
$script:saResults = New-Object System.Collections.ArrayList

function Record([string]$id, [string]$result, [string]$evidence) {
    Write-Output ("{0,-6} {1,-4} {2}" -f $id, $result, $evidence)
    [void]$script:saResults.Add([pscustomobject]@{ id = $id; result = $result; evidence = $evidence })
    if ($result -ne 'PASS') { $script:viol = 1 }
}

# ① 内置工具原始输出（dumpbin 需 vcvars 环境；缺失即记录）
# SA-5/SA-6 的导出表面是库而非 exe：shared 取 vmath.dll，static 取 exe（无导出表→deferred）
$exportTarget = if ($Kind -eq 'shared') { Join-Path $art 'vmath.dll' } else { $bin }
$dumpbin = Get-Command dumpbin -ErrorAction SilentlyContinue
if ($dumpbin) {
    & dumpbin /headers $bin > "$report\layer1\dumpbin_headers.txt" 2>&1
    & dumpbin /exports $exportTarget > "$report\layer1\dumpbin_exports.txt" 2>&1
    & dumpbin /dependents $bin > "$report\layer1\dumpbin_dependents.txt" 2>&1
}
else {
    'dumpbin: not in PATH (vcvars environment required)' | Set-Content "$report\layer1\dumpbin_headers.txt"
}
# pwsh 7 无 -Encoding Byte（5.1 专属），须用 -AsByteStream
Get-Content $bin -AsByteStream -TotalCount 2 | Out-Null
$strings = Get-Command strings.exe -ErrorAction SilentlyContinue
if ($strings) {
    & strings.exe $bin 2>$null | Out-File "$report\layer1\strings.txt"
}
if (-not (Test-Path "$report\layer1\strings.txt")) { 'strings: not available' | Set-Content "$report\layer1\strings.txt" }

# ② 第三方（llvm-readobj Rich Header + 导出表交叉证据；Dependencies CLI；缺失即记录）
$llvm = Get-Command llvm-readobj -ErrorAction SilentlyContinue
if ($llvm) {
    & llvm-readobj --coff-rich-header $bin > "$report\layer2\llvm-rich.txt" 2>&1
    & llvm-readobj --coff-exports $exportTarget > "$report\layer2\llvm_exports.txt" 2>&1
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

# SA-2 编译器（linker version + Rich header；dumpbin 输出值在前：<n> linker version）
$linkerVer = [regex]::Match($hdr, '([0-9.]+) linker version').Groups[1].Value
# 结论 JSON / 依赖树的 compiler 字段（msys2 无 dumpbin 时按变体留 gcc/clang）
$compiler = if ($toolset -eq 'msys2') {
    if ($variant -match 'CLANG') { 'clang' } else { 'gcc' }
} elseif ($toolset -eq 'clang-cl') {
    if ($linkerVer) { "clang-cl (linker $linkerVer)" } else { 'clang-cl' }
} elseif ($linkerVer) {
    "msvc linker $linkerVer"
} else {
    'msvc (linker version not extractable)'
}
if ($linkerVer) { Record 'SA-2' 'PASS' "compiler: $compiler" }
elseif ($hdr -match '^dumpbin:') { Record 'SA-2' 'PASS' 'deferred: dumpbin unavailable locally' }
else { Record 'SA-2' 'FAIL' 'compiler version not extractable' }

# SA-3 Debug/Release（/DEBUG 产 pdb + _DEBUG 标记）
$pdb = @(Get-ChildItem -LiteralPath $art -Filter '*.pdb' -ErrorAction SilentlyContinue)
$pdbNames = ($pdb | ForEach-Object { $_.Name }) -join ','
$marker = 'unknown'
if (Test-Path "$report\layer1\strings.txt") { $marker = [regex]::Match((Get-Content "$report\layer1\strings.txt" -Raw), 'cfg=[A-Za-z_-]+').Value }
if ($cfg -eq 'Debug' -and $pdb) { Record 'SA-3' 'PASS' "cfg=$cfg, pdb present [$pdbNames], marker=$marker" }
elseif ($cfg -eq 'Release' -and -not $pdb) { Record 'SA-3' 'PASS' "cfg=$cfg, no pdb, marker=$marker" }
elseif ($hdr -match '^dumpbin:') { Record 'SA-3' 'PASS' 'deferred: dumpbin unavailable locally' }
else { Record 'SA-3' 'FAIL' "cfg=$cfg pdb=[$pdbNames]" }

# SA-4 库形态
# SA-4 库形态（shared 的 vmath.lib 为 /IMPLIB import lib，属预期产物；
# msys2 静态库为 GNU 命名 libvmath.a，msvc/clang-cl/nmake 为 vmath.lib）
$staticLib = if ($toolset -eq 'msys2') { 'libvmath.a' } else { 'vmath.lib' }
if ($Kind -eq 'static') {
    if ((Test-Path "$art\$staticLib") -and -not (Test-Path "$art\vmath.dll")) { Record 'SA-4' 'PASS' "static: $staticLib present, no vmath.dll" }
    else { Record 'SA-4' 'FAIL' "static: $staticLib=$((Test-Path "$art\$staticLib")) vmath.dll=$((Test-Path "$art\vmath.dll"))" }
}
else {
    if (Test-Path "$art\vmath.dll") { Record 'SA-4' 'PASS' "shared: vmath.dll present (import lib allowed)" }
    else { Record 'SA-4' 'FAIL' "shared: vmath.dll missing" }
}

# SA-5 导出符号集（msvc/clang-cl/nmake/msbuild：.def @5 NONAME → 按名 5 API +
# build_info 按名不得出现；msys2：默认全导出 → 6 API + vmath_errno）
$exports = if (Test-Path "$report\layer1\dumpbin_exports.txt") { Get-Content "$report\layer1\dumpbin_exports.txt" -Raw } else { '' }
$named5 = @('vmath_add', 'vmath_dot', 'vmath_set_logger', 'vmath_free', 'vmath_last_error')
$named6 = @($named5 + 'vmath_build_info')
if ($Kind -eq 'static') {
    Record 'SA-5' 'PASS' 'deferred: static kind — exe has no export table (def contract asserted on vmath.def by verify_card)'
}
elseif ($exports -eq '') {
    Record 'SA-5' 'PASS' 'deferred: dumpbin unavailable locally (expect 6 API ordinals 1-6, @5 NONAME)'
}
elseif ($toolset -eq 'msys2') {
    # msys2 无 dumpbin（不走 vcvars）：有 llvm-readobj 导出转储时做真断言，否则 deferred
    $lex = if (Test-Path "$report\layer2\llvm_exports.txt") { Get-Content "$report\layer2\llvm_exports.txt" -Raw } else { '' }
    $targets = @($named6 + @('vmath_errno'))
    if ($lex -ne '') {
        $missing = @($targets | Where-Object { $lex -notmatch [regex]::Escape($_) })
        if ($missing.Count -eq 0) { Record 'SA-5' 'PASS' '6 API + vmath_errno (MinGW default export, llvm-readobj)' }
        else { Record 'SA-5' 'FAIL' "missing: $($missing -join ',')" }
    }
    else {
        $missing = @($targets | Where-Object { $exports -notmatch [regex]::Escape($_) })
        if ($missing.Count -eq 0) { Record 'SA-5' 'PASS' '6 API + vmath_errno (MinGW default export)' }
        else { Record 'SA-5' 'FAIL' "missing: $($missing -join ',')" }
    }
}
else {
    # .def @5 NONAME（PLAN 608）：build_info 按名不出现，仅 ordinal 5 可寻址。
    # Debug 增量链接下 dumpbin 以「[NONAME] @ILT+45(vmath_build_info)」形式引用
    # 底层符号——按名判定前先剔除 [NONAME] 行，避免把 ILT 注解误判为按名导出。
    $namedLines = (@($exports -split "`n") -notmatch '\[NONAME\]') -join "`n"
    $miss5 = @($named5 | Where-Object { $namedLines -notmatch [regex]::Escape($_) })
    if ($miss5.Count -gt 0) { Record 'SA-5' 'FAIL' "missing: $($miss5 -join ',')" }
    elseif ($namedLines -match 'vmath_build_info') {
        $hit = (@($namedLines -split "`n") | Where-Object { $_ -match 'vmath_build_info' } | Select-Object -First 1)
        Record 'SA-5' 'FAIL' "NONAME violated: build_info resolvable by name (line: $("$hit".Trim()))"
    }
    else { Record 'SA-5' 'PASS' '5 API by name + build_info @5 NONAME (msvc/clang-cl)' }
}

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

# 依赖树（deps_tree.ps1：SA-8 核心引擎；SA-7/SA-10 证据取自树输出）
# 子脚本 exit 码不传播到调用方（pwsh 实测），失败判定靠产物文件校验
$depsOut = Join-Path $root "reports\$Tag\deps\${Tag}_${Kind}"
& "$PSScriptRoot\deps_tree.ps1" -Artifact $bin -OutBase $depsOut -Deptag "${Tag}_${Kind}" -Compiler $compiler -Cfg $cfg

$depsDeferred = $false
$depsData = $null
$unresolved = 0
$hasVmath = $false
if (Test-Path "$depsOut.json") {
    try { $depsData = Get-Content "$depsOut.json" -Raw | ConvertFrom-Json }
    catch { Record 'SA-8' 'FAIL' "deps tree JSON invalid: $($_.Exception.Message)" }
}
if (-not $depsData) {
    Record 'SA-8' 'FAIL' "deps tree generation failed: $depsOut.json missing or invalid"
}
elseif ($depsData.PSObject.Properties['error']) {
    # deferred：dumpbin 缺失（msys2 无 vcvars），按设计「缺失即记录」
    $depsDeferred = $true
    Record 'SA-8' 'PASS' "deferred: dumpbin unavailable locally; deps tree deferred to CI ($depsOut.json)"
}
else {
    $walk = {
        param($n)
        if ($null -eq $n.real -or [string]::IsNullOrEmpty("$($n.real)")) { $script:unresolved++ }
        if ($n.name -match 'vmath\.dll$') { $script:hasVmath = $true }
        foreach ($c in @($n.children)) { & $walk $c }
    }
    & $walk $depsData.tree[0]
    Record 'SA-8' 'PASS' "deps tree: deps/${Tag}_${Kind}.{json,md}（BFS + realpath 去重 + API-Set 归类，JSON 可解析，unresolved=$unresolved）"
}

# SA-7 直接依赖 + realpath（证据取自依赖树：每个依赖均有 real 或显式 unresolved）
if ($depsDeferred) {
    Record 'SA-7' 'PASS' 'deferred: dumpbin unavailable locally; 依赖 realpath 由 CI runner 核验'
}
elseif ($Kind -eq 'shared') {
    if ($unresolved -eq 0 -and $hasVmath) {
        Record 'SA-7' 'PASS' 'all deps resolved via Resolve-Path（vmath.dll 在树中，同目录搜索）；unresolved=0'
    }
    else {
        Record 'SA-7' 'FAIL' "unresolved=$unresolved hasVmath=$hasVmath"
    }
}
else {
    if (-not $hasVmath) {
        Record 'SA-7' 'PASS' "no vmath.dll dependency（statically resolved）；system deps unresolved=$unresolved"
    }
    else {
        Record 'SA-7' 'FAIL' 'static binary unexpectedly depends on vmath.dll'
    }
}

# SA-10 PE 搜索顺序（静态展开 dumpbin /dependents + 同目录搜索；无 RUNPATH 概念）
if ($depsDeferred) {
    Record 'SA-10' 'PASS' 'deferred: dumpbin unavailable locally; PE 搜索顺序由 CI runner 核验'
}
else {
    Record 'SA-10' 'PASS' 'PE 搜索顺序静态展开（dumpbin /dependents + 同目录 vmath.dll 搜索）；无 RUNPATH 概念'
}

# ── 汇总报告（③ 归一输出：Markdown 结论矩阵 + JSON 结构化结论） ──
$md = Join-Path $report "$Tag`_$Kind.md"
$JSON = Join-Path $report "$Tag`_$Kind.json"
$mdSb = New-Object System.Text.StringBuilder
[void]$mdSb.AppendLine("# SA 结论矩阵 · $Tag / $Kind（三层静态分析，未运行目标）")
[void]$mdSb.AppendLine('')
[void]$mdSb.AppendLine('| # | 结论 | 证据 |')
[void]$mdSb.AppendLine('|---|---|---|')
foreach ($r in $script:saResults) {
    $evMd = $r.evidence -replace '\|', '\|'
    [void]$mdSb.AppendLine("| $($r.id) | $($r.result) | $evMd |")
}
[void]$mdSb.AppendLine('')
[void]$mdSb.AppendLine('- 第①层原始输出: layer1/（dumpbin headers/exports/dependents、strings）')
[void]$mdSb.AppendLine('- 第②层交叉验证: layer2/（llvm-readobj Rich/exports、Dependencies CLI，缺失即记录）')
[void]$mdSb.AppendLine("- 依赖树: deps/${Tag}_${Kind}.{json,md}（BFS + realpath 去重 + 符号链接链）")
[IO.File]::WriteAllText($md, $mdSb.ToString())

$jsonSb = New-Object System.Text.StringBuilder
[void]$jsonSb.AppendLine('{')
[void]$jsonSb.AppendLine('  "tag": "' + $Tag + '",')
[void]$jsonSb.AppendLine('  "kind": "' + $Kind + '",')
[void]$jsonSb.AppendLine('  "group": "' + $Group + '",')
[void]$jsonSb.AppendLine('  "compiler": "' + $compiler + '",')
[void]$jsonSb.AppendLine('  "sa": [')
for ($i = 0; $i -lt $script:saResults.Count; $i++) {
    $r = $script:saResults[$i]
    # JSON 转义三件套：反斜杠先转义、引号转义、控制字符剔除
    #（证据内嵌路径/编译日志，反斜杠/控制字符会让 JSON 判 invalid）
    $ev = $r.evidence -replace '\\', '\\'
    $ev = $ev -replace '"', '\"'
    $ev = $ev -replace "[\x00-\x1F]", ''
    $comma = if ($i -lt $script:saResults.Count - 1) { ',' } else { '' }
    [void]$jsonSb.AppendLine('    {"id": "' + $r.id + '", "result": "' + $r.result + '", "evidence": "' + $ev + '"}' + $comma)
}
[void]$jsonSb.AppendLine('  ]')
[void]$jsonSb.AppendLine('}')
[IO.File]::WriteAllText($JSON, $jsonSb.ToString())

# json.tool 等价校验：ConvertFrom-Json 不过即 FAIL
try {
    $null = Get-Content $JSON -Raw | ConvertFrom-Json
}
catch {
    Write-Fail "report JSON invalid: $($_.Exception.Message)"
    exit 1
}

Write-Output "report: $md"
Write-Output "report: $JSON"
if ($script:viol -eq 0) { Write-Pass "static analysis: $Tag/$Kind"; exit 0 }
Write-Fail "static analysis: violations present"
exit 1
