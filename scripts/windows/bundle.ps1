# bundle.ps1 —— Windows 打包：exe 同目录平铺 DLL（F-09-07；PLAN 9.1）
# 布局：build\bundle\<tag>\<kind>\{calctool.exe, vmath.dll, LICENSE, NOTICE}
# 不打 KnownDLLs/系统 DLL；排除 Debug CRT（*d.dll）；dumpbin /dependents 静态复核。
param(
    [string]$Tag = 'win_msvc_x64_MD_Release',
    [string]$Kind = 'shared',
    [string]$Group = 'native'
)
$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\..\common.ps1"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$src = Join-Path $root "build\$Group\$Tag\$Kind"
$b = Join-Path $root "build\bundle\$Tag\$Kind"
if (-not (Test-Path (Join-Path $src 'calctool.exe'))) { Write-Fail "artifact not found: $src\calctool.exe"; exit 1 }

New-Item -ItemType Directory -Force -Path $b | Out-Null
Copy-Item (Join-Path $src 'calctool.exe') $b -Force
if ($Kind -eq 'shared') {
    Copy-Item (Join-Path $src 'vmath.dll') $b -Force -ErrorAction SilentlyContinue
}

# A4：排除 Debug CRT（*d.dll 绝不入包）
$debugDlls = Get-ChildItem $src -Filter '*d.dll' -ErrorAction SilentlyContinue
foreach ($d in $debugDlls) { Write-Fail "Debug CRT DLL must not be bundled: $($d.Name)" }

# A3：静态复核（dumpbin /dependents 只读）
$dumpbin = Get-Command dumpbin -ErrorAction SilentlyContinue
if ($dumpbin) {
    & dumpbin /dependents (Join-Path $b 'calctool.exe') | Out-File (Join-Path $b 'dependents.txt')
    foreach ($dep in (Get-Content (Join-Path $b 'dependents.txt') | Where-Object { $_ -match '^\s+\S+\.dll$' })) {
        $name = $dep.Trim()
        if ($name -eq 'vmath.dll') { Write-Pass "bundle dep $name" }
        elseif ($name -match '^(ntdll|kernel32|user32|ucrtbase|VCRUNTIME140)\.dll$') { Write-Pass "system dep $name (not bundled, per 9.1)" }
        else { Write-Note "dep $name" }
    }
}
else { Write-Note 'dumpbin unavailable (deferred to runner)' }

# A5：LICENSE/NOTICE
Copy-Item (Join-Path $root 'LICENSE') $b -Force
Set-Content (Join-Path $b 'NOTICE') "c-cpp-lib-lab - MIT License (see LICENSE). No third-party libraries bundled."
Write-Pass 'LICENSE + NOTICE bundled'

Write-Output "bundle OK: $b"
