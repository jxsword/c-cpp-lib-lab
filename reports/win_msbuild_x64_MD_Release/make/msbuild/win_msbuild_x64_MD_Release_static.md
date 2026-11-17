# SA 结论矩阵 · win_msbuild_x64_MD_Release / static（三层静态分析，未运行目标）

| # | 结论 | 证据 |
|---|---|---|
| SA-1 | PASS | machine=x64 (variant=x64_MD) |
| SA-2 | PASS | compiler: msvc linker 14.44 |
| SA-3 | PASS | cfg=Release, no pdb, marker=cfg=no-NDEBUG |
| SA-4 | PASS | static: vmath.lib present, no vmath.dll |
| SA-5 | PASS | deferred: static kind — exe has no export table (def contract asserted on vmath.def by verify_card) |
| SA-6 | PASS | normalize_ absent from exports |
| SA-9 | PASS | /MD variant: VCRUNTIME140.dll present |
| SA-8 | PASS | deps tree: deps/win_msbuild_x64_MD_Release_static.{json,md}（BFS + realpath 去重 + API-Set 归类，JSON 可解析，unresolved=8） |
| SA-7 | PASS | no vmath.dll dependency（statically resolved）；direct deps unresolved=0 |
| SA-10 | PASS | PE 搜索顺序静态展开（dumpbin /dependents + 同目录 vmath.dll 搜索）；无 RUNPATH 概念 |

- 第①层原始输出: layer1/（dumpbin headers/exports/dependents、strings）
- 第②层交叉验证: layer2/（llvm-readobj Rich/exports、Dependencies CLI，缺失即记录）
- 依赖树: deps/win_msbuild_x64_MD_Release_static.{json,md}（BFS + realpath 去重 + 符号链接链）
