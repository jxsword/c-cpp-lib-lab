# reports/v0.3.0/SUMMARY.md —— M3 里程碑摘要（R-03 · **Gate A**）

> D7 汇总：**Gate A 判定 = ① 原生 Linux 4 组合 + ③ CMake Linux 4 组合（各 × static/shared 双形态 = 16 个组合形态）全部构建 + 自测绿；SA-1…SA-10 与 RV-1…RV-4 结论齐全**。全部 SA 来自三层静态分析；RV 为独立 run.sh 通道。

## 覆盖矩阵

| 组 | 组合 | 形态 | build | ctest/self-test | SA-1…SA-10 | RV | 报告 |
|---|---|---|---|---|---|---|---|
| ① native | linux_gcc_{x86,x64}_{Debug,Release} | static + shared | 8/8 | 8/8 | 8 份全 PASS | 8 份 | `reports/<tag>/native/`（M2 期生成） |
| ③ cmake | 同上 4 组合 | static + shared | 8/8 | 8/8（CTest） | 8 份全 PASS | 8 份 | `reports/<tag>/native/`（analyze.sh group=cmake）+ 本目录收齐 SA 8 份 |

## Gate A 判据核对

| 判据 | 结论 | 证据 |
|---|---|---|
| ① 原生 Linux 4 × 双形态全绿 | **PASS** | `verify_card.sh F-02-01` 8/8（M2，v0.2.0 发布内容） |
| ③ CMake Linux 4 × 双形态全绿 | **PASS** | `verify_card.sh F-03-01` 7/7 + `F-03-02` 6/6（M3，PR #39/#40） |
| SA/RV 报告齐全 | **PASS** | SA 16 份（native 8 + cmake 8）、RV 16 份（native + cmake，run.sh 输出含 group 维度） |
| 编码 lint | **PASS** | develop/main 必需检查 strict；全部 PR checks pass |
| 缓存命中 | **PASS** | cache-drill run 43735529615 success（v0.2.0 期取证；机制随 PR paths 持续复证） |
| verify_card.sh 全回归 | **PASS** | F-00-01…F-03-02 共 17 卡基线全 PASS |
| README 单平台声明 | **PASS** | README「当前范围」节：仅 Linux 单平台；三 OS 见 M4–M6 |

## 跨形态发现（M3 期新增）

1. **CMake install RPATH 改写**：对绝对构建路径 RUNPATH，`file(RPATH_CHANGE)` 因格式不匹配报错；`CMAKE_BUILD_RPATH_USE_ORIGIN ON` 后构建树 `$ORIGIN`、install 树 `$ORIGIN/../lib`（两阶段差异实证）。
2. **CMake Debug 形态**：默认不定义 `_DEBUG`（`cfg=no-NDEBUG` + 7 个调试段）——SA-3 按双合法形态判定。
3. **run.sh 输出补 group 维度**：`${TAG}_${GROUP}_${KIND}.txt`（消除 native/cmake 同名覆盖隐患）。
