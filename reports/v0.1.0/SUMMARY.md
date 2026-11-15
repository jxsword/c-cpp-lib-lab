# reports/v0.1.0/SUMMARY.md —— M1 里程碑静态分析摘要（R-01）

> 依据 D7 生成：本里程碑仅 M1（纯 C 单平台 Linux/gcc/x64/Release），SA-1…SA-6 按实测填写，SA-7…SA-10（依赖树框架属 F-02-03）与 RV-1…RV-4（F-02-05）标 N/A。全部结论来自**静态读取**（file/readelf/nm/strings/ar），未运行任何被测程序、未动态加载（5.8.4）。

## 分析对象

- 四模式编译记录（F-01-06 冒烟，`SMOKE OK: linux_gcc_x64_Release`）：M1 static / M2 shared-build / M3 shared-use / M4 no-lib 全过（均含 `--self-test`）
- 产物：`build/native/smoke/linux_gcc_x64_Release/{libvmath.a, libvmath.so, calctool_m1, calctool_m3, calctool_m4}`

## SA 结论矩阵

| # | 项 | 结论 | 证据（静态读取） |
|---|---|---|---|
| SA-1 | 32/64 架构 | **x64** | `file`/`readelf -h`：x86-64，ELF64 |
| SA-2 | 编译器名+版本 | **gcc 15.2.0** | `readelf -p .comment`：`GCC: (Ubuntu 15.2.0-16ubuntu1) 15.2.0`（与 `gcc --version` 比对一致） |
| SA-3 | Debug/Release | **Release 标签；无调试段；.rodata 标记 `cfg=no-NDEBUG`** | `readelf -S` 无 debug 段；冒烟编译未定义 NDEBUG（如实记录，组合矩阵卡起由 cfg→宏映射保证） |
| SA-4 | 库形态 | **static + shared 双形态齐备（P3）** | `ar t libvmath.a` = core_m1.o report_m1.o；`libvmath.so` 存在（ELF 动态） |
| SA-5 | 导出符号集 | **6 API 全在 + gcc 额外 `vmath_errno`，与 5.2 导出集断言一致** | `nm -D --defined-only libvmath.so`：vmath_add / vmath_build_info / vmath_dot / vmath_errno / vmath_free / vmath_last_error / vmath_set_logger（恰 7 = 6 API + 裸符号） |
| SA-6 | 内部符号 | **`normalize_` 不在动态导出表** | 静态库 `t normalize_`（局部）；`nm -D \| grep normalize_` 0 命中 |
| SA-7 | 直接依赖+符号链接 | N/A | 依赖树框架 F-02-03 |
| SA-8 | 递归依赖树 | N/A | 同上 |
| SA-9 | CRT/运行库模式 | N/A（Linux 单平台无 MSVC CRT 维度） | F-04 系列 |
| SA-10 | 搜索路径 | N/A | F-03-02（RPATH 断言） |
| RV-1…RV-4 | 运行验证 | N/A | RV 通道 F-02-05 起（冒烟内 `--self-test` 为构建侧功能判据，不属 SA） |

## 9 符号清单 ↔ 导出集一致性（R-01 断言 2）

| 5.2 # | 符号 | 预期 | 实测 |
|---|---|---|---|
| 1–6 | vmath_add / vmath_dot / vmath_build_info / vmath_free / vmath_last_error / vmath_set_logger | 动态导出 | 全在（`nm -D`）✓ |
| 7 | vmath_errno | 裸符号：gcc 额外导出、不进 `.def` | 在 `nm -D`（gcc 预期行为）✓ |
| 8 | normalize_ | 任何平台不在导出表 | `nm -D` 无、静态库局部 `t` ✓ |
| 9 | main | calctool 入口（非库导出） | M4 二进制内 ✓ |

## 已知记录

- `.so` 由 `-shared` 直构、无 `SONAME`——M3 的 RPATH/SONAME 断言属 F-03-02，本摘要如实记录。
- 反例（`__imp_vmath_add` 未解析）按预期失败，主流程绿（详见 F-01-06 回执）。
