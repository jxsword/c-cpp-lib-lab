# env.ps1 — Windows 环境自检样例（F-00-04；薄入口 env.bat 调用本脚本，PLAN 5.10）
Write-Host 'c-cpp-lib-lab environment check'
$tools = @('git', 'cmake', 'ninja')
foreach ($t in $tools) {
  $cmd = Get-Command $t -ErrorAction SilentlyContinue
  if ($cmd) { Write-Host "  [ok] $t -> $($cmd.Source)" }
  else      { Write-Host "  [--] $t not found" }
}
exit 0
