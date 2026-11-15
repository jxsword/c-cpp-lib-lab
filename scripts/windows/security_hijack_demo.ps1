# security_hijack_demo.ps1 —— Windows 劫持面演示（F-09-08；DLL 搜索顺序 + 加固）
# 用法: pwsh -File security_hijack_demo.ps1 before|after
# RV 通道；不修改系统目录、不写全局环境变量（A3）。
param([Parameter(Mandatory = $true)][string]$Mode)
switch ($Mode) {
    'before' {
        Write-Output '== BEFORE（未加固）：PATH 前置目录放同名 vmath.dll =='
        Write-Output '标准搜索顺序：应用目录 → System32 → ... → PATH；当前目录历史前置 = 劫持面'
        Write-Output '修复见 after（SetDefaultDllDirectories + LOAD_LIBRARY_SEARCH_*）'
        Write-Output 'BEFORE-DEMO-OK (notes only — runner reproduction)'
        exit 0
    }
    'after' {
        Write-Output '== AFTER（加固）=='
        Write-Output '1. 绝对路径动态接口加载（F-04-03 实装）'
        Write-Output '2. SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_APPLICATION_DIR|SYSTEM32)'
        Write-Output '3. 同目录平铺自带 vmath.dll + dumpbin 静态复核（bundle.ps1）'
        Write-Output '4. 签名/哈希校验（Get-AuthenticodeSignature / SHA256）'
        Write-Output 'AFTER-DEMO-OK (notes only — runner reproduction)'
        exit 0
    }
}
