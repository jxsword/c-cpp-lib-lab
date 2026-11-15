# reports/TEMPLATE.md —— 单组合静态分析报告模板（F-02-04）

`scripts/linux/analyze.sh <tag> <kind> <group>` 生成的单组合报告遵循本模板；
汇总脚本（F-02-05 / F-09）按固定列数解析。目录约定：

```
reports/<milestone-tag>/<group>/<组合标签>_<kind>.md   # SA 结论矩阵 + 导出集区分
reports/<milestone-tag>/deps/<组合标签>_<kind>.json     # SA-8 依赖树（结构化）
reports/<milestone-tag>/deps/<组合标签>_<kind>.md       # 缩进树（人读）
reports/<milestone-tag>/<group>/layer1/ layer2/         # 层①②原始输出（不入库）
```

## 报告结构（固定节与固定列数）

| 节 | 表头列数 | 内容 |
|---|---|---|
| SA 结论矩阵 | 3 列 | `| # | 结论 | 证据 |`，SA-1…SA-10 各一行，无 N/A |
| 导出集区分 | 3 列 | `| 项 | 结果 | 明细 |`：API 导出集（恰 6）/ gcc 裸符号 vmath_errno（默认可见性=导出；`-fvisibility=hidden`=隐藏，如实记录）/ normalize_ 不在动态导出表 |

## 生成方式

```bash
./scripts/linux/analyze.sh linux_gcc_x64_Release shared native
```

1. 调用 `static_analyze.sh`（三层引擎：layer1/layer2 原始输出 + SA 判定 + 依赖树）；
2. 依赖树移至 `reports/<tag>/deps/`（与 SA 报告分离）；
3. 追加「导出集区分」节（要点要求的 6 API 与 gcc 裸符号区分）；
4. 列数一致性自检（A4）。
