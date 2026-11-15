# verify_make32.ps1 —— 32 组合横向对比·Windows 版（F-05-04；与 bash 版同构口径）
# 证明 32 = GNU make 14 + nmake 10 + MSBuild 8；清单与差异记录同 reports/v0.5.0/SUMMARY.md。
param()
$ErrorActionPreference = 'Stop'
$list = @(
    @('gnu','linux','gcc','x86','Debug'), @('gnu','linux','gcc','x86','Release'),
    @('gnu','linux','gcc','x64','Debug'), @('gnu','linux','gcc','x64','Release'),
    @('gnu','macos','clang','arm64','Debug'), @('gnu','macos','clang','arm64','Release'),
    @('gnu','msys2','gcc','MINGW64','Debug'), @('gnu','msys2','gcc','MINGW64','Release'),
    @('gnu','msys2','gcc','MINGW32','Debug'), @('gnu','msys2','gcc','MINGW32','Release'),
    @('gnu','msys2','gcc','CLANG64','Debug'), @('gnu','msys2','gcc','CLANG64','Release'),
    @('gnu','msys2','gcc','UCRT64','Debug'), @('gnu','msys2','gcc','UCRT64','Release'),
    @('nmake','windows','msvc','x86_MD','Debug'), @('nmake','windows','msvc','x86_MD','Release'),
    @('nmake','windows','msvc','x86_MT','Debug'), @('nmake','windows','msvc','x86_MT','Release'),
    @('nmake','windows','msvc','x64_MD','Debug'), @('nmake','windows','msvc','x64_MD','Release'),
    @('nmake','windows','msvc','x64_MT','Debug'), @('nmake','windows','msvc','x64_MT','Release'),
    @('nmake','windows','clang-cl','x64','Debug'), @('nmake','windows','clang-cl','x64','Release'),
    @('msbuild','windows','msbuild','x86_MD','Debug'), @('msbuild','windows','msbuild','x86_MD','Release'),
    @('msbuild','windows','msbuild','x86_MT','Debug'), @('msbuild','windows','msbuild','x86_MT','Release'),
    @('msbuild','windows','msbuild','x64_MD','Debug'), @('msbuild','windows','msbuild','x64_MD','Release'),
    @('msbuild','windows','msbuild','x64_MT','Debug'), @('msbuild','windows','msbuild','x64_MT','Release')
)
$viol = 0
Write-Output '== A1: 32 行矩阵无重复标签 =='
$uniq = ($list | ForEach-Object { $_ -join '_' } | Sort-Object -Unique).Count
if ($list.Count -eq 32 -and $uniq -eq 32) { Write-Output 'PASS: 32 行、32 个唯一标签' } else { Write-Output "FAIL: count=$($list.Count) uniq=$uniq"; $viol = 1 }
Write-Output '== A2: 三方言集合与 5.5.2 一致 =='
$gnu = @($list | Where-Object { $_[0] -eq 'gnu' }).Count
$nmake = @($list | Where-Object { $_[0] -eq 'nmake' }).Count
$msb = @($list | Where-Object { $_[0] -eq 'msbuild' }).Count
if ($gnu -eq 14 -and $nmake -eq 10 -and $msb -eq 8) { Write-Output "PASS: gnu=$gnu nmake=$nmake msbuild=$msb" } else { Write-Output 'FAIL: dialect counts'; $viol = 1 }
$mdrows = @($list | Where-Object { $_[3] -match '_(MD|MT)$' }).Count
if ($mdrows -eq 16) { Write-Output 'PASS: A4 /MD //MT 为 variant 字段（16 行携带）' } else { Write-Output "FAIL: mdrows=$mdrows"; $viol = 1 }
if ($viol -eq 0) { Write-Output '== 32 组合 parity 验证通过（清单/口径核验）=='; exit 0 }
Write-Output "== $viol 项 FAIL =="
exit 1
