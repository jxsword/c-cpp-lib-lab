# Changelog

本文件记录 c-cpp-lib-lab 的所有显著变更。每个里程碑发布对应一个 `v<semver>` 附注 tag（落在 `main`），版本语义见 CONTRIBUTING.md「版本与 tag 策略」一节。

## v0.0.0 (2026-11-15)

M0 里程碑发布：仓库骨架与 git flow（main/develop 受保护、SSH origin）、lint 门禁、CI 缓存基础设施（S1）、编码/换行规范与静态分析禁令基线（S6/S7，D9/D10 生效）全部就绪；`docs/PLAN.md`（v1.3.2）为唯一权威计划。Gate A 前置达成，下一里程碑进入纯 C 源码（M1）。

## v0.3.0 (in progress)

- F-03-01 · CMakeLists 与 CTest：新增 `CMakeLists.txt`（`BUILD_SHARED_LIBS` 驱动四模式宏注入 generator expression、`POSITION_INDEPENDENT_CODE`、`VERSION/SOVERSION 1`、`WINDOWS_EXPORT_ALL_SYMBOLS OFF`（WIN32 挂 `.def`）、`BUILD_RPATH $ORIGIN` / `INSTALL_RPATH $ORIGIN/../lib`、`CMAKE_EXPORT_COMPILE_COMMANDS`）与 `tests/CMakeLists.txt`（`--self-test` 注册 CTest）；4 组合 × 2 形态 8 次 configure+build+ctest 全绿（x86 `-m32` / x64 `-m64`）。
- F-03-02 · out-of-source / RPATH 断言与基线文档：`CMAKE_BUILD_RPATH_USE_ORIGIN` 使构建树 RUNPATH 为 `$ORIGIN`（并使 install 阶段 `file(RPATH_CHANGE)` 可靠改写为 `$ORIGIN/../lib`——实测 CMake 对绝对构建路径的改写会因格式不匹配报错）；`install(TARGETS …)` 落地；`analyze.sh` 以参数化 group 支持 `build/cmake/`（8 组合 SA 全绿，结论收齐 `reports/v0.3.0/`）；`docs/baseline.md` 补全 5.5–5.7（组合定义/客观约束/SA·RV 清单决策摘要）。

## v0.2.0 (2026-11-16)

M2 里程碑发布：① 原生 Linux 4 组合 × 2 形态 8 个组合形态全绿（out-of-source、compile.log 记录、ELF32/64 实证）；三层静态分析框架（SA-1…SA-10）+ BFS 依赖树（readlink -f realpath 去重 + 符号链接链）+ RV-1…RV-4 运行输出通道（P5 隔离）；`scripts/verify_card.sh` 成为 D1 唯一断言入口（15 卡机器可执行基线，受限指令集设计）；`reports/v0.2.0/SUMMARY.md` 汇总。Gate A 推进中，下一里程碑 CMake（M3，Gate A 完成）。

## v0.1.0 (2026-11-15)

M1 里程碑发布：纯 C 四模式（静态/建库/用库/直编）在 Linux gcc x64 单平台全绿；6 API 固定 ordinal 导出集与 5.2 断言一致；`reports/v0.1.0/SUMMARY.md` 完成 SA-1…SA-6 静态分析摘要（其余 N/A）。Gate A 推进中，下一里程碑进入原生 Linux 组合与静态分析框架（M2）。

- F-01-01 · 导出宏头：新增 `include/calc_export.h`——①平台判定 ②`CALC_EXTERN_C_BEGIN/END` ③`CALC_STATIC`/`CALC_BUILD_DLL`/`CALC_USE_DLL`/`CALC_NO_LIB` 四模式分派 ④32 位 Windows `CALC_CALL=__cdecl`（禁 `__stdcall`，保证 `.def` 未修饰名可寻址）⑤不导出任何数据符号 ⑥`CALC_DEPRECATED(msg)`。
- F-01-02 · 公共 API 与 `.def`：新增 `include/vmath.h`（恰 6 个导出函数 + `vmath_log_fn` 回调类型 + 裸数据符号教学对照，`extern "C"` 全包裹）与 `def/vmath.def`（ordinal 固定 1–6、`@5 NONAME`、不含错误码裸符号与任何数据符号声明）。
- F-01-03 · 库核心：新增 `src/vmath_core.c`——`vmath_add`（内部 `normalize_` 实际引用）、`vmath_dot`（n==0 与空指针校验，错误码经 `vmath_last_error()` 访问器）、裸符号 `vmath_errno` 教学对照；`-Wall -Wextra -Werror` 零警告。
- F-01-04 · 库报告与资源：新增 `src/vmath_report.c`——`vmath_build_info` 静态常量串（位数/数据模型/宽度/编译器/配置/迭代器调试层/库形态/CRT 全字段编译期进 `.rodata`，配 sizeof 静态断言互锁）、`vmath_free` 库侧 CRT 内释放、`vmath_set_logger`（可传 NULL 注销）。
- F-01-05 · CLI 主程序：新增 `src/calctool.c`——`add`/`dot`（逗号列表，维度不一致经访问器报 `VMATH_E_DIM`）/`info`/`probe`（静态自述）/`--self-test` 六项内建断言；`--dynamic`/`--bundle` 为明确提示桩；错误码只经 `vmath_last_error()` 读取。
- F-01-06 · 四模式冒烟 + 反例：新增 `scripts/linux/smoke_four_modes.sh`（M1 静态/M2 建库/M3 用库/M4 直编各编译一次 + readelf 静态解析 + 反例期望失败，产物全落 `build/native/smoke/`）、`tests/negative/static-with-dllimport/`（`__imp_` 未解析期望失败样本）与 `docs/baseline.md` 初版（PLAN 5.1–5.4 决策摘要）。
- F-02-01 · 原生命令脚本（out-of-source）：新增 `scripts/linux/native.sh`（入参 arch/cfg/kind → `build/native/linux_gcc_<arch>_<cfg>/<kind>/`，静态 `-DCALC_STATIC` 重编 + `ar rcs`，动态 `-fPIC -fvisibility=hidden` + soname 三级链接 + rpath `$ORIGIN`，每条命令入 compile.log）与 `scripts/{common.sh,linux/common.sh}`（组合标签/日志断言/D2 检查/cfg·arch 旗标）；4 组合 × 2 形态 8 产物全绿（x86 ELF32 + x64 ELF64，自测 8/8）。
- F-02-02 · Unix 动态加载分支（RV）：`calctool --dynamic [libpath] <cmd>` 实装——dlopen 绝对路径（默认可执行文件同目录 `libvmath.so.1`）→ dlsym 按名 6 API → 函数表（成员序 = ordinal 跨平台替代，`@5 NONAME` 经表成员可达）→ 调用 → `set_logger(NULL)` 注销 → dlclose → 卸载后不持有库内地址；仅 RV step 运行（P5 边界）。
- F-02-03 · 静态分析三层框架 + 依赖树（S7 核心）：新增 `scripts/linux/static_analyze.sh`（①file/readelf/nm/ar/strings/objdump ②lddtree/patchelf/llvm-*（缺失即记录）③自实现归一判定，SA-1…SA-10 全 PASS/FAIL，结论 JSON+MD + 三层原始输出落盘）与 `scripts/linux/deps_tree.sh`（BFS + readlink -f realpath 去重 + 符号链接链 + bundle/system 分类）；`.github/apt-packages.txt` 补 llvm；新增首个断言基线 `tests/assertions/F-02-03.yml`。
- F-02-04 · 静态分析结论报告：新增 `scripts/linux/analyze.sh`（调三层引擎 → 依赖树移至 `reports/<tag>/deps/` → 报告追加「导出集区分」节：恰 6 API 与 gcc 裸符号可见性如实区分 → 列数一致性自检）与 `reports/TEMPLATE.md`（单组合报告模板：固定节与固定列数，供汇总脚本解析）。
- F-02-05 · 运行输出采集 + 断言基线与验收入口（S8）：新增 `scripts/linux/run.sh`（RV-1…RV-4 的 stdout+stderr+exit code 采集 → `reports/<tag>/run/`，shared 形态含 `--dynamic` 演示）、`scripts/verify_card.sh`（D1 唯一断言入口：受限指令集 action 白名单 + `scripts/tools/assert_tree.sh` 受限子命令，不执行 yml 任意 shell）与 `tests/assertions/` 全部 M0–M2 共 15 卡基线（含 `tests/fixtures/corrupt/` 破坏夹具）。

- F-00-01 · 仓库与 git flow 初始化：建立 `main`/`develop` 长期分支并以 SSH 关联 `origin`；首次推送成功后为 `main` 设置分支保护（禁止直接 push、只接受 PR、禁止强制推送与删除）；`docs/PLAN.md`（v1.3）作为唯一权威计划原样纳入首个提交；新增 `.gitignore`（out-of-source 全量忽略）、`.gitattributes` 初版、MIT `LICENSE`、`README.md` 与 `CONTRIBUTING.md` 初版；建立计划 4.1 占位目录骨架。
- F-00-02 · lint 门禁：新增 `.github/workflows/lint.yml`（`pull_request` → `develop`/`main`），检查行尾空白、UTF-8、`*.ps1` UTF-8 BOM、`*.bat` CRLF 且无 BOM、`*.sh` LF 且无 BOM、禁止二进制入库与跟踪被忽略路径、`5.8.4` 禁用调用关键字扫描（`FORBIDDEN:` 注释白名单）、`docs/PLAN.md` 3.1 卡号格式与 Z1 越界章节引用、`scripts/` 内 `gh` 调用（J7 / K22）；不编译、不跑矩阵。
- F-00-03 · CI 缓存基础设施（S1）：新增 `.github/{apt,brew,msys2}-packages.txt`、`.github/tool-versions.env`、`.github/actions/setup-env`（composite，覆盖 5.9.2 全部 7 类缓存对象，key 严守 K1–K8，MSVC/SDK 不缓存）、`docs/ci-cache.md`（key/path/失效条件/命中率登记表）与 `.github/workflows/cache-drill.yml` 演练工作流（第二次调用必须命中）。
- hotfix/plan-02（v1.3.1）：`*.bat`/`*.cmd`/`Makefile.nmake` 的 `.gitattributes` 机制改为 `-text` 保真入库，使 lint 的 CRLF 断言可生效（留痕见 PLAN 12.H）。
- F-00-04 · 编码与换行规范落地（S6）：`.gitattributes` 补全 5.10 全量编码段（v1.3.1：bat/cmd/nmake `-text`）；新增 `scripts/tools/check_encoding.sh`、`check_encoding.ps1`（UTF-8 BOM）、`scan_dynamic_calls.sh`（5.8.4 禁令扫描，`FORBIDDEN:` 白名单）与首个 Windows 样例 `scripts/windows/env.bat`（CRLF）/`env.ps1`（BOM）；D9/D10 自本卡起生效。
