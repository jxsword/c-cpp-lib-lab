# reports/v0.5.0/SUMMARY.md —— M5 里程碑摘要（R-05 · Gate B 推进中）

> D7 汇总：M5 = ② make 组 32 组合 = **GNU make 14 + nmake 10 + MSBuild 8**（P4 三方言口径）。执行口径：GNU make Linux 8 形态本地实跑全绿；nmake/MSBuild 与 macOS/msys2 部分为「脚本先行、产物级实证委托 F-09-02 runner」，如实分列。

## 32 组合 parity 矩阵（`scripts/verify_make32.sh` 输出）

| 方言 | 组合数 | 标签形态 | 本地状态 | 产物级实证 |
|---|---|---|---|---|
| GNU make | 14（Linux 4 + macOS 2 + msys2 8） | `linux_gcc_x86_Debug` 等 | Linux 8 形态实跑 8/8 绿 | macOS/msys2 待 runner |
| nmake | 10（msvc 8 + clang-cl 2） | `win_nmake_x64_MD_Release` 等（/MD //MT 为 variant 字段） | Makefile.nmake CRLF/语法核验 | 待 windows runner（vcvars） |
| MSBuild | 8（4 配置 × RuntimeLibrary） | `win_msbuild_x64_MD_Release` 等 | vcxproj XML/结构核验 | 待 windows runner |

**注入差异记录（同一组合标签在三方言下的实现差异）**：

| 维度 | GNU make | nmake | MSBuild |
|---|---|---|---|
| 可见性/PIC | `VIS` 仅 shared（`-fvisibility=hidden -fPIC`） | （MSVC 无此概念，导出走 .def） | 同左 |
| 形态宏 | `DEF_LIB`/`DEF_APP` 按 KIND | `/DCALC_BUILD_DLL`（shared）/`/DCALC_STATIC` | PreprocessorDefinitions 按条件（默认 STATIC + DynamicLibrary 叠加） |
| CRT | （ELF/Mach-O 无 CRT 开关） | `/MD`↔`/MDd`、`/MT`↔`/MTd` 随 CFG（`!IF` 联动） | `/p:RuntimeLibrary` 注入（Debug 自动 `*d`） |
| .def | （ELF/Mach-O 无） | `/DEF:` 仅 KIND=shared | `ModuleDefinitionFile` 条件挂载仅 DynamicLibrary |

## 门禁状态

- `verify_make32.sh` exit 0（32 行唯一 + 14/10/8 口径 + info↔标签 8/8 实跑）✓
- `verify_card.sh` 全回归持续绿；scan 零命中；check_encoding 全绿（Makefile.nmake CRLF 特例 lint 已适配）✓
- lint 必需检查 strict ✓；缓存 drill 机制运行 ✓
