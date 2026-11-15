# SA 结论矩阵 · linux_gcc_x64_Release / shared（三层静态分析，未运行目标）

| # | 结论 | 证据 |
|---|---|---|
| SA-1 | PASS | class=ELF64 machine=X86-64 (variant=x64) |
| SA-2 | PASS | compiler: gcc 15.2.0 (local gcc 15.2.0) |
| SA-3 | PASS | cfg marker=cfg=NDEBUG, debug sections=0 (cfg=Release) |
| SA-4 | PASS | shared object: /home/ssy/proj/c-cpp-lib-lab/build/native/linux_gcc_x64_Release/shared/libvmath.so.1.0.0 (soname=libvmath.so.1) |
| SA-5 | PASS | export set = exactly 6 API (vmath_errno hidden by -fvisibility=hidden) |
| SA-6 | PASS | normalize_ absent from dynamic exports |
| SA-8 | PASS | deps tree: deps/linux_gcc_x64_Release_shared.{json,md} (BFS, realpath dedup, JSON valid) |
| SA-7 | PASS | all NEEDED resolved via readlink -f (libvmath.so.1 + libc); symlink chain recorded |
| SA-9 | PASS | glibc dynamic (libc.so.6); MSVC CRT dimension not applicable on ELF |
| SA-10 | PASS | RUNPATH contains $ORIGIN (same-dir search): $ORIGIN |

- 第①层原始输出: layer1/（file/readelf/nm/ar/strings/objdump）
- 第②层交叉验证: layer2/（lddtree/patchelf/llvm-*，缺失即记录）
- 依赖树: deps/linux_gcc_x64_Release_shared.{json,md}（BFS + realpath 去重 + 符号链接链）

## 导出集区分（F-02-04）

| 项 | 结果 | 明细 |
|---|---|---|
| API 导出集（恰 6） | PASS | vmath_add vmath_build_info vmath_dot vmath_free vmath_last_error vmath_set_logger  |
| gcc 裸符号 vmath_errno | PASS (hidden by -fvisibility=hidden — recorded, not an error) | 动态导出表 normalize_ 检查: PASS |
