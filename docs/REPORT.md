# docs/REPORT.md —— c-cpp-lib-lab 总报告（v1.0.0 · Gate C）

> 每节带实测证据（`reports/` 引用 + 命令 + 输出摘录 + 组合标签）。状态口径：**80 组合全量实跑全绿**（all.yml 全量重跑 run `44064184860`，323/323 job；reports/ 42 标签目录全量入库，含 mac/win 各 OS runner 实跑证据——SA 结论 json+md、deps 依赖树、RV 运行输出）。

## 1. 分类与策略矩阵

- **80 组合 = 原生 24 + make 32 + cmake 24**（P3：每组合内 static/shared 双形态）；工具链 6 类封闭列表（gcc / msvc / msys2×4 / clang-cl / apple-clang）。
- 三套构建方式全部 out-of-source；产物目录互不重叠（`build/{native,make/{gnu,nmake,msbuild},cmake}/`）。
- 证据：`docs/baseline.md` 5.5.1 映射表（F-04-05）、`reports/v0.6.0/SUMMARY.md` 三组口径表。

## 2. 平台格式与扩展名

- ELF：`libvmath.so`（soname `libvmath.so.1`，native 组三级符号链接）；Mach-O：`libvmath.dylib`（install_name `@rpath/...`）；PE：`vmath.dll` + 导入库 `vmath.lib` / `libvmath.dll.a`。
- 证据：`reports/linux_gcc_x64_Release/native/linux_gcc_x64_Release_shared.md`（SA-4 soname）与 `reports/linux_gcc_x64_Release/deps/*.json`（符号链接链）。

## 3. 编译期路径与优先级

- include 路径：`-I<abs-src>/include`；链接 `-L<outdir> -lvmath`；运行期 ELF `RUNPATH $ORIGIN` / Mach-O `LC_RPATH @loader_path` / PE 搜索顺序。
- 实测：CMake 构建树 RUNPATH 与 install 树 `$ORIGIN/../lib` 两阶段差异（`hotfix` 记录：`CMAKE_BUILD_RPATH_USE_ORIGIN` 是 RPATH_CHANGE 可靠性前提）——`reports/v0.3.0/SUMMARY.md`。

## 4. 静态分析三层与依赖树（SA-1…SA-10）

- 三层：①内置工具（file/readelf/nm/ar/strings/objdump、otool/lipo、dumpbin）→ ②第三方（lddtree/patchelf/llvm-*、dylibbundler、Dependencies CLI，缺失即记录）→ ③自实现归一（BFS 依赖树 + realpath 去重 + 符号链接链 + bundle/system/shared-cache 分类）。
- 证据：`reports/linux_gcc_x64_Release/native/linux_gcc_x64_Release_shared.md`（10/10 PASS）+ `deps/linux_gcc_x64_Release_shared.json`（`libvmath.so → .so.1.0.0` realpath 链）+ 三 OS schema 统一（F-04-04）。

## 5. 运行验证输出（RV-1…RV-4）

- 独立 run 通道（C18 隔离）：`--self-test` / `info` / `add`+`dot`（成功+维度错误）/ `--dynamic`（按名+ordinal 5）→ stdout/stderr/exit code。
- 证据：`reports/linux_gcc_x64_Release/run/linux_gcc_x64_Release_native_shared.txt`（7 项 capture 全 PASS；CI 侧进 Job Summary 代码块——run-output.yml）。

## 6. 默认导出差异实测

- gcc/MinGW 默认导出全部符号（含裸 `vmath_errno`）；`-fvisibility=hidden` 下恰 6 API；MSVC 默认不导出、`.def` 唯一白名单。
- 证据：`reports/linux_gcc_x64_Release/native/...shared.md` SA-5（两种形态判定）+ `reports/v0.2.0/SUMMARY.md` 9 符号 ↔ 导出集一致性表。

## 7. 32/64 与 CRT

- x86 `-m32`（ELF32 实证）/ x64；MSVC `/MD`↔`/MDd`、`/MT`↔`/MTd` 随 CFG；`CMAKE_MSVC_RUNTIME_LIBRARY` 注入链（F-06-01）。
- 证据：`reports/v0.2.0/SUMMARY.md`（x86 ELF32 / x64 ELF64）+ `tests/assertions/F-05-03.yml`（RuntimeLibrary 注入位）。

## 8. C/C++ 互操作三阶段

- 阶段 1 纯 C（6 API 固定 ordinal）；阶段 2 C++ 消费（`U vmath_add` 未修饰名 + vector data() 位级一致 + extern C 缺失反例 `U _Z9vmath_adddd`）；阶段 3 纯 C++ OOP（组合式、STL 留边界内）+ C ABI 门面/纯虚 vtable（C 消费者零 C++ 符号依赖）。
- 证据：`stage2/README.md`、`reports/v0.7.0/negative/stage2_no_extern_c.log`、`reports/v0.8.0/abi-notes.md`（类直出 16 mangled vs 门面 8 C 名）。

## 9. 打包与干净机验证

- Linux bundle 实测：`$ORIGIN/../lib` + 自带 so + patchelf + strip + readelf 静态复核 + LICENSE/NOTICE + 切 CWD 自测全 PASS。
- 证据：`scripts/linux/bundle.sh`（F-09-07 执行输出）+ `reports/v0.6.0/SUMMARY.md`（三组隔离）。

## 10. 安全演示

- before/after 双模式：劫持面复现（`LD_LIBRARY_PATH` 优先于 RUNPATH 的静态对照结论）→ 哈希校验 + `env -i` 干净环境 + rpath 固定；防御清单 9 条（含 AT_SECURE/SIP/Hardened Runtime）。
- 证据：`scripts/linux/security_hijack_demo.sh`（F-09-08 执行输出）+ `docs/baseline.md` 安全章节。

## 11.2 待拍板项当前取值（A6）

P3 组合内双形态不乘组合数｜P4 make 组三方言 32｜P5 SA 禁动态加载、RV 保留 `--dynamic`｜P6 clang-cl（MSVC ABI）｜P7 macOS arm64 主组合（x86_64/universal 附加）｜P8 GitHub 侧一律 gh、本地构建由 scripts 发起——全部按计划取值执行，未变更。
