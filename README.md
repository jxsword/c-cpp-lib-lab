# c-cpp-lib-lab

以一套 C 源码为实验载体，系统验证 C/C++ 链接库在不同操作系统、工具链、位数、CRT 与配置组合下的构建、链接与静态分析方法论。

**唯一权威开发计划：[docs/PLAN.md](docs/PLAN.md)**（Plan v1.3，自包含；所有任务卡、断言与构建矩阵以它为准）。

## 项目要点

- **80 个构建组合**：原生命令 24 + make 组 32（GNU make 14 / nmake 10 / MSBuild 8）+ CMake 24，三套方式全部**源码外构建**，产物只落在 `build/<group>/...`
- **24 个基础组合**：Linux gcc（x86/x64）、Windows msvc（x86/x64 × /MD /MT）、msys2（MINGW64/MINGW32/CLANG64/UCRT64）、clang-cl x64、macOS clang arm64；每个组合内必建 `static/` + `shared/` 双形态
- **三阶段语言演进**：纯 C → C++ 调用 C 链接库（`extern "C"`）→ 纯 C++ 面向对象，各含期望失败的反例实验
- **静态分析**（SA-1…SA-10）：架构位数、编译器名+版本、Debug/Release、依赖树（追踪符号链接、分级树形展示）；分析过程禁止任何动态加载或实际运行
- **运行验证**（RV-1…RV-4）：独立通道采集 stdout/stderr/退出码，与静态分析以不同 step / 脚本 / 报告目录严格隔离
- **产物形态**：静态库/动态库 `vmath` + CLI 工具 `calctool`；无 GUI、无网络、无第三方运行时依赖

## 仓库导航

| 路径 | 说明 |
|---|---|
| `docs/PLAN.md` | 唯一权威开发计划（任务卡、断言、80 组合构建矩阵） |
| `CONTRIBUTING.md` | 环境前置、健康检查、git flow 分支模型、领卡协议、提交规范、gh 操作矩阵 |
| `include/`、`src/`、`def/` | 库与 CLI 源码（后续里程碑产出） |
| `stage2/`、`stage3/` | 三阶段语言演进实验（C++ 调 C / 纯 C++ OOP） |
| `scripts/` | linux/macos（bash）、windows（bat + ps1）构建、分析与校验脚本 |
| `tests/` | 断言基线、反例与测试夹具 |
| `reports/` | 各里程碑静态分析 / 运行验证报告（`reports/<tag>/...`） |
| `build/`、`out/` | 构建产物（被 `.gitignore` 忽略，永不入库） |

## 状态

- 当前里程碑：M0（`v0.0.0` in progress，详见 [CHANGELOG.md](CHANGELOG.md)）
- 分支模型：git flow —— `main` 受保护（只接受 PR），`develop` 集成主线，feature 一卡一分支
- 许可：MIT（见 [LICENSE](LICENSE)）
