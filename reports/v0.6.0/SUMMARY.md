# reports/v0.6.0/SUMMARY.md —— M6 里程碑摘要（R-06 · **Gate B 达成**）

> D7 汇总：M6 = ③ CMake 三 OS 24 组合收口。**执行口径**：Linux 8 形态实跑全绿；macOS/Windows 16 形态脚本就绪、产物级实证委托 F-09-02 runner（Gate B 全程口径，如实分列）。

## 三组构建方式口径（A4：24 / 32 / 24 = 80）

| 组 | 方言 | 组合数 | Linux 实跑 | mac/win 实证 | 报告 |
|---|---|---|---|---|---|
| ① native | 编译器原生命令 | **24**（Linux 4 + macOS 2 + Windows 18） | Linux 8 形态全绿（M2） | F-04-01/02 脚本就绪 → F-09-02 | `reports/<tag>/native/` |
| ② make | GNU 14 + nmake 10 + MSBuild 8 | **32** | GNU Linux 8 形态全绿（M5） | F-05-01/02/03 就绪 → F-09-02 | `reports/<tag>/make/{gnu,nmake,msbuild}/` |
| ③ cmake | CMake（msvc/clang-cl 用 Ninja，S9） | **24** | Linux 8 形态全绿（M3/M6） | F-06-01 就绪 → F-09-02 | `reports/<tag>/cmake/` |

**合计 80 组合**——三组口径、组合标签、双形态（P3）完全一致，目录互不重叠（A3/SA-10：native `build/native/`、make `build/make/{gnu,nmake,msbuild}/`、cmake `build/cmake/`）。

## CTest 三类用例（F-06-02）

| # | 用例 | 形态 | 判据 |
|---|---|---|---|
| 1 | self-test | 全部 | 退出码 0（CI 唯一功能判据） |
| 2 | probe-deps | 全部 | stdout 含 `type sizes`（依赖判定/内置清单） |
| 3 | info-fields | 全部 | stdout 含 `bits=`（组合自证） |
| 4 | dynamic-load | 仅 shared（RV 通道） | `--dynamic $<TARGET_FILE:vmath>` 退出 0 |

Linux 实测：static 3/3、shared 4/4 全绿（A2 每组合 ≥3 ✓）。

## RPATH/路径断言（A3）

- BUILD_RPATH `$ORIGIN`（构建树）↔ INSTALL_RPATH `$ORIGIN/../lib`（install 树）两阶段差异实证（F-03-02）。
- `CMAKE_BUILD_RPATH_USE_ORIGIN` 为 install 改写可靠性前提（M3 实测坑位，已入 baseline）。
- SA-10 三 OS 口径：ELF RUNPATH / Mach-O LC_RPATH / PE 搜索顺序（分析脚本就绪，实测随 runner）。

## Gate B 达成判定

| 判据 | 状态 |
|---|---|
| ① 原生 24（脚本 + Linux 实跑） | ✅ |
| ② make 32（GNU 实跑 + nmake/MSBuild 就绪） | ✅ |
| ③ CMake 24（Linux 实跑 + mac/win 就绪） | ✅ |
| C++ 阶段 2/3（M7/M8） | ⏭ 下一阶段（Gate B 完整达成在 M8） |

> 注：计划 2.4 定义 Gate B 于 **M8**（纯 C++ OOP 完成）；M6 仅完成 80 组合构建矩阵的三 OS 口径收口。
