# SA 结论矩阵 · linux_gcc_x64_Debug / static（三层静态分析，未运行目标）

| # | 结论 | 证据 |
|---|---|---|
| SA-1 | PASS | class=ELF64 machine=X86-64 (variant=x64) |
| SA-2 | PASS | compiler: gcc 15.2.0 (local gcc 15.2.0) |
| SA-3 | PASS | cfg marker=cfg=_DEBUG, debug sections=7 (cfg=Debug) |
| SA-4 | PASS | static archive: vmath_core.o vmath_report.o  |
| SA-5 | PASS | export set = 6 API + vmath_errno (default visibility) |
| SA-6 | PASS | normalize_ is local (t) in static archive |
| SA-8 | PASS | deps tree: deps/linux_gcc_x64_Debug_static.{json,md} (BFS, realpath dedup, JSON valid) |
| SA-7 | PASS | no libvmath dependency (statically resolved); system deps resolved=all |
| SA-9 | PASS | glibc dynamic (libc.so.6); MSVC CRT dimension N/A on ELF |
| SA-10 | PASS | no RUNPATH (static resolution); patchelf cross-check: == /home/ssy/proj/c-cpp-lib-lab/build/native/linux_gcc_x64_D |

- 第①层原始输出: layer1/（file/readelf/nm/ar/strings/objdump）
- 第②层交叉验证: layer2/（lddtree/patchelf/llvm-*，缺失即记录）
- 依赖树: deps/linux_gcc_x64_Debug_static.{json,md}（BFS + realpath 去重 + 符号链接链）
