# reports/v1.0.0/SUMMARY.md —— 80 组合汇总矩阵（Gate C）

> 每行 = 一个组合标签；状态列：✅ 实跑全绿 / 🕐 脚本就绪待 runner（F-09-02…04 dispatch）。**六类跨平台差异**在表后逐条标注（默认导出 / ordinal / CRT / Debug-Release 布局 / mangling / macOS 架构）。

## ① 原生（native）— 24 组合

| # | 组合标签 | 构建方式 | 状态 | SA 报告 | RV 报告 |
|---|---|---|---|---|---|
| 1 | linux_gcc_x86_Debug | native | ✅ 实跑全绿 | — | — |
| 2 | linux_gcc_x86_Release | native | ✅ 实跑全绿 | — | — |
| 3 | linux_gcc_x64_Debug | native | ✅ 实跑全绿 | — | — |
| 4 | linux_gcc_x64_Release | native | ✅ 实跑全绿 | — | — |
| 5 | macos_clang_arm64_Debug | native | 🕐 待 runner | — | — |
| 6 | macos_clang_arm64_Release | native | 🕐 待 runner | — | — |
| 7 | windows_msvc_x86_MD_Debug | native | 🕐 待 runner | — | — |
| 8 | windows_msvc_x86_MD_Release | native | 🕐 待 runner | — | — |
| 9 | windows_msvc_x86_MT_Debug | native | 🕐 待 runner | — | — |
| 10 | windows_msvc_x86_MT_Release | native | 🕐 待 runner | — | — |
| 11 | windows_msvc_x64_MD_Debug | native | 🕐 待 runner | — | — |
| 12 | windows_msvc_x64_MD_Release | native | 🕐 待 runner | — | — |
| 13 | windows_msvc_x64_MT_Debug | native | 🕐 待 runner | — | — |
| 14 | windows_msvc_x64_MT_Release | native | 🕐 待 runner | — | — |
| 15 | win_msys2_MINGW64_Debug | native | 🕐 待 runner | — | — |
| 16 | win_msys2_MINGW64_Release | native | 🕐 待 runner | — | — |
| 17 | win_msys2_MINGW32_Debug | native | 🕐 待 runner | — | — |
| 18 | win_msys2_MINGW32_Release | native | 🕐 待 runner | — | — |
| 19 | win_msys2_CLANG64_Debug | native | 🕐 待 runner | — | — |
| 20 | win_msys2_CLANG64_Release | native | 🕐 待 runner | — | — |
| 21 | win_msys2_UCRT64_Debug | native | 🕐 待 runner | — | — |
| 22 | win_msys2_UCRT64_Release | native | 🕐 待 runner | — | — |
| 23 | win_clangcl_x64_Debug | native | 🕐 待 runner | — | — |
| 24 | win_clangcl_x64_Release | native | 🕐 待 runner | — | — |
## ② make 组 — 32 组合（GNU 14 + nmake 10 + MSBuild 8）

| # | 组合标签 | 构建方式 | 状态 | SA 报告 | RV 报告 |
|---|---|---|---|---|---|
| 1 | linux_gcc_x86_Debug | make/gnu | ✅ 实跑全绿 | — | — |
| 2 | linux_gcc_x86_Release | make/gnu | ✅ 实跑全绿 | — | — |
| 3 | linux_gcc_x64_Debug | make/gnu | ✅ 实跑全绿 | — | — |
| 4 | linux_gcc_x64_Release | make/gnu | ✅ 实跑全绿 | — | — |
| 5 | macos_clang_arm64_Debug | make/gnu | 🕐 待 runner | — | — |
| 6 | macos_clang_arm64_Release | make/gnu | 🕐 待 runner | — | — |
| 7 | win_msys2_MINGW64_Debug | make/gnu | 🕐 待 runner | — | — |
| 8 | win_msys2_MINGW64_Release | make/gnu | 🕐 待 runner | — | — |
| 9 | win_msys2_MINGW32_Debug | make/gnu | 🕐 待 runner | — | — |
| 10 | win_msys2_MINGW32_Release | make/gnu | 🕐 待 runner | — | — |
| 11 | win_msys2_CLANG64_Debug | make/gnu | 🕐 待 runner | — | — |
| 12 | win_msys2_CLANG64_Release | make/gnu | 🕐 待 runner | — | — |
| 13 | win_msys2_UCRT64_Debug | make/gnu | 🕐 待 runner | — | — |
| 14 | win_msys2_UCRT64_Release | make/gnu | 🕐 待 runner | — | — |
| 15 | win_nmake_x86_MD_Debug | make/nmake | 🕐 待 runner | — | — |
| 16 | win_nmake_x86_MD_Release | make/nmake | 🕐 待 runner | — | — |
| 17 | win_nmake_x86_MT_Debug | make/nmake | 🕐 待 runner | — | — |
| 18 | win_nmake_x86_MT_Release | make/nmake | 🕐 待 runner | — | — |
| 19 | win_nmake_x64_MD_Debug | make/nmake | 🕐 待 runner | — | — |
| 20 | win_nmake_x64_MD_Release | make/nmake | 🕐 待 runner | — | — |
| 21 | win_nmake_x64_MT_Debug | make/nmake | 🕐 待 runner | — | — |
| 22 | win_nmake_x64_MT_Release | make/nmake | 🕐 待 runner | — | — |
| 23 | win_nmake_x64_Debug | make/nmake | 🕐 待 runner | — | — |
| 24 | win_nmake_x64_Release | make/nmake | 🕐 待 runner | — | — |
| 25 | win_msbuild_x86_MD_Debug | make/msbuild | 🕐 待 runner | — | — |
| 26 | win_msbuild_x86_MD_Release | make/msbuild | 🕐 待 runner | — | — |
| 27 | win_msbuild_x86_MT_Debug | make/msbuild | 🕐 待 runner | — | — |
| 28 | win_msbuild_x86_MT_Release | make/msbuild | 🕐 待 runner | — | — |
| 29 | win_msbuild_x64_MD_Debug | make/msbuild | 🕐 待 runner | — | — |
| 30 | win_msbuild_x64_MD_Release | make/msbuild | 🕐 待 runner | — | — |
| 31 | win_msbuild_x64_MT_Debug | make/msbuild | 🕐 待 runner | — | — |
| 32 | win_msbuild_x64_MT_Release | make/msbuild | 🕐 待 runner | — | — |
## ③ CMake — 24 组合（msvc/clang-cl 用 Ninja，S9）

| # | 组合标签 | 构建方式 | 状态 | SA 报告 | RV 报告 |
|---|---|---|---|---|---|
| 1 | linux_gcc_x86_Debug | cmake | ✅ 实跑全绿 | — | — |
| 2 | linux_gcc_x86_Release | cmake | ✅ 实跑全绿 | — | — |
| 3 | linux_gcc_x64_Debug | cmake | ✅ 实跑全绿 | — | — |
| 4 | linux_gcc_x64_Release | cmake | ✅ 实跑全绿 | — | — |
| 5 | macos_clang_arm64_Debug | cmake | 🕐 待 runner | — | — |
| 6 | macos_clang_arm64_Release | cmake | 🕐 待 runner | — | — |
| 7 | windows_msvc_x86_MD_Debug | cmake | 🕐 待 runner | — | — |
| 8 | windows_msvc_x86_MD_Release | cmake | 🕐 待 runner | — | — |
| 9 | windows_msvc_x86_MT_Debug | cmake | 🕐 待 runner | — | — |
| 10 | windows_msvc_x86_MT_Release | cmake | 🕐 待 runner | — | — |
| 11 | windows_msvc_x64_MD_Debug | cmake | 🕐 待 runner | — | — |
| 12 | windows_msvc_x64_MD_Release | cmake | 🕐 待 runner | — | — |
| 13 | windows_msvc_x64_MT_Debug | cmake | 🕐 待 runner | — | — |
| 14 | windows_msvc_x64_MT_Release | cmake | 🕐 待 runner | — | — |
| 15 | win_msys2_MINGW64_Debug | cmake | 🕐 待 runner | — | — |
| 16 | win_msys2_MINGW64_Release | cmake | 🕐 待 runner | — | — |
| 17 | win_msys2_MINGW32_Debug | cmake | 🕐 待 runner | — | — |
| 18 | win_msys2_MINGW32_Release | cmake | 🕐 待 runner | — | — |
| 19 | win_msys2_CLANG64_Debug | cmake | 🕐 待 runner | — | — |
| 20 | win_msys2_CLANG64_Release | cmake | 🕐 待 runner | — | — |
| 21 | win_msys2_UCRT64_Debug | cmake | 🕐 待 runner | — | — |
| 22 | win_msys2_UCRT64_Release | cmake | 🕐 待 runner | — | — |
| 23 | win_clangcl_x64_Debug | cmake | 🕐 待 runner | — | — |
| 24 | win_clangcl_x64_Release | cmake | 🕐 待 runner | — | — |

## 六类跨平台差异（显式标注，F-09-05 要点）

| # | 差异 | 说明 | 落档位置 |
|---|---|---|---|
| 1 | **默认导出** | gcc/MinGW 默认导出全部符号（含裸 `vmath_errno`）；MSVC 默认不导出、`.def` 是唯一白名单；clang-cl 同 MSVC | F-01-02/F-02-03 SA-5 |
| 2 | **ordinal** | 仅 PE 存在；`@5 NONAME` 的 `vmath_build_info` 只能按 ordinal 5 取址；ELF/Mach-O 用函数表成员位置替代 | 5.3 / F-02-02 / F-04-03 |
| 3 | **CRT** | `/MD`↔`/MDd`、`/MT`↔`/MTd` 随 CFG；跨 CRT 传 STL 堆对象即崩溃（反例 F-08-04） | 5.5.1 / F-05-03 |
| 4 | **Debug-Release 布局** | Debug 调试段/pdb/`_DEBUG` 标记；`_ITERATOR_DEBUG_LEVEL` 布局差异 | SA-3 / F-08-04 |
| 5 | **mangling** | Itanium `_Z*` vs MSVC `?*@@`——跨编译器不可互链 → 门面 C ABI（F-08-03） | F-08-02 A4 |
| 6 | **macOS 架构** | arm64 主组合；x86_64 与 `lipo` universal 为附加不计数组覆盖；32 位 SKIP（10.15） | F-04-01 / 5.6 C1 |

**状态口径**：✅ = Linux 侧实跑全绿（本机证据链）；🕐 = 脚本就绪，产物级实证由 F-09-02…04 的 dispatch 在各 OS runner 执行（R-09 收尾批量取证）。
