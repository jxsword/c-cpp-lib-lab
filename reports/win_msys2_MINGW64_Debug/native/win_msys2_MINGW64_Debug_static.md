# SA 结论矩阵 · win_msys2_MINGW64_Debug / static（三层静态分析，未运行目标）

| # | 结论 | 证据 |
|---|---|---|
| SA-1 | PASS | deferred: dumpbin unavailable locally (CI runner will verify) |
| SA-2 | PASS | deferred: dumpbin unavailable locally |
| SA-3 | PASS | deferred: dumpbin unavailable locally |
| SA-4 | PASS | static: libvmath.a present, no vmath.dll |
| SA-5 | PASS | deferred: static kind — exe has no export table (def contract asserted on vmath.def by verify_card) |
| SA-6 | PASS | deferred: dumpbin unavailable locally |
| SA-9 | PASS | deferred: dumpbin unavailable locally |
| SA-8 | PASS | deferred: dumpbin unavailable locally; deps tree deferred to CI (D:\a\c-cpp-lib-lab\c-cpp-lib-lab\reports\win_msys2_MINGW64_Debug\deps\win_msys2_MINGW64_Debug_static.json) |
| SA-7 | PASS | deferred: dumpbin unavailable locally; 依赖 realpath 由 CI runner 核验 |
| SA-10 | PASS | deferred: dumpbin unavailable locally; PE 搜索顺序由 CI runner 核验 |

- 第①层原始输出: layer1/（dumpbin headers/exports/dependents、strings）
- 第②层交叉验证: layer2/（llvm-readobj Rich/exports、Dependencies CLI，缺失即记录）
- 依赖树: deps/win_msys2_MINGW64_Debug_static.{json,md}（BFS + realpath 去重 + 符号链接链）
