# SA 结论矩阵 · macos_clang_arm64_Release / shared（macOS 三层静态分析，未运行目标）

| # | 结论 | 证据 |
|---|---|---|
| SA-1 | PASS | lipo -archs=arm64 (variant=arm64) |
| SA-2 | PASS | deferred: no DWARF producer string in Release build (compiler identification exercised on Debug combos; dsym=none;cmds=cc -O2 -DNDEBUG -arch arm64 -fvisibility=hidden -fPIC -DCALC_BUILD_DLL -I/Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/include -c /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/src/vmath_core.c -o ./vmath_core.o;cc -O2 -DNDEBUG -arch arm64 -fvisibility=hidden -fPIC -DCALC_BUILD_DLL -I/Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/include -c /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/src/vmath_report.c -o ./vmath_report.o;cc -arch arm64 -shared -fvisibility=hidden -fPIC -Wl,-install_name,@rpath/libvmath.dylib -o ./libvmath.dylib ./vmath_core.o ./vmath_report.o;cc -O2 -DNDEBUG -arch arm64 -DCALC_USE_DLL -I/Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/include -c /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/src/calctool.c -o ./calctool.o;cc -arch arm64 ./calctool.o -L. -lvmath -Wl,-rpath,@loader_path -o ./calctool;./calctool --self-test;self-test: add OK;self-test: dot OK;self-test: dim-error OK;self-test: null-error OK;self-test: info OK;self-test: logger OK;self-test: ALL OK;) |
| SA-3 | PASS | cfg marker=cfg=NDEBUG, compile units=0, gflag=0 (cfg=Release) |
| SA-4 | PASS | dylib: /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/build/make/gnu/macos_clang_arm64_Release/shared/libvmath.dylib (install_name: @rpath/libvmath.dylib) |
| SA-5 | PASS | export set = exactly 6 API (-fvisibility=hidden) |
| SA-6 | PASS | normalize_ absent from dylib global exports |
| SA-8 | PASS | deps tree: deps/macos_clang_arm64_Release_shared.{json,md} (BFS, shared-cache classification) |
| SA-7 | PASS | all @rpath deps resolved via realpath; libSystem = shared-cache (not on disk) |
| SA-9 | PASS | libSystem.B.dylib (macOS unified runtime); MSVC CRT dimension not applicable |
| SA-10 | PASS | no LC_RPATH (static resolution) |

## 导出集区分（F-02-04）

| 项 | 结果 | 明细 |
|---|---|---|
| API 导出集（恰 6） | PASS | vmath_add vmath_build_info vmath_dot vmath_free vmath_last_error vmath_set_logger  |
| 裸符号 vmath_errno | PASS (hidden by -fvisibility=hidden — recorded, not an error) | 导出集 normalize_ 检查: PASS |
