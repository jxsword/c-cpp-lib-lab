# scripts/common.ps1 —— Windows 通用辅助（F-04-02；由 scripts/windows/*.ps1 dot-source）
# 不调用 GitHub CLI（9.4 J7）。

function Write-Pass([string]$msg) { Write-Output "PASS: $msg" }
function Write-Fail([string]$msg) { Write-Output "FAIL: $msg"; $script:viol = 1 }
function Write-Note([string]$msg) { Write-Output "NOTE: $msg" }

# 组合标签：<os>_<toolset>_<variant>_<cfg>（PLAN 1.3）
function Get-ComboTag([string]$Toolset, [string]$Variant, [string]$Cfg) {
    "win_${Toolset}_${Variant}_${Cfg}"
}

# D2：源码树无产物（排除 build/ 与 .git/）
function Assert-NoArtifacts([string]$Root) {
    $patterns = @('*.o', '*.obj', '*.a', '*.lib', '*.so', '*.dll', '*.dylib', '*.pdb')
    $found = Get-ChildItem -LiteralPath $Root -Recurse -File -Include $patterns -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/](build|\.git)[\\/]' }
    @($found).Count -eq 0
}

# variant → MSVC 机器标志与 CRT（/MD 或 /MT；Debug 自动 /MDd /MTd，7.1）
function Get-MsvcCrtFlag([string]$Variant, [string]$Cfg) {
    $base = if ($Variant -match 'MD$') { '/MD' } else { '/MT' }
    if ($Cfg -eq 'Debug') { "${base}d" } else { $base }
}

# msys2 四环境 → 工具链前缀（C8：四环境独立目录不混链）
# setup-msys2@v2 默认安装到 $env:RUNNER_TEMP\msys64；本机调试（无 RUNNER_TEMP）回退 C:\msys64
function Get-Msys2ToolPrefix([string]$Variant) {
    $root = if ($env:RUNNER_TEMP) { Join-Path $env:RUNNER_TEMP 'msys64' } else { 'C:\msys64' }
    switch ($Variant) {
        'MINGW64'  { Join-Path $root 'mingw64\bin\gcc.exe' }
        'MINGW32'  { Join-Path $root 'mingw32\bin\gcc.exe' }
        'UCRT64'   { Join-Path $root 'ucrt64\bin\gcc.exe' }
        'CLANG64'  { Join-Path $root 'clang64\bin\clang.exe' }
        default    { $null }
    }
}
