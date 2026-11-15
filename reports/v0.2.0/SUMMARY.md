# reports/v0.2.0/SUMMARY.md —— M2 里程碑分析摘要（R-02）

> D7 汇总：M2 = ① 原生 Linux 4 组合（linux_gcc_{x86,x64}_{Debug,Release}）× 2 形态（static/shared）= **8 个组合形态**，每形态 **10 项 SA + 4 项 RV** 结论齐全（`reports/<组合标签>/native/*.md` + `reports/<组合标签>/run/*.txt`）。全部 SA 结论来自三层**静态**分析（file/readelf/nm/ar/strings → lddtree/patchelf/llvm-* → 自实现归一），未运行任何被测程序；RV 为独立 run.sh 通道（`--self-test`/`info`/`add`/`dot`/`--dynamic`）。

## 覆盖与结论矩阵

| 组合形态 | SA-1…SA-10 | RV-1…RV-4 | 报告 |
|---|---|---|---|
| linux_gcc_x86_Debug/static · shared | 10/10 PASS | 7/7 capture PASS | `linux_gcc_x86_Debug/{native,run}/` |
| linux_gcc_x86_Release/static · shared | 10/10 PASS | 7/7 capture PASS | 同上 |
| linux_gcc_x64_Debug/static · shared | 10/10 PASS | 7/7 capture PASS | 同上 |
| linux_gcc_x64_Release/static · shared | 10/10 PASS | 7/7 capture PASS | 同上 |

RV 计数说明：RV-1（self-test）+ RV-2（info）+ RV-3×3（add/dot 成功/dot 维度错误）+ RV-4×2（dynamic 成功/bad-path；仅 shared）= static 5 项、shared 7 项。

## 跨形态发现（如实记录）

1. **`normalize_` 在 Release(-O2) 静态库被内联消失**（Debug 为局部 `t`）——导出表目标（不出现在任何导出表）两种形态均达成；引擎按「无全局符号即 PASS」如实记录。
2. **x86 静态库额外含 `__x86.get_pc_thunk.ax`**（i386 PIE 编译器辅助符号，非项目符号）——SA-5 判定已豁免该类符号。
3. **依赖树符号链接 realpath（断言）**：`libvmath.so → libvmath.so.1.0.0`、`libvmath.so.1 → libvmath.so.1.0.0` 链条 + `readlink -f` realpath 在全部 shared 形态 deps JSON 中记录（`symlink_chains` + 节点 `real` 字段）。
4. **分类**：依赖树 origin = bundle（build/ 前缀）/ system（/usr 系）；x86-64 归类优先（曾修正 ldconfig 命中 x32 ABI 的缺陷）。

## 门禁状态

- `scan_dynamic_calls.sh` 零命中（5.8.4 禁令）✓
- `verify_card.sh`：F-00-01…F-02-05 共 15 卡基线全 PASS（D1 唯一入口）✓
- 缓存 composite action 演练命中：`gh workflow run cache-drill.yml --ref develop` → run 43735529615 **success**（warm miss→save + verify 双命中）✓
- lint 门禁为 develop/main 必需检查（strict）✓
