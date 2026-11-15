# run.ps1 —— RV-1…RV-4 运行输出采集·Windows 版（F-04-02；PLAN 5.7.2，C18 隔离）
# stdout+stderr+exit code → reports\<tag>\run\<tag>_<group>_<kind>.txt
# 用法: pwsh -File run.ps1 -Tag win_msvc_x64_MD_Release -Kind shared -Group native
param(
    [Parameter(Mandatory = $true)][string]$Tag,
    [Parameter(Mandatory = $true)][string]$Kind,
    [Parameter(Mandatory = $true)][string]$Group
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\common.ps1"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$bin = Join-Path $root "build\$Group\$Tag\$Kind\calctool.exe"
$outDir = Join-Path $root "reports\$Tag\run"
$outFile = Join-Path $outDir "${Tag}_${Group}_${Kind}.txt"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
if (-not (Test-Path $bin)) { Write-Fail "executable not found: $bin"; exit 1 }

$script:viol = 0
function Capture([string]$rv, [int]$want, [string[]]$cmdArgs) {
    $lines = @("===== $rv =====", ('> ' + ($cmdArgs -join ' ')))
    $p = Start-Process -FilePath $cmdArgs[0] -ArgumentList $cmdArgs[1..($cmdArgs.Count - 1)] -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$env:TEMP\rv_out.txt" -RedirectStandardError "$env:TEMP\rv_err.txt"
    $lines += (Get-Content "$env:TEMP\rv_out.txt" -ErrorAction SilentlyContinue)
    $lines += (Get-Content "$env:TEMP\rv_err.txt" -ErrorAction SilentlyContinue)
    $rc = $p.ExitCode
    $lines += "----- exit code: $rc (expect $want) -----"
    $lines + '' | Add-Content $outFile
    if ($rc -ne $want) { Write-Fail "$rv: exit=$rc want=$want" } else { Write-Pass "$rv: exit=$rc ($Tag/$Kind)" }
}

Capture 'RV-1' 0 @($bin, '--self-test')
Capture 'RV-2' 0 @($bin, 'info')
Capture 'RV-3' 0 @($bin, 'add', '1.5', '2.5')
Capture 'RV-3' 0 @($bin, 'dot', '1,2,3', '4,5,6')
Capture 'RV-3' 2 @($bin, 'dot', '1,2', '1,2,3')

if ($Kind -eq 'shared') {
    $libdir = Split-Path -Parent $bin
    Capture 'RV-4' 0 @($bin, '--dynamic', "$libdir\vmath.dll", 'add', '1', '2')
    Capture 'RV-4' 2 @($bin, '--dynamic', 'C:\nonexistent\vmath.dll', 'add', '1', '2')
}
else {
    Add-Content $outFile "===== RV-4 =====`n(static form: dynamic loading demo not applicable)`n"
}
if ($script:viol -eq 0) { Write-Pass "run capture: $outFile"; exit 0 }
Write-Fail 'run capture: violations'
exit 1
