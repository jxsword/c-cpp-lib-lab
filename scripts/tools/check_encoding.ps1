# check_encoding.ps1 — D9 编码/换行校验（Windows 侧，PLAN 5.10 / F-00-04）
# 用法: pwsh -File scripts/tools/check_encoding.ps1 [目标目录]
# 规则与 check_encoding.sh 相同；本文件自身必须为 UTF-8 BOM。
param([string]$Target = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSCommandPath))))
$ErrorActionPreference = 'Stop'
$script:viol = 0
function Report([string]$msg) { Write-Output "FAIL: $msg"; $script:viol = 1 }

$exclude = '\\\.git\\|\\\.mimosa\\|\\\.zcode\\|\\build\\|\\out\\'
$files = Get-ChildItem -LiteralPath $Target -Recurse -File |
  Where-Object { $_.FullName -notmatch $exclude } |
  Sort-Object FullName

foreach ($f in $files) {
  $rel = [IO.Path]::GetRelativePath($Target, $f.FullName)
  $t = if ($f.Name -like '*.ps1') { 'ps1' }
       elseif ($f.Name -like '*.bat' -or $f.Name -like '*.cmd') { 'bat' }
       elseif ($f.Name -like '*.sh') { 'sh' }
       elseif ($f.Name -eq 'Makefile.nmake') { 'nmake' }
       else { 'other' }
  if ($t -eq 'other') { continue }
  $bytes = [IO.File]::ReadAllBytes($f.FullName)
  if ($bytes.Length -eq 0) {
    if ($t -eq 'ps1') { Report "${rel}: 空 ps1 缺 UTF-8 BOM" }
    continue
  }
  $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
  $cr = 0; $lf = 0
  foreach ($b in $bytes) { if ($b -eq 13) { $cr++ } elseif ($b -eq 10) { $lf++ } }
  switch ($t) {
    'ps1'   { if (-not $hasBom) { Report "${rel}: ps1 缺 UTF-8 BOM（前 3 字节非 EF BB BF）" } }
    'bat'   { if ($hasBom) { Report "${rel}: bat 有 BOM（禁止，cmd.exe 无法识别）" }
              if ($cr -ne $lf) { Report "${rel}: bat 换行非法（CR=$cr LF=$lf，需 CRLF 且无裸 LF）" } }
    'sh'    { if ($hasBom) { Report "${rel}: sh 有 BOM（禁止）" }
              if ($cr -ne 0) { Report "${rel}: sh 含 CR（需纯 LF）" } }
    'nmake' { if ($cr -ne $lf) { Report "${rel}: Makefile.nmake 需 CRLF（CR=$cr LF=$lf）" } }
  }
  try { [Text.UTF8Encoding]::new($false, $true).GetString($bytes) | Out-Null }
  catch { Report "${rel}: 非 UTF-8 编码" }
}

if ($script:viol -eq 0) {
  Write-Output "OK: 编码/换行检查全部通过（目标: $Target）"
  exit 0
}
Write-Output '发现违规，exit 1'
exit 1
