# docs/HANDOFF.md —— 会话交接文档（v1.0.0 发布后 · 2026-11-16）

## 已完成清单（54/54 卡）

M0–M9 全部里程碑完成：Gate A ✓（v0.3.0）Gate B ✓（v0.8.0）Gate C ✓（v1.0.0）；10 个 tag + 10 个 GitHub Release；`docs/REPORT.md` 十章证据版总报告；`verify_card.sh --all` 43 卡基线全回归绿。

## 状态快照

- 分支：`main` = `develop` 内容对齐（main `fe3709d`+ 收尾修正；develop 对齐 PR #96 链）；双分支受保护（lint 必需检查 strict）。
- 权威指纹：PLAN sha256 `f67e16d6…0a14`（BASE 演进链：`8aec3210`→`99618241`→`b0c0ade`→`f67e16d6`）。
- `verify_card.sh --all`：43 卡全 PASS（本地 Linux）。

## 待办（下一会话，按优先级）

1. **native-windows runner 调试**：dispatch `native-windows.yml`（如 `-f toolset=msvc -f variant=x64_MD -f cfg=Release -f kind=shared`）——当前 36 job 失败于 Build combo（vcvars 已生效，失败细节需在 runner 日志逐行深挖：native.ps1 的 `Invoke-Logged` 参数展开、cl/link PATH、`$ErrorActionPreference` 交互）。run id 参考：43764177524。
2. **native-macos runner**：两次 dispatch 均 `cancelled`（runner 排队/额度）——重试或改 self-hosted；脚本层已就绪（F-04-01 A6 SKIP 实测过）。
3. **make-windows/msbuild/cmake-windows 的 runner 实跑**（脚本就绪，nmake 需 vcvars）。
4. **all.yml 全量 dispatch**（80 job；建议非高峰，时长 30–60 分钟）。

## 踩坑记录（防重蹈）

- job 级 `if` 不能引用 `matrix` → 过滤在 `_combo` 的 `FILTER_MATCH` env + step 级。
- `_env`/`_combo` 是**两个 runner**——combo 首步必须重跑 setup-env（缓存命中装包）。
- `workflow_dispatch` 要求文件在**默认分支**；`workflow_call`-only workflow 不可 dispatch。
- `set -f`（noglob）会禁掉脚本自身 glob；yml args 分词不展开 glob/brace/变量。
- grep 对 ELF 按 binary 跳行——nm 类取证必须经 nm 管道（`nmsymref`/`nmclass`）。
- 系统 grep 是 **ugrep** 别名（ERE `\.` 等转义有差异）——pattern 尽量宽松。
- `| tail -1` 管道吞退出码；verify FAIL 拦截必须 `PIPESTATUS` 或直跑。
- 卡提交多次误落本地 develop（origin 未曾污染）——每卡提交前 `git branch --show-current` 核对。

## 纪律清单

- PLAN.md 仅勾选行可改（54/54 已完整）；实质修订走 `hotfix/plan-*` + 重跑 0.3.1 更新 BASE。
- 辅助脚本禁 gh（J7）；RV 与 SA 严格分 step/脚本/目录（P5/C18）。
- 每卡：分支 → 实测断言 → yml 基线 → D6 → PR（lint strict）→ `--merge --delete-branch` → 回执。
