# deps_tree.ps1 —— SA-8 递归依赖树·Windows 版（F-04-02；PLAN 5.8.3）
# dumpbin /dependents 静态读取；Resolve-Path 解析；API-Set 与 KnownDLL 归类；
# C8：msys2 四环境依赖不交叉（msys-2.0.dll / libwinpthread 等按变体归类 bundle-env）。
# 输出：<基名>.json（嵌套树 + symlinkChains + apiSets + dedup，按 realpath 去重）
#       + <基名>.md（缩进树，对齐 linux deps_tree.sh；dumpbin 缺失即记录 deferred）。
# FORBIDDEN: 刻意不使用执行类依赖解析（5.8.4），仅静态读取文件结构。
param(
    [Parameter(Mandatory = $true)][string]$Artifact,
    [string]$OutBase = '',
    [string]$Deptag = '',
    [string]$Compiler = 'unknown',
    [string]$Cfg = 'unknown'
)
$ErrorActionPreference = 'Stop'
if (-not $OutBase) { $OutBase = "$Artifact.deps" }
if (-not $Deptag) { $Deptag = [IO.Path]::GetFileName($Artifact) }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutBase) | Out-Null

$dumpbin = Get-Command dumpbin -ErrorAction SilentlyContinue
if (-not $dumpbin) {
    @{ tag = $Deptag; error = 'dumpbin unavailable (vcvars required); deferred to CI' } |
        ConvertTo-Json | Set-Content "$OutBase.json"
    @(
        "# 依赖树 · $Deptag —— deferred"
        ""
        "dumpbin unavailable（vcvars 环境缺失）；依赖树由 CI runner 在 vcvars 环境生成。"
    ) | Set-Content "$OutBase.md"
    Write-Output "deps_tree: $OutBase.json (deferred)"
    Write-Output "deps_tree: $OutBase.md (deferred)"
    exit 0
}

function Get-Dependents([string]$pe) {
    & dumpbin /dependents $pe 2>$null |
        Where-Object { $_ -match '^\s+\S+\.dll$' } |
        ForEach-Object { $_.Trim() }
}

function Classify([string]$name) {
    # api-ms/ext-ms 全族桩名（ext-ms-onecore-/win32-/mf-/windowscore- 等）
    if ($name -match '^(api|ext)-ms-') { return 'api-set' }
    if ($name -match '^(ntdll|kernel32|kernelbase|user32|msvcrt|ucrtbase)\.dll$') { return 'known-dll' }
    if ($name -match '^(msys-2\.0|libwinpthread|libgcc|libstdc\+\+)' -and $name -match '^msys-') { return 'msys2-env' }
    return 'system'
}

function Resolve-Dep([string]$name, [string]$dir) {
    $local = Join-Path $dir $name
    if (Test-Path $local) { return (Resolve-Path -LiteralPath $local).Path }
    $sys = Join-Path "$env:SystemRoot\System32" $name
    if (Test-Path $sys) { return $sys }
    return $null
}

$tree = [ordered]@{
    tag = $Deptag
    root = [ordered]@{ path = $Artifact; kind = 'PE'; compiler = $Compiler; cfg = $Cfg }
    tree = @()
    symlinkChains = @()
    apiSets = @()
    dedup = @()
}
$seen = @{}

# symlink/junction 判定（Get-Item -Force 的 LinkType；PLAN 5.8.3 Windows 行）
function Test-Symlink([string]$p) {
    $item = Get-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
    return ($item -and $item.LinkType)
}

# 递归发射节点：按 realpath 去重（PLAN 5.8.3：关联数组按 realpath 去重）。
# 已展开的 realpath → 返回 dedup 节点（不递归，标记 dedup=true）；未展开 → 展开依赖。
# 未解析节点（桩 dll / 缺失文件，real 为空）按 name 去重——ext-ms/api 桩名在
# PE 密集依赖图中多次出现，不按名去重会导致组合爆炸（CI 实测 466KB 截断树）。
function Add-Node([string]$name, [string]$path, [string]$indent) {
    $key = if ($path) { $path } else { "unresolved:$name" }
    if ($seen.ContainsKey($key)) {
        $origin = if ($path -and $path -like "$env:SystemRoot*") { 'system' } elseif ($path) { 'bundle' } else { 'unresolved' }
        return [ordered]@{ name = $name; logical = $name; real = $path; origin = $origin; dedup = $true; children = @() }
    }
    $seen[$key] = $true
    $origin = if ($path -like "$env:SystemRoot*") { 'system' } elseif ($path) { 'bundle' } else { 'unresolved' }
    $node = [ordered]@{ name = $name; logical = $name; real = $path; origin = $origin; children = @() }
    if ($path -and (Test-Path $path)) {
        foreach ($d in (Get-Dependents $path)) {
            $cls = Classify $d
            if ($cls -eq 'api-set') { $tree.apiSets += $d; continue }
            $rp = Resolve-Dep $d (Split-Path -Parent $path)
            if ($rp -and (Test-Symlink $rp)) { $tree.symlinkChains += @($d, $rp) }
            $node.children += (Add-Node $d $rp "$indent    ")
        }
    }
    return $node
}

# .md 缩进树输出（对齐 linux deps_tree.sh 口径：├─/└─ 连接符 + [origin]/[dedup] + real=）
function Emit-TreeNode([hashtable]$node, [string]$indent, [string]$suffix) {
    $connector = if ($suffix -eq ',') { '├─' } else { '└─' }
    if ($node.ContainsKey('dedup') -and $node.dedup) {
        $label = '[dedup]'
    }
    else {
        $label = "[$($node.origin)]"
    }
    $real = if ($null -eq $node.real) { 'null' } else { $node.real }
    Add-Content -LiteralPath $MDFile -Value ("{0}{1} {2} {3} real={4}" -f $indent, $connector, $node.name, $label, $real)
    $i = 0
    $total = @($node.children).Count
    foreach ($c in @($node.children)) {
        $i++
        $suf = if ($i -lt $total) { ',' } else { '' }
        Emit-TreeNode $c "$indent    " $suf
    }
}

$rootNode = Add-Node ([IO.Path]::GetFileName($Artifact)) $Artifact ''
$tree.tree = @($rootNode)
$tree.dedup = @($seen.Keys | Where-Object { $_ } | Sort-Object)
$tree | ConvertTo-Json -Depth 64 | Set-Content "$OutBase.json"

$MDFile = "$OutBase.md"
[IO.File]::WriteAllText($MDFile, '')
if ($rootNode) { Emit-TreeNode $rootNode '' '' }
Write-Output "deps_tree: $OutBase.json"
Write-Output "deps_tree: $OutBase.md"
exit 0
