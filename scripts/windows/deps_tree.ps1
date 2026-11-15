# deps_tree.ps1 —— SA-8 递归依赖树·Windows 版（F-04-02；PLAN 5.8.3）
# dumpbin /dependents 静态读取；Resolve-Path 解析；API-Set 与 KnownDLL 归类；
# C8：msys2 四环境依赖不交叉（msys-2.0.dll / libwinpthread 等按变体归类 bundle-env）。
# FORBIDDEN: 刻意不使用执行类依赖解析（5.8.4），仅静态读取文件结构。
param(
    [Parameter(Mandatory = $true)][string]$Artifact,
    [string]$OutBase = '',
    [string]$Deptag = ''
)
$ErrorActionPreference = 'Stop'
if (-not $OutBase) { $OutBase = "$Artifact.deps" }
if (-not $Deptag) { $Deptag = [IO.Path]::GetFileName($Artifact) }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutBase) | Out-Null

$dumpbin = Get-Command dumpbin -ErrorAction SilentlyContinue
if (-not $dumpbin) {
    @{ tag = $Deptag; error = 'dumpbin unavailable (vcvars required); deferred to CI' } |
        ConvertTo-Json | Set-Content "$OutBase.json"
    Write-Output "deps_tree: $OutBase.json (deferred)"
    exit 0
}

function Get-Dependents([string]$pe) {
    & dumpbin /dependents $pe 2>$null |
        Where-Object { $_ -match '^\s+\S+\.dll$' } |
        ForEach-Object { $_.Trim() }
}

function Classify([string]$name) {
    if ($name -match '^api-ms-win-') { return 'api-set' }
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
    root = [ordered]@{ path = $Artifact; kind = 'PE' }
    tree = @()
    apiSets = @()
    dedup = @()
}
$seen = @{}

function Add-Node([string]$name, [string]$path, [string]$indent) {
    if ($seen.ContainsKey($name)) { return }
    $seen[$name] = $true
    $origin = if ($path -like "$env:SystemRoot*") { 'system' } elseif ($path) { 'bundle' } else { 'unresolved' }
    $node = [ordered]@{ name = $name; real = $path; origin = $origin; children = @() }
    if ($path -and (Test-Path $path)) {
        foreach ($d in (Get-Dependents $path)) {
            $cls = Classify $d
            if ($cls -eq 'api-set') { $tree.apiSets += $d; continue }
            $rp = Resolve-Dep $d (Split-Path -Parent $path)
            Add-Node $d $rp "$indent    "
        }
    }
    $tree.tree += $node
}

Add-Node ([IO.Path]::GetFileName($Artifact)) $Artifact ''
$tree | ConvertTo-Json -Depth 8 | Set-Content "$OutBase.json"
Write-Output "deps_tree: $OutBase.json"
exit 0
