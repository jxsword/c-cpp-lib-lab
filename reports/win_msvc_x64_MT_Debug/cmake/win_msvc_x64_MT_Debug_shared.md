# SA 结论矩阵 · win_msvc_x64_MT_Debug / shared（三层静态分析，未运行目标）

| # | 结论 | 证据 |
|---|---|---|
| SA-1 | PASS | machine=x64 (variant=x64_MT) |
| SA-2 | PASS | compiler: msvc linker 14.51 |
| SA-3 | PASS | cfg=Debug, pdb present [calctool.pdb,vmath.pdb], marker= |
| SA-4 | PASS | shared: vmath.dll present (import lib allowed) |
| SA-5 | PASS | 5 API by name + build_info @5 NONAME (msvc/clang-cl) |
| SA-6 | PASS | normalize_ absent from exports |
| SA-9 | PASS | /MT variant: no VCRUNTIME140 (static CRT) |
| SA-8 | PASS | deps tree: deps/win_msvc_x64_MT_Debug_shared.{json,md}（BFS + realpath 去重 + API-Set 归类，JSON 可解析，unresolved=8） |
| SA-7 | PASS | direct deps resolved via Resolve-Path（vmath.dll 在树中，同目录搜索）；unresolved(direct)=0 |
| SA-10 | PASS | PE 搜索顺序静态展开（dumpbin /dependents + 同目录 vmath.dll 搜索）；无 RUNPATH 概念 |

- 第①层原始输出: layer1/（dumpbin headers/exports/dependents、strings）
- 第②层交叉验证: layer2/（llvm-readobj Rich/exports、Dependencies CLI，缺失即记录）
- 依赖树: deps/win_msvc_x64_MT_Debug_shared.{json,md}（BFS + realpath 去重 + 符号链接链）
