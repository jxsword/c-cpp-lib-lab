# c-cpp-lib-lab 开发计划

> **文档性质**：独立开发计划（Execution Plan / Git Flow Work Breakdown）。**完全自包含**：zcode 只凭本文件即可完成全部开发、构建、测试与分析，**不依赖、不引用任何外部文档**（校验见 `0.7.4`）。
> **来源与版本**：v1.0 由既有实战项目规格重组而来；v1.1、v1.2 经补充需求修订；**v1.3 = v1.2 + `hotfix/plan-01` 首次启动引导期修订（M1–M5 / S1 / S3，留痕见 `12.H`）**；**v1.3.1 = v1.3 + `hotfix/plan-02`（`*.bat`/`*.cmd`/`Makefile.nmake` 的 `.gitattributes` 机制由 `text eol=crlf` 修正为 `-text` 保真入库，使 lint 的 CRLF 断言可生效，留痕见 `12.H`）**；**v1.3.2 = v1.3.1 + `hotfix/plan-03`（`1.4` 的 `.gitignore` 二进制清单逐行化，与实现及 gitignore 语法对齐，留痕见 `12.H`）**。**v1.2 起所有执行所需的技术基线、参考代码骨架与知识补遗已全部内联**（第 5 章、第 7 章、附录 A–H）；外部学习资料与本计划**无引用关系**，开发时无需查阅。
> **适用**：在 **zcode** 中按 **git flow** 逐卡开发、调试、验证；所有 Git / GitHub 侧操作由 agent 调用 `gh` 完成（见 `0.7.3`、`8.5`）。
> **项目名**：`c-cpp-lib-lab`（仓库名 / 根目录名）｜**库**：`vmath`｜**可执行**：`calctool`
> **版本**：**Plan v1.3.2** · 完全自包含 + 仓库 / `gh` 前置条件 + 首次启动引导期修订（`hotfix/plan-01`）+ `hotfix/plan-02`（bat/cmd/nmake 保真）+ `hotfix/plan-03`（.gitignore 清单逐行化） · **状态：已确认，git flow 逐卡执行中**
> **本文件不含**：任何已编译验证的工程源码、git 仓库、CI 运行结果。它只定义「做什么、在哪个分支做、怎么算做完」。
> **本次交付边界**：只修订本计划文件；**未初始化仓库、未创建任何源码、未执行任何构建、未通过 `gh` 做任何写操作**。

---

## 0. 计划说明与使用方法

### 0.1 这份计划是什么 / 不是什么

| 是 | 不是 |
|---|---|
| 一张「里程碑 → 分支 → 任务卡 → 断言 → tag」的可执行分解表 | 任何外部文档的复制品（执行所需知识已全部内联至第 5 章与附录 F / G） |
| zcode 每次只领**一张卡**的作业指令书 | 一次性生成整个仓库的提示词 |
| 定义了可自动判定的 PASS / FAIL，避免「看起来跑通了」 | 已验证的命令清单（所有命令需在对应卡内首次实跑并记录偏差） |
| 定义了 git flow 的分支、合并、tag、回执协议 | 已建立的 git 仓库（仓库由 `F-00-01` 创建） |

### 0.2 三个能力档位（沿用你熟悉的简短指令）

把「方案 A / B / C」映射为三个**累积档位**（定义见本计划 `2.4` 的 tag 表），每个档位结束都对应一个可发布 tag，可随时停下验收：

| 档位 | 覆盖里程碑 | 结束时具备的能力 | 对应原方案 | 结束 tag |
|---|---|---|---|---|
| **Gate A** | M0 → M3 | 纯 C 工程 + ① 原生（Linux gcc 4 组合）+ ③ CMake（Linux 4 组合），**单平台跑通**；静态分析三层框架与缓存/编码基线已建立 | 方案 A | `v0.3.0` |
| **Gate B** | M4 → M8 | ① 三 OS 全 24 组合、② make 组 32 组合（GNU make / nmake / msbuild）、③ CMake 24 组合、阶段 2（C++ 调 C）、阶段 3（纯 C++ OOP）、静态分析全平台 | 方案 B | `v0.8.0` |
| **Gate C** | M9 | 全量 GitHub Actions（3 组工作流 + `all.yml`，共 **80 组合**）+ 缓存 + 静态分析与运行输出 + 打包 + 安全演示 + 汇总报告 | 方案 C | `v1.0.0` |

> 可回复「**做到 Gate A**」「**继续 Gate B**」「**全量 Gate C**」，或「**只做 F-05-02**」按卡推进，或「**只跑 native-windows.yml**」单独触发一条工作流。

### 0.3 领卡协议（zcode 执行约定）

1. **一次一张卡**：**首次启动先执行 `0.3.1` 只读健康检查**；之后按 `6.x` 的卡号顺序领取，不得跳卡；前置 tag 不存在时不得开工。
2. **先建分支再改文件**：严格使用卡上写死的分支名，从 `develop` 开出。
3. **断言优先**：卡上的断言是唯一验收依据；任一 FAIL 即停，先修再继续。
4. **提交规范**：Conventional Commits，scope 用模块名；每张卡至少一个提交。
5. **合并与回迁**：feature → `develop`（PR，`--no-ff`）；里程碑末由 `release/<ver>` 验证后同时合入 `main` 与 `develop`，在 `main` 打 tag。
6. **每卡结束输出回执并等待确认**，不自动领下一张。
7. **静态分析禁令**：所有 `scripts/analyze_*` 与 `scripts/static_analyze_*` 不得出现 `5.8.4` 的禁用调用；运行验证另走 `RV` 通道。
8. **GitHub 侧一律走 `gh`**：PR 创建 / 合并 / 检查、工作流触发与观测、artifact 下载、release 发布、分支保护设置，均由 agent 调用 `gh` 完成（`0.7.3`、`8.5`）；本地构建 / 测试 / 静态分析由 agent 调用 `scripts/` 脚本发起并把结论经 `gh` 回写 PR 与 checks，禁止用网页手工操作替代。辅助脚本本身不得依赖 `gh`（`9.4 J7`）。

#### 0.3.1 首次启动只读健康检查（仅执行一次，v1.3 / S1）

> 在领取 `F-00-01` **之前**执行，**只做只读检查、不做任何写操作**；任一失败即停下报告，不要继续、不要自行修复环境。全部输出原样记入 `F-00-01` 回执的「基线」与「权威指纹」栏。

| # | 命令 | 期望 / 记录 |
|---|---|---|
| H1 | `gh auth status` | 已登录、token 有效（A7 前置） |
| H2 | `ssh -T git@github.com` | 认证成功（A9 前置） |
| H3 | `gh repo view jxsword/c-cpp-lib-lab` | 远程仓库可见 |
| H4 | `ls -a c-cpp-lib-lab` | 存在 `docs/PLAN.md`、**无 `.git`**、无其它文件（`0.7.2`） |
| H5 | `sha256sum docs/PLAN.md` | **记为 BASE**，供 `F-00-01` A4 与 V21 比对；此后不得改写该文件 |
| H6 | `file docs/PLAN.md` + `od -An -tx1 -N3 docs/PLAN.md` | UTF-8 **无 BOM**（首 3 字节非 `ef bb bf`）、LF 换行（`5.10`） |
| H7 | `sed -n '/### 11.2/,/^---/p' docs/PLAN.md` | 记录 P3–P8 当前取值；启动后按取值执行，**需要决策时停下询问，不自选备选** |

> BASE 是 `docs/PLAN.md` 唯一权威副本的指纹。任何 `hotfix/plan-*` 修改计划后，须在下次启动前重新执行本节并更新 BASE（`0.7.4` Z4）。

### 0.4 卡回执模板（zcode 每卡结束必须输出）

```
## 卡回执 · <卡号>
- 分支：<branch>   基线：<前置 tag / commit>   起止 commit：<sha1>..<sha2>
- 改动文件：新增 [...] / 修改 [...] / 删除 [...]
- 断言结果：
    | # | 断言 | 命令 | PASS/FAIL | 关键输出摘录 |
- 编码/换行校验：*.ps1 UTF-8 BOM ✓ | *.bat CRLF ✓ | *.sh LF ✓
- 缓存命中：hit/miss（若本卡涉及 CI）
- gh 操作：`gh pr create/merge/checks`、`gh workflow run`、`gh run watch`（附 run id / URL）；CI 结论：success/failure
- 权威指纹：`docs/PLAN.md` sha256 = <BASE>（见 `0.3.1` H5）；编码/换行：UTF-8 无 BOM + LF ✓
- 已知偏差与未决项：...（无则写「无」）
- PR：<编号或链接>   合并到 develop：<commit>
- 结论：<卡号> 完成 / 阻塞（附根因）
- 等待确认后领取 <下一卡号>
```

### 0.5 变更本计划的规则

计划文件纳入版本控制（`docs/PLAN.md`）。若实跑发现基线有误，**不得直接改代码绕过**，须先提 `hotfix/plan-<n>` 修订本计划并附证据（命令行输出 + 本计划章节 / 卡号 + `gh run` URL），确认后再改实现。待拍板项见 `11.2`。**修订本计划时不得重新引入对外部文档的回指**（`0.7.4` Z1）。

### 0.6 补充需求采纳清单（v1.1 S1–S9 / v1.2 S10–S13，逐条可追溯；v1.3 复审修订见 `12.H`）

| # | 补充需求 | 落点章节 / 卡 | 处理方式 |
|---|---|---|---|
| **S1** | GitHub Action 构建、测试所需环境与**大体积安装包必须启用缓存** | `5.9`、`8.3`、`F-00-03`、`F-09-01`、`F-09-06` | 新增包清单文件 + 缓存矩阵；key 含 OS/工具链/位数/配置，禁止跨组合复用；缓存命中率写 Job Summary |
| **S2** | 明确 OS / 编译器 / 位数 / CRT / 配置 → **24 基础组合** | `5.5`、`7.1`、里程碑表 | **完全重写组合定义**；Linux 只保留 gcc（原 clang 降为不计数组的本地可选验证）；Windows 补 `MINGW32`、`clang-cl`；macOS 仅 64 位 |
| **S3** | 原生 24 + make 24 + msbuild 8 + cmake 24 = **80 组合** | `5.5`、`7`、`10` | 原生 24；make 组 = GNU make 14 + nmake 10 + msbuild 8 = 32；cmake 24（msvc 用 **Ninja**） |
| **S4** | 三套构建方式**必须源码外构建**、分别用不同子目录、`.gitignore` 忽略 | `1.4`、`2.3`、`7.0` | `build/native/`、`build/make/{gnu,nmake,msbuild}/`、`build/cmake/`；make 组内再按方言分 |
| **S5** | CI 按构建工具分 **3 组**、可单独运行某条工作流、最后全量测试 | `8.1`、`8.2`、`F-09-02`…`F-09-06` | 3 组 × OS 拆 10 条可 dispatch 工作流 + `analyze.yml` / `run-output.yml` + `all.yml`（`workflow_call` 串联 80 组合） |
| **S6** | 辅助脚本：linux/macos **bash**；windows **bat + powershell**；**ps1 = UTF-8 BOM**、**bat = CRLF**；CI 是否用脚本由计划分析决定 | `5.10`、`9.4`、`4.1` | 明确规范 + lint 断言 + 校验脚本；`9.4` 给出 **方案 C（混合复用）** 的决策记录与理由 |
| **S7** | 静态分析四项：架构位数 / **编译器名+版本号** / Debug-Release / **依赖树（追踪符号链接、分级树形展示）**；三层（内置 → 第三方需安装 → 自实现）；**禁止动态加载或实际运行分析** | `5.7` 重写、`5.8` 新增、`F-02-03`、`F-04-04`、`F-09-05` | 静态分析清单 `SA-1…SA-10`；三层工具表；依赖树 JSON+Markdown；`5.8.4` 硬禁令 + CI 关键字扫描 |
| **S8** | CI 中包含**程序运行输出的结果** | `5.7` RV 清单、`8.4`、`F-09-05` | 独立「运行验证」通道 `RV-1…RV-4`，采集 stdout/stderr/退出码 → artifact + `$GITHUB_STEP_SUMMARY`；**明确不属于静态分析** |
| **S9** | msvc 用 **nmake 编写单独的 makefile**；cmake 的 msvc 用 **Ninja** | `5.5`、`7.2`、`7.3`、`F-05-02`、`F-06-01` | `Makefile.nmake` 覆盖 msvc 8 + clang-cl 2；`CMake -G Ninja` 覆盖 msvc 与 clang-cl |
| **S10** | 远程仓库已创建，本地用 **SSH** 关联 `git@github.com:jxsword/c-cpp-lib-lab.git` | `0.7.1`、`2.1`、`F-00-01` | 初始化时 `git remote add origin <ssh>`；A6 断言校验 origin 为 SSH 形式，禁止 HTTPS |
| **S11** | 本地已装 `gh` 并登录，**所有开发测试由 agent 调用 `gh` 完成** | `0.3`、`0.7.3`、`8.5`、`9.4 J7`、`F-00-02` | 新增 gh 操作矩阵与工作流触发 / 观测命令；辅助脚本不得调用 `gh`，保证本地离线可跑 |
| **S12** | 本地 `c-cpp-lib-lab/` **目录已存在、仓库未初始化** | `0.7.2`、`F-00-01` | v1.3 修正为「目录内含且仅含 `docs/PLAN.md`」（启动前已存入，为**唯一权威**）；`F-00-01` **不新建 / 不覆盖**该文件，命令从 `git init -b main` 起，不重复建目录、不 `git clone` |
| **S13** | 计划**不依赖任何外部学习资料**，zcode 只凭本文件开发 | 全文、`12.F`、`12.G`、`F-00-01 A4` | 删除全部外部章节回指；内联导出宏骨架、C/C++ 互操作规则、协议决策表；新增自包含校验 Z1–Z4 |

> **S7 与 S8 的边界（重要）**：`不允许动态加载或实际运行` 约束的是**分析过程**；程序运行输出是**独立的运行验证 step**。两者在同一 job 里以不同 step、不同脚本、不同报告目录隔离，不互相违反。
>
> **S10–S12 的边界（重要）**：用户已明确「远程仓库已创建、本地空目录已存在但仓库未初始化、后续初始化并用 SSH 关联、所有开发测试由 agent 调用 `gh` 完成」。这些是**已成立的前置事实**，不是本计划要执行的动作；本次仅把它们写进计划，由 `F-00-01` 复核，**当前不做任何 `git` / `gh` 写操作**。
>
> **v1.3 补充**：该目录在首次启动前已存入 `docs/PLAN.md`（`0.7.2`、`0.3.1` H4/H5），`F-00-01` 只把它原样纳入版本控制；**「空目录」不再用于描述仓库根目录的现状**（`4.1` 的「占位目录骨架」是另一概念，指仓库内预留的子目录）。

### 0.7 环境与仓库前置条件（v1.2 新增，已由用户确认的事实；v1.3 修正目录现状与权威副本）

> 本节记录执行前已成立的事实与由此产生的强制约束。**zcode 不得假设这些事实之外的前提**；`F-00-01` 会通过断言逐条复核。

#### 0.7.1 远程仓库与协议

| 项 | 值 / 约束 |
|---|---|
| 远程仓库 | `https://github.com/jxsword/c-cpp-lib-lab`（**已创建**，仅用于展示与 `gh` 定位） |
| **实际关联地址** | `git@github.com:jxsword/c-cpp-lib-lab.git`（**SSH**，唯一允许的 `origin`） |
| 协议约束 | `git remote get-url origin` 必须等于上述 SSH 地址；**禁止**把 HTTPS 形式设为 `origin`（`F-00-01` A6） |
| 认证 | SSH 私钥已配置；`gh auth status` 已登录且具备 `repo` / `workflow` 权限（`F-00-01` A7） |
| 首次推送 | `git push -u origin main` 与 `git push -u origin develop`，由 `F-00-01` 完成 |
| 工具 | `gh` 已安装并登录；`git-flow` 可用（不可用时的等价原生 git 命令见 `2.1`） |

#### 0.7.2 本地目录现状

| 项 | 状态 |
|---|---|
| 本地路径 | 已存在目录 `c-cpp-lib-lab/`（即仓库根目录），**内含且仅含 `docs/PLAN.md`**（启动前已把本计划存入该路径） |
| 仓库状态 | **未初始化**：目录内无 `.git`；`docs/PLAN.md` 尚未纳入版本控制，由 `F-00-01` 执行 `git init -b main` 并把它加入首个提交 |
| **权威副本** | **仓库内 `docs/PLAN.md` 是唯一权威**；`/workspace` 下的同名文件只是交付快照，不参与开发、不作为断言基准（`0.7.4` Z4、`0.3.1` H5） |
| 禁止 | 不得再 `mkdir` / `git clone` 覆盖该目录，不得在其它路径另建仓库；**不得新建、覆盖、改写 `docs/PLAN.md`**（`F-00-01` A4 / A8） |
| 工具前置 | `git`、`gh`、各 OS 编译器/构建工具；版本与恢复步骤由 `F-00-01` 记入 `CONTRIBUTING.md` |

#### 0.7.3 gh 使用矩阵（agent 执行协议）

**总原则**：所有 **Git / GitHub 侧** 操作由 agent 调用 `gh` 完成；本地构建、测试、静态分析由 agent 调用 `scripts/` 脚本完成，其结论通过 `gh` 回写到 PR / checks / release。辅助脚本本身**不得依赖 `gh`**（`9.4 J7`），以保证本地批量构建离线可复现。

| 场景 | 命令（示例） | 出现位置 |
|---|---|---|
| 认证 / 定位仓库 | `gh auth status`、`gh repo view jxsword/c-cpp-lib-lab` | `F-00-01` |
| 建 PR | `gh pr create --base develop --head feature/m0-01-repo-skeleton --title "..." --body "卡号 / 断言结果 / 已知偏差"` | 每张 feature 卡 |
| 合并 PR（保留合并提交） | `gh pr merge <n> --merge --delete-branch` | 每张卡、`2.3` |
| PR 检查 | `gh pr checks <n>`、`gh pr view <n> --json statusCheckRollup` | `0.3` 第 5 条 |
| 单独触发工作流 | `gh workflow run native-windows.yml -f toolset=msvc -f variant=x64_MD -f cfg=Release` | `8.5` |
| 观测 run | `gh run list --workflow=all.yml --limit 5`、`gh run watch <run-id> --exit-status`、`gh run view <run-id> --log` | `8.5`、release 卡 |
| 下载 artifact | `gh run download <run-id> -n <artifact>` | `F-09-06` |
| 发布 release | `gh release create v0.3.0 --target main --notes-file CHANGELOG.md` | `R-03` 等 |
| 分支保护（一次性） | `gh api -X PUT repos/jxsword/c-cpp-lib-lab/branches/main/protection ...`；**必须在 `main` / `develop` 首次 push 成功之后执行**（`2.1`、`F-00-01` 命令顺序） | `F-00-01` |

> **边界登记（P8，`11.2`）**：「所有开发测试都用 agent 调用 `gh` 完成」按上表解读 —— `gh` 负责 GitHub 交互与结果回写，**不替代** `gcc` / `cl` / `nmake` / `cmake` 等本地构建命令；本地批量构建仍由 `scripts/build_all.*` 完成，但由 agent 发起、结论经 `gh` 回写。若需改为「本地也必须只经 `gh` 触发的 CI 执行」，走 `hotfix/plan-*` 先改本计划。

#### 0.7.4 自包含声明与校验

| # | 声明 | 校验方式 |
|---|---|---|
| Z1 | 本计划不引用、不依赖任何外部文档；全文所有 `见 X.X` 形式的引用编号必须落在**本计划自有章节集合**（`0.x`–`12.x`、附录 A–H）内 | `F-00-02` lint 抽取形如 `见 <数字>.<数字>` 的引用并比对章节集合；`F-00-01` A4 用 `0.3.1` 的 sha256 BASE 校验 `docs/PLAN.md` 未被改写 |
| Z2 | 任务卡执行所需的接口契约、9 个 API、`.def`、CLI、组合定义、命令、断言全部在本文件内 | 第 5 章、第 7 章、第 6 章任务卡、附录 A–E |
| Z3 | 原需外部查阅的导出宏骨架、C/C++ 互操作规则、协议策略决策表已内联 | `12.F.2`、`12.F.3`、`12.G` |
| Z4 | **仓库内 `docs/PLAN.md` 为唯一权威副本**；启动前已存入该路径，M0 起**原样**纳入版本控制（不新建 / 不覆盖 / 不改写）；`/workspace` 同名文件仅为交付快照，不参与开发、不作断言基准 | `F-00-01` A4 用 `0.3.1` 记录的 sha256 **BASE** 校验；任何 `hotfix/plan-*` 先在计划侧修订，再同步该快照并重新执行 `0.3.1` 更新 BASE |

---

## 1. 项目总览

### 1.1 目标与成功标准

| 目标 | 成功标准 |
|---|---|
| 一套源码产出静态库 / 动态库、32/64、Debug/Release、5 类工具链 | **80 组合**（原生 24 + make 32 + cmake 24）全部 `--self-test` 退出码 0 |
| 三套构建方式全部**源码外构建** | 源码树内无任何 `.o/.obj/.a/.lib/.so/.dll/.dylib/.pdb/CMakeCache.txt`；全部产物在 `build/<group>/...` |
| 覆盖三大 OS 与指定工具链 | Linux gcc 32/64；Windows msvc(32/64 × /MD /MT)、msys2 四环境、clang-cl 64；macOS clang 64 —— 均有实跑记录 |
| **静态**分析全部产物 | `SA-1…SA-10` 在 80 个组合上都有结论表（含编译器版本与依赖树），且分析脚本扫描无禁用调用 |
| 运行输出可追溯 | 每组合的 stdout/stderr/退出码进 artifact，并汇总进 `$GITHUB_STEP_SUMMARY` |
| CI 环境与大包全部缓存 | `8.3` 每个缓存对象均有 key、path、失效条件与命中率记录 |
| 三阶段语言演进 | 纯 C → C++ 调 C 库 → 纯 C++ OOP，各含**期望失败**的反例实验 |
| 可交付 | `v1.0.0` 的 `--bundle` 产物在干净目标机零额外安装即可运行 |

### 1.2 范围与非目标

| 范围内 | 非目标（明确不做，避免范围蔓延） |
|---|---|
| C / C++ 链接库的构建、链接、**静态**分析、打包、安全 | 引入真实 GPL/LGPL 第三方库做链接实验（协议策略以**本计划 `12.G` 决策表**为文档结论） |
| CLI 程序（无 GUI、无网络、无第三方运行时依赖） | 图形界面、包管理器发布、真实产品签名证书 |
| 反例实验做成**期望失败的 negative test** | 把反例合入 `main` 导致 CI 常红 |
| 三平台 CI 与 artifact、运行输出采集 | **分析阶段**的任何动态加载 / 运行（`ldd`、`dlopen`、`LoadLibrary`、`LD_DEBUG` 等） |
| macOS 64 位 + 附加 x86_64/universal 验证 | macOS 32 位（客观不可实现，见 `5.6 C1`） |
| Linux clang 作为**不计数组的本地可选验证** | 把 Linux clang 计入 24 组合矩阵（用户明确只列 gcc） |

### 1.3 命名约定（全仓库强制）

| 对象 | 规则 | 示例 |
|---|---|---|
| 仓库 / 根目录 | `c-cpp-lib-lab` | — |
| 库 / 可执行 | `vmath` / `calctool`（产物前缀按平台适配） | `libvmath.a`、`vmath.dll`、`libvmath.dylib` |
| **组合标签** | `<os>_<toolset>_<variant>_<cfg>` | `linux_gcc_x86_Debug`、`win_msvc_x64_MD_Release`、`win_msys2_MINGW32_Debug`、`win_clangcl_x64_Debug`、`macos_clang_arm64_Release` |
| 变体 `variant` | Linux gcc：`x86`/`x64`；msvc：`x86_MD`/`x86_MT`/`x64_MD`/`x64_MT`；msys2：`MINGW64`/`MINGW32`/`CLANG64`/`UCRT64`；clang-cl：`x64`；macOS：`arm64` | — |
| 配置值 | `Debug` / `Release` | — |
| 库形态（**组合内**） | `static` / `shared`，作为每个组合下的子目录，**不进入组合标签** | `build/native/linux_gcc_x86_Debug/static/` |
| 构建组 | `native` / `make` / `cmake`；make 组方言 `gnu` / `nmake` / `msbuild` | — |
| 报告目录 | `reports/<tag>/<group>/<组合标签>.{md,json}` | `reports/v1.0.0/native/win_msvc_x64_MD_Release.md` |
| 导出宏前缀 | 一律 `CALC_`，禁止无前缀宏 | `CALC_API`、`CALC_BUILD_DLL` |
| 任务卡号 | `F-<里程碑>-<序号>`；发布卡 `R-<里程碑>` | `F-05-02`、`R-05` |

### 1.4 构建目录布局（out-of-source，强制）

**三套构建方式各自一个顶层子目录，源码树内零产物**：

```
build/                                     # 整体被 .gitignore 忽略
├── native/<组合标签>/{static,shared}/       # ① 编译器原生命令
├── make/                                  # ② makefile + msbuild 组
│   ├── gnu/<组合标签>/{static,shared}/     #   GNU make（Linux / macOS / msys2）
│   ├── nmake/<组合标签>/{static,shared}/   #   MSVC nmake（msvc / clang-cl）
│   └── msbuild/<组合标签>/{static,shared}/ #   MSBuild（仅 msvc）
└── cmake/<组合标签>/{static,shared}/       # ③ CMake（msvc 用 Ninja 生成器）
```

| 构建方式 | 实现 out-of-source 的手段 | 禁止 |
|---|---|---|
| ① 原生命令 | 所有 `-o` / `/Fo` / `/OUT:` 指向 `build/native/...`；脚本 `cd` 到产物目录再执行，用 `-I<abs-src>/include` | 在 `src/` 下生成 `.o` |
| ② GNU make | `cd build/make/gnu/<tag>/<kind> && make -f <abs-src>/Makefile srcdir=<abs-src> ...`；Makefile 全部路径用 `$(srcdir)` 与 `$(outdir)` | 依赖 `.` 为源码目录 |
| ② nmake | `cd build/make/nmake/<tag>/<kind> && nmake /f <abs-src>\Makefile.nmake SRCDIR=<abs-src> ...` | 同左 |
| ② msbuild | `msbuild vmath.vcxproj /p:OutDir=<abs-build>\ /p:IntDir=<abs-build>\obj\ /p:Configuration=...` | 默认 `Debug\`、`x64\` 落到源码树 |
| ③ CMake | `cmake -S <src> -B build/cmake/<tag>/<kind>`（天然 out-of-source）；Ninja 时 `-G Ninja` | 在源码目录直接 `cmake .` |

**`.gitignore` 关键项**（`F-00-01` 建立、`F-00-02` 断言）：

```gitignore
/build/
/out/
/reports/**/*.log
CMakeCache.txt
CMakeFiles/
*.o
*.obj
*.a
*.lib
*.so
*.so.*
*.dll
*.dylib
*.pdb
*.ilk
*.exp
*.dSYM/
```

> **v1.3.2 注**：gitignore 语法一行一 pattern，二进制清单必须逐行列出——单行空格连写会被当作单个含空格 pattern 而静默失效（`F-00-01` 实测：独立 `x.o` 未被忽略、A3 断言 FAIL 后按本形式展开）。仓库 `.gitignore` 自 `F-00-01` 起即按逐行实现，本修订仅为使计划文本与实现对齐。

> **组合内双形态**：每个组合必须同时产出 `static/` 与 `shared/` 两套产物（库 + 对应 `calctool`），作为**组合内必建项**，不额外乘组合数。此解读登记为待拍板 **P3**（`11.2`）。

---

## 2. git flow 分支模型

### 2.1 分支类型与生命周期

| 分支 | 从哪开出 | 合回哪里 | 存活期 | 用途 |
|---|---|---|---|---|
| `main` | — | — | 永久 | 只含可发布状态；每个里程碑 tag 落在此分支；禁止直接 push |
| `develop` | `main` | — | 永久 | 集成主线；所有 feature 的唯一合并目标 |
| `feature/*` | `develop` | `develop`（PR + `--no-ff`） | 单卡 | 一卡一分支，卡完成即删 |
| `release/*` | `develop` | `main` **且** 回迁 `develop` | 里程碑验证期 | 跑该里程碑全量矩阵、修发布缺陷、生成 CHANGELOG 与报告 |
| `hotfix/*` | `main`（对应 tag） | `main` **且** 回迁 `develop` | 短 | 修已发布里程碑缺陷；登记到 `11.1` 风险册 |
| `hotfix/plan-*` | `main` | `main` + `develop` | 短 | 修订本计划文件（`0.5`） |

标准流程命令。**主分支必须是 `main`**，不能沿用 `git flow init -d` 的默认 `master`；**`origin` 必须为 SSH**（`0.7.1`）；**所有合并走 `gh` PR，不执行 `git flow feature finish` / `release finish` 的本地合并动作**（git-flow 仅用于 `init` 配置与 `start` 建分支）：

```bash
# F-00-01：在已存在的目录内初始化（含且仅含 docs/PLAN.md；禁止再 mkdir / git clone / 改写 PLAN）
cd c-cpp-lib-lab
git init -b main
git remote add origin git@github.com:jxsword/c-cpp-lib-lab.git
git flow init -d
git config gitflow.branch.master  main
git config gitflow.branch.develop develop
git config gitflow.prefix.feature  feature/
git config gitflow.prefix.release  release/
git config gitflow.prefix.hotfix   hotfix/
git config gitflow.prefix.versiontag v
git switch -c develop main 2>/dev/null; git switch develop   # develop 已存在时由第二条命令兜底切过去
git push -u origin main
git push -u origin develop
# 顺序硬约束：两条长期分支 push 成功后，才设置分支保护（否则规则无分支可绑定）
gh api -X PUT repos/jxsword/c-cpp-lib-lab/branches/main/protection ...   # 仅一次
ssh -T git@github.com                # F-00-01 A9：SSH 连通性
gh auth status && gh repo view jxsword/c-cpp-lib-lab

# 单卡：feature → develop（GitHub 侧一律 gh）
git flow feature start m5-02-nmake-makefile
# ... 改动 / 断言 / commit ...
git push -u origin feature/m5-02-nmake-makefile
gh pr create --base develop --head feature/m5-02-nmake-makefile --title "feat(nmake): ..." --body "卡号 / 断言结果 / 已知偏差"
gh pr checks <n>
gh pr merge <n> --merge --delete-branch       # 保留合并提交（等效 --no-ff）

# 里程碑：release → main + 回迁 develop + tag
git flow release start 0.5.0
# ... gh workflow run / gh run watch 跑全量矩阵；CHANGELOG、报告 ...
gh pr create --base main    --head release/0.5.0 --title "release 0.5.0" --body "..."
gh pr create --base develop --head release/0.5.0 --title "back-merge 0.5.0" --body "..."
git tag -a v0.5.0 -m "M5" main
git push origin main develop --follow-tags
gh release create v0.5.0 --target main --notes-file CHANGELOG.md
```

> **版本差异兜底**：不同 `git-flow` 版本的 `-d` 对生产分支默认值处理不同。初始化后校验并修正：若出现 `master` 则 `git branch -m master main`，最终以 **`main`/`develop` 均存在、`gitflow.branch.master == main`** 为准（`F-00-01` A2 断言）。未安装 `git-flow` 扩展时，`CONTRIBUTING.md` 给出等价原生 git 命令并写入同样的 `gitflow.*` 键，**分支命名与合并拓扑不变**。
> **合并方式说明**：`git flow feature finish` / `release finish` 会在本地直接合并，与「GitHub 侧一律走 `gh`」冲突，因此**只使用 `git flow init` 与 `start` 子命令**；`finish` 的等效动作由 `gh pr merge` 与 `git tag -a` 完成，`--no-ff` 合并拓扑不变（`2.3`）。同一 `release/*` 分支向 `main` 与 `develop` 各开一个 PR 实现「合入 + 回迁」。
> **tag 与 GitHub Release**：`git tag -a` 的附注 tag 经 `git push --follow-tags` 推送；`gh release create` 只创建 GitHub Release，不替代本地 tag。

### 2.2 分支命名规范（写死）

```
feature/m<n>-<2位序号>-<kebab-slug>    例：feature/m5-02-nmake-makefile
release/<semver>                       例：release/0.5.0
hotfix/<semver>                        例：hotfix/0.5.1
hotfix/plan-<序号>                     例：hotfix/plan-01
tag: v<semver>                         例：v0.5.0（附注标签）
```

### 2.3 保护规则与合并策略

| 规则 | 内容 |
|---|---|
| `main` / `develop` | 禁止直接 push；只接受 PR；`main` 的 PR 只来自 `release/*` 或 `hotfix/*` |
| feature PR | 必须：断言全 PASS、`docs/PLAN.md` 的 `3.1` 勾选清单对应卡打勾、CHANGELOG 追加一行、**无 `build/` 产物入库**、**编码/换行 lint 通过** |
| `--no-ff` | feature / release 合并保留合并提交，保证「一卡一节点」可追溯 |
| 禁止入库 | `build/`、`out/`、所有二进制与中间产物（见 `1.4` 的 `.gitignore`） |
| **编码 / 换行门禁** | `*.ps1` 必须 UTF-8 BOM；`*.bat` 必须 CRLF 且无 BOM；`*.sh` 必须 LF 无 BOM（见 `5.10`） |
| **静态分析门禁** | `scripts/analyze_*` / `scripts/static_analyze_*` 不得含 `5.8.4` 禁用调用（lint 关键字扫描） |
| 大文件 | CI artifact 走 `actions/upload-artifact`；缓存走 `actions/cache`，均不进 git |

### 2.4 版本与 tag 策略

| 里程碑 | tag | 语义 |
|---|---|---|
| M0 | `v0.0.0` | 仓库骨架、lint、缓存与编码基线可用 |
| M1 | `v0.1.0` | 纯 C 四模式在单平台编译通过 |
| M2 | `v0.2.0` | ① 原生 Linux 4 组合 + 静态分析三层框架全绿 |
| M3 | `v0.3.0` | **Gate A**：③ CMake Linux 4 组合全绿 |
| M4 | `v0.4.0` | ① 原生三 OS 全 **24** 组合；静态分析三 OS 扩展 |
| M5 | `v0.5.0` | ② make 组 **32** 组合（GNU make 14 + nmake 10 + msbuild 8） |
| M6 | `v0.6.0` | ③ CMake **24** 组合（msvc 用 Ninja） |
| M7 | `v0.7.0` | 阶段 2：C++ 调 C 库 + 反例 |
| M8 | `v0.8.0` | **Gate B**：阶段 3 纯 C++ OOP + 反例 |
| M9 | `v1.0.0` | **Gate C**：3 组 CI + `all.yml` 全量 **80** 组合 + 缓存 + 打包 + 安全 + 报告 |

### 2.5 提交规范

```
<type>(<scope>): <简述，≤72 字符>

type   : feat | fix | docs | test | ci | build | refactor | chore
scope  : export | api | core | report | cli | stage2 | stage3 |
         scripts | make | nmake | msbuild | cmake | ci | cache | analyze |
         bundle | security | docs | plan | encoding
```

示例：`ci(cache): add apt/brew/msys2 package caches with per-combination keys`、`feat(analyze): add recursive dependency tree with realpath resolution`。

### 2.6 全局 DoD（每张卡与每个里程碑）

| # | 检查 |
|---|---|
| D1 | 卡上**全部断言 PASS**，断言输出已贴入回执 |
| D2 | 源码树无产物；所有构建落在 `build/<group>/...`（`git status --porcelain` + `find . -name '*.o'` 双重断言） |
| D3 | 新增/修改文件路径与 `4.2` 文件归属表一致 |
| D4 | 提交信息符合 `2.5`；一个 feature 分支不混入其他卡改动 |
| D5 | PR 描述含「卡号 / 断言结果 / 已知偏差」三节 |
| D6 | `CHANGELOG.md` 追加一行；`docs/PLAN.md` 的 `3.1 任务卡勾选清单` 中该卡由 `- [ ]` 改 `- [x]`（引导期分期生效见下表） |
| D7 | 里程碑 release：产出 `reports/<tag>/SUMMARY.md`（SA-1…SA-10 结论矩阵 + RV 摘要） |
| D8 | release 合入 `main` 后打附注 tag，摘要回填 CHANGELOG |
| D9 | **编码/换行**：`scripts/tools/check_encoding.*` 全绿（`2.3`） |
| D10 | **静态分析禁令**：`5.8.4` 关键字扫描零命中 |
| D11 | 涉及 CI 的卡：缓存命中/未命中记录写入回执与 Job Summary |

> **分期生效表（引导期例外，v1.3 / M3）**：D1 的 `scripts/verify_card.sh` 与 `tests/assertions/*.yml` 到 `F-02-05` 才建立；D9 的 `check_encoding.*`、D10 的 `scan_dynamic_calls.sh` 到 `F-00-04` 才建立。**脚本未建不构成 FAIL**，按下表分阶段执行：
>
> | 阶段 | 不适用 | 替代做法 |
> |---|---|---|
> | `F-00-01` … `F-00-03` | **D9 / D10**（校验脚本未建） | 由 agent **逐条执行卡上命令**、把原始输出贴入回执；编码 / 换行只对本卡新增文件做内联检查 |
> | `F-00-04` … `F-02-04` | **D1 的 `verify_card` 自动入口**（`F-02-05` 才建） | 断言仍逐条由 agent 执行卡上命令判定并贴原始输出；D9 / D10 自本阶段起生效 |
> | `F-02-05` 起 | — | D1–D11 全部生效，`scripts/verify_card.sh <卡号>` 为唯一断言入口 |
>
> 每张 `F-00-*` 卡的「适用 D 项」以本表为准；卡上 DoD 显式标注适用 D 项，不得因脚本缺失判定 FAIL。

---

## 3. 里程碑 × 分支 × tag 总表

| 里程碑 | 主题 | 档位 | feature 卡 | release | tag | 里程碑验收门槛 |
|---|---|---|---|---|---|---|
| **M0** | 仓库 / git flow / lint / **缓存与编码基线** | A | F-00-01 … F-00-04 | R-00 | `v0.0.0` | 干净克隆、lint 绿、缓存复合 action 可调用、编码校验脚本可跑 |
| **M1** | 阶段 1 纯 C 源码与接口契约 | A | F-01-01 … F-01-06 | R-01 | `v0.1.0` | 四模式 M1–M4 编译通过；负例 `dllimport`+静态库按预期失败 |
| **M2** | ① 原生 Linux 4 组合 + **静态分析三层框架** | A | F-02-01 … F-02-05 | R-02 | `v0.2.0` | 4 组合 × 双形态全绿；SA-1…SA-10 有结论；依赖树含符号链接 realpath；禁用调用扫描零命中 |
| **M3** | ③ CMake Linux 4 组合（**Gate A**） | A | F-03-01, F-03-02 | R-03 | `v0.3.0` | CTest 4 组合 × 双形态全绿；out-of-source 与 RPATH 断言一致 |
| **M4** | ① 原生三 OS 全 **24** 组合 | B | F-04-01 … F-04-05 | R-04 | `v0.4.0` | 24 组合 × 双形态全绿；编译器名+版本、依赖树三 OS 齐全；SKIP 有据 |
| **M5** | ② make 组 **32** 组合 | B | F-05-01 … F-05-04 | R-05 | `v0.5.0` | GNU make 14 + nmake 10 + msbuild 8 全绿；`Makefile.nmake` 独立；CRT 断言成立 |
| **M6** | ③ CMake **24** 组合（msvc Ninja） | B | F-06-01, F-06-02 | R-06 | `v0.6.0` | 24 组合全绿；msvc `-G Ninja`；`CMAKE_MSVC_RUNTIME_LIBRARY` 联动 |
| **M7** | 阶段 2 C++ 调 C 库 | B | F-07-01 … F-07-03 | R-07 | `v0.7.0` | `extern "C"` 守卫生效；`std::vector` 数据指针传入；反例按预期失败 |
| **M8** | 阶段 3 纯 C++ OOP（**Gate B**） | B | F-08-01 … F-08-04 | R-08 | `v0.8.0` | 2 类 / 3 源 / 2 头；mangling、ABI 面、STL 跨 CRT 反例与门面修复均有记录 |
| **M9** | **3 组 CI + 全量 80 + 静态分析/运行输出 + 打包 + 安全 + 报告** | C | F-09-01 … F-09-09 | R-09 | `v1.0.0` | `all.yml` 80 组合全绿；缓存全生效；SA/RV 报告齐全；干净机零安装运行；README 与报告完整 |

**依赖链**：每里程碑前置为上一里程碑 tag；M9 额外依赖 M2/M4/M5/M6 的全部脚本稳定。

### 3.1 任务卡勾选清单（v1.3 / M2）

> `D6`、`2.3` 与第 6 章读卡说明中的「打勾」**一律指本节**：每完成一张卡，把对应 `- [ ]` 改为 `- [x]`，随该卡 PR 一起提交。**这是 `docs/PLAN.md` 中唯一的状态记录位置**，不在卡标题下另加勾选框。引导期（校验脚本未建）按 `2.6` 分期生效表执行。

**Feature 卡（44）**

- [x] `F-00-01` · 仓库与 git flow 初始化（含 SSH 关联与 gh 前置校验）
- [x] `F-00-02` · lint 门禁（含编码 / 静态分析禁令扫描）
- [x] `F-00-03` · **CI 缓存基础设施（S1）**
- [x] `F-00-04` · **编码与换行规范落地（S6）**
- [x] `F-01-01` · 导出宏头
- [x] `F-01-02` · 公共 API 与 `.def`
- [x] `F-01-03` · 库核心
- [x] `F-01-04` · 库报告与资源
- [x] `F-01-05` · CLI 主程序
- [x] `F-01-06` · 四模式冒烟 + 反例
- [x] `F-02-01` · 原生命令脚本（out-of-source）
- [x] `F-02-02` · Unix 动态加载分支（**属 RV**）
- [x] `F-02-03` · **静态分析三层框架 + 依赖树（S7 核心）**
- [x] `F-02-04` · 静态分析结论报告
- [x] `F-02-05` · **运行输出采集 + 断言基线与验收入口（S8）**
- [x] `F-03-01` · CMakeLists 与 CTest
- [x] `F-03-02` · out-of-source / RPATH 断言与基线文档
- [x] `F-04-01` · macOS 原生与静态分析脚本（bash）
- [x] `F-04-02` · Windows 原生脚本（**bat + ps1**）与 18 组合
- [x] `F-04-03` · Windows 动态加载（按名 + ordinal，**属 RV**）
- [x] `F-04-04` · **静态分析三 OS 扩展（S7）**
- [x] `F-04-05` · 24 组合矩阵收口与约束记录
- [x] `F-05-01` · GNU make（14 组合）
- [x] `F-05-02` · **nmake 单独 makefile（10 组合，S9）**
- [x] `F-05-03` · MSBuild（8 组合）
- [x] `F-05-04` · 32 组合横向对比
- [x] `F-06-01` · CMake 三 OS 24 组合
- [x] `F-06-02` · CTest 三 OS 与 out-of-source 断言
- [x] `F-07-01` · C++ 主程序
- [x] `F-07-02` · 反例：去掉 `extern "C"`
- [x] `F-07-03` · `std::vector` 跨边界用例
- [x] `F-08-01` · `Vector` 类
- [x] `F-08-02` · `Statistics` 类与 3 源 / 2 头
- [x] `F-08-03` · `extern "C"` 门面与纯虚接口
- [x] `F-08-04` · 反例：STL 跨 CRT 与 ABI 面膨胀
- [x] `F-09-01` · **可复用环境/组合工作流与全量缓存（S1 / S5）**
- [x] `F-09-02` · **Group N：原生组 3 条工作流（24 组合）**
- [x] `F-09-03` · **Group M：make 组 4 条工作流（32 组合）**
- [x] `F-09-04` · **Group C：cmake 组 3 条工作流（24 组合）**
- [x] `F-09-05` · **静态分析与运行输出工作流（S7 / S8）**
- [x] `F-09-06` · **`all.yml` 全量 80 组合编排（S5 收口）**
- [x] `F-09-07` · 打包脚本
- [x] `F-09-08` · 安全演示
- [x] `F-09-09` · 汇总报告与发布

**Release 卡（10）**

- [x] `R-00` · 发布 `v0.0.0`
- [ ] `R-01` · 发布 `v0.1.0`
- [x] `R-02` · 发布 `v0.2.0`
- [x] `R-03` · 发布 `v0.3.0`（Gate A）
- [x] `R-04` · 发布 `v0.4.0`
- [x] `R-05` · 发布 `v0.5.0`
- [x] `R-06` · 发布 `v0.6.0`
- [x] `R-07` · 发布 `v0.7.0`
- [x] `R-08` · 发布 `v0.8.0`（Gate B）
- [x] `R-09` · 发布 `v1.0.0`（Gate C）

---

## 4. 仓库目录结构与文件归属

### 4.1 目录树（M9 完成时的最终形态）

```
c-cpp-lib-lab/
├── .github/
│   ├── workflows/
│   │   ├── lint.yml                  # PR 门禁（含编码/换行/静态分析禁令扫描）
│   │   ├── _env.yml                  # reusable：环境安装 + 全量缓存（workflow_call）
│   │   ├── _combo.yml               # reusable：单组合 构建/静态分析/运行输出（workflow_call）
│   │   ├── native-linux.yml  native-macos.yml  native-windows.yml
│   │   ├── make-linux.yml   make-macos.yml    make-windows.yml
│   │   ├── msbuild-windows.yml
│   │   ├── cmake-linux.yml  cmake-macos.yml   cmake-windows.yml
│   │   ├── analyze.yml               # 静态分析（可单独 dispatch）
│   │   ├── run-output.yml            # 运行输出采集（可单独 dispatch）
│   │   └── all.yml                  # 全量 80 组合编排 + 汇总
│   ├── actions/setup-env/action.yml # composite：包安装 + 缓存恢复/保存
│   ├── apt-packages.txt             # Linux 包清单（纳入缓存 key）
│   ├── brew-packages.txt            # macOS 包清单
│   ├── msys2-packages.txt           # Windows/MSYS2 包清单（按 msystem 分段）
│   └── tool-versions.env            # CMake / Ninja / LLVM / Dependencies 版本锁定
├── .gitignore
├── .gitattributes                  # *.sh eol=lf | *.ps1 eol=crlf | *.bat -text（CRLF 保真）
├── LICENSE                         # MIT
├── README.md  CONTRIBUTING.md  CHANGELOG.md
├── Makefile                        # GNU make（Linux / macOS / msys2）
├── Makefile.nmake                  # MSVC nmake（msvc / clang-cl），单独文件
├── CMakeLists.txt  tests/CMakeLists.txt
├── vmath.vcxproj                   # MSBuild（仅 msvc）
├── include/calc_export.h  include/vmath.h
├── def/vmath.def                   # ordinal 1~6，@5 NONAME
├── src/vmath_core.c  src/vmath_report.c  src/calctool.c
├── stage2/main.cpp  stage2/README.md
├── stage3/include/{vector.hpp,stats.hpp}
│         src/{vector.cpp,stats.cpp,main.cpp}  facade.{h,cpp}  README.md
├── scripts/
│   ├── linux/    env.sh native.sh make.sh cmake.sh build_all.sh
│   │             static_analyze.sh deps_tree.sh run.sh bundle.sh    # bash, LF
│   ├── macos/    env.sh native.sh make.sh cmake.sh build_all.sh
│   │             static_analyze.sh deps_tree.sh run.sh bundle.sh    # bash, LF
│   ├── windows/  env.bat env.ps1                                    # bat:CRLF / ps1:UTF-8 BOM
│   │             native.bat native.ps1  nmake.bat nmake.ps1
│   │             msbuild.bat msbuild.ps1  cmake.bat cmake.ps1
│   │             build_all.bat build_all.ps1
│   │             static_analyze.bat static_analyze.ps1
│   │             deps_tree.ps1  run.bat run.ps1  bundle.bat bundle.ps1
│   ├── common.sh / common.ps1       # 组合标签解析、日志、断言输出格式
│   ├── tools/check_encoding.sh / check_encoding.ps1 / scan_dynamic_calls.sh
│   └── verify_card.sh / verify_card.ps1
├── tests/assertions/<card-id>.yml  tests/negative/  tests/fixtures/
├── docs/PLAN.md  docs/baseline.md  docs/REPORT.md  docs/ci-cache.md
├── reports/<tag>/<group>/<组合标签>.{md,json}
│           <tag>/deps/<组合标签>.{json,md}
│           <tag>/run/<组合标签>.txt
│           <tag>/SUMMARY.md
└── build/                          # .gitignore，见 1.4
```

### 4.2 文件归属表（哪个文件由哪张卡产出）

| 文件 / 目录 | 产出卡 | 文件 / 目录 | 产出卡 |
|---|---|---|---|
| git 仓库、`.gitignore`、`.gitattributes` 初版、`LICENSE`、`README.md` 初版、`CONTRIBUTING.md`、`CHANGELOG.md`、`docs/PLAN.md` | F-00-01 | `.github/workflows/lint.yml` | F-00-02 |
| `.github/{apt,brew,msys2}-packages.txt`、`tool-versions.env`、`actions/setup-env/action.yml`、`docs/ci-cache.md` | F-00-03 | `.gitattributes` 编码段、`scripts/tools/check_encoding.*`、`scan_dynamic_calls.sh` | F-00-04 |
| `include/calc_export.h` | F-01-01 | `include/vmath.h`、`def/vmath.def` | F-01-02 |
| `src/vmath_core.c` | F-01-03 | `src/vmath_report.c` | F-01-04 |
| `src/calctool.c` | F-01-05 | `tests/negative/` 初版、`scripts/linux/smoke_four_modes.sh`、`docs/baseline.md` 初版 | F-01-06 |
| `scripts/linux/{native.sh,common.sh}`、`scripts/common.sh` | F-02-01 | `src/calctool.c` 的 `--dynamic` Unix 分支 | F-02-02 |
| `scripts/linux/{static_analyze.sh,deps_tree.sh}`、三层分析框架 | F-02-03 | `scripts/linux/analyze.sh`、`reports/<tag>/` 模板 | F-02-04 |
| `tests/assertions/` 基线、`scripts/verify_card.sh`、`scripts/linux/run.sh` | F-02-05 | `CMakeLists.txt`、`tests/CMakeLists.txt` | F-03-01 |
| out-of-source/RPATH 断言、补全 `docs/baseline.md`（5.5–5.7） | F-03-02 | `scripts/macos/*`（bash 全套） | F-04-01 |
| `scripts/windows/*`（bat + ps1 全套） | F-04-02 | `--dynamic` Windows 分支（按名 + ordinal 5） | F-04-03 |
| 静态分析三 OS 扩展（otool/dumpbin/编译器版本/依赖树） | F-04-04 | 工具链映射表、SKIP/架构覆盖记录、`docs/baseline.md` 补全 | F-04-05 |
| `Makefile`（GNU make，14 组合） | F-05-01 | `Makefile.nmake`（nmake，10 组合） | F-05-02 |
| `vmath.vcxproj`（msbuild，8 组合） | F-05-03 | 32 组合横向对比与断言 | F-05-04 |
| `CMakeLists.txt` 三 OS + msvc Ninja（24 组合） | F-06-01 | CTest 三 OS、out-of-source/RPATH 断言 | F-06-02 |
| `stage2/main.cpp`、`stage2/README.md` | F-07-01 | 阶段 2 反例（去 `extern "C"`） | F-07-02 |
| 阶段 2 `std::vector` 用例 | F-07-03 | `stage3/include/vector.hpp`、`src/vector.cpp` | F-08-01 |
| `stage3/include/stats.hpp`、`src/stats.cpp`、`src/main.cpp`、`stage3/README.md` | F-08-02 | `stage3/facade.{h,cpp}` | F-08-03 |
| STL 跨 CRT 反例 + 修复记录 + mangling 对照 | F-08-04 | `_env.yml`、`_combo.yml`、缓存矩阵落地 | F-09-01 |
| `native-{linux,macos,windows}.yml` | F-09-02 | `make-{linux,macos,windows}.yml`、`msbuild-windows.yml` | F-09-03 |
| `cmake-{linux,macos,windows}.yml` | F-09-04 | `analyze.yml`、`run-output.yml`、SA/RV 汇总脚本 | F-09-05 |
| `all.yml` 全量编排 + 汇总 artifact | F-09-06 | `scripts/{linux,macos,windows}/bundle.*`、实现 `--bundle` | F-09-07 |
| `scripts/{linux,macos,windows}/security_hijack_demo.*`、`docs/baseline.md` 安全章节 | F-09-08 | `docs/REPORT.md`、`README.md` 终版、`CHANGELOG` 终版、发布注解 | F-09-09 |

### 4.3 许可与合规约定

- 项目自身源码 **MIT**（`LICENSE` 由 F-00-01 建立），避免演示代码自身引入链接合规噪声。
- GPL / LGPL / MPL / Apache-2.0 静动态链接策略矩阵内联于本计划 **`12.G`**，并以 `docs/baseline.md` 的**决策表**呈现，不引入真实受限依赖。
- `--bundle` 产物必须随包携带自带第三方库的许可证与 NOTICE（F-09-07 断言）。
- Debug CRT（`*d.dll`）**不得**进入任何发布包或发布 artifact。

---

## 5. 技术基线（开发前冻结，自包含）

> 本节是计划**不依赖翻阅大纲**的关键。M0 完成后复制为 `docs/baseline.md`。

### 5.1 接口契约：`calc_export.h` 四模式

| 模式 | 产物 | 库侧定义 | 使用侧定义 | `CALC_API` 展开 |
|---|---|---|---|---|
| **M1 静态库** | `.a` / `.lib` | `CALC_STATIC` | `CALC_STATIC` | 空（**禁止 dllimport**，否则 MSVC 报 `__imp_foo`） |
| **M2 动态·导出侧** | `.dll`/`.so`/`.dylib` | `CALC_BUILD_DLL` | — | PE：`__declspec(dllexport)` / `__attribute__((dllexport))`；ELF/Mach-O：`visibility("default")` |
| **M3 动态·导入侧** | 导入库 / `-l` | — | 无（或 `CALC_USE_DLL`） | PE：`dllimport`；ELF/Mach-O：`visibility("default")` |
| **M4 不生成库** | 源码直编 / header-only | `CALC_NO_LIB` | `CALC_NO_LIB` | 空；header-only 用 `static inline` |

结构顺序不可乱：① 平台判定（`_WIN32`/`_WIN64`/`__CYGWIN__`/`__APPLE__`）→ ② `CALC_EXTERN_C_BEGIN/END`（`__cplusplus` 判定）→ ③ 四模式分派 → ④ **`CALC_CALL` 在 32 位 Windows 统一 `__cdecl`**（不得用 `__stdcall`：x86 COFF 会产生 `_foo@N`，与 `.def` 未修饰名不匹配，`GetProcAddress("vmath_add")` 失败）→ ⑤ **本项目刻意不导出任何数据符号**，错误码走访问器 → ⑥ `CALC_DEPRECATED(msg)`（可选）。宏名全部 `CALC_` 前缀。

### 5.2 `vmath.h` 公共 API（9 个符号）

| # | 声明 | 位置 | 说明 |
|---|---|---|---|
| 1 | `CALC_API double CALC_CALL vmath_add(double, double)` | `vmath_core.c` | 标量，最简导出 |
| 2 | `CALC_API int CALC_CALL vmath_dot(const double*, const double*, size_t, double*)` | `vmath_core.c` | 指针 / `size_t`（32-64 宽度差异）、错误码 |
| 3 | `CALC_API const char* CALC_CALL vmath_build_info(void)` | `vmath_report.c` | **静态字符串**，含位数、数据模型、`sizeof(long)`、`sizeof(void*)`、编译器、`NDEBUG`/`_DEBUG`、`_ITERATOR_DEBUG_LEVEL`、库形态、CRT 模式 |
| 4 | `CALC_API void CALC_CALL vmath_free(void*)` | `vmath_report.c` | 库侧释放，跨 CRT 安全 |
| 5 | `CALC_API int CALC_CALL vmath_last_error(void)` | `vmath_core.c` | **错误码访问器**，跨 CRT / 跨编译器的正确做法 |
| 6 | `CALC_API void CALC_CALL vmath_set_logger(vmath_log_fn)` | `vmath_report.c` | 回调注册；`typedef void (CALC_CALL *vmath_log_fn)(const char*)` |
| 7 | `extern int vmath_errno;`（**裸符号，无 `CALC_API`、不进 `.def`**） | `vmath_core.c` | 教学对照：gcc/MinGW 默认导出、MSVC 默认不导出；**消费者禁止直接引用** |
| 8 | `static double normalize_(double)` | `vmath_core.c` | 内部符号，导出表中不应出现 |
| 9 | `main()` | `calctool.c` | CLI 入口 |

**导出集断言**：动态库恰好 **6 个 API**；gcc/MinGW 下**额外**出现 `vmath_errno`；MSVC 下**不出现**；`normalize_` 任何平台都不在动态导出表。

### 5.3 `def/vmath.def`（固定导出顺序与位置）

```def
LIBRARY "vmath"
EXPORTS
    vmath_add        @1
    vmath_dot        @2
    vmath_set_logger @3
    vmath_free       @4
    vmath_build_info @5  NONAME   ; 隐藏名字，Windows 只能按 ordinal 5 取址
    vmath_last_error @6
; vmath_errno 刻意不列入 EXPORTS（含 DATA 也不行）：
; 一旦列出，MSVC 也会导出该裸符号，默认导出行为的教学对照即失效。
```

> **ordinal 只在 PE 存在**：ELF / Mach-O 无序号概念，`.dynsym` 索引不稳定。Unix 侧用「按名 + 函数表结构体成员位置」作为跨平台替代。Windows `--dynamic` 必须同时演示 `GetProcAddress(h, "vmath_add")`（按名）与 `GetProcAddress(h, MAKEINTRESOURCEA(5))`（按 ordinal）。

### 5.4 CLI 规格与错误处理

```
calctool <command> [args] [options]
```

| 命令 | 行为 | 覆盖点 |
|---|---|---|
| `add <a> <b>` | 调 `vmath_add`，经 logger 输出 | 基本链接、回调 |
| `dot <x1,x2,...> <y1,y2,...>` | 调 `vmath_dot`；错误码经 `vmath_last_error()` 读 | ABI、定宽类型、32/64、数据符号不跨边界 |
| `info` | 打印 `vmath_build_info()` | 组合自证，CI 断言输出 |
| `probe` | 打印自身 / 库的架构、类型、依赖清单（**静态读取**，不运行外部分析器） | 工具集成 |
| `--dynamic` | 不链接库，改 `dlopen`/`LoadLibrary`；按名 + Windows ordinal 5 | 动态加载 / 卸载 / 取址（**属运行验证 RV，不属静态分析**） |
| `--self-test` | 断言 `add`/`dot`/`info` 预期值，返回退出码 | 唯一 CI 功能判据 |
| `--bundle` | 构建目标，产出「解压即用」目录 | 打包发布（本计划 `9.1` / F-09-07） |

**错误处理约定**：`dot` 长度不一致 → 返回非零码，库内置 `vmath_errno = VMATH_E_DIM`（消费方**只能**通过 `vmath_last_error()` 读取），同时经 `vmath_set_logger` 回调输出；`vmath_free` 负责释放库侧分配内存。

### 5.5 组合定义（v1.1 重写：**24 / 32 / 24 = 80**）

#### 5.5.1 基础组合 B = 24（用户明确指定，封闭列表）

| OS | 工具链 | 变体（位数 / CRT / 环境） | 配置 | 组合数 |
|---|---|---|---|---|
| **Linux** | `gcc` | `x86`、`x64` | Debug、Release | **2×2 = 4** |
| **Windows** | `msvc` | `x86_MD`、`x86_MT`、`x64_MD`、`x64_MT` | Debug、Release | **4×2 = 8** |
| **Windows** | `msys2` | `MINGW64`、`MINGW32`、`CLANG64`、`UCRT64` | Debug、Release | **4×2 = 8** |
| **Windows** | `llvm-clang`（按 `clang-cl` 处理，见 P6） | `x64` | Debug、Release | **1×2 = 2** |
| **macOS** | `clang`（Apple clang，64 位） | `arm64` | Debug、Release | **1×2 = 2** |
| | | | **合计** | **24** |

> Windows 小计 `(4+4+1)×2 = 18` ✓；Linux `2×2 = 4` ✓；macOS `1×2 = 2` ✓；总计 **24** ✓。
> **变更说明**：v1.0 的 Linux `clang` 组合按本轮明确列表**移出矩阵**，降为不计数组的本地可选验证；Windows 补齐 `MINGW32` 与 `clang-cl`；macOS 只保留 64 位。
> **组合内双形态**：每组合必建 `static/` 与 `shared/` 两套产物（P3，见 `11.2`）。

#### 5.5.2 三套构建方式 = 80

| 组 | 构建工具 | 覆盖范围 | 组合数 |
|---|---|---|---|
| **N 原生** | 编译器原生命令 | 全部 24 基础组合 | **24** |
| **M make 组** | GNU make（`Makefile`） | Linux 4 + macOS 2 + msys2 8 | 14 |
| **M make 组** | **nmake（`Makefile.nmake`，单独文件）** | msvc 8 + clang-cl 2 | 10 |
| **M make 组** | msbuild（`vmath.vcxproj`） | msvc 8 | 8 |
| | | **M 小计** | **32** |
| **C cmake** | CMake（**msvc 用 Ninja** 生成器） | 全部 24 基础组合 | **24** |
| | | **总计** | **80** |

`14 + 10 + 8 = 32` ✓；`24 + 32 + 24 = 80` ✓。

> **与本计划 v1.0 旧定义的关系**：v1.0 的「8 / 16 / 8」定义（位数×配置×库形态）由 v1.1 补充需求**取代**。库形态降级为组合内必建子目录；`/MD /MT` 上升为 Windows msvc 的**变体维度**（4 变体 × 2 配置 = 8）。原待拍板 **P1 已关闭**（`11.2`）。

#### 5.5.3 组合标签与每个组合的必做动作

组合标签 `<os>_<toolset>_<variant>_<cfg>`（见 `1.3`）。**每个组合**都必须：

1. 在 `build/<group>/<dialect>/<组合标签>/{static,shared}/` 下完成**源码外构建**；
2. 跑 `RV-1…RV-4`（运行验证），采集 stdout/stderr/退出码；
3. 跑 `SA-1…SA-10`（静态分析），产出结论表 + 依赖树 JSON/Markdown；
4. 四类一致性断言：位数 / 库形态 / Debug-Release / 编译器名+版本 / CRT 模式 与组合标签一致。

### 5.6 客观约束（写进 README 与 CI，不得绕过）

| # | 约束 | 处理 |
|---|---|---|
| C1 | macOS 10.15 起内核不再加载 32 位进程、SDK 无 i386 slice | 新定义中 macOS 仅 64 位；32 位由 Linux `x86` 与 Windows `x86` / `MINGW32` 承担；x86_64 + `lipo` universal 作**附加不计数组合**的架构覆盖验证 |
| C2 | Linux 32 位需 multilib | 装 `gcc-multilib` / `g++-multilib`（纳入缓存）；clang `-m32` 需 32 位 libc 开发包 |
| C3 | Windows x86 用 64 位宿主交叉 | `vcvarsall amd64_x86` / `ilammy/msvc-dev-cmd` 的 `arch: x86`；`MINGW32` 用 `i686-w64-mingw32-gcc` |
| C4 | MSVC Debug CRT 不可再分发 | CI 只验证构建与本地运行；debug 产物**不作为发布 artifact** |
| C5 | runner 无 GUI | Dependencies / MachOView 仅本地项；CI 用等价 **CLI 静态**工具 |
| C6 | 各 OS 无法原生产出其他 OS 格式 | CI 按 OS 分叉；Wine 仅可作冒烟 |
| C7 | ARM64 是 64 位另一分支 | macOS `arm64` 单列；x86_64 作附加验证 |
| C8 | msys2 的 `msys`（依赖 `msys-2.0.dll`）与 `mingw64/ucrt64/clang64` 产物不可混链；四环境产物亦**互不混用** | 脚本按 `msystem` 分目录，CI 用不同 `msystem` |
| C9 | **静态组合的目标文件必须以 `CALC_STATIC` 重新编译**，不可复用动态组合的 `.o` | 否则 `CALC_BUILD_DLL` / `-fvisibility=hidden` 残留；F-02-01 显式断言 |
| C10 | `visibility` 只在编译期生效 | 构建脚本统一注入 `-fvisibility=hidden`，分析脚本断言导出集 |
| C11 | 老目标机 `GLIBC_2.xx` / `GLIBCXX_3.4.xx` 基线 | 老基线构建 + `objdump -T` 检查 + 干净容器验证 |
| **C12** | **所有构建必须源码外** | `1.4` 目录布局 + `2.3` 禁止入库 + D2 断言 |
| **C13** | **所有分析必须静态** | `5.8.4` 硬禁令 + lint 关键字扫描（D10） |
| **C14** | **CI 大体积环境与安装包必须缓存** | `5.9` / `8.3`；缓存 key 含 OS+工具链+位数+配置 |
| **C15** | **脚本编码与换行** | `5.10`；ps1 UTF-8 BOM、bat CRLF 无 BOM、sh LF 无 BOM |
| **C16** | 32/64 与 `/MD /MT` 的编译缓存**不可跨组合复用** | 缓存 key 强制含 `arch`/`variant`/`cfg`（`8.3` K1） |
| **C17** | CI 分组须可单独触发、最后全量 | `8.2` 工作流清单 + `all.yml`（`workflow_call`） |
| **C18** | 运行验证与静态分析隔离 | 不同 step / 不同脚本 / 不同报告目录（`5.7`、`8.4`） |

### 5.7 分析与运行验证清单（v1.1 重写）

> **v1.0 的「12 项分析清单」被拆为 `SA-1…SA-10`（静态）+ `RV-1…RV-4`（运行）**。所有 SA 项**禁止执行目标程序、禁止动态加载**；所有 RV 项**不属于分析**。

#### 5.7.1 静态分析清单 SA-1…SA-10

| # | 检查项 | ① 系统/编译器内置工具 | ② 第三方工具（需安装） | ③ 自实现脚本 | 期望 / 输出 |
|---|---|---|---|---|---|
| **SA-1** | **32 / 64 架构** | `file`、`readelf -h`(Class/Machine)、`lipo -archs`、`otool -hv`、`dumpbin /headers`、`objdump -f` | `llvm-readobj --file-headers` | 归一为 `x86 / x64 / arm64` | 与组合标签一致 |
| **SA-2** | **编译器名称 + 版本号** | ELF：`readelf -p .comment`、`readelf --debug-dump=info \| grep DW_AT_producer`；Mach-O：`dwarfdump --debug-info`、`otool -l`；PE：`dumpbin /rawdata`（**Rich Header**）、`dumpbin /headers`(linker ver)、`strings` | `llvm-readobj --coff-rich-header`、`llvm-dwarfdump`、`pev/readpe` | 正则归一为 `gcc 11.4.0` / `clang 15.0.7` / `msvc 19.38.33130` / `apple-clang 15.0.0`，与构建时记录的 `cc --version` 比对 | 名称与版本**均**记录，缺失即 FAIL |
| **SA-3** | **Debug / Release** | `readelf -S \| grep debug`、`*.dSYM`、`dwarfdump`、`*.pdb`、`dumpbin /directives`(`libcmtd`/`libcmt`)、`dumpbin /symbols` | `llvm-dwarfdump` | 调试段存在 + `.rodata` 中 `NDEBUG`/`_DEBUG` 标记静态提取 | 与 CFG 一致 |
| **SA-4** | 库形态（静态 / 动态） | `ar t` vs `readelf -d`、`ar t` vs `otool -hv`、`lib /list`、`dumpbin /exports` | `llvm-readobj` | — | 与 `static/` 或 `shared/` 子目录一致 |
| **SA-5** | 导出符号集 | `nm -D --defined-only`、`nm -gU`、`dumpbin /exports`、`dyld_info -exports` | `llvm-nm` | 6 API 判定 + 裸符号平台差异 | 6 个 API；gcc/MinGW 额外 `vmath_errno`；MSVC 无；`normalize_` 不出现 |
| **SA-6** | 内部符号 | `nm`、`nm -m`、`dumpbin /symbols` | `llvm-nm` | — | `normalize_` 不在动态导出表 |
| **SA-7** | **直接依赖 + 符号链接追踪** | `readelf -d \| grep NEEDED`、`objdump -p`、`otool -L`、`dumpbin /dependents`；路径按 `RUNPATH`/`RPATH` + `ldconfig -p` **静态读取**、`@rpath` + `LC_RPATH`、PE 搜索顺序展开 | — | `readlink -f` / `Resolve-Path` 逐级追踪到**实际文件**，记录 `logical → real` 映射 | 每条依赖都有 realpath；静态组合无 `libvmath` 依赖 |
| **SA-8** | **递归依赖树（分级树形展示）** | `readelf -d` / `otool -L` / `dumpbin /dependents` 递归（脚本驱动） | `lddtree`(pax-utils)、`Dependencies` CLI、`dylibbundler`/`macdependency`、`llvm-readobj` | **自实现 BFS 树解析器**（`deps_tree.sh` / `deps_tree.ps1`）：收集 → realpath 去重 → 树形缩进 → JSON | `reports/<tag>/deps/<标签>.{json,md}`；区分「自带库 / 系统库 / API-Set / shared cache」 |
| **SA-9** | CRT / 运行库模式 | `readelf -d`、`otool -L`、`dumpbin /dependents`（`VCRUNTIME140.dll` 有无） | — | `/MD` vs `/MT` 断言 | 与 `variant` 中 `_MD`/`_MT` 一致 |
| **SA-10** | 搜索路径（静态） | `readelf -d`(RUNPATH/RPATH)、`otool -l`(LC_RPATH)、`install_name`、`dumpbin` | `patchelf --print-rpath` | 路径展开（**不执行 loader**） | `$ORIGIN` / `@rpath` / 同目录；无相对不安全路径 |

**依赖树输出示例（SA-8）**：

```
calctool [ELF64 x86-64]
├── libvmath.so.1 → libvmath.so.1.0.0        [自带]  /build/native/linux_gcc_x64_Release/shared/libvmath.so.1.0.0
│   ├── libm.so.6 → /lib/x86_64-linux-gnu/libm.so.6 → libm-2.35.so   [系统]
│   └── libc.so.6 → /lib/x86_64-linux-gnu/libc.so.6 → libc-2.35.so   [系统]
├── libdl.so.2 → ...                          [系统]
└── libc.so.6 (已见，去重)
```

```
calctool.exe [PE32+ x64 /MD]
├── vmath.dll                                 [自带]
│   ├── VCRUNTIME140.dll                     [VC++ Redist]
│   └── ucrtbase.dll → api-ms-win-core-*.dll [系统 / API Set]
└── KERNEL32.dll                             [KnownDLL]
```

```
calctool [Mach-O 64-bit arm64]
├── @rpath/libvmath.dylib → build/.../libvmath.dylib  [自带]
│   └── /usr/lib/libSystem.B.dylib                    [系统 shared cache，不落盘]
└── ...
```

#### 5.7.2 运行验证清单 RV-1…RV-4（**与静态分析严格隔离**）

| # | 项目 | 采集内容 | 输出去向 |
|---|---|---|---|
| **RV-1** | `calctool --self-test` | stdout + stderr + exit code | `reports/<tag>/run/<标签>.txt`、artifact、`$GITHUB_STEP_SUMMARY` |
| **RV-2** | `calctool info` | 组合自证输出（位数 / 编译器 / 配置 / 库形态 / CRT） | 同上 + 与组合标签比对断言 |
| **RV-3** | `calctool add 1.5 2.5`、`calctool dot ...` | 功能输出与错误码 | 同上 |
| **RV-4** | `calctool --dynamic ...`（按名 + Windows ordinal 5） | 动态加载路径输出（**功能演示，非分析**） | 同上 |

> **RV 不属于分析**：`--dynamic` 使用 `dlopen`/`LoadLibrary` 是**程序功能**，在 RV step 中运行；`5.8.4` 的禁令只约束 `scripts/analyze_*` 与 `scripts/static_analyze_*`。两者脚本文件、报告目录、CI step 均不同。

#### 5.7.3 旧 12 项 → 新清单映射（追溯用）

| v1.0 | v1.1 | 说明 |
|---|---|---|
| 1 架构 / 位数 | SA-1 | 加第三方与自实现层 |
| 2 动静态 | SA-4 | — |
| 3 Debug/Release | SA-3 | 加编译器版本无关，仅配置 |
| 4 导出符号集 | SA-5 | — |
| 5 内部符号 | SA-6 | — |
| 6 直接依赖 | SA-7 | **新增符号链接 realpath 追踪** |
| 7 递归依赖 | SA-8 | **升级为树形分级 + JSON** |
| 8 运行期路径 | SA-10 | **改为静态读取** |
| 9 CRT 模式 | SA-9 | — |
| 10 功能自证 | RV-1 / RV-2 | **移出分析** |
| 11 动态加载 | RV-4 | **移出分析** |
| 12 打包验证 | `9.1` 发布验收 | **移出分析** |
| — | **SA-2 编译器名+版本** | **本轮新增** |

### 5.8 静态分析三层规格（本轮新增重点）

#### 5.8.1 三层执行顺序（强制）

```
① 系统 / 编译器内置工具   →  原始输出（只读二进制结构，绝不执行）
        ↓
② 第三方工具（需安装）    →  交叉验证 / 补齐（lddtree、Dependencies、llvm-readobj…）
        ↓
③ 自实现 bash / powershell →  归一、去重、树形化、结论判定、JSON+Markdown 报告
```

三层都必须**只读取文件字节 / 段表 / 符号表 / 导入表**，不加载进进程地址空间、不调用目标导出函数、不启动目标程序。

#### 5.8.2 第三方工具清单（需安装，全部纳入缓存）

| 平台 | 工具 | 用途 | 安装来源 |
|---|---|---|---|
| Linux | `pax-utils`（含 `lddtree`）、`patchelf`、`llvm`（`llvm-readobj`/`llvm-nm`/`llvm-dwarfdump`）、`binutils`、`libabigail`(`abidiff`) | SA-1/2/3/8/10 交叉验证 | `.github/apt-packages.txt` → apt（缓存） |
| macOS | `llvm`、`binutils`、`dylibbundler` | SA-1/2/8 | `.github/brew-packages.txt` → brew（缓存） |
| Windows | `LLVM`(`llvm-readobj --coff-rich-header`)、`Dependencies` CLI、`pev`/`readpe` | SA-2/8 | `.github/tool-versions.env` 锁定版本 → 预下载二进制（缓存） |

> `lddtree` / `Dependencies` / `dylibbundler` 均为**解析文件结构的静态工具**（不执行目标程序），符合 C13；`ldd` 不属于此列（见 `5.8.4`）。

#### 5.8.3 自实现解析器规格

| 平台 | 脚本 | 输入 | 算法 | 输出 |
|---|---|---|---|---|
| Linux / macOS | `deps_tree.sh`（bash） | `readelf -d` / `objdump -p` / `otool -L` 文本 | BFS 队列；关联数组按 `realpath` 去重；`readlink -f` 逐级解析；`@rpath`/`$ORIGIN` 用 `LC_RPATH`/`RUNPATH` 展开；标记 `自带/系统/shared-cache` | 缩进树 `.md` + 结构化 `.json` |
| Windows | `deps_tree.ps1`（**UTF-8 BOM**） | `dumpbin /dependents` / Dependencies CLI 文本 | BFS；`Resolve-Path` + `Get-Item -Force` 判定 symlink/junction；API-Set 与 KnownDLL 归类 | 同上 |

JSON 结构：

```json
{
  "tag": "win_msvc_x64_MD_Release",
  "root": { "path": "calctool.exe", "arch": "x64", "compiler": "msvc 19.38.33130", "cfg": "Release" },
  "tree": [
    { "name": "vmath.dll", "logical": "vmath.dll", "real": ".../vmath.dll",
      "origin": "bundle", "children": [
        { "name": "VCRUNTIME140.dll", "real": "C:/Windows/System32/VCRUNTIME140.dll",
          "origin": "system", "children": [] }
      ]}
  ],
  "symlink_chains": [ ["libvmath.so.1", "libvmath.so.1.0.0"] ],
  "dedup": ["libc.so.6"]
}
```

#### 5.8.4 静态分析硬禁令（CI lint 扫描）

| 类别 | 禁止调用 / 命令 |
|---|---|
| 动态加载 | `dlopen`、`dlsym`、`dlclose`、`LoadLibrary`、`LoadLibraryEx`、`GetProcAddress`、`FreeLibrary`、`NSBundle`、`CFBundle` |
| 依赖解析（会执行） | **`ldd`**、`LD_TRACE_LOADED_OBJECTS`、`pldd`、`/proc/<pid>/maps`、`vmmap` |
| 运行期注入 / 跟踪 | `LD_DEBUG`、`LD_PRELOAD`、`DYLD_PRINT_LIBRARIES`、`DYLD_PRINT_RPATHS`、`DYLD_INSERT_LIBRARIES`、ProcMon `Load Image`、Process Explorer 模块列表 |
| 运行目标程序 | 执行 `calctool` / 任何被测二进制（**`RV` step 除外**） |
| 其他 | 任何需要启动进程才能得出「依赖」结论的手段 |

> `scripts/tools/scan_dynamic_calls.sh` 在 lint 中扫描 `scripts/analyze_*`、`scripts/static_analyze_*`、`scripts/{linux,macos,windows}/deps_tree.*`，命中即 FAIL（允许在**注释**中以 `FORBIDDEN:` 前缀引用，白名单除外）。

### 5.9 CI 缓存规格（本轮新增，S1）

#### 5.9.1 包清单文件（缓存 key 的 `hashFiles` 依据）

| 文件 | 内容 | 变更影响 |
|---|---|---|
| `.github/apt-packages.txt` | `gcc-multilib g++-multilib clang lld binutils pax-utils patchelf libabigail` 等 | Linux apt 缓存失效 |
| `.github/brew-packages.txt` | `llvm binutils dylibbundler pax-utils` 等 | macOS brew 缓存失效 |
| `.github/msys2-packages.txt` | 按 `MINGW64/MINGW32/CLANG64/UCRT64` 分段的 pacman 包 | MSYS2 缓存失效 |
| `.github/tool-versions.env` | CMake / Ninja / LLVM / Dependencies CLI 版本锁定 | 工具二进制缓存失效 |

#### 5.9.2 缓存对象矩阵

| 平台 | 大体积对象 | 缓存机制 | path | key（示例） |
|---|---|---|---|---|
| Linux | **apt deb 包** | `awalsh128/cache-apt-pkgs-action@latest` 或 `actions/cache@v4` | `/var/cache/apt/archives` | `apt-Linux-${{ hashFiles('.github/apt-packages.txt') }}` |
| Linux | **ccache / sccache 编译产物** | `actions/cache@v4` | `~/.cache/ccache` | `ccache-linux-gcc-<variant>-<cfg>-<kind>-${{ github.run_id }}` |
| macOS | **Homebrew 下载缓存** | `actions/cache@v4` | `~/Library/Caches/Homebrew`、`$(brew --cache)` | `brew-macOS-<arch>-${{ hashFiles('.github/brew-packages.txt') }}` |
| macOS | ccache | `actions/cache@v4` | `~/.cache/ccache` | `ccache-macos-clang-<variant>-<cfg>-<kind>-<run_id>` |
| Windows | **MSYS2 pacman 包** | `msys2/setup-msys2@v2` 的 `cache: true` | 内部 `/var/cache/pacman/pkg` | 由 action 按 `msystem` 内部管理 |
| Windows | **LLVM / Ninja / CMake / Dependencies CLI** | `actions/cache@v4` | `C:\tools\llvm`、`C:\tools\deps`、`C:\tools\ninja` | `win-tools-<toolset>-${{ hashFiles('.github/tool-versions.env') }}` |
| Windows | **sccache** | `actions/cache@v4` | `%LOCALAPPDATA%\sccache` | `sccache-win-<toolset>-<variant>-<cfg>-<kind>-<run_id>` |
| 全平台 | 第三方静态分析工具 | 并入上述包缓存（apt / brew / 预下载） | — | — |

> **不缓存**：MSVC 工具集与 Windows SDK（runner 预装，缓存无收益且体积过大）；`lddtree`/`Dependencies` 等小工具随包缓存一并命中。

#### 5.9.3 缓存规则（强制）

| # | 规则 |
|---|---|
| K1 | key **必须含 OS + toolset + variant(位数/CRT) + cfg**；32/64 与 `/MD`/`/MT` 的目标文件**不可跨组合复用**（C16） |
| K2 | 包清单文件变更 → `hashFiles` 变化 → 缓存自动失效 |
| K3 | `restore-keys` 只允许**同前缀**回退，禁止跨 toolset / variant |
| K4 | 跨 job 传递构建产物用 `upload-artifact` / `download-artifact`，**不用 `actions/cache`**（cache 不是产物通道） |
| K5 | 缓存命中 / 未命中写入 `$GITHUB_STEP_SUMMARY` 与卡回执（D11） |
| K6 | `all.yml` 全量运行复用前三组已建立的缓存，不重复下载；`workflow_run` / `workflow_call` 串联 |
| K7 | `actions/cache` 用 `save-always: true`（或显式 save step）保证失败 job 也能保存已下载包 |
| K8 | 缓存内容只读恢复；脚本不得写入缓存目录以外的路径 |

### 5.10 辅助脚本编码与换行规范（本轮新增，S6 / C15）

| 文件 | 编码 | 换行 | 强制方式 |
|---|---|---|---|
| `*.sh`（Linux / macOS bash） | UTF-8 **无 BOM** | **LF** | `.gitattributes: *.sh text eol=lf` + lint 断言 |
| `*.ps1`（Windows PowerShell） | **UTF-8 BOM**（首 3 字节 `EF BB BF`） | CRLF（建议） | `.gitattributes: *.ps1 text eol=crlf` + lint 断言首 3 字节 |
| `*.bat` / `*.cmd`（Windows 批处理） | UTF-8 **无 BOM**（cmd.exe 会把 BOM 当命令前缀，导致首行报错） | **CRLF 必须** | `.gitattributes: *.bat -text`（blob 保真）+ lint 断言 CRLF（无裸 LF） |
| `*.yml` / `*.md` / `*.c` / `*.h` / `*.cpp` / `*.hpp` / `Makefile*` | UTF-8 无 BOM | LF | `.gitattributes` |

`.gitattributes` 关键行：

```gitattributes
* text=auto
*.sh   text eol=lf
*.ps1  text eol=crlf
*.bat  -text
*.cmd  -text
*.yml  text eol=lf
*.md   text eol=lf
Makefile    text eol=lf
Makefile.nmake -text
```

> **注意**：`.gitattributes` 的 `eol` 只保证 checkout **换行**，**不能自动添加 BOM**。`*.ps1` 的 UTF-8 BOM 由**首个 `.ps1` 的产出卡 `F-00-04` 创建时写入**（v1.3 修正：`F-00-01` 不产出任何 `.ps1`），由 `scripts/tools/check_encoding.ps1` 与 lint 在每次 PR 校验；**D9 自 `F-00-04` 起生效**（`2.6` 分期生效表）。**v1.3.1 修正**：`text eol=crlf` 会在**提交时把 blob 归一化为 LF**（CI 检出再展开为 CRLF），lint 对 blob/检出内容的 CRLF 断言将**恒空转**——因此 `*.bat`/`*.cmd`/`Makefile.nmake` 改用 **`-text` 保真入库**（blob 原样保留 CRLF，lint 可断言「CRLF 必须」；`*.ps1` 维持 `eol=crlf`，其换行仅为建议、BOM 断言不受影响）。

**Windows 脚本分工**：`.bat` 作**薄入口**（`vcvarsall` / msys2 环境切换 + 调用对应 `.ps1`），`.ps1` 承担全部构建、分析、断言逻辑。两套文件都存在于 `scripts/windows/`，满足「windows 用 bat 和 powershell 脚本」。

**校验脚本**：`scripts/tools/check_encoding.sh`（Unix）、`check_encoding.ps1`（Windows，UTF-8 BOM）；lint workflow 在三个 OS 各跑一次。

---

## 6. 任务卡（核心）

> **读卡说明**：`前置` 为必须已存在的 tag 或已合并卡；`断言` 是 `tests/assertions/<卡号>.yml` 的内容源，由 `scripts/verify_card.sh <卡号>`（或 `.ps1`）执行 —— **该自动入口自 `F-02-05` 起才存在，此前见 `2.6` 分期生效表**；`DoD` 另须满足 `2.6` 的 D1–D11（分期适用）。分支名写死。状态在 `docs/PLAN.md` 的 `3.1 任务卡勾选清单` 中由 `- [ ]` 改 `- [x]`。

### M0 · 仓库 / git flow / 缓存与编码基线（Gate A，`v0.0.0`）

#### F-00-01 · 仓库与 git flow 初始化（含 SSH 关联与 gh 前置校验）

| 项 | 内容 |
|---|---|
| 分支 | `feature/m0-01-repo-skeleton` |
| 前置 | **本地 `c-cpp-lib-lab/` 目录已存在，内含且仅含 `docs/PLAN.md`、无 `.git`**（`0.7.2`）；远程 `jxsword/c-cpp-lib-lab` 已创建；`gh` 已登录；SSH 私钥可用（`0.7`）；**已完成 `0.3.1` 首次启动健康检查并记下 BASE** |
| 改动 | 在该目录内初始化仓库；**把已存在的 `docs/PLAN.md` 原样纳入首个提交（不新建、不覆盖、不改写，`0.7.2`）**；新建 `.gitignore`（含 `1.4` 全部条目）、`.gitattributes` 初版、`LICENSE`(MIT)、`README.md` 初版、`CONTRIBUTING.md`（含 `0.7` 前置、`0.3.1` 健康检查、gh 操作矩阵、`2.6` 分期生效表）、`CHANGELOG.md`、`4.1` 占位目录骨架；把 `3.1` 勾选清单的 `F-00-01` 打勾 |
| 要点 | `git init -b main` → `git remote add origin git@github.com:jxsword/c-cpp-lib-lab.git`（**SSH**）→ `git flow init -d` 后覆写 `gitflow.*` 使主分支为 `main`（`2.1`）→ 首次 push 两条长期分支；`CONTRIBUTING.md` 写入 `0.3`/`0.4`/`0.7`/`2.1`–`2.5`；`.gitignore` 覆盖 `build/`、`out/` 与全部二进制；`docs/PLAN.md` 原样纳入提交、为**唯一权威副本**（`0.7.2`、`0.7.4` Z4）；**先 push 两条长期分支，再设置分支保护**（`0.7.3`） |
| 命令 | `git init -b main && git remote add origin git@github.com:jxsword/c-cpp-lib-lab.git && git flow init -d` → 写 `gitflow.*` 配置 → `git switch -c develop main 2>/dev/null; git switch develop` → `git push -u origin main && git push -u origin develop` → **（顺序：push 成功后）** `gh api -X PUT .../branches/main/protection` 设保护 → `ssh -T git@github.com` → `gh auth status && gh repo view jxsword/c-cpp-lib-lab` → `git flow feature start m0-01-repo-skeleton` → `git check-ignore -v build/x.o` → `sha256sum docs/PLAN.md` 比对 `0.3.1` BASE |
| 断言 | A1 当前分支为期望分支；A2 `main`/`develop` 均存在、`gitflow.branch.master == main`、`versiontag == v`、无 `master` 残留；A3 `git check-ignore` 命中 `build/`、`*.o`、`*.obj`、`*.dll`、`*.so`、`*.dylib`、`*.pdb`；**A4 `sha256sum docs/PLAN.md` == `0.3.1` 记录的 BASE 基准值**，且文件为 UTF-8 无 BOM + LF、**全文无越界章节引用**（`0.7.4` Z1/Z4）；A5 工作树无二进制；**A6 `git remote get-url origin` == `git@github.com:jxsword/c-cpp-lib-lab.git`（SSH，非 HTTPS）**；**A7 `gh auth status` 成功且 `gh repo view` 可见该仓库**；**A8 未重新创建目录、未执行 `git clone`、未改写 `docs/PLAN.md`**；**A9 `ssh -T git@github.com` 连通成功，且分支保护在两条长期分支 push 之后设置** |
| 提交 | `chore(repo): initialize c-cpp-lib-lab with git flow, ssh origin and out-of-source ignores` |
| DoD | **A1–A9 PASS**；适用 D 项 = D1–D6（D9/D10 按 `2.6` 分期生效表暂不适用）；PR → develop（`gh pr create` + `gh pr merge`）；CHANGELOG 追加 `v0.0.0 (in progress)` |

#### F-00-02 · lint 门禁（含编码 / 静态分析禁令扫描）

| 项 | 内容 |
|---|---|
| 分支 | `feature/m0-02-ci-lint` |
| 前置 | F-00-01 |
| 改动 | 新建 `.github/workflows/lint.yml` |
| 要点 | `on: pull_request` 到 `develop`/`main`；检查行尾空白、UTF-8、**`*.ps1` UTF-8 BOM**、**`*.bat` CRLF 且无 BOM**、**`*.sh` LF 且无 BOM**、禁止二进制入库、**`5.8.4` 禁用调用关键字扫描**、断言 `docs/PLAN.md` 卡号格式、**全文无越界章节引用（Z1）**、**`scripts/` 内无 `gh` 调用（J7 / K22）**。**不编译、不跑矩阵** |
| 命令 | 推送 PR 触发；**本卡校验脚本尚未建立（`2.6` 分期生效表），本地改用内联检查**：`find . -type f -not -path './.git/*' -exec file {} +` 抽查编码、`grep -rIn 'ldd\|dlopen\|LoadLibrary\|LD_DEBUG' scripts/; true`、`grep -rIn 'gh ' scripts/; true`、`grep -n '见 [0-9]*\.[0-9]*' docs/PLAN.md` 比对章节集合；**不调用 `check_encoding.*` / `scan_dynamic_calls.sh`（它们由 `F-00-04` 产出）** |
| 断言 | A1 空 PR lint 绿；A2 试探加入 `build/x.o` 的 PR 被拒；A3 试探「无 BOM 的 `.ps1`」「LF 的 `.bat`」「含 `ldd` 的分析脚本」三个 PR 分别被拒；A4 workflow 无编译 job；**A5 试探「`scripts/` 内出现 `gh ` 调用」「`docs/PLAN.md` 含越界章节引用」两个 PR 分别被拒** |
| 提交 | `ci: add PR gate for encoding, line endings, binaries and static-analysis bans` |
| DoD | **A1–A5 PASS**；适用 D 项 = D1–D6（D9/D10 暂不适用）；删除全部试探分支 |

#### F-00-03 · **CI 缓存基础设施（S1）**

| 项 | 内容 |
|---|---|
| 分支 | `feature/m0-03-cache-baseline` |
| 前置 | F-00-01 |
| 改动 | 新建 `.github/{apt,brew,msys2}-packages.txt`、`.github/tool-versions.env`、`.github/actions/setup-env/action.yml`、`docs/ci-cache.md` |
| 要点 | composite action 按 `inputs.os/toolset/variant` 恢复/保存 `5.9.2` 全部缓存对象；key 严格遵守 K1–K8；输出 `cache-hit` 给调用方；**MSVC/SDK 明确不缓存并写明理由** |
| 命令 | 用一个最小 `workflow_dispatch` 演练 workflow 调用该 action 两次（第二次应命中） |
| 断言 | A1 四个包清单文件齐全且与 `5.9.1` 一致；A2 composite action 覆盖 `5.9.2` 全部 7 类缓存对象；A3 key 含 OS+toolset+variant+cfg（正则断言）；A4 第二次调用 `cache-hit == true`；A5 `docs/ci-cache.md` 含 key/path/失效条件/命中率记录方式 |
| 提交 | `ci(cache): add package manifests and setup-env composite action with per-combo keys` |
| DoD | A1–A5 PASS；适用 D 项 = D1–D6、D11（D9/D10 暂不适用）；命中率写入回执 |

#### F-00-04 · **编码与换行规范落地（S6）**

| 项 | 内容 |
|---|---|
| 分支 | `feature/m0-04-encoding` |
| 前置 | F-00-01 |
| 改动 | 补全 `.gitattributes` 编码段（`5.10`）、新建 `scripts/tools/check_encoding.sh`、`check_encoding.ps1`（**UTF-8 BOM**）、`scan_dynamic_calls.sh`；新建首个 `scripts/windows/env.bat`（CRLF）与 `env.ps1`（UTF-8 BOM）样例 |
| 要点 | `*.ps1` 首 3 字节 `EF BB BF`；`*.bat` 无 BOM 且无裸 LF；`*.sh` 无 BOM 且 LF；`Makefile.nmake` CRLF |
| 命令 | `./scripts/tools/check_encoding.sh`；`pwsh -File ./scripts/tools/check_encoding.ps1` |
| 断言 | A1 样例 `.ps1` 为 UTF-8 BOM；A2 样例 `.bat` 为 CRLF 且无 BOM；A3 故意破坏三种文件各一次，校验脚本均返回非 0 并指出文件与原因；A4 `.gitattributes` 含 `5.10` 全部行；A5 `scan_dynamic_calls.sh` 能识别 `ldd`/`dlopen`/`LoadLibrary`/`LD_DEBUG` 样例 |
| 提交 | `chore(encoding): enforce UTF-8 BOM for ps1, CRLF for bat, LF for sh` |
| DoD | A1–A5 PASS；适用 D 项 = D1–D11（本卡起 D9/D10 生效，D1 的 `verify_card` 自动入口仍待 `F-02-05`） |

#### R-00 · 发布 `v0.0.0`

| 项 | 内容 |
|---|---|
| 分支 | `release/0.0.0` |
| 断言 | 干净克隆成功；lint 绿；缓存 composite action 二次命中；编码校验三 OS 可跑；git flow 拓扑演练一次（后回滚） |
| 动作 | `gh pr merge` ×2（合入 `main` + 回迁 `develop`）→ `git tag -a v0.0.0` → `git push origin main develop --follow-tags` → `gh release create v0.0.0 --target main` |

---

### M1 · 阶段 1 纯 C 源码与接口契约（Gate A，`v0.1.0`）

#### F-01-01 · 导出宏头

| 项 | 内容 |
|---|---|
| 分支 | `feature/m1-01-export-header` |
| 前置 | `v0.0.0` |
| 改动 | 新建 `include/calc_export.h` |
| 要点 | 严格 `5.1` 六条；宏名 `CALC_` 前缀；`CALC_CALL` 32 位 Windows 为 `__cdecl`；不给数据符号导出修饰 |
| 命令 | 四种宏组合 × C/C++ 共 8 次 `-fsyntax-only` |
| 断言 | A1 8 次全过；A2 `-DCALC_STATIC` 时 `CALC_API` 展开为空；A3 `-D_WIN32 -DCALC_BUILD_DLL` 预处理含 `dllexport`；A4 32 位 Windows 分支 `CALC_CALL` 为 `__cdecl` |
| 提交 | `feat(export): add four-mode CALC_API header with __cdecl convention` |
| DoD | A1–A4 PASS |

#### F-01-02 · 公共 API 与 `.def`

| 项 | 内容 |
|---|---|
| 分支 | `feature/m1-02-public-api` |
| 前置 | F-01-01 |
| 改动 | 新建 `include/vmath.h`、`def/vmath.def` |
| 要点 | 严格 `5.2` 的 9 符号与 `5.3` ordinal；`vmath_errno` 只声明、不加 `CALC_API`、不进 `.def`；`extern "C"` 宏包裹整个声明区 |
| 命令 | `gcc -fsyntax-only -Iinclude -xc - <<< '#include "vmath.h"'`；C++ 同测 |
| 断言 | A1 C/C++ 通过；A2 `vmath.h` 中 `CALC_API` 恰好 6 次；A3 `extern int vmath_errno;` 前无 `CALC_API`；A4 `.def` ordinal 恰 1–6、`@5` 带 `NONAME`、全文无 `DATA`、无 `vmath_errno` |
| 提交 | `feat(api): define vmath public API and fixed-ordinal DEF file` |
| DoD | A1–A4 PASS |

#### F-01-03 · 库核心

| 项 | 内容 |
|---|---|
| 分支 | `feature/m1-03-lib-core` |
| 前置 | F-01-02 |
| 改动 | 新建 `src/vmath_core.c` |
| 要点 | `vmath_add`、`vmath_dot`、`vmath_last_error`、裸符号 `vmath_errno`、`static normalize_`（须有实际引用，避免被优化掉）；`dot` 校验 `n==0` 与空指针，错误置 `vmath_errno` 并返回非零 |
| 命令 | `gcc -c -Wall -Wextra -Werror -Iinclude src/vmath_core.c -o /tmp/core.o` |
| 断言 | A1 零警告；A2 `nm` 含 4 个目标符号、`normalize_` 为局部；A3 `add(1.5,2.5)==4.0`、`dot` 正确值与错误码 |
| 提交 | `feat(core): implement vmath_add, vmath_dot, error accessor and bare errno symbol` |
| DoD | A1–A3 PASS |

#### F-01-04 · 库报告与资源

| 项 | 内容 |
|---|---|
| 分支 | `feature/m1-04-lib-report` |
| 前置 | F-01-02 |
| 改动 | 新建 `src/vmath_report.c` |
| 要点 | `vmath_build_info()` 返回**静态常量字符串**（含 `5.2 #3` 全部字段，供 SA-3 静态读取 `.rodata`）；`vmath_free` 库侧释放；`vmath_set_logger` 可置 NULL |
| 命令 | `gcc -c -Wall -Wextra -Werror -Iinclude src/vmath_report.c -o /tmp/report.o` |
| 断言 | A1 零警告；A2 `strings /tmp/report.o` 可静态提取位数/配置/编译器标记（**不运行**）；A3 无 `malloc` 调用；A4 3 个 API 均为全局 |
| 提交 | `feat(report): add build_info, free and logger bridge` |
| DoD | A1–A4 PASS |

#### F-01-05 · CLI 主程序

| 项 | 内容 |
|---|---|
| 分支 | `feature/m1-05-cli` |
| 前置 | F-01-03, F-01-04 |
| 改动 | 新建 `src/calctool.c` |
| 要点 | 实现 `add`/`dot`/`info`/`probe`/`--self-test`；`probe` **静态读取**自身结构，不调用外部分析器；`--dynamic`、`--bundle` 仅留桩并返回明确提示；错误码只读 `vmath_last_error()`；`dot` 支持逗号分隔列表 |
| 命令 | `gcc -Wall -Wextra -Werror -Iinclude -DCALC_NO_LIB src/*.c -lm -o /tmp/calctool && /tmp/calctool --self-test` |
| 断言 | A1 M4 直编（不链任何库）`--self-test` 退出码 0；A2 `add 1.5 2.5` 输出 `4`；A3 `dot` 维度不一致返回非零且 `vmath_last_error()` 为 `VMATH_E_DIM`；A4 `vmath_errno` 仅在 `vmath_core.c` 出现；A5 两桩返回可识别提示而非崩溃 |
| 提交 | `feat(cli): implement calctool commands and self-test harness` |
| DoD | A1–A5 PASS |

#### F-01-06 · 四模式冒烟 + 反例

| 项 | 内容 |
|---|---|
| 分支 | `feature/m1-06-four-mode-smoke` |
| 前置 | F-01-05 |
| 改动 | 新建 `tests/negative/` 初版、`scripts/linux/smoke_four_modes.sh`、`docs/baseline.md` 初版（`5.1`–`5.4`） |
| 要点 | M1–M4 各编译一次；反例：静态库使用侧误开 `dllimport`（`__imp_` 未解析）记录为**期望失败**；产物落在 `build/native/smoke/`（out-of-source） |
| 命令 | `./scripts/linux/smoke_four_modes.sh gcc x64 Release` |
| 断言 | A1 M1–M4 四次编译全过；A2 M4 产物静态解析（`readelf -d`）显示未链接 `libvmath`；A3 反例按预期失败且不导致主流程红；A4 `docs/baseline.md` 含 `5.1`–`5.4`；A5 源码树无 `.o` |
| 提交 | `test(core): add four-mode smoke and expected-failure negative cases` |
| DoD | A1–A5 PASS |

#### R-01 · 发布 `v0.1.0`

| 项 | 内容 |
|---|---|
| 分支 | `release/0.1.0` |
| 断言 | 四模式编译记录齐全；9 符号清单与导出集一致；`reports/v0.1.0/SUMMARY.md` 生成（只填 SA-1…SA-6，其余标 `N/A`） |
| 动作 | `gh pr merge` ×2（合入 `main` + 回迁 `develop`）→ `git tag -a v0.1.0` → `git push origin main develop --follow-tags` → `gh release create v0.1.0 --target main` |

---

### M2 · ① 原生 Linux 4 组合 + 静态分析三层框架（Gate A，`v0.2.0`）

#### F-02-01 · 原生命令脚本（out-of-source）

| 项 | 内容 |
|---|---|
| 分支 | `feature/m2-01-native-linux` |
| 前置 | `v0.1.0` |
| 改动 | 新建 `scripts/linux/native.sh`、`scripts/linux/common.sh`、`scripts/common.sh` |
| 要点 | 入参 `<arch> <cfg> <kind>` → `build/native/linux_gcc_<arch>_<cfg>/<kind>/`；**所有产物 out-of-source**；动态：`-DCALC_BUILD_DLL -fPIC -fvisibility=hidden`、`-shared -Wl,-soname,libvmath.so.1 -Wl,--enable-new-dtags`、三级符号链接；主程序 `-L... -lvmath -Wl,-rpath,'$ORIGIN' -ldl -lm`；静态：`.o` **必须以 `-DCALC_STATIC` 重编**（C9）、`ar rcs`、主程序带 `-DCALC_STATIC`；Debug `-g -O0 -D_DEBUG`，Release `-O2 -DNDEBUG`，x86 `-m32` |
| 命令 | `for a in x86 x64; do for c in Debug Release; do for k in static shared; do ./scripts/linux/native.sh $a $c $k; done; done; done` |
| 断言 | A1 **4 组合 × 2 形态 = 8 个产物目录**齐全且各含 `calctool`；A2 8 个 `--self-test` 全 0；A3 `info` 与标签逐项一致；A4 静态 `.o` 不复用动态 `.o`（`-DCALC_STATIC` 编译记录断言）；A5 x86 为 `ELF32`、x64 为 `ELF64`；A6 shared 含 `NEEDED libvmath.so.1`、static 不含；A7 **`find . -path ./build -prune -o -name '*.o' -print` 为空**（D2） |
| 提交 | `build(scripts): add out-of-source native Linux matrix for 4 combos x 2 kinds` |
| DoD | A1–A7 PASS |

#### F-02-02 · Unix 动态加载分支（**属 RV**）

| 项 | 内容 |
|---|---|
| 分支 | `feature/m2-02-dynamic-unix` |
| 前置 | F-02-01 |
| 改动 | 修改 `src/calctool.c`：`--dynamic` Unix 分支 |
| 要点 | `dlopen` 绝对路径 → `dlsym` 按名取 6 个 API → 函数表结构体成员位置作为 ordinal 跨平台替代 → 调用 → `dlclose` → 卸载后不持有库内地址；`vmath_set_logger(NULL)` 卸载前注销。**此功能只在 RV step 运行，分析脚本不得引用** |
| 命令 | `build/native/linux_gcc_x64_Release/shared/calctool --dynamic add 1 2` |
| 断言 | A1 输出与静态链接路径一致；A2 `dlsym` 6 个 API 均非 NULL；A3 卸载后正常退出；A4 传错库路径返回明确错误而非崩溃；A5 `scan_dynamic_calls.sh` 对 `scripts/analyze_*` 零命中 |
| 提交 | `feat(cli): add Unix dlopen/dlsym/dlclose dynamic-loading path (RV only)` |
| DoD | A1–A5 PASS |

#### F-02-03 · **静态分析三层框架 + 依赖树（S7 核心）**

| 项 | 内容 |
|---|---|
| 分支 | `feature/m2-03-static-analysis` |
| 前置 | F-02-01 |
| 改动 | 新建 `scripts/linux/static_analyze.sh`、`scripts/linux/deps_tree.sh`；安装清单补入 `.github/apt-packages.txt` |
| 要点 | 按 `5.8.1` 三层顺序：① `file`/`readelf`/`objdump`/`nm`/`ar`/`strings` → ② `lddtree`(pax-utils)/`llvm-readobj`/`llvm-nm`/`llvm-dwarfdump`/`patchelf` → ③ bash 归一 + BFS 依赖树。**SA-2 编译器版本**从 `.comment` / `DW_AT_producer` 提取并与 `gcc --version` 比对；**SA-7/SA-8** 用 `readlink -f` 追踪符号链接、按 realpath 去重；输出 `5.8.3` 的 JSON + 缩进 Markdown |
| 命令 | `./scripts/linux/static_analyze.sh linux_gcc_x64_Release shared native` |
| 断言 | A1 `SA-1…SA-10` 十项均有 PASS/FAIL 结论；A2 编译器输出形如 `gcc <x.y.z>` 且与 `gcc --version` 一致；A3 依赖树含 `libvmath.so.1 → libvmath.so.1.0.0` 符号链接链与 realpath；A4 树为分级缩进且 JSON 可解析；A5 系统库 / 自带库已分类；A6 **脚本全文无 `5.8.4` 禁用调用**；A7 三层工具各自输出均落盘可查 |
| 提交 | `feat(analyze): add three-layer static analysis and recursive dependency tree (Linux)` |
| DoD | A1–A7 PASS；新增 `tests/assertions/F-02-03.yml` |

#### F-02-04 · 静态分析结论报告

| 项 | 内容 |
|---|---|
| 分支 | `feature/m2-04-analysis-report` |
| 前置 | F-02-03 |
| 改动 | 新建 `scripts/linux/analyze.sh`、`reports/<tag>/` 报告模板 |
| 要点 | 对指定组合逐项执行 SA-1…SA-10 并写 `reports/<tag>/<group>/<标签>.md`；依赖树单独写 `reports/<tag>/deps/`；导出集断言区分「6 API」与「gcc 额外裸符号」 |
| 命令 | `./scripts/linux/analyze.sh linux_gcc_x64_Release shared native` |
| 断言 | A1 单组合 10 项无 `N/A`；A2 导出集恰 6 API + 1 裸符号、`normalize_` 不在动态导出表；A3 static 组合 SA-7 判定「无 `libvmath` 依赖」；A4 报告 Markdown 表格列数一致且可被汇总脚本解析 |
| 提交 | `build(scripts): generate SA-1..SA-10 conclusion reports` |
| DoD | A1–A4 PASS；4 组合 × 2 形态报告齐全 |

#### F-02-05 · **运行输出采集 + 断言基线与验收入口（S8）**

| 项 | 内容 |
|---|---|
| 分支 | `feature/m2-05-run-output-and-assertions` |
| 前置 | F-02-01, F-02-04 |
| 改动 | 新建 `scripts/linux/run.sh`、`scripts/verify_card.sh`、`tests/assertions/F-00-01.yml` … `F-02-05.yml` |
| 要点 | `run.sh` 采 `RV-1…RV-4` 的 stdout+stderr+exit code → `reports/<tag>/run/<标签>.txt`；`verify_card.sh <卡号>` 读 yml 逐条执行并输出 `0.4` 回执所需 PASS/FAIL 表；后续每卡同步新增 yml |
| 命令 | `./scripts/linux/run.sh linux_gcc_x64_Release shared native && ./scripts/verify_card.sh F-02-01` |
| 断言 | A1 M0–M2 全部卡号有对应 yml；A2 `verify_card.sh F-02-01` 全 PASS；A3 故意改坏一个 `expect` 时返回非 0 且指出断言 id；A4 运行输出文件含 `--self-test`/`info` 完整文本与退出码；A5 **运行脚本位于 `run.sh`，分析脚本不含 RV 调用**（C18 隔离） |
| 提交 | `test: add RV output capture and machine-checkable assertions entrypoint` |
| DoD | A1–A5 PASS |

#### R-02 · 发布 `v0.2.0`

| 项 | 内容 |
|---|---|
| 分支 | `release/0.2.0` |
| 断言 | 4 组合 × 2 形态 × (10 SA + 4 RV) 结论齐全；依赖树含符号链接 realpath；`scan_dynamic_calls.sh` 零命中；缓存 composite action 在演练 workflow 命中 |
| 动作 | `gh pr merge` ×2（合入 `main` + 回迁 `develop`）→ `git tag -a v0.2.0` → `git push origin main develop --follow-tags` → `gh release create v0.2.0 --target main` |

---

### M3 · ③ CMake Linux 4 组合（**Gate A 完成**，`v0.3.0`）

#### F-03-01 · CMakeLists 与 CTest

| 项 | 内容 |
|---|---|
| 分支 | `feature/m3-01-cmake-base` |
| 前置 | `v0.2.0` |
| 改动 | 新建 `CMakeLists.txt`、`tests/CMakeLists.txt` |
| 要点 | `project(c_cpp_lib_lab C CXX)`；`option(BUILD_SHARED_LIBS)` 由 `<kind>` 驱动；generator expression 按 shared/static 注入 `CALC_BUILD_DLL`/`CALC_STATIC`（**静态库不带隐藏可见性**）；`POSITION_INDEPENDENT_CODE ON`、`VERSION/SOVERSION`；`WIN32` 时加 `.def` 且 `WINDOWS_EXPORT_ALL_SYMBOLS OFF`；`BUILD_RPATH "$ORIGIN"`、`INSTALL_RPATH "$ORIGIN/../lib"`；`target_link_libraries(calctool PRIVATE vmath ${CMAKE_DL_LIBS})`；`--self-test` 注册为 CTest。**一律 `-S <src> -B build/cmake/<tag>/<kind>`** |
| 命令 | `cmake -S . -B build/cmake/linux_gcc_x64_Release/shared -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_C_FLAGS=-m64 && cmake --build build/cmake/... && ctest --test-dir build/cmake/... --output-on-failure` |
| 断言 | A1 4 组合 × 2 形态 = 8 次 configure + build 成功；A2 8 次 `ctest` 全绿；A3 静态组合编译命令**不含** `-fvisibility=hidden`（`compile_commands.json`）；A4 `WINDOWS_EXPORT_ALL_SYMBOLS` 为 OFF；A5 源码树无 `CMakeCache.txt`（D2） |
| 提交 | `build(cmake): add out-of-source 4-combo CMake project with CTest` |
| DoD | A1–A5 PASS |

#### F-03-02 · out-of-source / RPATH 断言与基线文档

| 项 | 内容 |
|---|---|
| 分支 | `feature/m3-02-out-of-source` |
| 前置 | F-03-01 |
| 改动 | 补全 `docs/baseline.md`（`5.5`–`5.7`）、扩展 `scripts/linux/analyze.sh` 支持 `build/cmake/` 产物 |
| 要点 | 断言 build 阶段 `BUILD_RPATH`、install 阶段 `INSTALL_RPATH`；记录 `CMAKE_MSVC_RUNTIME_LIBRARY` 与 Debug/Release 联动（Windows 部分标「待 M6 实跑」） |
| 命令 | `readelf -d build/cmake/linux_gcc_x64_Release/shared/calctool \| grep -E 'RUNPATH\|RPATH\|NEEDED'` |
| 断言 | A1 shared 组合含 `RUNPATH` 且值含 `$ORIGIN`；A2 `cmake --install` 后 install 树 RPATH 为 `$ORIGIN/../lib`；A3 8 组合 SA 结论写入 `reports/v0.3.0/`；A4 `docs/baseline.md` 含 `5.5`/`5.6`/`5.7` 全文；A5 三种构建方式的产物目录互不重叠 |
| 提交 | `test(cmake): assert out-of-source layout and BUILD/INSTALL RPATH` |
| DoD | A1–A5 PASS |

#### R-03 · 发布 `v0.3.0`（Gate A）

| 项 | 内容 |
|---|---|
| 分支 | `release/0.3.0` |
| 断言 | **Gate A**：① 原生 Linux 4 + ③ CMake Linux 4（各 × 双形态）全绿；SA/RV 报告齐全；编码 lint + 缓存命中 + `verify_card.sh` 全回归；README 写明「当前仅单平台，三 OS 见 M4–M6」 |
| 动作 | `gh pr merge` ×2（合入 `main` + 回迁 `develop`）→ `git tag -a v0.3.0` → `git push origin main develop --follow-tags` → `gh release create v0.3.0 --target main`；**暂停，等待确认是否进入 Gate B** |

---

### M4 · ① 原生三 OS 全 24 组合（Gate B，`v0.4.0`）

#### F-04-01 · macOS 原生与静态分析脚本（bash）

| 项 | 内容 |
|---|---|
| 分支 | `feature/m4-01-macos-scripts` |
| 前置 | `v0.3.0` |
| 改动 | 新建 `scripts/macos/{env,native,make,cmake,build_all,static_analyze,deps_tree,run,bundle}.sh`（**全部 bash / LF / 无 BOM**） |
| 要点 | `-dynamiclib -Wl,-install_name,@rpath/libvmath.dylib -fvisibility=hidden`；`arm64` 主组合；x86_64 与 `lipo` universal 作**附加不计数组合**的架构覆盖；静态分析用 `otool -L`/`otool -l`/`lipo -archs`/`nm -gU`/`dwarfdump`/`dyld_info -exports`；SA-2 编译器版本从 `DW_AT_producer` / `LC_BUILD_VERSION` 提取 |
| 命令 | `./scripts/macos/static_analyze.sh macos_clang_arm64_Release shared native` |
| 断言 | A1 2 组合 × 双形态全绿；A2 `otool -L` 中 install_name 为 `@rpath/...` 而非绝对路径；A3 SA-2 输出 `apple-clang <版本>`；A4 依赖树标记 `libSystem.B.dylib` 为「系统 shared cache，不落盘」；A5 universal 产物 `lipo -archs` 同时含两架构；A6 32 位输入返回 `SKIP` 且退出码 0、日志写明 10.15 原因 |
| 提交 | `build(scripts): add macOS bash matrix and three-layer static analysis` |
| DoD | A1–A6 PASS |

#### F-04-02 · Windows 原生脚本（**bat + ps1**）与 18 组合

| 项 | 内容 |
|---|---|
| 分支 | `feature/m4-02-windows-scripts` |
| 前置 | `v0.3.0` |
| 改动 | 新建 `scripts/windows/` 全套：`env.bat`/`env.ps1`、`native.bat`/`native.ps1`、`nmake.*`、`msbuild.*`、`cmake.*`、`build_all.*`、`static_analyze.*`、`deps_tree.ps1`、`run.*`、`bundle.*`、`scripts/common.ps1`、`scripts/verify_card.ps1` |
| 要点 | **`.bat` 为薄入口（vcvarsall / msys2 环境切换 + 调用 `.ps1`），`.ps1` 承担全部逻辑**；ps1 **UTF-8 BOM**、bat **CRLF 无 BOM**。覆盖 `msvc` 4 变体 × 2 配置、`msys2` 四环境 × 2 配置、`clang-cl` × 2 配置 = 18；MSVC：`cl /LD /DCALC_BUILD_DLL /MD\|/MT ... /link /DEF:def\vmath.def`；MinGW：`-shared -Wl,--out-implib,libvmath.dll.a`；四环境**独立目录不混链**（C8） |
| 命令 | `.\scripts\windows\build_all.bat native` |
| 断言 | A1 18 组合 × 双形态全绿且 `--self-test` 退出码 0；A2 `dumpbin /exports` 的 6 API ordinal 恰 1–6、`@5` 无名字；A3 MSVC 下 `vmath_errno` 不出现在导出表、MinGW 下出现；A4 `/MD` 含 `VCRUNTIME140.dll`、`/MT` 不含；A5 Debug `.pdb` 存在且被 `.gitignore` 排除；A6 msys2 四环境产物无交叉引用；A7 `check_encoding.ps1` 全绿（ps1 BOM / bat CRLF） |
| 提交 | `build(scripts): add Windows bat+ps1 matrix for msvc, 4 msys2 envs and clang-cl` |
| DoD | A1–A7 PASS |

#### F-04-03 · Windows 动态加载（按名 + ordinal，**属 RV**）

| 项 | 内容 |
|---|---|
| 分支 | `feature/m4-03-dynamic-win` |
| 前置 | F-04-02 |
| 改动 | 修改 `src/calctool.c` 的 Windows `--dynamic` 分支、`scripts/windows/run.ps1` |
| 要点 | `LoadLibrary` 绝对路径；`GetProcAddress(h, "vmath_add")` 按名；`GetProcAddress(h, MAKEINTRESOURCEA(5))` 取 `vmath_build_info`（`NONAME`）；`FreeLibrary` 前注销 logger；`LOAD_LIBRARY_SEARCH_*` 加固对照写入 `docs/baseline.md` |
| 命令 | `.\build\native\win_msvc_x64_MD_Release\shared\calctool.exe --dynamic info` |
| 断言 | A1 按名与按 ordinal 均返回正确值；A2 `GetProcAddress(h, "vmath_build_info")` 因 `NONAME` 返回 NULL（**期望如此**）；A3 `MAKEINTRESOURCEA(5)` 非 NULL；A4 卸载后无悬空调用；A5 `scan_dynamic_calls.sh` 对分析脚本零命中（RV 隔离） |
| 提交 | `feat(cli): add Windows LoadLibrary path with named and ordinal-5 lookup (RV only)` |
| DoD | A1–A5 PASS |

#### F-04-04 · **静态分析三 OS 扩展（S7）**

| 项 | 内容 |
|---|---|
| 分支 | `feature/m4-04-analysis-crossos` |
| 前置 | F-04-01, F-04-02 |
| 改动 | 扩展 `scripts/{macos,windows}/static_analyze.*`、`deps_tree.*`；补 `.github/brew-packages.txt`、`tool-versions.env` |
| 要点 | macOS：`dwarfdump --debug-info` 取 `DW_AT_producer`、`dylibbundler` 作第二层；Windows：`dumpbin /rawdata` **Rich Header** + `llvm-readobj --coff-rich-header` 取 MSVC 版本、`Dependencies` CLI 作第二层、`deps_tree.ps1` 用 `Resolve-Path` + `Get-Item -Force` 判定 symlink/junction、API-Set 与 KnownDLL 归类；三 OS 输出**同一 JSON schema**（`5.8.3`） |
| 命令 | `.\scripts\windows\static_analyze.bat win_msvc_x64_MD_Release shared native` |
| 断言 | A1 三 OS 各跑 SA-1…SA-10 全有结论；A2 SA-2 在三 OS 分别输出 `gcc` / `apple-clang` / `msvc` 或 `clang-cl` + 版本号；A3 Windows 依赖树含 `VCRUNTIME140.dll` 及 API-Set 归类；A4 三 OS JSON schema 字段完全一致；A5 三 OS 分析脚本均通过 `5.8.4` 关键字扫描 |
| 提交 | `feat(analyze): extend three-layer static analysis to macOS and Windows` |
| DoD | A1–A5 PASS |

#### F-04-05 · 24 组合矩阵收口与约束记录

| 项 | 内容 |
|---|---|
| 分支 | `feature/m4-05-toolchain-matrix` |
| 前置 | F-04-01…F-04-04 |
| 改动 | 补全 `docs/baseline.md` 工具链映射表、`README.md` 已知差异、`tests/negative/` 跨平台反例 |
| 要点 | 记录 `5.5.1` 全部工具链的 32/64 开关、动态库命令、导入库、CRT；记录 5 类高频跨平台坑；**明确 24 组合清单与 SKIP / 附加架构覆盖的边界** |
| 命令 | `./scripts/verify_card.sh F-04-05` |
| 断言 | A1 24 组合标签清单与 `5.5.1` 逐行一致、无重复；A2 映射表覆盖 6 类工具链（gcc / msvc / msys2×4 / clang-cl / apple-clang）且每类 4 列齐全；A3 所有 SKIP / 附加验证在 README 有说明；A4 反例在 `tests/negative/` 且不进主绿路径；A5 24 组合 SA/RV 报告汇总无缺失 |
| 提交 | `docs: freeze 24-combo toolchain matrix and platform constraint notes` |
| DoD | A1–A5 PASS |

#### R-04 · 发布 `v0.4.0`

| 项 | 内容 |
|---|---|
| 分支 | `release/0.4.0` |
| 断言 | ① 原生 **24** 组合 × 双形态全绿；三 OS SA-1…SA-10 与 RV-1…RV-4 齐全；编译器名+版本、依赖树 realpath 全部有值；`reports/v0.4.0/SUMMARY.md` 完成 |
| 动作 | `gh pr merge` ×2（合入 `main` + 回迁 `develop`）→ `git tag -a v0.4.0` → `git push origin main develop --follow-tags` → `gh release create v0.4.0 --target main` |

---

### M5 · ② make 组 32 组合（Gate B，`v0.5.0`）

#### F-05-01 · GNU make（14 组合）

| 项 | 内容 |
|---|---|
| 分支 | `feature/m5-01-gnu-make` |
| 前置 | `v0.4.0` |
| 改动 | 新建 `Makefile` |
| 要点 | `?=` 变量 `OS`、`TOOLSET`、`VARIANT`、`CFG`、`KIND`、`CC`；`srcdir`/`outdir` 强制 out-of-source（`1.4`）；`VIS` 仅 shared 时 `-fvisibility=hidden -fPIC`；`DEF_LIB` shared→`CALC_BUILD_DLL`、static→`CALC_STATIC`；覆盖 Linux 4 + macOS 2 + msys2 8 = 14；只用 POSIX 兼容语法，macOS 显式要求 `gmake` |
| 命令 | `cd build/make/gnu/linux_gcc_x86_Debug/static && make -f $(abs-src)/Makefile srcdir=$(abs-src) VARIANT=x86 CFG=Debug KIND=static selftest analyze` |
| 断言 | A1 14 组合 × 双形态全绿；A2 静态组合 `make -n` 不含 `-fPIC -fvisibility=hidden`；A3 `make analyze` 产出 SA 报告；A4 macOS `gmake` 与 msys2 GNU make 至少各 1 组合成功；A5 产物全在 `build/make/gnu/` 且源码树无产物 |
| 提交 | `build(make): add out-of-source GNU Makefile for Linux/macOS/msys2 (14 combos)` |
| DoD | A1–A5 PASS |

#### F-05-02 · **nmake 单独 makefile（10 组合，S9）**

| 项 | 内容 |
|---|---|
| 分支 | `feature/m5-02-nmake-makefile` |
| 前置 | `v0.4.0` |
| 改动 | 新建 `Makefile.nmake`（**CRLF**）、`scripts/windows/nmake.bat`/`nmake.ps1` |
| 要点 | **独立于 `Makefile` 的单独文件**，语法用 nmake（`!IF`/`!ELSE`/`!ENDIF`、`$(CC)`、`/Fo`、`/link`）；`SRCDIR`/`OUTDIR` 强制 out-of-source；覆盖 msvc 8（`x86/x64` × `/MD`/`/MT` × Debug/Release）+ clang-cl 2 = 10；`/MD`↔`/MDd`、`/MT`↔`/MTd` 随 CFG 联动；动态库用 `/DEF:$(SRCDIR)\def\vmath.def` |
| 命令 | `cd build\make\nmake\win_msvc_x64_MD_Release\shared && nmake /f <abs-src>\Makefile.nmake SRCDIR=<abs-src> VARIANT=x64_MD CFG=Release KIND=shared selftest` |
| 断言 | A1 `Makefile.nmake` 与 `Makefile` 为**两个独立文件**且互不 include；A2 10 组合 × 双形态全绿；A3 `/MD` 组合 `dumpbin /dependents` 含 `VCRUNTIME140.dll`、`/MT` 不含；A4 Debug 组合用 `*d` CRT 且 `.pdb` 存在；A5 `Makefile.nmake` 为 CRLF 且无 BOM（`check_encoding` 绿）；A6 源码树无 `.obj` |
| 提交 | `build(nmake): add standalone CRLF Makefile.nmake for msvc and clang-cl (10 combos)` |
| DoD | A1–A6 PASS |

#### F-05-03 · MSBuild（8 组合）

| 项 | 内容 |
|---|---|
| 分支 | `feature/m5-03-msbuild` |
| 前置 | `v0.4.0` |
| 改动 | 新建 `vmath.vcxproj`、`scripts/windows/msbuild.bat`/`msbuild.ps1` |
| 要点 | `Configuration` × `Platform`（Debug/Release × Win32/x64）= 4，`RuntimeLibrary`（`/MD`/`/MT`）= 2 → 8；`/p:OutDir=<abs-build>\ /p:IntDir=<abs-build>\obj\` **强制 out-of-source**；`PlatformToolset v143`；`ModuleDefinitionFile` 仅动态；`PreprocessorDefinitions` 按形态注入 `CALC_BUILD_DLL`/`CALC_STATIC` |
| 命令 | `msbuild vmath.vcxproj /p:Configuration=Release /p:Platform=x64 /p:RuntimeLibrary=MultiThreadedDLL /p:ConfigurationType=DynamicLibrary /p:OutDir=<abs-build>\ /p:IntDir=<abs-build>\obj\` |
| 断言 | A1 8 组合 × 双形态全绿；A2 每组合 CRT 与 `RuntimeLibrary` 一致；A3 静态组合不引用 `.def`；A4 x86 产物 `dumpbin /headers` 为 `machine (x86)`；A5 所有中间产物在 `build/make/msbuild/` 内，源码树无 `Debug\`/`Release\`/`x64\` 目录 |
| 提交 | `build(msbuild): add out-of-source 8-combo vcxproj with CRT overrides` |
| DoD | A1–A5 PASS |

#### F-05-04 · 32 组合横向对比

| 项 | 内容 |
|---|---|
| 分支 | `feature/m5-04-make-32-parity` |
| 前置 | F-05-01…F-05-03 |
| 改动 | 新建 `scripts/verify_make32.sh` / `.ps1`、`reports/v0.5.0/SUMMARY.md`、`CHANGELOG` |
| 要点 | 证明 **32 = GNU make 14 + nmake 10 + msbuild 8**；三者语义一一对应（同组合标签），记录可见性 / PIC / CRT / `CALC_STATIC` 注入差异；**不改 `5.5` 的定义** |
| 命令 | `./scripts/verify_make32.sh` |
| 断言 | A1 32 行矩阵无重复标签；A2 三方言的 `(os,toolset,variant,cfg)` 集合与 `5.5.2` 逐行一致；A3 每行 `info` 输出与标签一致；A4 报告中 `/MD /MT` 为 `variant` 字段而非额外行；A5 32 组合的 SA/RV 报告齐全 |
| 提交 | `test: verify 32-combination GNU make + nmake + MSBuild parity` |
| DoD | A1–A5 PASS |

#### R-05 · 发布 `v0.5.0`

| 项 | 内容 |
|---|---|
| 分支 | `release/0.5.0` |
| 断言 | make 组 **32** 组合全绿；三个产物目录 `gnu/`/`nmake/`/`msbuild/` 互不重叠；`Makefile.nmake` 独立且编码合规 |
| 动作 | `gh pr merge` ×2（合入 `main` + 回迁 `develop`）→ `git tag -a v0.5.0` → `git push origin main develop --follow-tags` → `gh release create v0.5.0 --target main` |

---

### M6 · ③ CMake 24 组合（msvc 用 Ninja，Gate B，`v0.6.0`）

#### F-06-01 · CMake 三 OS 24 组合

| 项 | 内容 |
|---|---|
| 分支 | `feature/m6-01-cmake-crossos` |
| 前置 | `v0.5.0` |
| 改动 | 修改 `CMakeLists.txt`；新建 `scripts/{linux,macos,windows}/cmake.*` |
| 要点 | 全部 24 组合；**msvc 与 clang-cl 强制 `-G Ninja`**（S9）；macOS `-DCMAKE_OSX_ARCHITECTURES=arm64`、32 位 SKIP；Windows `-A Win32/x64` 仅用于非 Ninja 生成器，Ninja 下用 `CMAKE_C_COMPILER` + `vcvarsall` 环境、`--config` 用 `CMAKE_BUILD_TYPE`（单配置）或多配置 `--config`；`CMAKE_MSVC_RUNTIME_LIBRARY` 联动 `/MD /MT`；`WINDOWS_EXPORT_ALL_SYMBOLS OFF` 强制走 `.def`/宏；`-S <src> -B build/cmake/<tag>/<kind>` |
| 命令 | `cmake -S . -B build/cmake/win_msvc_x64_MD_Release/shared -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL && cmake --build build/cmake/...` |
| 断言 | A1 24 组合 × 双形态 configure + build 成功；A2 msvc / clang-cl 共 10 组合的 `CMakeCache.txt` 中 `CMAKE_GENERATOR:INTERNAL=Ninja`；A3 Windows x86 产出 32 位；A4 macOS 32 位输入返回 SKIP；A5 `CMAKE_MSVC_RUNTIME_LIBRARY` 与 `variant` 中 `_MD`/`_MT` 一致；A6 源码树无 `CMakeCache.txt` |
| 提交 | `build(cmake): extend to all 24 combos with Ninja for msvc/clang-cl` |
| DoD | A1–A6 PASS |

#### F-06-02 · CTest 三 OS 与 out-of-source 断言

| 项 | 内容 |
|---|---|
| 分支 | `feature/m6-02-ctest-crossos` |
| 前置 | F-06-01 |
| 改动 | 扩展 `tests/CMakeLists.txt`、`scripts/verify_card.*` |
| 要点 | 每组合注册 `--self-test`、`--dynamic`、依赖判定三类 CTest；三 OS `ctest --output-on-failure`；断言 `BUILD_RPATH`/`INSTALL_RPATH` 与三套构建方式的目录隔离 |
| 命令 | `ctest --test-dir build/cmake/<tag>/<kind> --output-on-failure` |
| 断言 | A1 24 组合 CTest 全绿；A2 每组合 ≥3 个 test case；A3 SA-10 路径断言全 PASS；A4 `reports/v0.6.0/SUMMARY.md` 中三组（native / make / cmake）列齐全且组合数分别为 24 / 32 / 24 |
| 提交 | `test(cmake): register cross-OS CTest cases and out-of-source assertions` |
| DoD | A1–A4 PASS |

#### R-06 · 发布 `v0.6.0`

| 项 | 内容 |
|---|---|
| 分支 | `release/0.6.0` |
| 断言 | 三套构建方式（① 24 / ② 32 / ③ 24 = **80**）在三 OS 均有实跑记录；`reports/v0.6.0/SUMMARY.md` 覆盖 80 语义 |
| 动作 | `gh pr merge` ×2（合入 `main` + 回迁 `develop`）→ `git tag -a v0.6.0` → `git push origin main develop --follow-tags` → `gh release create v0.6.0 --target main` |

---

### M7 · 阶段 2：C++ 调用 C 链接库（Gate B，`v0.7.0`）

#### F-07-01 · C++ 主程序

| 项 | 内容 |
|---|---|
| 分支 | `feature/m7-01-stage2-main` |
| 前置 | `v0.6.0` |
| 改动 | 新建 `stage2/main.cpp`、`stage2/README.md` |
| 要点 | `g++`/`clang++`/`cl` 编译，`#include "vmath.h"`；**复用阶段 1 库产物，不重编库**；验证 `CALC_EXTERN_C_BEGIN/END`；三 OS 各跑一次；产物落 `build/native/stage2/` |
| 命令 | `g++ -Iinclude stage2/main.cpp -Lbuild/native/linux_gcc_x64_Release/shared -lvmath -Wl,-rpath,'$ORIGIN' -o build/native/stage2/calcxx` |
| 断言 | A1 链接 C 库成功并输出正确 `add`；A2 `nm -C` 中对 `vmath_add` 的引用为**未修饰名**；A3 三 OS 各 ≥1 组合通过；A4 README 说明「复用产物、不重编库」 |
| 提交 | `feat(stage2): add C++ consumer linking the pure-C vmath library` |
| DoD | A1–A4 PASS |

#### F-07-02 · 反例：去掉 `extern "C"`

| 项 | 内容 |
|---|---|
| 分支 | `feature/m7-02-negative-externc` |
| 前置 | F-07-01 |
| 改动 | 新建 `tests/negative/stage2_no_extern_c.cpp`、`tests/negative/README.md` |
| 要点 | 去掉 `extern "C"` 后编译，捕获 `undefined reference to '_Z9vmath_adddd'` / `LNK2019 ?vmath_add@@...`，作为**期望失败**对照，归档到 `reports/v0.7.0/negative/` |
| 命令 | `./tests/negative/run.sh stage2_no_extern_c`（返回非 0 视为通过） |
| 断言 | A1 按预期失败且含 mangling 特征串；A2 不进主 CI 绿路径；A3 报告记录修复方式 = 恢复 `extern "C"` 守卫 |
| 提交 | `test(stage2): add expected-failure extern-C negative case` |
| DoD | A1–A3 PASS |

#### F-07-03 · `std::vector` 跨边界用例

| 项 | 内容 |
|---|---|
| 分支 | `feature/m7-03-stage2-vector` |
| 前置 | F-07-01 |
| 改动 | 扩展 `stage2/main.cpp` 的 `--self-test` |
| 要点 | `std::vector<double>::data()` 传入 `vmath_dot`，验证「数据可传、类型不可跨」；C 库侧不接触 C++ 类型；错误码走 `vmath_last_error()` |
| 命令 | `build/native/stage2/calcxx --self-test` |
| 断言 | A1 `dot` 结果与纯 C 路径逐位一致；A2 C 库导出表无 C++ mangled 符号；A3 空 vector 走错误分支而非 UB；A4 三 OS 各跑一次 |
| 提交 | `test(stage2): pass std::vector data into C ABI without leaking C++ types` |
| DoD | A1–A4 PASS |

#### R-07 · 发布 `v0.7.0`

| 项 | 内容 |
|---|---|
| 分支 | `release/0.7.0` |
| 断言 | 阶段 2 三 OS 通过；反例归档完整；`docs/REPORT.md` 增加「C/C++ 互操作」章节初稿 |
| 动作 | `gh pr merge` ×2（合入 `main` + 回迁 `develop`）→ `git tag -a v0.7.0` → `git push origin main develop --follow-tags` → `gh release create v0.7.0 --target main` |

---

### M8 · 阶段 3：纯 C++ 面向对象（**Gate B 完成**，`v0.8.0`）

#### F-08-01 · `Vector` 类

| 项 | 内容 |
|---|---|
| 分支 | `feature/m8-01-vector-class` |
| 前置 | `v0.7.0` |
| 改动 | 新建 `stage3/include/vector.hpp`、`stage3/src/vector.cpp` |
| 要点 | 类 `Vector` **≥2 成员方法**、含 STL 容器成员；声明与实现分离；不导出 STL 类型到库边界 |
| 命令 | `g++ -std=c++17 -Wall -Wextra -Werror -c -Istage3/include stage3/src/vector.cpp -o build/native/stage3/vector.o` |
| 断言 | A1 零警告；A2 `nm -C` 可见 `Vector::` mangled 符号；A3 ≥2 public 方法；A4 与 `vmath.h` 无类型耦合 |
| 提交 | `feat(stage3): add Vector class with STL-backed storage` |
| DoD | A1–A4 PASS |

#### F-08-02 · `Statistics` 类与 3 源 / 2 头

| 项 | 内容 |
|---|---|
| 分支 | `feature/m8-02-stats-and-main` |
| 前置 | F-08-01 |
| 改动 | 新建 `stage3/include/stats.hpp`、`stage3/src/stats.cpp`、`stage3/src/main.cpp`、`stage3/README.md` |
| 要点 | 类 `Statistics` **≥2 成员方法**，组合或继承 `Vector`；**恰好 3 `.cpp` + 2 `.hpp`**；Debug/Release 下 `_ITERATOR_DEBUG_LEVEL` 差异可见 |
| 命令 | `g++ -std=c++17 -Istage3/include stage3/src/*.cpp -o build/native/stage3/calcpp && .../calcpp --self-test` |
| 断言 | A1 文件数满足 3 源 / 2 头 / 2 类；A2 `--self-test` 退出码 0；A3 Debug 与 Release 分别构建成功；A4 `nm -C` / `dumpbin /symbols` 记录 mangling 差异 |
| 提交 | `feat(stage3): add Statistics class and OOP self-test driver` |
| DoD | A1–A4 PASS |

#### F-08-03 · `extern "C"` 门面与纯虚接口

| 项 | 内容 |
|---|---|
| 分支 | `feature/m8-03-facade` |
| 前置 | F-08-02 |
| 改动 | 新建 `stage3/facade.h`、`stage3/facade.cpp` |
| 要点 | **opaque handle 门面**（不完整类型 + `vmath_new/delete/add`，异常在 C++ 侧捕获转错误码）与 **C 工厂函数 + 纯虚接口 + 库侧 `release()`**（接口头禁 STL / 内联函数体 / 模板 / 默认参数）；消费者只链接 C 名字 |
| 命令 | `gcc -Istage3 -fsyntax-only -xc - <<< '#include "facade.h"'` |
| 断言 | A1 `facade.h` 能被纯 C 编译器通过；A2 门面导出为未修饰 C 名；A3 纯虚接口头 grep 不到 `std::`/内联函数体/`template`；A4 消费者不链接 C++ mangled 符号 |
| 提交 | `feat(stage3): add C-ABI facade and pure-virtual interface contract` |
| DoD | A1–A4 PASS |

#### F-08-04 · 反例：STL 跨 CRT 与 ABI 面膨胀

| 项 | 内容 |
|---|---|
| 分支 | `feature/m8-04-negative-stl-crt` |
| 前置 | F-08-03 |
| 改动 | 新建 `tests/negative/stage3_stl_across_crt.*`、`reports/v0.8.0/abi-notes.md` |
| 要点 | 反例 A：含 `std::string` 成员的类整体 `dllexport`，在另一 CRT 选项的 exe 中调用，复现崩溃 / `Debug 崩溃 Release 正常`，给出 F-08-03 门面修复；反例 B：整体导出类导致导出表膨胀（导出符号数量对比）。均为**期望失败 / 对照观察** |
| 命令 | `.\tests\negative\run.bat stage3_stl_across_crt`（仅 MSVC 实际复现；其他 OS 标 `SKIP: MSVC-specific`） |
| 断言 | A1 Windows 上按预期失败且日志含 CRT / `_ITERATOR_DEBUG_LEVEL`；A2 其他 OS 输出 SKIP 且退出码 0；A3 `abi-notes.md` 含导出符号数量对比表与修复结论；A4 主 CI 绿路径不受影响 |
| 提交 | `test(stage3): add STL-across-CRT negative case and ABI surface comparison` |
| DoD | A1–A4 PASS |

#### R-08 · 发布 `v0.8.0`（Gate B）

| 项 | 内容 |
|---|---|
| 分支 | `release/0.8.0` |
| 断言 | **Gate B**：三阶段源码齐全、① 24 / ② 32 / ③ 24 = 80 组合全绿、SA-1…SA-10 在所有组合有结论、RV 输出齐全、反例归档完整、编码与缓存门禁全绿 |
| 动作 | `gh pr merge` ×2（合入 `main` + 回迁 `develop`）→ `git tag -a v0.8.0` → `git push origin main develop --follow-tags` → `gh release create v0.8.0 --target main`；**暂停，等待确认是否进入 Gate C** |

---

### M9 · 3 组 CI + 全量 80 + 静态分析 / 运行输出 + 打包 + 安全 + 报告（**Gate C**，`v1.0.0`）

#### F-09-01 · **可复用环境/组合工作流与全量缓存（S1 / S5）**

| 项 | 内容 |
|---|---|
| 分支 | `feature/m9-01-reusable-workflows` |
| 前置 | `v0.8.0` |
| 改动 | 新建 `.github/workflows/_env.yml`、`_combo.yml`；落地 `5.9` 缓存矩阵 |
| 要点 | `_env.yml`（`workflow_call`）调用 `actions/setup-env` composite action，按 `inputs.os/toolset/variant/cfg` 恢复 `5.9.2` 全部缓存；`_combo.yml`（`workflow_call`）执行「构建 → RV 运行输出采集 → SA 静态分析 → 结论表 → artifact」五个 step，**RV 与 SA 分 step 隔离**；输出 `cache-hit` 与 `sa-pass` |
| 命令 | `workflow_dispatch` 用 `_combo.yml` 单独跑 `linux_gcc_x64_Release/shared` 两次 |
| 断言 | A1 两个 reusable workflow 均声明 `on: workflow_call` 且 inputs 含 `os/toolset/variant/cfg/kind/group`；A2 覆盖 `5.9.2` 全部 7 类缓存对象且 key 满足 K1–K8；A3 第二次运行 `cache-hit == true` 且命中率写入 `$GITHUB_STEP_SUMMARY`；A4 RV 与 SA 为不同 step、写不同报告目录；A5 Debug 产物不上传为发布 artifact；A6 `scan_dynamic_calls.sh` 在 CI 中执行且零命中 |
| 提交 | `ci(cache): add reusable env/combo workflows with full per-combo caching` |
| DoD | A1–A6 PASS |

#### F-09-02 · **Group N：原生组 3 条工作流（24 组合）**

| 项 | 内容 |
|---|---|
| 分支 | `feature/m9-02-group-native` |
| 前置 | F-09-01 |
| 改动 | 新建 `native-linux.yml`、`native-macos.yml`、`native-windows.yml` |
| 要点 | 每条 `workflow_dispatch` 可单独触发，inputs `toolset/variant/cfg`（缺省 = 该 OS 全量）；`fail-fast: false`；matrix 由 `_combo.yml` 展开；`group: native`；产物目录 `build/native/` |
| 命令 | 分别 dispatch 三条工作流；再单跑 `native-windows.yml` 的 `toolset=msvc,variant=x64_MT,cfg=Debug` |
| 断言 | A1 三条 workflow 覆盖 4 + 2 + 18 = **24** 组合无重复；A2 三条各自单跑全绿；A3 单条 inputs 过滤只跑 1 个 job；A4 全部 workflow 调用 `_env.yml` 且缓存命中 |
| 提交 | `ci: add individually dispatchable native workflows (3 OS, 24 combos)` |
| DoD | A1–A4 PASS |

#### F-09-03 · **Group M：make 组 4 条工作流（32 组合）**

| 项 | 内容 |
|---|---|
| 分支 | `feature/m9-03-group-make` |
| 前置 | F-09-01 |
| 改动 | 新建 `make-linux.yml`、`make-macos.yml`、`make-windows.yml`、`msbuild-windows.yml` |
| 要点 | GNU make 14（Linux 4 / macOS 2 / msys2 8）、nmake 10（msvc 8 + clang-cl 2）在 `make-windows.yml` 内按 `dialect` 分叉、`msbuild-windows.yml` 单列 8；每条可单独 dispatch；`msystem` **随 matrix 动态选择**（`MINGW64`/`MINGW32`/`CLANG64`/`UCRT64`，不得写死）；`msys2/setup-msys2@v2` 的 `cache: true` |
| 命令 | dispatch `msbuild-windows.yml` 单跑；再 dispatch `make-windows.yml` 的 `dialect=nmake,toolset=msvc` |
| 断言 | A1 四条 workflow 覆盖 14 + 10 + 8 = **32** 组合无重复；A2 `msystem` 表达式非常量且四环境各命中一次；A3 `Makefile.nmake` 被 nmake job 引用；A4 四条各自单跑全绿；A5 产物分别落 `build/make/{gnu,nmake,msbuild}/` |
| 提交 | `ci: add individually dispatchable make/nmake/msbuild workflows (32 combos)` |
| DoD | A1–A5 PASS |

#### F-09-04 · **Group C：cmake 组 3 条工作流（24 组合）**

| 项 | 内容 |
|---|---|
| 分支 | `feature/m9-04-group-cmake` |
| 前置 | F-09-01 |
| 改动 | 新建 `cmake-linux.yml`、`cmake-macos.yml`、`cmake-windows.yml` |
| 要点 | 24 组合；**msvc / clang-cl 共 10 组合强制 `-G Ninja`**；`CMAKE_MSVC_RUNTIME_LIBRARY` 随 `variant` 的 `_MD`/`_MT`；macOS 32 位 SKIP；三条可单独 dispatch |
| 命令 | dispatch `cmake-windows.yml` 的 `toolset=msvc,variant=x64_MD` 单跑 |
| 断言 | A1 三条 workflow 覆盖 4 + 2 + 18 = **24** 组合；A2 msvc/clang-cl job 的 `CMakeCache.txt` 中生成器为 Ninja；A3 三条各自单跑全绿；A4 产物落 `build/cmake/` 且源码树无 `CMakeCache.txt` |
| 提交 | `ci: add individually dispatchable cmake workflows with Ninja for msvc (24 combos)` |
| DoD | A1–A4 PASS |

#### F-09-05 · **静态分析与运行输出工作流（S7 / S8）**

| 项 | 内容 |
|---|---|
| 分支 | `feature/m9-05-analyze-and-run-output` |
| 前置 | F-09-02, F-09-03, F-09-04 |
| 改动 | 新建 `analyze.yml`、`run-output.yml`、`scripts/summarize_reports.sh`、`reports/v1.0.0/SUMMARY.md` |
| 要点 | `analyze.yml` 可单独 dispatch，对指定 `group/os/tag` 的**已上传 artifact** 跑三层静态分析 → SA-1…SA-10 结论 + 依赖树 JSON/Markdown；`run-output.yml` 采集 RV-1…RV-4 的 stdout/stderr/退出码 → `reports/<tag>/run/<标签>.txt` + artifact + **`$GITHUB_STEP_SUMMARY` 表格展示程序输出**；汇总矩阵显式标注六类差异（默认导出 / ordinal / CRT / Debug-Release 布局 / mangling / macOS 架构） |
| 命令 | 单独 dispatch `analyze.yml` 对 `group=native,os=windows`；单独 dispatch `run-output.yml` 对同范围 |
| 断言 | A1 两条 workflow 可独立单跑且互不依赖对方成功；A2 SA 结论矩阵对每个组合 10 项无空格；A3 依赖树对 `libvmath.so.1`/`vmath.dll`/`@rpath/libvmath.dylib` 均含 realpath 与符号链接链；A4 **CI 日志 / Job Summary 中可见 `calctool --self-test` 与 `info` 的实际输出文本**；A5 `SUMMARY.md` 80 行（含 24/32/24 分组标识）；A6 分析 workflow 中 `scan_dynamic_calls.sh` 零命中 |
| 提交 | `ci: add standalone static-analysis and run-output workflows with Job Summary` |
| DoD | A1–A6 PASS |

#### F-09-06 · **`all.yml` 全量 80 组合编排（S5 收口）**

| 项 | 内容 |
|---|---|
| 分支 | `feature/m9-06-all-workflows` |
| 前置 | F-09-02…F-09-05 |
| 改动 | 新建 `.github/workflows/all.yml` |
| 要点 | `workflow_dispatch` 触发；用 `workflow_call` 依次调用 Group N / M / C 的 10 条工作流 + `analyze.yml` + `run-output.yml`；**复用已建立缓存**（K6）；最后 `summary` job 汇总 80 组合结果、缓存命中率、SA/RV 结论、上传总 artifact；明确「最后进行全部工作流测试」 |
| 命令 | `gh workflow run all.yml` → `gh run list --workflow=all.yml --limit 1` → `gh run watch <run-id> --exit-status` → `gh run download <run-id>`（全量由 agent 经 `gh` 发起，见 `8.5`） |
| 断言 | A1 `all.yml` 引用全部 10 条组合工作流 + 2 条分析/运行工作流，共 12 条；A2 全量运行 **80** 组合全绿（24+32+24）；A3 汇总报告组合数 = 80 且三组分别 24/32/24；A4 缓存复用率有记录、无重复下载大包；A5 干净机 job（老 glibc 容器 / 全新 VM / 新 runner）零额外安装运行成功；A6 任一工作流失败时 `all.yml` 明确标红并给出失败的 `group/os/tag` |
| 提交 | `ci: add all.yml orchestrating the full 80-combination workflow suite` |
| DoD | A1–A6 PASS |

#### F-09-07 · 打包脚本

| 项 | 内容 |
|---|---|
| 分支 | `feature/m9-07-bundle` |
| 前置 | F-09-01 |
| 改动 | 新建 `scripts/{linux,macos,windows}/bundle.*`；实现 `--bundle` 目标 |
| 要点 | Linux：`$ORIGIN/lib` + 自带 so + `patchelf --set-rpath` + `strip` + `readelf -d` 复核（不打 glibc / ld-linux / NSS）；macOS：`.app` 内嵌 Frameworks + `@rpath` + `codesign --deep`（不打 shared-cache 系统 dylib）；Windows：exe 同目录平铺 DLL + `dumpbin /dependents` 复核（不打 KnownDLLs）；三平台排除 Debug CRT；许可证 / NOTICE 随包 |
| 命令 | `./scripts/linux/bundle.sh linux_gcc_x64_Release shared && ./build/bundle/calctool --self-test` |
| 断言 | A1 三 OS 各产出「解压即用」目录；A2 干净目标机零额外安装运行成功；A3 **静态复核**（SA-7/SA-8）确认加载的是包内库（不使用运行期跟踪）；A4 包内无 `*d.dll`、无系统库副本；A5 许可证/NOTICE 存在；A6 断网 + 切换 CWD + 受限用户再跑仍成功 |
| 提交 | `build(bundle): produce relocatable zero-install bundles on all three OSes` |
| DoD | A1–A6 PASS |

#### F-09-08 · 安全演示

| 项 | 内容 |
|---|---|
| 分支 | `feature/m9-08-security-demo` |
| 前置 | F-04-03, F-09-01 |
| 改动 | 新建 `scripts/{linux,macos,windows}/security_hijack_demo.*`、`docs/baseline.md` 安全章节 |
| 要点 | 复现「同名动态库劫持」后演示加固：绝对路径加载、`$ORIGIN`/`@rpath` 收紧、`SetDefaultDllDirectories` + `LOAD_LIBRARY_SEARCH_*`、无相对 RPATH、签名/哈希校验；`AT_SECURE` / SIP / Hardened Runtime 对 `LD_*`/`DYLD_*` 的限制说明。**演示脚本属 RV 通道，不进静态分析脚本** |
| 命令 | `./scripts/linux/security_hijack_demo.sh before` → `... after` |
| 断言 | A1 `before` 明确复现劫持；A2 `after` 加载可信库且哈希匹配；A3 演示脚本不修改系统目录、不写全局环境变量；A4 文档列出 ≥8 条防御项与特权程序额外规则；A5 `scan_dynamic_calls.sh` 对分析脚本仍零命中 |
| 提交 | `build(security): add same-name DLL hijack reproduction and hardening comparison` |
| DoD | A1–A5 PASS |

#### F-09-09 · 汇总报告与发布

| 项 | 内容 |
|---|---|
| 分支 | `feature/m9-09-report-release` |
| 前置 | F-09-05, F-09-06, F-09-07, F-09-08 |
| 改动 | 新建 `docs/REPORT.md`；`README.md` 终版、`CHANGELOG.md` 终版、`CONTRIBUTING.md` 补全 |
| 要点 | REPORT 按「分类与策略 → 平台格式 → 编译期 → 静态分析三层 → 运行验证 → 默认导出差异 → 32/64 与 CRT → C/C++ 互操作 → 打包 → 安全」组织，每节带**实测证据**（命令 + 输出摘录 + 组合标签）；README 含快速开始、24/32/24=80 矩阵、三组工作流索引、命令索引、C1–C18 约束、已知差异、目录导览、编码规范、缓存说明 |
| 命令 | `./scripts/verify_card.sh --all`（或 `.ps1`） |
| 断言 | A1 REPORT 10 章节齐全且每节 ≥1 条 `reports/` 实测引用；A2 README 每个命令代码块在 CI 中有等价调用；A3 全卡 `verify_card --all` 回归全绿；A4 内部链接可达；A5 `CHANGELOG` 与 10 个 tag 一一对应；A6 明确列出 `11.2` 全部待拍板项的当前取值 |
| 提交 | `docs: finalize evidence-backed report, README and release notes for v1.0.0` |
| DoD | A1–A6 PASS |

#### R-09 · 发布 `v1.0.0`（Gate C）

| 项 | 内容 |
|---|---|
| 分支 | `release/1.0.0` |
| 断言 | **Gate C**：`all.yml` **80** 组合全绿；三组工作流可各自单跑；缓存全生效且命中率有记录；SA/RV 报告齐全且分析禁令零命中；bundle 干净机验证通过；安全 before/after 成立；`docs/REPORT.md` 与 `reports/v1.0.0/SUMMARY.md` 完整；无 Debug CRT 进入发布物 |
| 动作 | `gh pr merge` ×2（合入 `main` + 回迁 `develop`）→ `git tag -a v1.0.0` → `git push origin main develop --follow-tags` → `gh release create v1.0.0 --target main --notes-file docs/REPORT.md` |

---

## 7. 构建矩阵执行规格（80 组合，全部源码外）

### 7.0 通用 out-of-source 约定

所有脚本统一入口：`scripts/<os>/build_all.<ext> <group> [filters]`，`group ∈ {native, make, cmake}`；产物严格落在 `1.4` 定义的目录；脚本执行前后各跑一次 D2 断言（`find` 源码树无产物）。

| 组 | 方言 | 产物根 | 组合数 |
|---|---|---|---|
| native | 编译器原生命令 | `build/native/<tag>/<kind>/` | 24 |
| make | `gnu` | `build/make/gnu/<tag>/<kind>/` | 14 |
| make | `nmake` | `build/make/nmake/<tag>/<kind>/` | 10 |
| make | `msbuild` | `build/make/msbuild/<tag>/<kind>/` | 8 |
| cmake | （msvc Ninja） | `build/cmake/<tag>/<kind>/` | 24 |

### 7.1 ① 原生命令（24 组合）

```
./scripts/linux/native.sh  <arch> <cfg> <kind>
./scripts/macos/native.sh  <arch> <cfg> <kind>
.\scripts\windows\native.bat -Toolset <...> -Variant <...> -Cfg <...> -Kind <...>
```

| OS | 工具链 | 32/64 或变体 | 动态库命令要点 | 导入库 | CRT / 运行库 |
|---|---|---|---|---|---|
| Linux | gcc | `-m32` / `-m64` | `-shared -fPIC -Wl,-soname,libvmath.so.1 -Wl,--enable-new-dtags` | 无 | `-lm -ldl` |
| Windows | msvc | `vcvarsall x86` / `x64` + `/MD`\|`/MT` | `cl /LD /DCALC_BUILD_DLL /O2 /DNDEBUG ... /link /DEF:def\vmath.def /OUT:vmath.dll` | `vmath.lib` | `/MD`↔`/MDd`、`/MT`↔`/MTd` |
| Windows | msys2 `MINGW64` / `MINGW32` / `UCRT64` / `CLANG64` | 由 `msystem` 决定 | `-shared -Wl,--out-implib,libvmath.dll.a -Wl,--output-def,vmath.def` | `libvmath.dll.a` | msvcrt / UCRT 由变体决定；**四环境不混用** |
| Windows | `clang-cl` | `--target=x86_64-pc-windows-msvc` | `clang-cl /LD ... /link /DEF:` | `llvm-lib` | 同 MSVC |
| macOS | Apple clang | `-arch arm64` | `-dynamiclib -Wl,-install_name,@rpath/libvmath.dylib -fvisibility=hidden` | 无 | 按需 `-framework` |

**动态组合基准链（Linux gcc）**：

```bash
OUT=build/native/linux_gcc_x64_Release/shared   # 源码外
gcc -c -O2 -DNDEBUG -fPIC -fvisibility=hidden -DCALC_BUILD_DLL \
    -Iinclude src/vmath_core.c   -o $OUT/vmath_core.o
gcc -c -O2 -DNDEBUG -fPIC -fvisibility=hidden -DCALC_BUILD_DLL \
    -Iinclude src/vmath_report.c -o $OUT/vmath_report.o
gcc -shared -Wl,-soname,libvmath.so.1 -Wl,--enable-new-dtags \
    -o $OUT/libvmath.so.1.0.0 $OUT/*.o
ln -sf libvmath.so.1.0.0 $OUT/libvmath.so.1 && ln -sf libvmath.so.1 $OUT/libvmath.so
gcc -O2 -DNDEBUG -Iinclude src/calctool.c -L$OUT -lvmath \
    -Wl,-rpath,'$ORIGIN' -ldl -lm -o $OUT/calctool
```

**静态组合差异（C9 强制）**：

```bash
OUT=build/native/linux_gcc_x64_Release/static
gcc -c -O2 -DNDEBUG -DCALC_STATIC -Iinclude src/vmath_core.c   -o $OUT/vmath_core.o
gcc -c -O2 -DNDEBUG -DCALC_STATIC -Iinclude src/vmath_report.c -o $OUT/vmath_report.o
ar rcs $OUT/libvmath.a $OUT/vmath_core.o $OUT/vmath_report.o
gcc -O2 -DNDEBUG -DCALC_STATIC -Iinclude src/calctool.c $OUT/libvmath.a -lm -o $OUT/calctool
```

**配置差异**：Debug `-g -O0 -D_DEBUG`（去 `-DNDEBUG`），MSVC `/Zi /Od /D_DEBUG` + `/DEBUG`；32 位 `-m32`（需 multilib）。

### 7.2 ② make 组（32 组合）

| 方言 | 入口 | 组合数 | 要点 |
|---|---|---|---|
| GNU make | `cd build/make/gnu/<tag>/<kind> && make -f <abs-src>/Makefile srcdir=<abs-src> ...` | 14 | `?=` 变量；`VIS` 仅 shared；`DEF_LIB`/`DEF_APP` 按形态；macOS 用 `gmake` |
| **nmake** | `cd build\make\nmake\<tag>\<kind> && nmake /f <abs-src>\Makefile.nmake SRCDIR=<abs-src> ...` | 10 | **单独文件、CRLF**；`!IF` 语法；`/MD`↔`/MDd` 随 CFG；`/DEF:` 仅动态 |
| msbuild | `msbuild vmath.vcxproj /p:OutDir=<abs-build>\ /p:IntDir=<abs-build>\obj\ ...` | 8 | `Configuration`×`Platform`×`RuntimeLibrary`；中间产物不落源码树 |

### 7.3 ③ CMake（24 组合，msvc 用 Ninja）

```bash
# Linux / macOS / 非 msvc Windows
cmake -S . -B build/cmake/<tag>/<kind> -DCMAKE_BUILD_TYPE=<cfg> \
      -DBUILD_SHARED_LIBS=<ON|OFF> -DCMAKE_C_FLAGS=-m32|-m64
cmake --build build/cmake/<tag>/<kind>
ctest --test-dir build/cmake/<tag>/<kind> --output-on-failure

# msvc / clang-cl：强制 Ninja（S9）
cmake -S . -B build/cmake/<tag>/<kind> -G Ninja \
      -DCMAKE_BUILD_TYPE=<cfg> -DBUILD_SHARED_LIBS=<ON|OFF> \
      -DCMAKE_MSVC_RUNTIME_LIBRARY=<MultiThreadedDLL|MultiThreaded>
cmake --build build/cmake/<tag>/<kind>
```

**必须验证**：`WINDOWS_EXPORT_ALL_SYMBOLS OFF` 强制走 `.def`/宏；`BUILD_RPATH` 与 `INSTALL_RPATH` 两阶段差异；`CMAKE_MSVC_RUNTIME_LIBRARY` 与 Debug/Release 联动。

### 7.4 80 组合覆盖证明矩阵

| 组 / 工作流 | Linux | macOS | Windows | 组合数 |
|---|---|---|---|---|
| N 原生 `native-*.yml` | gcc 4 | clang 2 | msvc 8 + msys2 8 + clang-cl 2 = 18 | **24** |
| M GNU make `make-{linux,macos}.yml` | 4 | 2 | — | 14 |
| M nmake `make-windows.yml` | — | — | msvc 8 + clang-cl 2 = 10 | 10 |
| M msbuild `msbuild-windows.yml` | — | — | msvc 8 | 8 |
| M 小计 | | | | **32** |
| C cmake `cmake-*.yml` | 4 | 2 | 18（msvc/clang-cl Ninja） | **24** |
| **总计** | | | | **80** |

---

## 8. CI 工作流分组、缓存与运行输出（S1 / S5 / S8）

### 8.1 分组原则

> 「为了避免 github ci 矩阵爆炸，可以将所有组合按构建工具分为 3 组：原生、make(name)、cmake。其他的组合也可以进一步分类。这样可以针对某条单独的工作流进行运行而无需全量运行。最后进行全部工作流测试。」

| 层级 | 划分 | 目的 |
|---|---|---|
| **第 1 层：组** | `N 原生` / `M make（含 nmake 与 msbuild）` / `C cmake` | 按构建工具分 3 组，可整组单跑 |
| **第 2 层：OS** | 每组再拆 `linux` / `macos` / `windows` 三条 workflow | 可单跑某 OS |
| **第 3 层：方言 / toolset** | `make-windows` 内按 `dialect=gnu\|nmake`；`msbuild` 单列；各 workflow 的 `workflow_dispatch` inputs 可精确过滤 `toolset/variant/cfg` | 可单跑某一条组合 |
| **第 4 层：全量** | `all.yml` 用 `workflow_call` 串联 10 条组合工作流 + `analyze.yml` + `run-output.yml` | **最后进行全部工作流测试** |

> 「make(name)」按 **make 组含 GNU make / nmake / msbuild 三种方言** 解读（待拍板 P4）。

### 8.2 工作流文件清单（16 个）

> **数量口径（v1.3 / S3，消除歧义）**：全文出现三种数字，含义不同、互不矛盾 —— **10 条** = 按「构建工具 × OS」拆出的**组合工作流**（`native-*` 3 + `make-*` 3 + `msbuild-windows` 1 + `cmake-*` 3，`S5` 与 `8.1` 第 1/2 层口径）；**12 条** = 10 条 + `analyze.yml` + `run-output.yml`（`V2`、`F-09-05` 口径）；**16 个文件** = 12 条 + `lint.yml` + `_env.yml` + `_combo.yml` + `all.yml`（本节清单口径）。`all.yml` 用 `workflow_call` 串联 10 条组合工作流 + 2 条分析 / 运行工作流，覆盖 **80 组合**。

| 类别 | 文件 | 可单独 dispatch | 组合数 |
|---|---|---|---|
| 门禁 | `lint.yml` | ✓（PR 自动） | — |
| 基础设施 | `_env.yml`（`workflow_call`） | 被调 | — |
| 基础设施 | `_combo.yml`（`workflow_call`） | 被调 | — |
| **N** | `native-linux.yml` | ✓ | 4 |
| **N** | `native-macos.yml` | ✓ | 2 |
| **N** | `native-windows.yml` | ✓ | 18 |
| **M** | `make-linux.yml` | ✓ | 4 |
| **M** | `make-macos.yml` | ✓ | 2 |
| **M** | `make-windows.yml`（gnu 8 + nmake 10） | ✓ | 18 |
| **M** | `msbuild-windows.yml` | ✓ | 8 |
| **C** | `cmake-linux.yml` | ✓ | 4 |
| **C** | `cmake-macos.yml` | ✓ | 2 |
| **C** | `cmake-windows.yml`（msvc Ninja） | ✓ | 18 |
| 分析 | `analyze.yml` | ✓ | 对指定产物 |
| 运行 | `run-output.yml` | ✓ | 对指定产物 |
| **全量** | `all.yml` | ✓ | **80** |

统一的 `workflow_dispatch` inputs：

```yaml
on:
  workflow_dispatch:
    inputs:
      toolset: { description: 'all|gcc|msvc|msys2|clang-cl|clang', default: 'all' }
      variant: { description: 'all|x86|x64|x64_MD|...|MINGW32|...', default: 'all' }
      cfg:     { description: 'all|Debug|Release', default: 'all' }
      kind:    { description: 'all|static|shared', default: 'all' }
      dialect: { description: 'all|gnu|nmake|msbuild (make group only)', default: 'all' }
```

`all.yml` 通过 `uses: ./.github/workflows/<file>.yml`（`workflow_call`）串联，最后 `summary` job 汇总。

### 8.3 缓存落地（对应 `5.9`）

`_env.yml` 调用 `.github/actions/setup-env/action.yml`，按输入恢复/保存缓存。关键片段（示意）：

```yaml
- uses: awalsh128/cache-apt-pkgs-action@latest      # Linux：apt deb 包
  if: runner.os == 'Linux'
  with: { packages: ${{ readFile('.github/apt-packages.txt') }}, version: 1 }

- uses: actions/cache@v4                             # Homebrew 下载缓存
  if: runner.os == 'macOS'
  with:
    path: |
      ~/Library/Caches/Homebrew
      ${{ github.workspace }}/.brew-cache
    key: brew-${{ runner.os }}-${{ runner.arch }}-${{ hashFiles('.github/brew-packages.txt') }}

- uses: msys2/setup-msys2@v2                        # Windows：pacman 包（内部缓存）
  if: startsWith(inputs.toolset, 'msys2')
  with:
    msystem: ${{ inputs.variant }}                  # 动态，不得写死
    cache: true
    install: ${{ readFile('.github/msys2-packages.txt') }}

- uses: actions/cache@v4                             # 全平台：编译缓存
  with:
    path: ${{ runner.os == 'Windows' && '%LOCALAPPDATA%\\sccache' || '~/.cache/ccache' }}
    key: cc-${{ runner.os }}-${{ inputs.toolset }}-${{ inputs.variant }}-${{ inputs.cfg }}-${{ inputs.kind }}-${{ github.run_id }}
    restore-keys: cc-${{ runner.os }}-${{ inputs.toolset }}-${{ inputs.variant }}-${{ inputs.cfg }}-${{ inputs.kind }}-
    save-always: true
```

> 缓存命中/未命中与命中率写入 `$GITHUB_STEP_SUMMARY`；`all.yml` 复用已建立缓存（K6）。

### 8.4 运行输出采集（对应 S8 / RV）

每个 `_combo.yml` 内**按 step 隔离**：

```yaml
- name: RV - capture program output            # 运行验证（非分析）
  run: ./scripts/<os>/run.<ext> <tag> <kind> <group>
  # 产物：reports/<tag>/run/<tag>.txt（stdout + stderr + exit code）

- name: SA - three-layer static analysis       # 静态分析（禁止运行）
  run: ./scripts/<os>/static_analyze.<ext> <tag> <kind> <group>
  # 产物：reports/<tag>/<group>/<tag>.md + reports/<tag>/deps/<tag>.{json,md}

- name: Publish program output to Job Summary
  run: |
    echo '## calctool 运行输出 · ${{ inputs.tag }}' >> "$GITHUB_STEP_SUMMARY"
    echo '```' >> "$GITHUB_STEP_SUMMARY"
    cat reports/<tag>/run/<tag>.txt >> "$GITHUB_STEP_SUMMARY"
    echo '```' >> "$GITHUB_STEP_SUMMARY"

- uses: actions/upload-artifact@v4
  with: { name: <tag>-<kind>-<group>, path: reports/<tag>/ }
```

> **CI 中包含程序运行输出的结果**：`--self-test` / `info` / `add` / `dot` / `--dynamic` 的完整 stdout+stderr+退出码既进 artifact，也在 Job Summary 直接可见（F-09-05 A4 断言）。

### 8.5 通过 `gh` 单独触发与观测（v1.2 新增，S11）

> 「所有开发测试都用 agent 调用 `gh` 完成」在本章落地为：**CI 的触发、观测、结果回收一律由 agent 调用 `gh`**，不在网页手工点击；`workflow_dispatch`（`8.1` 的分层分组）正是为单条 `gh workflow run` 设计的。

| 场景 | 命令 | 说明 |
|---|---|---|
| 单跑一条工作流 | `gh workflow run native-windows.yml -f toolset=msvc -f variant=x64_MD -f cfg=Release -f kind=shared` | 对应 `8.1` 第 1 / 2 / 3 层过滤 |
| 整组单跑 | `gh workflow run make-windows.yml -f dialect=nmake`、`gh workflow run msbuild-windows.yml` | M 组按方言再分 |
| 只跑静态分析 | `gh workflow run analyze.yml -f tag=linux_gcc_x64_Release` | 对指定产物 |
| 只跑运行输出 | `gh workflow run run-output.yml -f tag=linux_gcc_x64_Release` | RV 通道 |
| **最后全量测试** | `gh workflow run all.yml` | 串联 80 组合（`8.2` 第 4 层） |
| 观测 | `gh run list --workflow=all.yml --limit 5`、`gh run watch <run-id> --exit-status`、`gh run view <run-id> --log` | `--exit-status` 作为 release 门槛 |
| 结果回收 | `gh run download <run-id>`、`gh api repos/jxsword/c-cpp-lib-lab/actions/runs/<id>/jobs` 读 Job Summary | artifact 与程序运行输出 |
| 发布卡 | `gh pr checks <n>` 全绿后方可 `gh pr merge`；`gh release create v<semver> --target main --notes-file CHANGELOG.md` | `2.1`、`R-*` |

> **判定留痕**：上述 run 的 id / URL 与结论写进卡回执（`0.4`）和 `docs/REPORT.md`，作为 `V19` / `V20` 的判定依据。
> **辅助脚本（J1–J7）不调用 `gh`**：`gh` 只出现在 workflow、任务卡命令、`CONTRIBUTING.md` 与 agent 的执行动作里，保证本地批量构建在离线、未登录状态下仍可跑（`9.4 J7`）。

---

## 9. 打包、安全、报告与脚本职责决策

### 9.1 打包决策（F-09-07）

| 需求 | Linux | macOS | Windows |
|---|---|---|---|
| 单可执行文件 | 全静态 / AppImage | 不自然，用 `.app` 或 pkg | `/MT` 全静态 / 资源内嵌 |
| 压缩包解压即用 | `$ORIGIN/lib` + 自带 so | `.app` 内嵌 Frameworks + `@rpath` | exe 同目录平铺 DLL |
| 规避版本不匹配 | 老基线构建 + 自带 so | 自带 dylib + 收紧 rpath | 自带 DLL + 避免 SxS 冲突 |
| 收尾（**静态复核**） | `patchelf` + `strip` + `readelf -d` | `install_name_tool` + `codesign` | `dumpbin /dependents` |
| **绝对不要打包** | glibc / ld-linux / NSS | 系统 dylib（shared cache） | KnownDLLs / 系统 DLL |

> 打包后的「加载的是包内库」验证改用 **SA-7/SA-8 静态复核**，不使用运行期跟踪（C13）。

### 9.2 安全演示要点（F-09-08）

| 环节 | 内容 |
|---|---|
| 攻击面 | 搜索路径优先级、`LD_PRELOAD` / `DYLD_INSERT_LIBRARIES`、`PATH` 前置目录、相对 `RPATH`、未固定 ordinal 的 DLL 版本替换 |
| `before` | 前置目录放同名 `libvmath.so` / `vmath.dll`，观察被劫持（**RV 通道**） |
| `after` | 绝对路径加载、`$ORIGIN`/`@rpath` 收紧、`SetDefaultDllDirectories` + `LOAD_LIBRARY_SEARCH_*`、无相对 RPATH、签名/哈希校验 |
| 特权程序 | Linux `AT_SECURE`（忽略 `LD_*`、限制相对 RPATH 与部分 `$ORIGIN`）、macOS SIP / Hardened Runtime 清除 `DYLD_*` |
| 交付 | ≥8 条防御清单 + 静态审计项（不依赖运行期监控） |

### 9.3 报告结构（`docs/REPORT.md`）

1. 分类与策略矩阵 → 2. 平台格式与扩展名 → 3. 编译期路径与优先级 → 4. **静态分析三层与依赖树** → 5. **运行验证输出** → 6. 默认导出差异实测 → 7. 32/64 与 CRT → 8. C/C++ 互操作三阶段 → 9. 打包与干净机验证 → 10. 安全演示。每节带**实测证据引用**（`reports/<tag>/...` + 命令 + 输出摘录 + 组合标签）。

### 9.4 **CI 是否使用辅助脚本：决策记录（S6 要求「由计划分析决定」）**

| 方案 | 描述 | 优点 | 缺点 | 结论 |
|---|---|---|---|---|
| A 全复用 | CI 直接调用本地脚本完成一切（含环境安装与缓存） | 单一事实来源 | 缓存 action 无法塞进脚本、脚本绑死 CI、编码要求复杂化 | 否 |
| B 全内联 | workflow 里写全部命令，不用辅助脚本 | CI 自包含 | 与本地命令漂移、失败难复现、workflow 膨胀 | 否 |
| **C 混合（采用）** | **环境安装 + 缓存**由 `_env.yml` / composite action 负责（用原生 cache action）；**构建、RV 运行输出、SA 静态分析**复用同一套辅助脚本；artifact 上传与汇总用 workflow 原生能力 | CI 与本地命令一致、失败可本地复现、缓存用原生 action、脚本不绑 CI、便于批量本地构建 | 脚本必须严格无交互 / 参数化 / 退出码明确 | **采用** |

**采用 C 的配套约束**（写进 `CONTRIBUTING.md` 与 lint）：

| # | 约束 |
|---|---|
| J1 | 脚本统一入口 `build_all.<ext> <group> [filters]`、`static_analyze.<ext> <tag> <kind> <group>`、`run.<ext> <tag> <kind> <group>`；CI 与本地调用同一入口、同一参数 |
| J2 | 脚本**不得引用 `GITHUB_*` 环境变量**；Job Summary / artifact 由调用方 workflow 处理 |
| J3 | 脚本无交互、无 `read`、无 TTY 依赖；退出码 `0`=成功、非 `0`=失败并附原因 |
| J4 | 脚本只写 `build/` 与 `reports/` 下路径，不改源码树 |
| J5 | 脚本编码/换行遵守 `5.10`，由 lint 在三个 OS 各校验一次 |
| J6 | 静态分析脚本遵守 `5.8.4` 禁令；运行脚本与静态分析脚本**文件分离** |
| **J7** | **辅助脚本不得调用 `gh`、不得引用 `GH_TOKEN` / `GITHUB_*` 凭据**：GitHub 侧操作（PR / workflow 触发 / run 观测 / artifact 下载 / release）只由 agent 在 workflow 与任务卡命令中调用 `gh`（`0.7.3`、`8.5`），保证本地批量构建离线、未登录仍可跑 |

> 结论：**CI 复用辅助脚本**，但只复用「构建/测试/分析/运行采集」部分；「环境+缓存」不复用脚本而用原生 action。这样既满足 S6「辅助脚本主要便于本地批量构建」，又保证 S1 缓存与 S5 分组能力。

---

## 10. 全局验收清单与发布 DoD

| # | 验收项 | 判定 |
|---|---|---|
| V1 | **80 组合**（原生 24 + make 32 + cmake 24）全部 `--self-test` 退出码 0 | `all.yml` + `verify_card --all` |
| V2 | 三套构建方式在三大 OS 均有 CI 记录，且可各自单独 dispatch | 12 条工作流 + F-09-06 A1 |
| V3 | **全部源码外构建**，源码树零产物、三套构建目录互不相同 | D2 + F-03-02 A5 + F-05-04 |
| V4 | SA-1…SA-10 在 80 组合上有结论，含**编译器名+版本号** | `reports/v1.0.0/SUMMARY.md` |
| V5 | 依赖树**追踪符号链接到实际库**、分级树形展示、区分自带/系统 | `reports/v1.0.0/deps/*.{json,md}` |
| V6 | 分析**全程静态**，`5.8.4` 禁用调用零命中 | D10 + lint |
| V7 | **程序运行输出**进 artifact 且在 Job Summary 可见 | F-09-05 A4 |
| V8 | 6 API 导出集 + `vmath_errno` 平台差异由断言证明 | F-02-04 / F-04-02 |
| V9 | ordinal 1–6、`@5 NONAME`、Windows 按序号取址成功 | F-04-03 |
| V10 | 静态组合 `.o` 以 `CALC_STATIC` 重编 | F-02-01 A4 |
| V11 | **CI 大体积环境与安装包全部启用缓存**，key 满足 K1–K8、命中率有记录 | F-00-03 / F-09-01 |
| V12 | `*.ps1` UTF-8 BOM、`*.bat` CRLF 无 BOM、`*.sh` LF 无 BOM | F-00-04 / lint |
| V13 | `Makefile.nmake` 独立且 CRLF；msvc cmake 用 Ninja | F-05-02 / F-06-01 |
| V14 | 阶段 2 / 阶段 3 源码与反例齐全 | M7 / M8 release 门槛 |
| V15 | bundle 在干净机零额外安装运行 | F-09-07 A2 |
| V16 | 无 Debug CRT 进入发布物 | F-09-01 A5 + F-09-07 A4 |
| V17 | 10 个 tag 与 CHANGELOG 一一对应 | F-09-09 A5 |
| V18 | `main` 分支可直接克隆并按 README 复现 | R-09 |
| **V19** | `git remote get-url origin` 为 **SSH** `git@github.com:jxsword/c-cpp-lib-lab.git`；`gh auth status` 通过；`ssh -T git@github.com` 连通（A9）；无 HTTPS origin 残留；分支保护在首 push 之后设置 | `F-00-01` A6 / A7 / A9 + `R-00` |
| **V20** | 全部开发测试的 GitHub 侧动作有 `gh` 调用记录（PR / checks / workflow run / run watch / release），且 `scripts/` 内 `gh` 调用数为 0 | `8.5`、`9.4 J7`、`docs/REPORT.md` |
| **V21** | 计划**自包含**：全文无越界章节引用；`docs/PLAN.md` 与 `0.3.1` 记录的 sha256 **BASE** 一致且为唯一权威副本；zcode 仅凭本文件完成 `F-00-01`…`F-09-09` | `0.7.4` Z1–Z4、`F-00-01` A4、`0.3.1` |

---

## 11. 风险登记册

### 11.1 已识别风险与缓解

| # | 风险 | 影响 | 缓解 | 触发时动作 |
|---|---|---|---|---|
| K1 | macOS 32 位客观不可实现 | 组合矩阵缺口 | 新定义 macOS 仅 64 位；32 位由 Linux x86 / Windows x86 / MINGW32 承担；x86_64 + universal 作附加验证 | 记入 README 与 SUMMARY，不伪造产物 |
| K2 | Linux 32 位 multilib 缺失 | x86 组合编译失败 | apt 装 `gcc-multilib`（纳入缓存） | `hotfix/*` 补依赖，不删组合 |
| K3 | MSVC Debug CRT 不可分发 | 合规与运行失败 | 只本地验证，不上传发布 artifact | CI 断言 |
| K4 | 静态组合复用动态 `.o` | 四模式语义被破坏 | C9 强制重编 + `make -n` 断言 | 视为 FAIL，回 F-02-01 |
| K5 | `__stdcall` 导致按名 `GetProcAddress` 失败 | `--dynamic` 失效 | 统一 `__cdecl`（本计划 `5.1` 基线） | `hotfix/plan-*` |
| K6 | `.def` 中列出 `vmath_errno` | 教学对照失效 | F-01-02 断言全文无 `DATA`、无该符号 | 立即修 `.def` |
| K7 | msys2 四环境产物混链 | 链接/运行期诡异失败 | 环境独立目录（C8）+ `msystem` 动态选择 | F-04-02 A6 / F-09-03 A2 拦截 |
| K8 | `WINDOWS_EXPORT_ALL_SYMBOLS` 默认开启 | 导出集超出 6 个 | 显式 `OFF` + `.def` | F-03-01 / F-06-01 断言 |
| K9 | 跨 CRT 传 STL | Debug 崩溃、Release 正常 | 门面 / 纯虚接口 / 库侧 `release()` | F-08-04 反例 + 修复记录 |
| K10 | 目标机 glibc / GLIBCXX 基线过高 | `version ... not found` | 老基线构建 + `objdump -T` | 干净容器 job 拦截 |
| K11 | CI 全 80 组合成本过高 | 反馈慢 | 3 组 × OS 分层 dispatch；`all.yml` 最后全量；缓存复用 | 按 `8.1` 分层 |
| K12 | 反例污染主 CI | 常红 | `tests/negative/` expected-failure 隔离 | F-01-06 / F-07-02 / F-08-04 |
| K13 | runner 无 GUI 工具 | SA-8 依赖树缺口 | CLI 等价静态工具（Dependencies CLI / `lddtree` / `dylibbundler`） | 报告标 `CLI-equivalent` |
| **K14** | **缓存 key 跨组合复用导致 32/64 或 /MD /MT 目标文件串味** | 隐蔽的 ABI 错误 | K1 强制 key 含 `variant`；`restore-keys` 同前缀；ccache/sccache 按组合分 | 命中异常时清空该前缀缓存并重跑 |
| **K15** | **缓存污染 / 陈旧包** | 构建结果与本地不一致 | 包清单 `hashFiles` 失效；版本锁定文件；缓存命中率与包版本写入 Job Summary | 提 `hotfix/*` 更新清单 |
| **K16** | **ps1 丢 BOM / bat 变 LF** | Windows 中文乱码、首行报错、cmd 执行异常 | `.gitattributes` + `check_encoding.*` + lint 三 OS 校验 | PR 直接拒绝（F-00-02 A3） |
| **K17** | **`ldd` / 运行期手段混入分析脚本** | 违反「分析必须静态」 | `5.8.4` 禁令 + `scan_dynamic_calls.sh` lint 扫描 + RV/SA 文件分离 | PR 直接拒绝（D10） |
| **K18** | **nmake 与 GNU make 语法混淆 / 换行不对** | 10 组合构建失败 | `Makefile.nmake` 独立文件 + CRLF + `!IF` 语法 + F-05-02 A1 | 回 F-05-02 |
| **K19** | **msbuild 默认把产物写回源码树** | 违反 out-of-source | `/p:OutDir` `/p:IntDir` 强制 + F-05-03 A5 | 回 F-05-03 |
| **K20** | 编译期与运行期结论依赖「实际运行」 | SA 结论不可信 | SA 只读段表/符号表/导入表；运行结论一律归 RV | F-09-05 A6 |
| **K21** | SSH 私钥 / `gh` 凭据失效，或 `origin` 误用 HTTPS | push 失败、CI 无法触发、release 无法发布 | `F-00-01` A6 / A7 前置校验；`CONTRIBUTING.md` 写明 SSH 与 `gh auth login` 恢复步骤 | 暂停领卡，先修凭据，不改计划 |
| **K22** | 把 `gh` 调用写进辅助脚本 | 本地离线批量构建失败、脚本绑死登录态 | `9.4 J7` + `F-00-02` A5 扫描 `scripts/` 内 `gh ` 调用 | PR 直接拒绝 |
| **K23** | `git flow feature finish` 与 `gh pr merge` 重复合并 | 分支拓扑混乱、合并提交重复 | `2.1` 禁用 finish 的本地合并动作，只保留 `init` / `start` | 回 `2.1` 复核命令 |

### 11.2 待拍板项（**未确认前不得更改**）

**已关闭（由本轮补充需求取代）**：

| 项 | v1.0 状态 | v1.1 结论 |
|---|---|---|
| ~~P1~~ 16 组合定义 | 待拍板 | **关闭**：由 `5.5` 的 24/32/24=80 取代；库形态降为组合内双形态，`/MD /MT` 升为变体维度 |
| ~~P2~~ macOS 32 位 | 待拍板 | **关闭**：新定义 macOS 仅 64 位（C1） |

**新增待拍板（本轮需求解读点）**：

| # | 议题 | 当前计划取值 | 备选 | 影响面 |
|---|---|---|---|---|
| **P3** | 库形态（静态 / 动态）在新 24 组合中的位置 | **每组合内 `static/` + `shared/` 双形态必建**，不乘组合数（保持总数 80） | 若库形态也作独立矩阵维度 → 基础 48、总计 160 | `1.4`、`5.5`、全部任务卡断言、V1、README |
| **P4** | 「make(name)」的解读 | make 组 = **GNU make + nmake + msbuild** 三种方言，共 32；按组单跑 | 若仅指 GNU make+nmake（24），msbuild 8 另立第 4 组 | `5.5.2`、`8.1`、`8.2`、F-09-03 |
| **P5** | `--dynamic` 与「分析禁动态加载」的边界 | **分析（SA）禁** `dlopen`/`LoadLibrary`；**运行验证（RV）保留** `--dynamic` 功能演示；两者脚本/报告/step 隔离 | 完全移除 `--dynamic` 功能 | `5.7`、`5.8.4`、F-02-02、F-04-03、RV-4 |
| **P6** | Windows `llvm-clang(64)` 的具体形态 | 按 **`clang-cl`**（MSVC ABI、可用 `/MD /MT`、走 `.def`）处理，计入 nmake/cmake 的 2 个组合 | 原生 `clang --target=x86_64-pc-windows-gnu`（MinGW ABI） | `5.5.1` 工具链表、F-04-02、F-05-02、F-06-01 |
| **P7** | macOS `clang64` 与双架构 | 24 组合内按 **1 变体 `arm64`**（`macos-14`）；x86_64（`macos-13`）与 `lipo` universal 作**附加不计数组合**的架构覆盖验证 | 把 x86_64 也计入 → macOS 4、总计 26/82 | `5.5.1`、C1/C7、F-04-01、CI 矩阵 |
| **P8** | 「所有开发测试都用 agent 调用 `gh` 完成」的边界 | **GitHub 侧**（PR / checks / workflow 触发 / run 观测 / artifact / release）一律 `gh`；本地构建 / 测试 / 分析由 agent 调用 `scripts/` 脚本发起，结论经 `gh` 回写 | 本地构建也必须只经 `gh` 触发的 CI 执行（无本地直跑） | `0.3`、`0.7.3`、`8.5`、`9.4 J7` |

> 另有一项**明确指令**（非待拍板）：Linux 工具链由 v1.0 的 `gcc + clang` 收敛为**仅 gcc**，clang 降为不计数组的本地可选验证。此项已按 S2 落地。
>
> 如需变更任一待拍板项，请回复「**hotfix/plan-01：P3 改为按库形态展开**」之类的明确指令，走 `0.5` 的 `hotfix/plan-*` 流程，**先改本计划再改实现**。

---

## 12. 附录

### A. 静态分析命令速查（按 SA 项）

| SA | Linux（内置 / 第三方） | macOS（内置 / 第三方） | Windows（内置 / 第三方） |
|---|---|---|---|
| SA-1 架构 | `file`、`readelf -h` / `llvm-readobj --file-headers` | `file`、`lipo -archs`、`otool -hv` / `llvm-readobj` | `dumpbin /headers` / `llvm-readobj` |
| SA-2 编译器版本 | `readelf -p .comment`、`readelf --debug-dump=info` / `llvm-dwarfdump` | `dwarfdump --debug-info`、`otool -l` / `llvm-readobj` | `dumpbin /rawdata`(Rich Header)、`strings` / `llvm-readobj --coff-rich-header`、`pev` |
| SA-3 Debug/Release | `readelf -S \| grep debug` / `llvm-dwarfdump` | `dwarfdump`、`*.dSYM` | `dumpbin /directives`、`*.pdb` |
| SA-4 库形态 | `ar t` vs `readelf -d` | `ar t` vs `otool -hv` | `lib /list`、`dumpbin /exports` |
| SA-5 导出符号 | `nm -D --defined-only` / `llvm-nm` | `nm -gU`、`dyld_info -exports` | `dumpbin /exports` / `Dependencies` |
| SA-6 内部符号 | `nm` / `llvm-nm` | `nm -m` | `dumpbin /symbols` |
| SA-7 直接依赖 + realpath | `readelf -d`、`objdump -p` + `readlink -f` | `otool -L` + `readlink` | `dumpbin /dependents` + `Resolve-Path` |
| SA-8 递归依赖树 | `lddtree`(pax-utils) + `deps_tree.sh` | `dylibbundler` / `macdependency` + `deps_tree.sh` | `Dependencies` CLI + `deps_tree.ps1` |
| SA-9 CRT | `readelf -d` | `otool -L` | `dumpbin /dependents` |
| SA-10 搜索路径 | `readelf -d`、`patchelf --print-rpath` | `otool -l`、`install_name_tool -id` 查询 | `dumpbin`、清单 |
| **禁用** | `ldd`、`LD_DEBUG`、`LD_PRELOAD`、`pldd` | `DYLD_*` 运行期变量、`vmmap` | ProcMon Load Image、Process Explorer 模块列表 |

### B. 宏与环境变量速查

| 类别 | 名称 |
|---|---|
| 平台 | `_WIN32` `_WIN64` `__CYGWIN__` `__APPLE__` `__linux__` |
| 编译器 | `__GNUC__` `__clang__` `_MSC_VER` `__MINGW32__` `__MINGW64__` `__MSYS__` |
| 位数 | `__LP64__` `_WIN64` `__i386__` `__x86_64__` `__aarch64__` `__SIZEOF_POINTER__` |
| 语言 / 配置 | `__cplusplus` `_MSVC_LANG` / `NDEBUG` `_DEBUG` `_ITERATOR_DEBUG_LEVEL` |
| 项目四模式 | `CALC_STATIC` `CALC_BUILD_DLL` `CALC_USE_DLL` `CALC_NO_LIB` |
| 编译期路径 | `LIBRARY_PATH` `CPATH` `SDKROOT` / `LIB` `INCLUDE` |
| 运行期（**仅 RV，分析禁用**） | `LD_LIBRARY_PATH` `LD_PRELOAD` `LD_DEBUG` / `DYLD_LIBRARY_PATH` `DYLD_FALLBACK_LIBRARY_PATH` / `PATH` |

### C. 缓存速查

| 平台 | 缓存对象 | 机制 | key 必含 |
|---|---|---|---|
| Linux | apt deb 包 | `cache-apt-pkgs-action` / `actions/cache` | `hashFiles('.github/apt-packages.txt')` |
| Linux | ccache | `actions/cache@v4` | os + toolset + variant + cfg + kind + run_id |
| macOS | Homebrew | `actions/cache@v4` | `hashFiles('.github/brew-packages.txt')` |
| macOS | ccache | `actions/cache@v4` | 同上组合维度 |
| Windows | MSYS2 pacman | `msys2/setup-msys2@v2` `cache: true` | 内部按 `msystem` |
| Windows | LLVM / Ninja / CMake / Dependencies | `actions/cache@v4` | `hashFiles('.github/tool-versions.env')` |
| Windows | sccache | `actions/cache@v4` | 同上组合维度 |
| 跨 job 产物 | 构建产物 / 报告 | `upload-artifact` / `download-artifact`（**非 cache**） | — |

### D. 脚本编码与换行速查

| 扩展名 | 编码 | 换行 | 校验 |
|---|---|---|---|
| `.sh` | UTF-8 无 BOM | LF | `check_encoding.sh` |
| `.ps1` | **UTF-8 BOM** | CRLF | `check_encoding.ps1` 查首 3 字节 `EF BB BF` |
| `.bat` / `.cmd` | UTF-8 **无 BOM**（cmd.exe 不接受 BOM） | **CRLF 必须** | 查无裸 LF、无 BOM |
| `Makefile.nmake` | UTF-8 无 BOM | **CRLF** | nmake 语法要求 |
| 其他源文件 / yml / md | UTF-8 无 BOM | LF | `.gitattributes` |

### E. 排错索引

| 现象 | 根因 | 静态定位 |
|---|---|---|
| `cannot open shared object file` | RUNPATH 未覆盖 | `readelf -d`、`patchelf --print-rpath` |
| `Library not loaded: image not found` | install_name 绝对路径 / `@rpath` 未配 | `otool -L`、`otool -l` |
| `X.dll was not found` | DLL 不在搜索路径 / CRT Redist 缺失 | `dumpbin /dependents`、Dependencies CLI |
| `skipping incompatible ...` / `LNK1112` | 32-64 混链 | `file`、`readelf -h`、`dumpbin /headers` |
| `bad CPU type in executable` | 架构 slice 不匹配 / 32 位已不支持 | `lipo -archs` |
| `version 'GLIBC_2.xx' / 'GLIBCXX_3.4.xx' not found` | 构建机基线高于目标机 | `objdump -T \| grep GLIBC` |
| `undefined reference` / `LNK2019` | 链接顺序 / 漏库 / `extern "C"` / `dllimport` | `nm -C`、`dumpbin /exports` |
| `undefined symbol: __imp_foo` | 静态库误用 `dllimport` | 检查 `CALC_STATIC` |
| `LNK2038` / `LNK4098` | CRT 或 STL 配置混链 | `dumpbin /directives`、`link /verbose:lib` |
| `The ordinal N could not be located` | ordinal 未用 `.def` 固定 | `dumpbin /exports` |
| `dlsym` 返回 NULL | `visibility=hidden` 未导出 / 名字被 mangling | `nm -D`、`c++filt` |
| `DSO missing from command line` | `--as-needed` 下间接依赖未显式 `-l` | `readelf -d` |
| `0xc000007b` | 32/64 位 DLL 混装 | `dumpbin /headers` |
| Debug 崩溃、Release 正常 | 跨模块 STL / `new-delete` 跨 CRT | `dumpbin /directives`、统一 `/MD /MT` |
| **ps1 中文乱码 / 首行报错** | 缺 UTF-8 BOM / bat 带 BOM | `check_encoding.ps1` |
| **bat 只执行第一行** | 换行是 LF 而非 CRLF | `check_encoding.sh` |
| **nmake `syntax error`** | 用了 GNU make 语法或 LF 换行 | 检查 `Makefile.nmake` 独立性 + CRLF |
| **缓存命中后结果异常** | 32/64 或 `/MD /MT` 缓存串味（K14） | 检查 key 是否含 `variant`，清前缀重跑 |

### F. 本计划内部索引与执行知识补遗（v1.2 重写）

> v1.2 起本节**不再指向任何外部文档**。F.1 是本计划自身的章节 ↔ 任务卡索引；F.2–F.4 把原先需外部查阅的关键契约内联，确保 zcode 只凭本文件即可写出代码。

#### F.1 章节 ↔ 任务卡索引（纯内部）

| 要找什么 | 本计划位置 | 对应任务卡 |
|---|---|---|
| 环境与仓库前置（SSH / `gh` / 目录现状与权威副本） | `0.7`、`0.3.1` | F-00-01 |
| 分支模型、命名、tag、提交规范 | `2.1`–`2.6` | F-00-01、F-00-02 |
| 里程碑 / 能力档位 / tag / **勾选清单** | `0.2`、`3`、`3.1` | `R-00`…`R-09` |
| 首次启动健康检查 / 引导期分期生效 / 修订留痕 | `0.3.1`、`2.6`、`12.H` | F-00-01…F-00-04 |
| 目录树与文件归属 | `4.1`、`4.2` | 全部卡 |
| 接口契约、9 个 API、`.def`、CLI | `5.1`–`5.4`、`12.F.2` | F-01-01…F-01-06 |
| 组合定义 24 / 32 / 24 = 80 | `5.5`、`7` | F-02-01…F-06-02 |
| 客观约束 C1–C18 | `5.6` | 全部卡 |
| SA / RV 清单、三层静态分析、依赖树 | `5.7`、`5.8`、`12.A` | F-02-03、F-04-04、F-09-05 |
| CI 缓存、分组、`gh` 触发与观测 | `5.9`、`8`、`12.C` | F-00-03、F-09-01…F-09-06 |
| 脚本编码 / 换行 | `5.10`、`12.D` | F-00-04 |
| 打包 / 安全 / 报告 / 脚本职责决策 | `9` | F-09-07…F-09-09 |
| 验收 / 风险 / 待拍板 | `10`、`11` | `R-*` |
| 排错 | `12.E` | 全部卡 |
| 许可协议决策表 | `12.G` | F-00-01、F-09-07 |

#### F.2 `calc_export.h` 参考骨架（内联，F-01-01 的实现依据）

```c
/* include/calc_export.h —— 参考骨架；实现以 5.1 六条与 F-01-01 断言为准 */
#ifndef CALC_EXPORT_H
#define CALC_EXPORT_H

/* ① 平台判定 */
#if defined(_WIN32) || defined(_WIN64) || defined(__CYGWIN__)
#  define CALC_PLATFORM_WINDOWS 1
#elif defined(__APPLE__)
#  define CALC_PLATFORM_MACOS 1
#else
#  define CALC_PLATFORM_UNIX 1
#endif

/* ② C++ 链接规格：C 库被 C++ 调用时不改名 */
#ifdef __cplusplus
#  define CALC_EXTERN_C_BEGIN extern "C" {
#  define CALC_EXTERN_C_END   }
#else
#  define CALC_EXTERN_C_BEGIN
#  define CALC_EXTERN_C_END
#endif

/* ③ 四模式分派：CALC_STATIC / CALC_BUILD_DLL / CALC_USE_DLL / CALC_NO_LIB */
#if defined(CALC_STATIC) || defined(CALC_NO_LIB)
#  define CALC_API                                  /* 静态 / 不建库：展开为空 */
#elif defined(CALC_PLATFORM_WINDOWS)
#  if defined(CALC_BUILD_DLL)
#    define CALC_API __declspec(dllexport)
#  else
#    define CALC_API __declspec(dllimport)         /* 未指定时按导入侧（M3） */
#  endif
#else
#  if defined(CALC_BUILD_DLL)
#    define CALC_API __attribute__((visibility("default")))
#  else
#    define CALC_API
#  endif
#endif

/* ④ 调用约定：32 位 Windows 统一 __cdecl（禁用 __stdcall，见 5.1） */
#if defined(CALC_PLATFORM_WINDOWS) && !defined(_WIN64)
#  define CALC_CALL __cdecl
#else
#  define CALC_CALL
#endif

/* ⑤ 本项目刻意不导出任何数据符号：错误码走 vmath_last_error() 访问器 */
/* ⑥ 可选弃用标记 */
#if defined(__GNUC__) || defined(__clang__)
#  define CALC_DEPRECATED(msg) __attribute__((deprecated(msg)))
#elif defined(_MSC_VER)
#  define CALC_DEPRECATED(msg) __declspec(deprecated(msg))
#else
#  define CALC_DEPRECATED(msg)
#endif

/* vmath.h 内用 CALC_EXTERN_C_BEGIN / ... 声明 / CALC_EXTERN_C_END 包裹，
   每个 API 以 CALC_API + CALC_CALL 修饰。 */

#endif /* CALC_EXPORT_H */
```

> 严格遵循 `5.1` 六条顺序；宏名一律 `CALC_` 前缀；`F-01-01` 的 A1–A4 以预处理输出判定，**不导出数据符号**。

#### F.3 C / C++ 互操作与跨 CRT 规则（内联，阶段 2 / 3 的实现依据）

| # | 规则 | 说明 / 反例卡 |
|---|---|---|
| 1 | C 库头用 `CALC_EXTERN_C_BEGIN/END` 包裹，C++ 侧包含同一头即可直接调用 | 去掉包裹即 `undefined reference`（F-07-02） |
| 2 | `extern "C"` 不可用于成员函数 / 重载；C 接口只暴露自由函数与 POD | F-07-01、F-08-03 |
| 3 | 结构体用定宽类型，避免 `long` / `bool` / 枚举宽度差异；Windows x86 注意 `CALC_CALL` 一致 | `5.2`、`7` |
| 4 | 谁分配谁释放：库侧返回的堆内存必须经 `vmath_free()` 释放 | 跨 CRT `free` 崩溃反例（F-08-04） |
| 5 | 异常不得穿过 C 帧：C++ 侧在边界内捕获全部异常并转成错误码 | F-07-03 |
| 6 | 不跨边界传 STL 容器 / `std::string` / 异常对象：MSVC 与 Itanium ABI、STL 布局、`/MD` 与 `/MT` 堆均不兼容 | F-08-04 |
| 7 | C++ 库跨编译器不可互链：`?foo@@...`（MSVC）vs `_Z3foo...`（Itanium） | 门面 / 纯虚接口（F-08-03） |
| 8 | 32/64 与 Debug/Release 组合必须同 CRT 形态：`/MD` 对 `/MD`、`/MT` 对 `/MT` | `5.5`、F-05-03 |

#### F.4 默认导出行为差异（内联，SA 结论的解释依据）

| 平台 / 格式 | 默认行为 | 成因（简述） | 项目应对 |
|---|---|---|---|
| ELF（Linux gcc / clang） | 默认导出全部外部符号 | 动态绑定依赖 `.dynsym`，链接器须把符号放入动态符号表 | 统一注入 `-fvisibility=hidden` + 显式 `CALC_API`（C10） |
| PE（MSVC） | 默认**不**导出，须 `dllexport` 或 `.def` | PE 用独立可选的 `IMAGE_EXPORT_DIRECTORY`，源自 16 位内存约束与 ordinal 快速绑定 | `.def` 固定 ordinal；`WINDOWS_EXPORT_ALL_SYMBOLS OFF`（K8） |
| Mach-O（Apple clang） | 默认导出，`-fvisibility=hidden` 可收敛 | 与 ELF 类似的两级命名空间 | 同 ELF 方案 |
| 裸数据符号 `vmath_errno` | gcc / MinGW **意外导出**，MSVC **不导出** | 数据符号无需 `__declspec` 即可进 `.dynsym`；PE 需显式 `DATA` 项 | 刻意不进 `.def`，作教学对照（`5.2`、`5.3`） |

> **ordinal 只在 PE 存在**：ELF / Mach-O 无序号概念，`.dynsym` 索引不稳定；Unix 侧以「按名 + 函数表结构体成员位置」替代（`5.3`）。

### G. 开源协议 / 静态链接策略决策表（内联，`4.3` 的依据）

> 本项目不引入真实受限依赖；下表是 `docs/baseline.md` 决策表的内容源，供 F-00-01 / F-09-07 打包时判定。

| 协议 | 静态链接后果 | 动态链接后果 | 本项目选择 |
|---|---|---|---|
| MIT / BSD-2/3 | 保留版权声明即可 | 同左 | 项目自身采用 MIT（`LICENSE`） |
| Apache-2.0 | 保留 NOTICE、声明修改、专利授权条款 | 同左，另需随包提供 NOTICE | `--bundle` 随包携带 NOTICE（F-09-07 A5） |
| LGPL-2.1/3 | 需提供目标文件 / 可重链接能力 | **推荐动态链接**，可规避重链接义务 | 不引入；若引入则强制动态 |
| GPL-2/3 | 整体衍生作品需同协议开源 | 一般仍需遵守 GPL 分发义务 | **不引入**（`1.2` 非目标） |
| MPL-2.0 | 文件级 copyleft，修改过的 MPL 文件需开源 | 同左 | 不引入 |
| 专有 / 商业库 | 依 EULA；**Debug CRT 明确不可再分发** | 同左 | Debug CRT 禁入发布包（`4.3`、C4、V16） |

| 判定维度 | 结论 |
|---|---|
| 组件暴露 / 版权隐私 | 静态链接把库符号打进可执行文件，`nm` / `dumpbin` 可见；涉及隐私或版权时优先动态链接，或静态 + `--exclude-libs` 符号隐藏 |
| 版本治理 | 动态库需随包固定版本并记录 SONAME / install_name（`5.8` 依赖树） |
| SBOM | `--bundle` 产出依赖清单与许可证清单，进 `docs/REPORT.md` |

### H. hotfix/plan-01 修订记录（v1.3）

> 本轮只修订**首次启动引导期**的可执行性与自洽性；**不改动**技术基线、`24/32/24 = 80` 组合定义、三 OS CI 矩阵、静态分析三层与 RV 隔离、缓存 K1–K8、脚本编码规范，以及 `11.2` 待拍板项 P3–P8 的取值。

| # | 复审发现（v1.2） | v1.3 修法 | 落点 |
|---|---|---|---|
| **M1** | 「空目录」与「启动前先存 `docs/PLAN.md`」冲突；`F-00-01` 又「新建」该文件；A4「与本计划字节一致」在仓库里只有一份时**自指、不可判定**；Z4 未指明权威副本 | 前置改为「目录内含且仅含 `docs/PLAN.md`、无 `.git`」；`F-00-01` **只把它原样纳入首个提交，不新建 / 不覆盖**；明确**仓库内该文件为唯一权威**、`/workspace` 同名文件仅为交付快照；A4 改用 `0.3.1` 记录的 sha256 **BASE** | `0.7.2`、`0.7.4` Z1/Z4、`F-00-01` 前置/改动/要点/A4/A8、`V21`、`S12` |
| **M2** | 全文无 `- [ ]` 复选框，但 `D6`、`2.3`、读卡说明要求「该卡由 `[ ]` 改 `[x]`」 | 新增 `3.1 任务卡勾选清单`（44 张 F 卡 + 10 张 R 卡）；`D6` / `2.3` / 读卡说明统一改指向 `3.1` | `3.1`、`2.3`、`2.6` D6、第 6 章读卡说明 |
| **M3** | 引导期顺序倒置：读卡说明把 `verify_card.sh`（`F-02-05` 才建）当断言入口，`F-00-02` 命令调用 `check_encoding.*` / `scan_dynamic_calls.sh`（`F-00-04` 才建）；`5.10` 把 ps1 BOM 错归 `F-00-01`（该卡不产出 `.ps1`） | `2.6` 新增**分期生效表**（D9/D10 自 `F-00-04`、D1 自动验收入口自 `F-02-05` 起生效，之前由 agent 逐条执行卡上命令并把原始输出贴回执）；`F-00-02` 命令改**内联检查**；`5.10` 修正产出卡为 `F-00-04`；`F-00-01`…`F-00-04` 的 DoD 标注适用 D 项 | `2.6`、`5.10`、第 6 章读卡说明、`F-00-01`…`F-00-04` |
| **M4** | `F-00-02` 断言含 A5、DoD 仍写 `A1–A4`（44 卡全扫唯一不一致） | DoD 改 `A1–A5 PASS` | `F-00-02` DoD |
| **M5** | `git switch -c develop main` 无 develop 已存在兜底；首次 push 与「`gh api` 设分支保护」的先后未定义；A6/A7 只校验 URL 与 gh，缺 SSH 连通性 | 改 `git switch -c develop main 2>/dev/null; git switch develop`（无竖线转义，可直接复制执行）；`2.1` 与 `F-00-01` 命令写死**先 push 两条长期分支、后设保护**；新增 **A9 `ssh -T git@github.com`** | `2.1`、`0.7.3`、`F-00-01` 命令/断言/DoD、`V19` |
| **S1** | `0.3` 直接从领卡开始，缺首次启动只读健康检查 | 新增 `0.3.1`（H1–H7：`gh auth status` / `ssh -T` / `gh repo view` / 目录现状 / **sha256 BASE** / 编码换行 / P3–P8 取值固化）；`0.4` 回执模板加「权威指纹」行 | `0.3`、`0.3.1`、`0.4` |
| **S3** | 工作流数量口径不一：`S5` 10 条、`V2` 12 条、`8.2` 16 个文件 | `8.2` 增「数量口径」注：**10** = 组合工作流（N 3 + M 3 + msbuild 1 + C 3）；**12** = 10 + `analyze.yml` + `run-output.yml`；**16** = 12 + `lint.yml` + `_env.yml` + `_combo.yml` + `all.yml` | `8.2` |

> **校验**：本轮修订后，全卡断言 ↔ DoD 范围零不一致；8 项判据全部翻转；表格列数、代码块配对、卡号 / 分支名 / 组合数（`24+32+24=80`、`14+10+8=32`）自洽；HTML 阅读版同步重生成。

**hotfix/plan-02 修订记录（v1.3.1）**

> 背景：`F-00-02` A3 试探实测——`*.bat text eol=crlf` 在提交时把 blob 归一化为 LF（CRLF 与 LF 内容的 blob 经 `git cat-file` 比对完全相同），CI 检出时再展开为 CRLF；由此 (a) lint 的「无裸 LF / CRLF 必须」断言对 bat 维度恒空转，「LF 的 .bat 被拒」无法演示；(b) 功能面无恙（任何检出点 bat 均为 CRLF）。本轮**只改机制、不改验收语义**（bat/nmake 仍必须 CRLF）。

| # | 复审发现 | v1.3.1 修法 | 落点 |
|---|---|---|---|
| **P1** | `text eol=crlf` 提交时归一化，lint CRLF 断言恒空转 | `*.bat`/`*.cmd`/`Makefile.nmake` 改 **`-text`**（blob 保真）+ lint 断言 CRLF；`*.ps1` 维持 `eol=crlf`（EOL 仅建议） | `5.10` 表行/关键行/注意段、`4.1` 注释、`F-00-04`（按新机制补全编码段）、`12.D`（断言语义不变） |

> 仓库侧同步：`.gitattributes` 初版中由 `F-00-01` 写入的 `*.bat text eol=crlf` 行，由独立 chore PR 依本修正改为 `*.bat -text`（不混入任务卡分支）。

**hotfix/plan-03 修订记录（v1.3.2）**

> 背景：`F-00-01` 实测——`1.4` 原文中 `.gitignore` 二进制清单为单行空格连写；gitignore 语法一行一 pattern，连写会被当作单个含空格 pattern 静默失效（独立 `x.o` 不被忽略，A3 断言 FAIL）。当时实现侧已按语义展开为逐行并留痕于卡回执；本轮将计划文本对齐实现。

| # | 复审发现 | v1.3.2 修法 | 落点 |
|---|---|---|---|
| **G1** | `1.4` 的 `.gitignore` 关键项块为单行连写，与 gitignore 语法及仓库实现不一致 | 二进制清单拆为逐行 pattern，并补注失效机理 | `1.4` |

> 校验：仓库 `.gitignore` 无需改动（自 `F-00-01` 起即逐行实现）；`F-00-02` A2/A3 断言语义不变。

---

**计划文件结束** · `c-cpp-lib-lab` · **Plan v1.3.2** · **完全自包含 + 仓库 / `gh` 前置条件 + 引导期修订（hotfix/plan-01）+ bat/cmd/nmake 保真修正（hotfix/plan-02）+ .gitignore 清单逐行化（hotfix/plan-03）** · **状态：已确认，执行中**

> 10 个里程碑（M0–M9）、**44 张 feature 卡** + 10 次 release（`3.1` 勾选清单共 54 项）、3 个能力档位（Gate A/B/C）、**80 个组合**（原生 24 + make 32 + cmake 24）、3 组可单独 dispatch 的 CI 工作流（10 条 / 12 条 / 16 文件三种口径见 `8.2`）+ `all.yml` 全量编排；`0.3.1` 首次健康检查、`2.6` 分期生效表、`12.H` 修订留痕；**不依赖任何外部文档**，zcode 只凭本文件即可逐卡开发。
> 本次仅修订本计划（`hotfix/plan-01`：M1–M5 / S1 / S3），**未初始化仓库、未写源码、未执行构建、未通过 `gh` 做任何写操作**。可回复「**确认 v1.3**」收尾，或「**hotfix/plan-02：…**」调整 `11.2` 待拍板项，或「**做到 Gate A**」在 zcode 中从 `F-00-01` 开始按 git flow 领卡。
