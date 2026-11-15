# docs/baseline.md —— 基线决策记录（初版：PLAN 5.1–5.4，F-01-06）

本文件是开发基线的决策级摘要，与唯一权威计划 `docs/PLAN.md` 对应章节同源；后续里程碑按 4.2 归属逐卡补全（5.5–5.7 由 F-03-02 / F-04-05 等补全）。

## 5.1 接口契约：`calc_export.h` 四模式

| 宏 | 语义 | 侧 | CALC_API 展开 |
|---|---|---|---|
| `CALC_STATIC` | 静态库 | 消费侧与库侧同宏 | 空 |
| `CALC_BUILD_DLL` | 建库 | 库侧 | `__declspec(dllexport)` / `__attribute__((visibility("default")))` |
| `CALC_USE_DLL` | 用库 | 消费侧 | `__declspec(dllimport)`（PE）/ 空（ELF/Mach-O） |
| `CALC_NO_LIB` | 源码直编 | 消费侧 | 空 |

- `CALC_CALL`：32 位 Windows 统一 `__cdecl`；**禁用 `__stdcall`**——x86 COFF 生成 `_foo@N` 修饰名，与 `.def` 未修饰名不匹配，`GetProcAddress("vmath_add")` 失败。64 位与 Unix 为空。
- **本项目刻意不导出任何数据符号**：状态走 `vmath_last_error()` 访问器；裸符号 `vmath_errno` 仅为默认导出行为的教学对照，消费者禁止直接引用。
- 宏名一律 `CALC_` 前缀。

## 5.2 `vmath.h` 公共 API（9 符号）

| # | 符号 | 归属 | 说明 |
|---|---|---|---|
| 1 | `vmath_add` | vmath_core.c | 标量加法 |
| 2 | `vmath_dot` | vmath_core.c | 点积；指针/size_t 跨宽度边界 |
| 3 | `vmath_build_info` | vmath_report.c | 静态常量串（SA-3 静态提取目标） |
| 4 | `vmath_free` | vmath_report.c | 库侧释放（同 CRT 内），跨 CRT 安全 |
| 5 | `vmath_last_error` | vmath_core.c | 错误码访问器（跨 CRT 正确做法） |
| 6 | `vmath_set_logger` | vmath_report.c | 回调注册，可 NULL 注销 |
| 7 | `vmath_errno` | vmath_core.c | 裸数据符号教学对照；不进导出表 |
| 8 | `normalize_` | vmath_core.c | 内部静态符号，不出现在导出表 |
| 9 | `main` | calctool.c | CLI 入口 |

动态库恰好 6 个 API；gcc/MinGW 额外出现 `vmath_errno`，MSVC 不出现；`normalize_` 任何平台均不在导出表。

**错误码取值约定**（库内置，经 `vmath_last_error()` 读取；常量名见 `src/calctool.c` 的对照枚举）：`0 = VMATH_E_OK`、`1 = VMATH_E_DIM`（维度无效/不一致类）、`2 = VMATH_E_NULL`（空指针）。

## 5.3 `def/vmath.def`

- ordinal 固定 1–6：add=1、dot=2、set_logger=3、free=4、build_info=5（**NONAME**，Windows 仅可按 ordinal 5 取址）、last_error=6。
- ordinal 仅 PE 存在；ELF/Mach-O 用「按名 + 函数表结构体成员位置」作跨平台替代。
- 错误码裸符号刻意不列入导出表（列入即令 MSVC 也导出，教学对照失效）；导出表不接受任何数据符号声明。

## 5.4 CLI 规格与错误处理

`calctool <command> [args]`：

| 命令 | 行为 |
|---|---|
| `add <a> <b>` | 调 `vmath_add`，结果经 logger 输出 |
| `dot <x1,...> <y1,...>` | 逗号列表；错误码经 `vmath_last_error()` 读取 |
| `info` | 打印 `vmath_build_info()` |
| `probe` | 静态自述（架构/类型表/内置依赖清单），不调用外部分析器 |
| `--self-test` | 内建断言，退出码为 CI 唯一功能判据 |
| `--dynamic` | 桩：属运行验证（RV）通道（F-02-02 / F-04-03） |
| `--bundle` | 桩：打包发布（F-09-07） |

- 维度不一致 → 非零退出 + `VMATH_E_DIM`（经访问器读取）。
- `--self-test` 六项断言：add 值、dot 值、维度错误、空指针错误、info 字段、logger 注册/注销。
