# 贡献指南（CONTRIBUTING）

本仓库由计划文件驱动开发：**仓库内 `docs/PLAN.md` 是唯一权威副本**——不新建、不覆盖、不改写；确需修订计划时走 `hotfix/plan-<n>` 分支，先改计划再改实现。本文件把开发过程中需长期遵守的约定固化于此。

## 1. 环境前置

| 项 | 约束 |
|---|---|
| 远程仓库 | `git@github.com:jxsword/c-cpp-lib-lab.git`（**SSH，唯一允许的 `origin`**；禁止 HTTPS 形式） |
| 认证 | SSH 私钥可用；`gh` 已安装并登录（具备 `repo` 权限） |
| 本地目录 | 仓库根目录即 `c-cpp-lib-lab/`；禁止再 `mkdir` / `git clone` 覆盖该目录，不得在其它路径另建仓库 |
| 计划文件 | `docs/PLAN.md` 原样纳入版本控制，是唯一权威副本；启动健康检查记录其 sha256 作为 BASE 指纹 |
| 工具 | `git`（git-flow 扩展可选：未安装时用本文件第 4 节的等价原生命令，分支命名与合并拓扑不变）、`gh`、各 OS 编译器/构建工具 |
| GitHub 操作 | Git/GitHub 侧操作一律由 agent 调用 `gh` 完成（PR / checks / workflow 触发与观测 / artifact / release / 分支保护）；禁止网页手工操作替代。本地构建、测试、静态分析由 `scripts/` 脚本发起，结论经 `gh` 回写 PR 与 checks；**辅助脚本本身不得依赖 `gh`**，保证本地批量构建离线可复现 |

## 2. 首次启动健康检查（仅执行一次）

领取第一张卡之前做只读检查，**不做任何写操作**；任一失败即停下报告，不继续、不自行修复环境。全部输出原样记入首卡回执的「基线」与「权威指纹」栏：

| # | 命令 | 期望 / 记录 |
|---|---|---|
| H1 | `gh auth status` | 已登录、token 有效 |
| H2 | `ssh -T git@github.com` | 认证成功 |
| H3 | `gh repo view jxsword/c-cpp-lib-lab` | 远程仓库可见 |
| H4 | `ls -a c-cpp-lib-lab` | 存在 `docs/PLAN.md`、无 `.git`、无其它文件 |
| H5 | `sha256sum docs/PLAN.md` | **记为 BASE**，供首卡断言与后续比对；此后不得改写该文件 |
| H6 | `file docs/PLAN.md` + `od -An -tx1 -N3 docs/PLAN.md` | UTF-8 **无 BOM**（首 3 字节非 `ef bb bf`）、LF 换行 |
| H7 | `sed -n '/### 11.2/,/^---/p' docs/PLAN.md` | 记录待拍板项 P3–P8 当前取值；需要决策时停下询问，不自选备选 |

BASE 是 `docs/PLAN.md` 唯一权威副本的指纹。任何 `hotfix/plan-*` 修改计划后，须在下次启动前重新执行本节并更新 BASE。

## 3. 领卡协议

1. **一次一张卡**：按计划第 6 章卡号顺序领取，不得跳卡；前置 tag 不存在时不得开工。
2. **先建分支再改文件**：严格使用卡上写死的分支名，从 `develop` 开出。
3. **断言优先**：卡上的断言是唯一验收依据；任一 FAIL 即停，先修再继续。
4. **提交规范**：Conventional Commits（见第 8 节）；每张卡至少一个提交。
5. **合并与回迁**：feature → `develop`（PR，保留合并提交）；里程碑末由 `release/<ver>` 验证后同时合入 `main` 与 `develop`，在 `main` 打 tag。
6. **每卡结束输出回执并等待确认**，不自动领下一张。回执模板：

   ```
   ## 卡回执 · <卡号>
   - 分支：<branch>   基线：<前置 tag / commit>   起止 commit：<sha1>..<sha2>
   - 改动文件：新增 [...] / 修改 [...] / 删除 [...]
   - 断言结果：
       | # | 断言 | 命令 | PASS/FAIL | 关键输出摘录 |
   - 编码/换行校验：*.ps1 UTF-8 BOM ✓ | *.bat CRLF ✓ | *.sh LF ✓
   - 缓存命中：hit/miss（若本卡涉及 CI）
   - gh 操作：`gh pr create/merge/checks`、`gh workflow run`、`gh run watch`（附 run id / URL）；CI 结论：success/failure
   - 权威指纹：`docs/PLAN.md` sha256 = <BASE>；编码/换行：UTF-8 无 BOM + LF ✓
   - 已知偏差与未决项：...（无则写「无」）
   - PR：<编号或链接>   合并到 develop：<commit>
   - 结论：<卡号> 完成 / 阻塞（附根因）
   - 等待确认后领取 <下一卡号>
   ```

7. **静态分析禁令**：所有 `scripts/analyze_*` 与 `scripts/static_analyze_*` 不得出现动态加载 / 实际运行分析调用（`ldd`、`dlopen`、`LoadLibrary`、`LD_DEBUG` 等）；程序运行输出属独立 RV 通道，与分析过程隔离。
8. **GitHub 侧一律走 `gh`**：PR 创建 / 合并 / 检查、工作流触发与观测、artifact 下载、release 发布、分支保护设置均由 agent 调用 `gh` 完成。

## 4. git flow 分支模型

| 分支 | 从哪开出 | 合回哪里 | 存活期 | 用途 |
|---|---|---|---|---|
| `main` | — | — | 永久 | 只含可发布状态；每个里程碑 tag 落在此分支；禁止直接 push |
| `develop` | `main` | — | 永久 | 集成主线；所有 feature 的唯一合并目标 |
| `feature/*` | `develop` | `develop`（PR + 保留合并提交） | 单卡 | 一卡一分支，卡完成即删 |
| `release/*` | `develop` | `main` **且** 回迁 `develop` | 里程碑验证期 | 跑全量矩阵、修发布缺陷、生成 CHANGELOG 与报告 |
| `hotfix/*` | `main`（对应 tag） | `main` **且** 回迁 `develop` | 短 | 修已发布里程碑缺陷 |
| `hotfix/plan-*` | `main` | `main` + `develop` | 短 | 修订计划文件 |

分支命名规范（写死）：

```
feature/m<n>-<2位序号>-<kebab-slug>    例：feature/m5-02-nmake-makefile
release/<semver>                       例：release/0.5.0
hotfix/<semver>                        例：hotfix/0.5.1
hotfix/plan-<序号>                     例：hotfix/plan-01
tag: v<semver>                         例：v0.5.0（附注标签）
```

**主分支必须是 `main`**：`gitflow.branch.master == main`、`gitflow.branch.develop == develop`、`gitflow.prefix.versiontag == v`；不得存在 `master` 残留分支。

**git-flow 扩展可选**。未安装时使用下列等价原生命令，并把同样的 `gitflow.*` 键写入本地配置（键名沿用 git-flow 约定，值指向 `main`）：

```bash
# 一次性初始化（等效 git flow init -d 后覆写 gitflow.*）
git init -b main
git remote add origin git@github.com:jxsword/c-cpp-lib-lab.git
git config gitflow.branch.master   main
git config gitflow.branch.develop  develop
git config gitflow.prefix.feature  feature/
git config gitflow.prefix.release  release/
git config gitflow.prefix.hotfix   hotfix/
git config gitflow.prefix.versiontag v
git switch -c develop main

# 日常建分支等价替换
git flow feature start <name>   ≙   git switch -c feature/<name> develop
git flow release start <ver>    ≙   git switch -c release/<ver> develop
git flow hotfix start <ver>     ≙   git switch -c hotfix/<ver> main
```

**合并方式说明**：`git flow * finish` 会在本地直接合并，与「GitHub 侧一律走 `gh`」冲突，因此**只使用 start 类建分支动作**；`finish` 的等效动作由 `gh pr merge`（`--merge` 保留合并提交，等效 `--no-ff`）与 `git tag -a` 完成，合并拓扑不变。同一 `release/*` 分支向 `main` 与 `develop` 各开一个 PR 实现「合入 + 回迁」。

**tag 与 GitHub Release**：`git tag -a` 附注 tag 经 `git push --follow-tags` 推送；`gh release create` 只创建 GitHub Release，不替代本地 tag。

## 5. 保护规则与合并策略

| 规则 | 内容 |
|---|---|
| `main` / `develop` | 禁止直接 push；只接受 PR；`main` 的 PR 只来自 `release/*` 或 `hotfix/*` |
| feature PR | 必须：断言全 PASS、`docs/PLAN.md` 3.1 勾选清单对应卡打勾、CHANGELOG 追加一行、**无 `build/` 产物入库**、编码/换行 lint 通过 |
| 合并拓扑 | feature / release 合并保留合并提交，保证「一卡一节点」可追溯 |
| 禁止入库 | `build/`、`out/`、所有二进制与中间产物 |
| 编码 / 换行门禁 | `*.ps1` 必须 UTF-8 BOM；`*.bat` 必须 CRLF 且无 BOM；`*.sh` 必须 LF 无 BOM |
| 静态分析门禁 | `scripts/analyze_*` / `scripts/static_analyze_*` 不得含动态加载 / 实际运行禁用调用（lint 关键字扫描） |
| 大文件 | CI artifact 走 `actions/upload-artifact`；缓存走 `actions/cache`，均不进 git |

## 6. 版本与 tag 策略

| 里程碑 | tag | 语义 |
|---|---|---|
| M0 | `v0.0.0` | 仓库骨架、lint、缓存与编码基线可用 |
| M1 | `v0.1.0` | 纯 C 四模式在单平台编译通过 |
| M2 | `v0.2.0` | 原生 Linux 4 组合 + 静态分析三层框架全绿 |
| M3 | `v0.3.0` | **Gate A**：CMake Linux 4 组合全绿 |
| M4 | `v0.4.0` | 原生三 OS 全 24 组合；静态分析三 OS 扩展 |
| M5 | `v0.5.0` | make 组 32 组合（GNU make 14 + nmake 10 + msbuild 8） |
| M6 | `v0.6.0` | CMake 24 组合（msvc 用 Ninja） |
| M7 | `v0.7.0` | 阶段 2：C++ 调 C 库 + 反例 |
| M8 | `v0.8.0` | **Gate B**：阶段 3 纯 C++ OOP + 反例 |
| M9 | `v1.0.0` | **Gate C**：3 组 CI + 全量 80 组合 + 缓存 + 打包 + 安全 + 报告 |

## 7. 全局 DoD 与引导期分期

每张卡与每个里程碑检查 D1–D11：

| # | 检查 |
|---|---|
| D1 | 卡上全部断言 PASS，断言输出已贴入回执 |
| D2 | 源码树无产物；所有构建落在 `build/<group>/...`（`git status --porcelain` + `find . -name '*.o'` 双重断言） |
| D3 | 新增/修改文件路径与计划 4.2 文件归属表一致 |
| D4 | 提交信息符合第 8 节规范；一个 feature 分支不混入其他卡改动 |
| D5 | PR 描述含「卡号 / 断言结果 / 已知偏差」三节 |
| D6 | `CHANGELOG.md` 追加一行；`docs/PLAN.md` 3.1 任务卡勾选清单中该卡由 `- [ ]` 改 `- [x]`（这是计划中唯一的状态记录位置） |
| D7 | 里程碑 release：产出 `reports/<tag>/SUMMARY.md` |
| D8 | release 合入 `main` 后打附注 tag，摘要回填 CHANGELOG |
| D9 | 编码/换行：`scripts/tools/check_encoding.*` 全绿 |
| D10 | 静态分析禁令关键字扫描零命中 |
| D11 | 涉及 CI 的卡：缓存命中/未命中记录写入回执与 Job Summary |

**引导期分期生效**（校验脚本未建不构成 FAIL，按阶段替代）：

| 阶段 | 不适用 | 替代做法 |
|---|---|---|
| `F-00-01` … `F-00-03` | D9 / D10（校验脚本未建） | agent 逐条执行卡上命令、把原始输出贴入回执；编码/换行只对本卡新增文件做内联检查 |
| `F-00-04` … `F-02-04` | D1 的 `verify_card` 自动入口 | 断言仍逐条由 agent 执行卡上命令判定并贴原始输出；D9 / D10 自本阶段起生效 |
| `F-02-05` 起 | — | D1–D11 全部生效，`scripts/verify_card.sh <卡号>` 为唯一断言入口 |

## 8. 提交规范

```
<type>(<scope>): <简述，≤72 字符>

type   : feat | fix | docs | test | ci | build | refactor | chore
scope  : export | api | core | report | cli | stage2 | stage3 |
         scripts | make | nmake | msbuild | cmake | ci | cache | analyze |
         bundle | security | docs | plan | encoding
```

示例：`ci(cache): add apt/brew/msys2 package caches with per-combination keys`、`feat(analyze): add recursive dependency tree with realpath resolution`。

## 9. gh 操作矩阵

| 场景 | 命令（示例） |
|---|---|
| 认证 / 定位仓库 | `gh auth status`、`gh repo view jxsword/c-cpp-lib-lab` |
| 建 PR | `gh pr create --base develop --head feature/<名> --title "..." --body "卡号 / 断言结果 / 已知偏差"` |
| 合并 PR（保留合并提交） | `gh pr merge <n> --merge --delete-branch` |
| PR 检查 | `gh pr checks <n>`、`gh pr view <n> --json statusCheckRollup` |
| 单独触发工作流 | `gh workflow run native-windows.yml -f toolset=msvc -f variant=x64_MD -f cfg=Release` |
| 观测 run | `gh run list --workflow=all.yml --limit 5`、`gh run watch <run-id> --exit-status`、`gh run view <run-id> --log` |
| 下载 artifact | `gh run download <run-id> -n <artifact>` |
| 发布 release | `gh release create v0.3.0 --target main --notes-file CHANGELOG.md` |
| 分支保护（一次性） | `gh api -X PUT repos/jxsword/c-cpp-lib-lab/branches/main/protection ...`；**必须在 `main` / `develop` 首次 push 成功之后执行** |
