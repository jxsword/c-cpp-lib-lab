# verify_card.ps1 —— D1 断言验收入口·Windows 版（F-04-02；与 scripts/verify_card.sh 同构）
# 受限指令集：action ∈ {run, exists, script}（Windows 侧简化集）；
# script 仅允许 scripts\ 前缀仓库脚本。不执行 yml 任意 shell（对齐 bash 版安全设计）。
# 用法: pwsh -File scripts/verify_card.ps1 <卡号>
param([Parameter(Mandatory = $true)][string]$CardId)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot\..").Path
$yml = Join-Path $root "tests\assertions\$CardId.yml"
if (-not (Test-Path $yml)) { Write-Output "FAIL: assertion file not found: $yml"; exit 1 }

$script:viol = 0
$rows = 0
Write-Output '| # | 断言 | 检查 | PASS/FAIL |'
Write-Output '|---|---|---|---|'

$id = ''; $action = ''; $args_ = @(); $expect = ''
function Invoke-Flush {
    if (-not $script:id) { return }
    $script:rows++
    $out = ''
    $rc = 0
    try {
        switch ($script:action) {
            'run'    { $prog = $script:args_[0]; $rest = @($script:args_ | Select-Object -Skip 1); $out = (& $prog @rest 2>&1 | Out-String); $rc = $LASTEXITCODE }
            'exists' { $rc = if (Test-Path $script:args_[0]) { 0 } else { 1 } }
            'script' {
                $prog = $script:args_[0]
                if ($prog -notmatch '^\.\\scripts\\') { throw "script restricted to scripts\: $prog" }
                $rest = @($script:args_ | Select-Object -Skip 1)
                $out = (& $prog @rest 2>&1 | Out-String)
                $rc = $LASTEXITCODE
            }
            default  { throw "unknown action: $($script:action)" }
        }
    } catch { $out = $_.Exception.Message; $rc = 125 }
    $ok = switch -Wildcard ($script:expect) {
        'exit0'      { $rc -eq 0 }
        'exit:*'     { $rc -eq [int]($script:expect -replace 'exit:', '') }
        'regex:*'    { ($out -match ($script:expect -replace 'regex:', '')) }
        default      { $false }
    }
    $detail = "$($script:action) $($script:args_ -join ' ')"
    if ($ok) { Write-Output "| $($script:id) | $($script:id) | ``$detail`` | PASS |" }
    else {
        Write-Output "| $($script:id) | $($script:id) | ``$detail`` | FAIL (rc=$rc) |"
        $script:viol = 1
    }
    $script:id = ''; $script:action = ''; $script:args_ = @(); $script:expect = ''
}

foreach ($line in (Get-Content $yml)) {
    if ($line -match '^  - id: (.+)$')         { Invoke-Flush; $script:id = $Matches[1] }
    elseif ($line -match '^    action: (.+)$') { $script:action = $Matches[1] }
    elseif ($line -match '^    args: (.+)$')   { $script:args_ = $Matches[1] -split '\s+' }
    elseif ($line -match '^    expect: (.+)$') { $script:expect = $Matches[1] }
}
Invoke-Flush

if ($script:viol -eq 0) { Write-Output "`nverify_card: $CardId — $rows checks, all PASS"; exit 0 }
Write-Output "`nverify_card: $CardId — FAILED"
exit 1
