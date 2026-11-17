# SA 结论矩阵 · macos_clang_arm64_Debug / static（macOS 三层静态分析，未运行目标）

| # | 结论 | 证据 |
|---|---|---|
| SA-1 | PASS | lipo -archs=arm64 (variant=arm64) |
| SA-2 | PASS | deferred: no DWARF producer string in Debug build (compiler identification exercised on Debug combos; dsym=none;cmds=cc -g -O0 -D_DEBUG -arch arm64  -DCALC_STATIC -I/Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/include -c /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/src/vmath_core.c -o ./vmath_core.o;cc -g -O0 -D_DEBUG -arch arm64  -DCALC_STATIC -I/Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/include -c /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/src/vmath_report.c -o ./vmath_report.o;ar rcs ./libvmath.a ./vmath_core.o ./vmath_report.o;cc -g -O0 -D_DEBUG -arch arm64 -DCALC_STATIC -I/Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/include -c /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/src/calctool.c -o ./calctool.o;cc -arch arm64 ./calctool.o ./libvmath.a -o ./calctool;./calctool --self-test;self-test: add OK;self-test: dot OK;self-test: dim-error OK;self-test: null-error OK;self-test: info OK;self-test: logger OK;self-test: ALL OK;) |
| SA-3 | PASS | cfg marker=cfg=_DEBUG, compile units=0, gflag=3 (cfg=Debug) |
| SA-4 | PASS | static archive: __.SYMDEF SORTED vmath_core.o vmath_report.o  |
| SA-5 | PASS | export set = exactly 6 API (-fvisibility=hidden) |
| SA-6 | PASS | normalize_ local (t) in static archive |
| SA-8 | PASS | deps tree: deps/macos_clang_arm64_Debug_static.{json,md} (BFS, shared-cache classification) |
| SA-7 | PASS | all @rpath deps resolved via realpath; libSystem = shared-cache (not on disk) |
| SA-9 | PASS | libSystem.B.dylib (macOS unified runtime); MSVC CRT dimension not applicable |
| SA-10 | PASS | no LC_RPATH (static resolution) |

## 导出集区分（F-02-04）

| 项 | 结果 | 明细 |
|---|---|---|
| API 导出集（恰 6） | PASS | vmath_add vmath_build_info vmath_dot vmath_free vmath_last_error vmath_set_logger  |
| 裸符号 vmath_errno | PASS (hidden by -fvisibility=hidden — recorded, not an error) | 导出集 normalize_ 检查: FAIL |
