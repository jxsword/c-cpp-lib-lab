# SA 结论矩阵 · macos_clang_arm64_Debug / shared（macOS 三层静态分析，未运行目标）

| # | 结论 | 证据 |
|---|---|---|
| SA-1 | PASS | lipo -archs=arm64 (variant=arm64) |
| SA-2 | PASS | deferred: no DWARF producer string in Debug build (compiler identification exercised on Debug combos; dsym=none;cmds=clang -g -O0 -D_DEBUG -arch arm64 -DCALC_BUILD_DLL -fvisibility=hidden -I/Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/include -c /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/src/vmath_core.c -o /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/build/native/macos_clang_arm64_Debug/shared/vmath_core.o;clang -g -O0 -D_DEBUG -arch arm64 -DCALC_BUILD_DLL -fvisibility=hidden -I/Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/include -c /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/src/vmath_report.c -o /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/build/native/macos_clang_arm64_Debug/shared/vmath_report.o;clang -arch arm64 -dynamiclib -Wl,-install_name,@rpath/libvmath.dylib -Wl,-rpath,@loader_path /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/build/native/macos_clang_arm64_Debug/shared/vmath_core.o /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/build/native/macos_clang_arm64_Debug/shared/vmath_report.o -o /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/build/native/macos_clang_arm64_Debug/shared/libvmath.dylib -g -gsplit-dwarf;clang -g -O0 -D_DEBUG -arch arm64 -DCALC_USE_DLL -I/Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/include -c /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/src/calctool.c -o /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/build/native/macos_clang_arm64_Debug/shared/calctool.o;clang -arch arm64 /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/build/native/macos_clang_arm64_Debug/shared/calctool.o -L/Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/build/native/macos_clang_arm64_Debug/shared -lvmath -Wl,-rpath,@loader_path -o /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/build/native/macos_clang_arm64_Debug/shared/calctool -g -gsplit-dwarf;) |
| SA-3 | PASS | cfg marker=cfg=_DEBUG, compile units=0, gflag=5 (cfg=Debug) |
| SA-4 | PASS | dylib: /Users/runner/work/c-cpp-lib-lab/c-cpp-lib-lab/build/native/macos_clang_arm64_Debug/shared/libvmath.dylib (install_name: @rpath/libvmath.dylib) |
| SA-5 | PASS | export set = exactly 6 API (-fvisibility=hidden) |
| SA-6 | PASS | normalize_ absent from dylib global exports |
| SA-8 | PASS | deps tree: deps/macos_clang_arm64_Debug_shared.{json,md} (BFS, shared-cache classification) |
| SA-7 | PASS | all @rpath deps resolved via realpath; libSystem = shared-cache (not on disk) |
| SA-9 | PASS | libSystem.B.dylib (macOS unified runtime); MSVC CRT dimension not applicable |
| SA-10 | PASS | no LC_RPATH (static resolution) |

## 导出集区分（F-02-04）

| 项 | 结果 | 明细 |
|---|---|---|
| API 导出集（恰 6） | PASS | vmath_add vmath_build_info vmath_dot vmath_free vmath_last_error vmath_set_logger  |
| 裸符号 vmath_errno | PASS (hidden by -fvisibility=hidden — recorded, not an error) | 导出集 normalize_ 检查: PASS |
