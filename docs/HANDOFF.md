# docs/HANDOFF.md —— 会话交接文档（收官版 · 2026-11-17）

## 已完成清单

- **M0–M9 全部里程碑 + v1.0.0 发布**（前会话）：54/54 卡；Gate A/B/C ✓；10 tag + 10 Release；`verify_card.sh --all` 43 卡基线全回归绿。
- **待办 #1 native-windows ✅ / #2 native-macos ✅**（会话 2）：native-windows 36 job（18 组合 × bat+ps1）全绿（run `43777488838`）、native-macos 4 组合全绿（run `43855274143`）。修复链 PR #102–#125。
- **待办 #1 续 make/msbuild/cmake windows ✅ + #2 all.yml 全量 ✅**（本会话）：三组 workflow 实跑全绿——make-windows **72/72**（run `43952005104`）、msbuild-windows **32/32**（run `43952013046`）、cmake-windows **72/72**（run `43946852396`）；**all.yml 全量 80 组合全绿**（run `43980791603`，main=`77f6306`，323/323 job，组合数 24/32/24=80，A2 断言成立）。修复链 PR #126–#150（详见踩坑）。
- **收官收尾 ✅**：analyze.yml/run-output.yml 补 workflow_call + 标签段位解析修复，all.yml 从「解析即 422 不可 dispatch」修复至全量实跑全绿。
- develop 已逐 PR 同步对齐（#127/#129/#131/#133/#135/#137/#139/#141/#143/#145/#147/#149/#151）。

## 状态快照（收官时点）

- 分支：`main` = `77f6306`（HANDOFF 更新 PR 另计，doc-only）；`develop` 与 main 内容对齐；双分支受保护（lint strict）。
- 权威指纹：PLAN sha256 `f67e16d6…0a14`（本会话未动 PLAN.md）。
- `verify_card.sh --all`：43 卡全 PASS（本地 Linux，本会话验证 15+ 轮）。
- CI 基线：10 条组合工作流 + all.yml 全部实跑绿；缓存全热（apt/brew/pacman/win-tools/sccache）。
- 本地已装：pwsh 7.7.0（~/.local/bin）、gcc-multilib、pax-utils、patchelf、cmake 4.2.3；系统 grep 是 ugrep 别名。

## 待办（下一会话）

**无强制待办**。收官已完成：54/54 卡 + 80 组合全量实跑全绿 + all.yml 汇总断言成立。
可选后续（非阻塞）：
1. R-09 批量取证登记（把各 run id 写入对应卡面/REPORT.md 的 dispatch 实测栏）。
2. summarize_reports.sh 的「待 runner」状态列仍是静态占位，可改为读 reports/ 实测刷新（F-09-05 状态口径升级）。
3. reports/v1.0.0/SUMMARY.md 实测刷新并随 PR 入库。

## 踩坑记录（本会话新增，防重蹈）

- **pwsh 7.7 裸词不展开**：`-DNAME=$var` 形态的裸词中内嵌 $var **不展开**（字面传递，本地 shim 实测）——cmake.ps1 构建参数曾全字面量传给 cmake（CMAKE_BUILD_TYPE 收到字面 "$Cfg" → Ninja 规则名损坏；BUILD_SHARED_LIBS 收到字面 "$sh" → 静态组合被 option 默认 ON 建成 shared）。凡 `-` 开头含变量的参数一律显式双引号。
- **nmake 环境变量宏是「活绑定」**：makefile 里定义 `LIB=lib` 会连真实环境变量 LIB（vcvars 库路径表）一起改写，spawned link.exe 丢 SDK 路径 → LNK1104。工具宏用不撞名的 TOOLLIB/TOOLLINK。nmake 预定义命令宏只有 AS/CC/CPP/CXX/RC（LINK/LIB 无）。
- **vcxproj 属性必须接线到元数据**：定义 $(RuntimeLibrary) 属性而不写进 ClCompile 元数据 = 无效，v143 默认全走 /MD(d)。`lib.exe` 会把带 CodeView（/Zi）的 obj 归并出「库 PDB」落 OutDir——Release 需同时关 /GL、/Z*、链接器 /DEBUG 三处。Makefile.nmake 链接行不经过 CLFLAGS（/DEBUG 需单独 LNKDBG）。
- **CMakeLists 普通 set() 遮蔽命令行 -D**：`set(CMAKE_MSVC_RUNTIME_LIBRARY ...)` 会覆盖 `-D` 缓存值，须 `if(NOT DEFINED ...)` 守卫。CMake Windows-GNU 默认 DLL 带 lib 前缀（libvmath.dll），与全仓 vmath.dll 口径冲突 → `PREFIX ""`（import lib 走 IMPORT_PREFIX 不受影响）。
- **_combo make/gnu 必须显式传 OS**：Makefile 默认 `OS ?= linux`，macOS 建出 ELF 命名 libvmath.so 并被链接，dyld 报 Library not loaded（all.yml 实测）。toolset 按 OS 留痕。
- **msys2 环境工具链 bin 必须 PATH 前置**：镜像 PATH 预装 C:\mingw64\bin（64 位 DLL），MINGW32 的 cc1.exe（32 位）沿 PATH 解析到 64 位 zlib1.dll 等 → 静默死亡（gcc -v 取证：cc1 调起后零输出退 1）。与 native.ps1/cmake.ps1 同守卫（C8）。
- **make/msys2 的 make.exe 位置**：mingw-w64-<env>-make 只提供 mingw32-make.exe（packages.msys2.org 查证 2026-11-17）；本项目 Makefile recipes 需 sh（mkdir -p/rm -f）→ 用 MSYS `usr/bin/make.exe`；cmake.ps1 用 <env>/bin/mingw32-make.exe。
- **构建/RV/SA 三步标签必须同口径**：nmake.ps1 按 win_nmake_* 落盘，RV/SA 步需特判 make/nmake 组标签，否则寻址落空。
- **group 方言标签含 / 不得进文件名**：make/gnu 进 RV 报告文件名 → 建不出（三份 run 脚本同款修复：/ 归一 -）。
- **SA 结论 JSON 转义三件套**：反斜杠先转义、引号转义、控制字符剔除——SA-2 deferred 证据内嵌整段编译日志（cmds=）必踩。
- **all.yml 两个潜伏解析缺陷**：① `needs[k]` 动态键名 → 整个 workflow 解析失败、不可 dispatch（HTTP 422）；② 被 `uses:` 调用的 workflow 必须有 workflow_call 触发器。analyze/run-output 的组合标签解析 `${TAG##*_}` 取到的是 cfg（段位错误）。
- **macOS dylib 需配对**：`install_name=@rpath/<name>.dylib`（建库侧）+ `-Wl,-rpath,@loader_path`（消费侧）缺一即 dyld 解析失败；Makefile 与 native.sh 口径对齐。
- **git safecrlf=true** 对混合换行直接 fatal（本会话三次靠它拦下错误提交）；**本地 main 踩线三次**（提交前 branch 核对不可省，已改为 grep '^fix/' 硬闸）。
- **runner 镜像在漂移**：windows-2025 = VS18 + MSVC 14.51（v143 工具集自解析 14.44）+ Ninja 1.13.2 预装 + C:\mingw64\bin 预装；msys2 mingw-w64-make 无 make.exe；binutils PE ld 对 .def 输入自动解析（pe.em def_file_parse）、对 -rpath 接受但忽略（lexsup.c:461 通用选项）——均 2026-11-17 查证。

## 纪律清单

- PLAN.md 仅勾选行可改（54/54 已完整）；实质修订走 `hotfix/plan-*` + 重跑 0.3.1 更新 BASE。
- 辅助脚本禁 gh（J7）；RV 与 SA 严格分 step/脚本/目录（P5/C18）。
- 每卡/每修复：分支（基于 origin/main）→ 实测断言 → 门禁（check_encoding.sh + scan_dynamic_calls.sh + bash -n / pwsh Parser）→ `verify_card.sh --all` → PR（lint strict）→ `--merge --delete-branch` → 同步 develop（走 PR）→ 回执。
- **提交前 branch 核对用硬闸**（`git branch --show-current | grep -q '^fix/'`），禁止肉眼核对——本链本地 main 踩线三次。
- dispatch 优先用过滤参数做单组合快验；`gh run view --log` 在 run 未结束前不可拉，per-job 日志用 `gh api .../jobs/<id>/logs --allow-escape-sequences`。
- 辅助脚本禁 gh（J7）；RV 与 SA 严格分 step/脚本/目录（P5/C18）。
- 网络直连失败时按代理 `http://192.168.33.1:10808` 重试一次再下结论；WebFetch 失败不代表不可达（以 curl 代理实测为准）。
