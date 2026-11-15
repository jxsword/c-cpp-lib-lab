# Changelog

本文件记录 c-cpp-lib-lab 的所有显著变更。每个里程碑发布对应一个 `v<semver>` 附注 tag（落在 `main`），版本语义见 CONTRIBUTING.md「版本与 tag 策略」一节。

## v0.8.0 (in progress)

- F-08-03 · `extern "C"` 门面与纯虚接口：新增 `stage3/facade.h`（纯 C 可编译：opaque handle `stage3_vector_*` + C 工厂/`release()` + 函数指针表 vtable 契约；禁 STL/内联/模板/默认参数）与 `stage3/facade.cpp`（异常在 C++ 侧捕获转错误码、C 未修饰名导出、库侧释放）；实测：`gcc -fsyntax-only -xc` 过头文件、门面 4+ 个 `T stage3_*` C 名、C 消费者经 vtable 调用 `mean=2 count=2`（消费者 _Z 引用仅为 libstdc++ 运行时，stage3 类符号零泄漏）。

- F-08-02 · `Statistics` 类与 3 源 / 2 头：新增 `stage3/include/stats.hpp`（组合 Vector，非继承）+ `stage3/src/stats.cpp`（min/max/mean/count）+ `stage3/src/main.cpp`（OOP 自测驱动）+ `stage3/README.md`（设计要点与 `_ITERATOR_DEBUG_LEVEL` 差异说明）；`Vector` 增 `push_back`（组合可用性）；恰好 3 `.cpp` + 2 `.hpp`；Debug/Release 双构建成功、`nm -C` 记录 Itanium mangling（MSVC `?*@@` 差异待 runner 对照）。
- F-08-01 · `Vector` 类：新增 `stage3/include/vector.hpp` + `stage3/src/vector.cpp`（声明与实现分离、`std::vector` 私有成员不导出到库边界、public 方法、与 vmath.h 零 include 耦合）；`-std=c++17 -Wall -Wextra -Werror` 零警告、`nm -C` 可见 `Vector::` mangled 符号。

## v0.7.0 (2026-11-16)

M7 里程碑发布：阶段 2（C++ 调 C 库）完成——`stage2/main.cpp` 未修饰名直调 extern "C" 接口（`U vmath_add` 实证）、`std::vector` data() 跨边界逐位一致（数据可传、类型不可跨）、空容器走 C 库错误分支；反例 `extern "C"` 缺失（`U _Z9vmath_adddd` + undefined reference 双证）与期望失败机制就绪。Linux 全实跑；mac/win 随 runner。下一里程碑纯 C++ OOP（M8，Gate B 完整达成）。

- F-07-03 · `std::vector` 跨边界用例：`stage2/main.cpp` 增 `--self-test` 分派——`std::vector<double>::data()` 传入 `vmath_dot` 与纯 C 数组路径逐位一致（数据可传、类型不可跨）、空 vector 走 C 库错误分支（errno=VMATH_E_DIM 经访问器）而非 UB；C 库导出表 0 mangled 符号实测；三 OS 命令见 stage2/README.md（mac/win 随 runner）。

- F-07-02 · 反例：去掉 `extern "C"`：新增 `tests/negative/stage2_no_extern_c.cpp`（C++ 风格重声明 → Itanium 修饰名 `_Z9vmath_adddd` 未定义引用）、`tests/negative/run.sh`（期望失败运行器：mangling 特征 nm 证明 + 链接失败 = 通过，日志归档 `reports/v0.7.0/negative/`）与 `tests/negative/README.md`（修复方式 = 恢复 extern "C" 守卫）；实测特征串双证（nm `U _Z9vmath_adddd` + ld `undefined reference`）。

- F-07-01 · C++ 主程序：新增 `stage2/main.cpp`（`#include "vmath.h"` 直调 extern "C" 接口、异常边界防御示范）与 `stage2/README.md`（三 OS 构建命令 + 复用产物不重编库说明）；Linux 实测：链接运行正确（`add=4`/`dot=32`）、`nm -C` 引用为未修饰名 `U vmath_add`；mac/win 随 runner。

## v0.6.0 (2026-11-16)

M6 里程碑发布：③ CMake 三 OS 24 组合口径收口（msvc/clang-cl 强制 Ninja，S9）——**80 组合构建矩阵三 OS 口径全部就绪**（native 24 + make 32 + cmake 24）；CTest 三类四项用例（每组合 ≥3）；RPATH 两阶段断言汇总（`reports/v0.6.0/SUMMARY.md`）。Linux 16 组合形态实跑全绿；mac/win 产物级实证按口径委托 F-09-02。下一里程碑进入 C++ 语言演进（M7 阶段 2）。

- F-06-01 · CMake 三 OS 24 组合：新增 `scripts/linux/cmake.sh`（Linux 4 组合驱动）；`CMakeLists.txt` 补 `CMAKE_MSVC_RUNTIME_LIBRARY` 默认值（CMP0091 NEW，命令行按 variant 的 _MD/_MT 注入 MultiThreadedDLL/MultiThreaded）；macOS（`-DCMAKE_OSX_ARCHITECTURES`、32 位 SKIP）与 Windows（msvc/clang-cl 强制 `-G Ninja`，S9）入口已于 F-04-01/02 就绪；Linux 8 形态实跑全绿；全 24 组合与 msvc Ninja CMakeCache 断言待 F-09-02 runner。
- F-06-02 · CTest 三 OS 与 out-of-source 断言：`tests/CMakeLists.txt` 注册三类四项用例（self-test / probe-deps 依赖判定 / info-fields 组合自证，shared 增 dynamic-load 属 RV 通道）；Linux 实测 static 3/3、shared 4/4 全绿（每组合 ≥3 ✓）；`reports/v0.6.0/SUMMARY.md` 三组口径（24/32/24 = 80）与 RPATH 两阶段断言汇总。

## v0.5.0 (2026-11-16)

M5 里程碑发布：② make 组 32 组合三方言全就绪——GNU make（`Makefile`，Linux 8 形态实跑全绿）、nmake（`Makefile.nmake` CRLF 独立文件）、MSBuild（`vmath.vcxproj`）；`verify_make32.{sh,ps1}` parity 口径核验（14+10+8=32、/MD //MT 为 variant 字段、注入差异表落档）。macOS/msys2/nmake/MSBuild 产物级实证委托 F-09-02 runner（口径如实分列，见 `reports/v0.5.0/SUMMARY.md`）。下一里程碑 CMake 三 OS（M6，Gate B 收口）。

- F-05-04 · 32 组合横向对比：新增 `scripts/verify_make32.{sh,ps1}`（32 行唯一标签清单、三方言 14/10/8 口径核验、/MD //MT 为 variant 字段（16 行携带 + clang-cl 参数承载）、Linux gnu info↔标签 8/8 实跑核对）与 `reports/v0.5.0/SUMMARY.md`（三方言注入差异记录表）；不改 5.5 定义。

- F-05-04 · 32 组合横向对比：新增 `scripts/verify_make32.{sh,ps1}`（32 行唯一标签清单、三方言 14/10/8 口径核验、/MD //MT 为 variant 字段（16 行携带 + clang-cl 参数承载）、Linux gnu info↔标签 8/8 实跑核对）与 `reports/v0.5.0/SUMMARY.md`（三方言注入差异记录表）；不改 5.5 定义。

- F-05-03 · MSBuild（8 组合）：新增 `vmath.vcxproj`（4 配置 Debug/Release × Win32/x64、`PlatformToolset v143`、`ConfigurationType` 与 `RuntimeLibrary` 命令行 `/p:` 注入（DynamicLibrary/StaticLibrary ↔ CALC_BUILD_DLL/CALC_STATIC 形态宏、MultiThreadedDLL/MultiThreaded ↔ /MD//MT）、`ModuleDefinitionFile` 条件挂载仅动态、`OutDir/IntDir` 默认即 `build\make\msbuild\` 强制 out-of-source）并完整化 `scripts/windows/msbuild.{bat,ps1}`（Kind→ConfigurationType、Variant→RuntimeLibrary 映射）；8 组合产物级实测待 F-09-02 windows runner。

- F-05-02 · nmake 单独 makefile（10 组合，S9）：新增 `Makefile.nmake`（**独立于 GNU Makefile 的 CRLF 无 BOM 文件**；`!IF/!ELSE/!ENDIF` 条件、`/MD`↔`/MDd` `/MT`↔`/MTd` 随 CFG 联动、`/DEF:$(SRCDIR)\def\vmath.def` 仅动态、`/MACHINE` 随变体、`SRCDIR/OUTDIR` 强制 out-of-source、`selftest/analyze` 目标）并完整化 `scripts/windows/nmake.{bat,ps1}`（vcvars 缺失时 NOTE 降级）；10 组合（msvc 8 + clang-cl 2）产物级实测待 F-09-02 windows runner。

- F-05-01 · GNU make（14 组合）：新增 `Makefile`（`?=` 变量 OS/TOOLSET/VARIANT/CFG/KIND/CC、`srcdir`/`outdir` 强制 out-of-source、`VIS` 仅 shared、`DEF_LIB/DEF_APP` 按 KIND 分派、动态库名按 OS 分派 `libvmath.so`/`libvmath.dylib`/`vmath.dll`、`selftest`/`analyze` 目标、msys2 加 `--out-implib`）；Linux 4 组合 × 2 形态 8/8 selftest 绿（A2 `make -n` 静态零 hidden/PIC；A3 `make analyze` 产报告；`-Wl,-rpath,'$$ORIGIN'`）；macOS gmake / msys2 GNU make 待 F-09-02 runner。

## v0.4.0 (2026-11-16)

M4 里程碑发布：24 组合矩阵三 OS 脚本矩阵全就绪（macOS bash + Windows bat/ps1 + 三层分析扩展 + JSON schema 统一）；Linux 16 组合形态实跑全绿；macOS/Windows 产物级实证按计划委托 F-09-02 各 OS runner CI（执行口径如实分列，见 `reports/v0.4.0/SUMMARY.md`）。工具链映射表与 5 类跨平台坑固化。下一里程碑进入 make 组 32 组合（M5）。

- F-04-05 · 24 组合矩阵收口与约束记录：`docs/baseline.md` 补 24 组合工具链映射表（6 类工具链 × 32/64 开关/动态库命令/导入库/CRT 四列）与 5 类高频跨平台坑；README 增「已知差异与边界」（macOS x86 SKIP、x86_64/universal 附加覆盖、Linux clang 移出、产物级断言委托 CI）；`tests/negative/pe-def-missing/` PE 反例样本。
- F-04-04 · 静态分析三 OS 扩展（S7）：三 OS 依赖树输出统一 JSON schema（`root{path,arch,compiler,cfg}` + `tree{name,logical,real,origin,children}` + `symlink_chains`/`dedup`，Linux 实证四字段）；`deps_tree.ps1` 增 `Get-Item -Force` 的 LinkType symlink/junction 判定与 API-Set/KnownDLL 归类；第二层工具接入（macOS `dylibbundler` 分析模式、Windows Dependencies CLI，版本 pin 于 tool-versions.env，缺失即记录）；产物级断言（A1–A3）待各 OS runner CI 实证。

- F-04-03 · Windows 动态加载（RV）：`calctool --dynamic` 平台分叉——Windows 分支 `LoadLibraryA` 绝对路径、`GetProcAddress` 按名 6 API、`GetProcAddress(h, MAKEINTRESOURCEA(5))` 按 ordinal 取 `vmath_build_info`（`.def @5 NONAME`：按名必 NULL 为 A2 期望行为）、`FreeLibrary` 前经函数表注销 logger；Unix 分支不受影响（Linux 回归全绿）；`docs/baseline.md` 增 `LOAD_LIBRARY_SEARCH_*` 加固对照（PATH 劫持面 → 收敛搜索面，加固变体登记 F-09-08）；产物级断言（A1–A4）待 F-09-02 windows runner CI 实证。
- F-04-02 · Windows 原生脚本（bat + ps1）与 18 组合：新增 `scripts/windows/` 全套（native/nmake/msbuild/cmake/build_all/static_analyze/run/bundle 的 bat 薄入口 + ps1 逻辑层、deps_tree.ps1、env.*）与 `scripts/{common.ps1,verify_card.ps1}`（ps1 全 UTF-8 BOM + CRLF、bat 全 CRLF）——msvc `cl /LD /DEF:def\vmath.def`（/MD|/MT ↔ /MDd|/MTd 联动）、msys2 四环境独立工具链前缀（C8 不混链）、clang-cl 同 MSVC、cmake.ps1 msvc/clang-cl 强制 Ninja（S9）；18 组合（msvc 4 变体 × 2 + msys2 4 环境 × 2 + clang-cl × 2）× 双形态编排就绪，产物级断言（A1–A6）待 F-09-02 windows runner CI 实证。
- F-04-01 · macOS 原生与静态分析脚本（bash）：新增 `scripts/macos/` 全套（env/common/native/make/cmake/build_all/static_analyze/deps_tree/run/bundle，bash/LF/无 BOM）——`-dynamiclib -Wl,-install_name,@rpath/libvmath.dylib -fvisibility=hidden`、arm64 主组合 + x86_64 附加架构覆盖、x86 输入 SKIP（10.15 起 32 位移除，exit 0）、三层静态分析（otool/lipo/nm -gU/dwarfdump/dyld_info + `libSystem.B.dylib` shared-cache 分类）；产物级断言（A1–A5）待 F-09-02 macos runner CI 实证。

## v0.3.0 (2026-11-16) · Gate A

M3 里程碑发布，**Gate A 达成**：① 原生 Linux 4 组合 + ③ CMake Linux 4 组合（各 × static/shared 双形态 = 16 个组合形态）全部构建 + 自测绿；SA-1…SA-10（三层静态分析）与 RV-1…RV-4 结论齐全（`reports/v0.3.0/SUMMARY.md`）；CMake install RPATH 两阶段差异实证（`$ORIGIN` → `$ORIGIN/../lib`）；`verify_card.sh` 17 卡基线全回归 PASS。README 已注明当前仅 Linux 单平台，三 OS 见 M4–M6（Gate B）。

- F-03-01 · CMakeLists 与 CTest：新增 `CMakeLists.txt`（`BUILD_SHARED_LIBS` 驱动四模式宏注入 generator expression、`POSITION_INDEPENDENT_CODE`、`VERSION/SOVERSION 1`、`WINDOWS_EXPORT_ALL_SYMBOLS OFF`（WIN32 挂 `.def`）、`BUILD_RPATH $ORIGIN` / `INSTALL_RPATH $ORIGIN/../lib`、`CMAKE_EXPORT_COMPILE_COMMANDS`）与 `tests/CMakeLists.txt`（`--self-test` 注册 CTest）；4 组合 × 2 形态 8 次 configure+build+ctest 全绿（x86 `-m32` / x64 `-m64`）。
- F-03-02 · out-of-source / RPATH 断言与基线文档：`CMAKE_BUILD_RPATH_USE_ORIGIN` 使构建树 RUNPATH 为 `$ORIGIN`（并使 install 阶段 `file(RPATH_CHANGE)` 可靠改写为 `$ORIGIN/../lib`——实测 CMake 对绝对构建路径的改写会因格式不匹配报错）；`install(TARGETS …)` 落地；`analyze.sh` 以参数化 group 支持 `build/cmake/`（8 组合 SA 全绿，结论收齐 `reports/v0.3.0/`）；`docs/baseline.md` 补全 5.5–5.7（组合定义/客观约束/SA·RV 清单决策摘要）。

## v0.2.0 (2026-11-16)

M2 里程碑发布：① 原生 Linux 4 组合 × 2 形态 8 个组合形态全绿（out-of-source、compile.log 记录、ELF32/64 实证）；三层静态分析框架（SA-1…SA-10）+ BFS 依赖树（readlink -f realpath 去重 + 符号链接链）+ RV-1…RV-4 运行输出通道（P5 隔离）；`scripts/verify_card.sh` 成为 D1 唯一断言入口（15 卡机器可执行基线，受限指令集设计）；`reports/v0.2.0/SUMMARY.md` 汇总。Gate A 推进中，下一里程碑 CMake（M3，Gate A 完成）。

- F-02-01 · 原生命令脚本（out-of-source）：新增 `scripts/linux/native.sh`（入参 arch/cfg/kind → `build/native/linux_gcc_<arch>_<cfg>/<kind>/`，静态 `-DCALC_STATIC` 重编 + `ar rcs`，动态 `-fPIC -fvisibility=hidden` + soname 三级链接 + rpath `$ORIGIN`，每条命令入 compile.log）与 `scripts/{common.sh,linux/common.sh}`（组合标签/日志断言/D2 检查/cfg·arch 旗标）；4 组合 × 2 形态 8 产物全绿（x86 ELF32 + x64 ELF64，自测 8/8）。
- F-02-02 · Unix 动态加载分支（RV）：`calctool --dynamic [libpath] <cmd>` 实装——dlopen 绝对路径（默认可执行文件同目录 `libvmath.so.1`）→ dlsym 按名 6 API → 函数表（成员序 = ordinal 跨平台替代，`@5 NONAME` 经表成员可达）→ 调用 → `set_logger(NULL)` 注销 → dlclose → 卸载后不持有库内地址；仅 RV step 运行（P5 边界）。
- F-02-03 · 静态分析三层框架 + 依赖树（S7 核心）：新增 `scripts/linux/static_analyze.sh`（①file/readelf/nm/ar/strings/objdump ②lddtree/patchelf/llvm-*（缺失即记录）③自实现归一判定，SA-1…SA-10 全 PASS/FAIL，结论 JSON+MD + 三层原始输出落盘）与 `scripts/linux/deps_tree.sh`（BFS + readlink -f realpath 去重 + 符号链接链 + bundle/system 分类）；`.github/apt-packages.txt` 补 llvm；新增首个断言基线 `tests/assertions/F-02-03.yml`。
- F-02-04 · 静态分析结论报告：新增 `scripts/linux/analyze.sh`（调三层引擎 → 依赖树移至 `reports/<tag>/deps/` → 报告追加「导出集区分」节：恰 6 API 与 gcc 裸符号可见性如实区分 → 列数一致性自检）与 `reports/TEMPLATE.md`（单组合报告模板：固定节与固定列数，供汇总脚本解析）。
- F-02-05 · 运行输出采集 + 断言基线与验收入口（S8）：新增 `scripts/linux/run.sh`（RV-1…RV-4 的 stdout+stderr+exit code 采集 → `reports/<tag>/run/`，shared 形态含 `--dynamic` 演示）、`scripts/verify_card.sh`（D1 唯一断言入口：受限指令集 action 白名单 + `scripts/tools/assert_tree.sh` 受限子命令，不执行 yml 任意 shell）与 `tests/assertions/` 全部 M0–M2 共 15 卡基线（含 `tests/fixtures/corrupt/` 破坏夹具）。

## v0.1.0 (2026-11-15)

M1 里程碑发布：纯 C 四模式（静态/建库/用库/直编）在 Linux gcc x64 单平台全绿；6 API 固定 ordinal 导出集与 5.2 断言一致；`reports/v0.1.0/SUMMARY.md` 完成 SA-1…SA-6 静态分析摘要（其余 N/A）。Gate A 推进中，下一里程碑进入原生 Linux 组合与静态分析框架（M2）。

- F-01-01 · 导出宏头：新增 `include/calc_export.h`——①平台判定 ②`CALC_EXTERN_C_BEGIN/END` ③`CALC_STATIC`/`CALC_BUILD_DLL`/`CALC_USE_DLL`/`CALC_NO_LIB` 四模式分派 ④32 位 Windows `CALC_CALL=__cdecl`（禁 `__stdcall`，保证 `.def` 未修饰名可寻址）⑤不导出任何数据符号 ⑥`CALC_DEPRECATED(msg)`。
- F-01-02 · 公共 API 与 `.def`：新增 `include/vmath.h`（恰 6 个导出函数 + `vmath_log_fn` 回调类型 + 裸数据符号教学对照，`extern "C"` 全包裹）与 `def/vmath.def`（ordinal 固定 1–6、`@5 NONAME`、不含错误码裸符号与任何数据符号声明）。
- F-01-03 · 库核心：新增 `src/vmath_core.c`——`vmath_add`（内部 `normalize_` 实际引用）、`vmath_dot`（n==0 与空指针校验，错误码经 `vmath_last_error()` 访问器）、裸符号 `vmath_errno` 教学对照；`-Wall -Wextra -Werror` 零警告。
- F-01-04 · 库报告与资源：新增 `src/vmath_report.c`——`vmath_build_info` 静态常量串（位数/数据模型/宽度/编译器/配置/迭代器调试层/库形态/CRT 全字段编译期进 `.rodata`，配 sizeof 静态断言互锁）、`vmath_free` 库侧 CRT 内释放、`vmath_set_logger`（可传 NULL 注销）。
- F-01-05 · CLI 主程序：新增 `src/calctool.c`——`add`/`dot`（逗号列表，维度不一致经访问器报 `VMATH_E_DIM`）/`info`/`probe`（静态自述）/`--self-test` 六项内建断言；`--dynamic`/`--bundle` 为明确提示桩；错误码只经 `vmath_last_error()` 读取。
- F-01-06 · 四模式冒烟 + 反例：新增 `scripts/linux/smoke_four_modes.sh`（M1 静态/M2 建库/M3 用库/M4 直编各编译一次 + readelf 静态解析 + 反例期望失败，产物全落 `build/native/smoke/`）、`tests/negative/static-with-dllimport/`（`__imp_` 未解析期望失败样本）与 `docs/baseline.md` 初版（PLAN 5.1–5.4 决策摘要）。

## v0.0.0 (2026-11-15)

M0 里程碑发布：仓库骨架与 git flow（main/develop 受保护、SSH origin）、lint 门禁、CI 缓存基础设施（S1）、编码/换行规范与静态分析禁令基线（S6/S7，D9/D10 生效）全部就绪；`docs/PLAN.md`（v1.3.2）为唯一权威计划。Gate A 前置达成，下一里程碑进入纯 C 源码（M1）。

- F-00-01 · 仓库与 git flow 初始化：建立 `main`/`develop` 长期分支并以 SSH 关联 `origin`；首次推送成功后为 `main` 设置分支保护（禁止直接 push、只接受 PR、禁止强制推送与删除）；`docs/PLAN.md`（v1.3）作为唯一权威计划原样纳入首个提交；新增 `.gitignore`（out-of-source 全量忽略）、`.gitattributes` 初版、MIT `LICENSE`、`README.md` 与 `CONTRIBUTING.md` 初版；建立计划 4.1 占位目录骨架。
- F-00-02 · lint 门禁：新增 `.github/workflows/lint.yml`（`pull_request` → `develop`/`main`），检查行尾空白、UTF-8、`*.ps1` UTF-8 BOM、`*.bat` CRLF 且无 BOM、`*.sh` LF 且无 BOM、禁止二进制入库与跟踪被忽略路径、`5.8.4` 禁用调用关键字扫描（`FORBIDDEN:` 注释白名单）、`docs/PLAN.md` 3.1 卡号格式与 Z1 越界章节引用、`scripts/` 内 `gh` 调用（J7 / K22）；不编译、不跑矩阵。
- F-00-03 · CI 缓存基础设施（S1）：新增 `.github/{apt,brew,msys2}-packages.txt`、`.github/tool-versions.env`、`.github/actions/setup-env`（composite，覆盖 5.9.2 全部 7 类缓存对象，key 严守 K1–K8，MSVC/SDK 不缓存）、`docs/ci-cache.md`（key/path/失效条件/命中率登记表）与 `.github/workflows/cache-drill.yml` 演练工作流（第二次调用必须命中）。
- hotfix/plan-02（v1.3.1）：`*.bat`/`*.cmd`/`Makefile.nmake` 的 `.gitattributes` 机制改为 `-text` 保真入库，使 lint 的 CRLF 断言可生效（留痕见 PLAN 12.H）。
- hotfix/plan-03（v1.3.2）：计划 1.4 的 `.gitignore` 二进制清单逐行化，与 gitignore 语法及仓库实现对齐（留痕见 PLAN 12.H）。
- F-00-04 · 编码与换行规范落地（S6）：`.gitattributes` 补全 5.10 全量编码段（v1.3.1：bat/cmd/nmake `-text`）；新增 `scripts/tools/check_encoding.sh`、`check_encoding.ps1`（UTF-8 BOM）、`scan_dynamic_calls.sh`（5.8.4 禁令扫描，`FORBIDDEN:` 白名单）与首个 Windows 样例 `scripts/windows/env.bat`（CRLF）/`env.ps1`（BOM）；D9/D10 自本卡起生效。
