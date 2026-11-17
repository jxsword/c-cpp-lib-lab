# docs/decision_log.md —— 决策记录

> 编号规则：取当前最大编号 + 1。推翻不改写旧条目，新增并标 `[状态: 已替代 → DR-新编号]`。

## DR-001 2026-11-17 reports-* artifact 全组合上传（Debug 文本报告入库）  [状态: 生效]

- 背景: F-09-01 原 A5 断言「Debug 产物不上传为发布 artifact」以 `inputs.cfg == 'Release'`
  上传条件实现，导致 Debug 组合文本报告无 artifact、reports/ 缺 38 个标签目录，
  「报告全量补齐」无捷径（CI 上传 glob 从未覆盖 cmake/make/SA 层证据）。
- 选项与权衡:
  方案A 放开上传条件（去掉 cfg==Release、path 扩为 reports/）并联动修订断言：
  全组合 160 job 文本报告一次重跑全量入库，口径统一；代价是一次全量重跑 +
  断言契约修订（A5 语义从「仅 Release」变为「全组合」）。
  方案B 仅补传缺失文件的定向 artifact：不重跑但需逐文件定制上传路径，
  与 runner 落盘口径错位、后续维护双轨，弃用。
  方案C 本地生成报告直接入库：绕过 CI 证据链，linux 本地报告与 CI 版本口径
  不一致（D-C 已否决覆盖式合并），弃用。
- 结论: 采用方案A。_combo.yml Upload step 条件改为 `if: always() && env.FILTER_MATCH == 'true'`，
  path 改为 `reports/`；F-09-01.yml A5 断言改为 `notgrep "cfg == 'Release'"` +
  `grepeq "reports/"`（id 改 A5-upload-all-combos / A5b-upload-reports-path）。
- 理由: A5 原语义「Debug 产物不上传」约束的是二进制产物；reports-* artifact 仅含
  文本证据（md/json/txt），放开不违背发布物纯净性，且是补齐 reports/ 的唯一
  全量口径通道。PLAN.md 原文不改，A5 解读修订记录于此。
- 影响: .github/workflows/_combo.yml；tests/assertions/F-09-01.yml；阶段 2 全量重跑。
- 记录时间 / 会话: 2026-11-17 / c-cpp-lib-lab 报告补齐执行会话。

## DR-002 2026-11-17 windows SA 口径补齐（deps_tree 实测化 + 双格式结论）  [状态: 生效]

- 背景: windows SA 原为标注式 PASS：static_analyze.ps1 从不调用 deps_tree.ps1，
  SA-7/8 证据为占位文案；deps_tree.ps1 只产 .json 且树为平铺、dedup 为空；
  无结论 .json，与 PLAN §7 `reports/<tag>/<group>/<组合标签>.{md,json}` 双格式
  及 5.8.3 嵌套树结构不符。
- 选项与权衡:
  方案A 三项补齐（①static_analyze.ps1 接入 deps_tree.ps1 真实调用，SA-7/8 证据
  实测化；②deps_tree.ps1 补 .md 缩进树并对齐嵌套树/dedup 结构；③static_analyze.ps1
  补结论 .json 镜像 linux {tag,kind,group,compiler,sa[]}）：对齐全仓口径，
  msys2 无 dumpbin 按设计「缺失即记录」产出 deferred。
  方案B 仅补 .json 不接 deps_tree：SA-7/8 仍为占位，证据链不实，弃用。
  方案C 重写为 linux bash 版：破坏 windows 脚本体系（pwsh/PowerShell 生态），
  改造代价大，弃用。
- 结论: 采用方案A。deps_tree.ps1 按 realpath 去重建嵌套树（dedup 节点标 dedup=true）、
  补 .md 缩进树（├─/└─ 口径对齐 linux）、deferred 双格式落盘；
  static_analyze.ps1 收尾前调用 deps_tree.ps1（-Artifact/-OutBase/-Deptag/-Compiler/-Cfg），
  SA-7/SA-8/SA-10 证据改实测值，结论 .json 转义三件套（反斜杠→引号→控制字符）
  并经 ConvertFrom-Json 校验不过即 FAIL；SA 结论矩阵 .md 同步补全（原仅表头）。
- 理由: 证据实测化是报告可信的前提；双格式与嵌套树对齐 PLAN 5.8.3 / §7 口径，
  避免 windows 侧成为全仓报告体系的短板。
- 影响: scripts/windows/deps_tree.ps1；scripts/windows/static_analyze.ps1；
  阶段 2 重跑后 windows 报告目录结构。
- 记录时间 / 会话: 2026-11-17 / c-cpp-lib-lab 报告补齐执行会话。
- 补充（CI 全量重跑反馈修复，同日）：all.yml 重跑暴露三个实现缺陷——
  ①ext-ms-win-* 桩 DLL 未过滤（Classify 仅识别 api-ms-win-），桩名在密集
  依赖图中不去重致树组合爆炸（466KB 截断树）；②unresolved 节点（real 为空）
  不参与去重；③$walk 脚本块递归在深链上 call depth overflow。
  修复：Classify 扩展 `^(api|ext)-ms-win-`；Add-Node 对 unresolved 按
  name 去重（键 unresolved:$name）；ConvertTo-Json -Depth 16→64；
  static_analyze.ps1 遍历改显式栈迭代。修复后沙箱深链实测树 5.2KB、
  JSON 有效、无截断产物、无爆栈。
