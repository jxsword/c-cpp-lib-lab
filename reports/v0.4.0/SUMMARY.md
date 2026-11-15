# reports/v0.4.0/SUMMARY.md —— M4 里程碑摘要（R-04 · Gate B 推进中）

> D7 汇总：M4 = 24 组合矩阵的三 OS 脚本矩阵 + 静态分析三层扩展 + 约束记录收口。**执行口径（Gate B 特有）**：Linux 组合本地实跑全绿；macOS/Windows 组合为「脚本先行、产物级实证委托 F-09-02 各 OS runner CI」——本摘要如实分列实跑/待跑，不虚报。

## 24 组合状态矩阵（× static/shared 双形态）

| 组 | 组合 | 形态 | 脚本 | 构建/自测 | SA-1…SA-10 | RV | 报告 |
|---|---|---|---|---|---|---|---|
| ① native Linux | linux_gcc_{x86,x64}_{Debug,Release} | static+shared | ✅ F-02-01 | **实跑 8/8 绿**（M2） | 8 份全 PASS | 8 份 | `reports/<tag>/native/` |
| ③ cmake Linux | 同上 4 组合 | static+shared | ✅ F-03-01/02 | **实跑 8/8 绿**（M3） | 8 份全 PASS | 8 份 | 同上（group=cmake）+ `reports/v0.3.0/` |
| ① native macOS | macos_clang_arm64_{Debug,Release}（x86_64 附加） | static+shared | ✅ F-04-01 | 待 F-09-02 macos runner | 脚本就绪（A6 SKIP 实测） | 脚本就绪 | CI 生成 |
| ① native Windows msvc | win_msvc_{x86,x64}_{MD,MT}_{Debug,Release} | static+shared | ✅ F-04-02 | 待 F-09-02 windows runner | 脚本就绪 | 脚本就绪 | CI 生成 |
| ① native Windows msys2 | win_msys2_{MINGW64,MINGW32,CLANG64,UCRT64}_{Debug,Release} | static+shared | ✅ F-04-02 | 待 CI | 脚本就绪 | 脚本就绪 | CI 生成 |
| ① native Windows clang-cl | win_clangcl_x64_{Debug,Release} | static+shared | ✅ F-04-02 | 待 CI | 脚本就绪 | 脚本就绪 | CI 生成 |

## Gate B 期间的关键技术产出（M4）

1. **三 OS JSON schema 统一**（F-04-04）：`root{path,arch,compiler,cfg}` + `tree{name,logical,real,origin,children}` + `symlink_chains`/`dedup`——Linux 侧实跑实证四字段。
2. **平台 RV 动态加载**：Unix dlopen（F-02-02，实测）+ Windows LoadLibrary 按名/ordinal-5（F-04-03，NONAME 按名 NULL 为期望行为）。
3. **约束与坑位固化**（F-04-05）：工具链映射表（6 类 × 4 列）、5 类高频跨平台坑、SKIP/附加架构边界、PE/ELF 跨平台反例样本。

## 门禁状态

- `verify_card.sh`：22 张已勾 feature 卡基线全 PASS（R-04 期全回归 22/22）✓
- `scan_dynamic_calls.sh` 零命中 ✓；check_encoding 双运行时全绿（ps1 BOM+CRLF、bat CRLF 21 文件）✓
- lint 必需检查（strict）全程运行 ✓；缓存 drill 机制随 PR paths 复证 ✓
