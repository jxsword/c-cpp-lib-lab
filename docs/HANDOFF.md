# docs/HANDOFF.md —— 会话交接文档（native-windows/native-macos 全绿后 · 2026-11-17）

## 已完成清单

- **M0–M9 全部里程碑 + v1.0.0 发布**（前会话）：54/54 卡；Gate A/B/C ✓；10 tag + 10 Release；`verify_card.sh --all` 43 卡基线全回归绿。
- **待办 #1 native-windows ✅**（本会话）：全量 36 组合 runner 实跑全绿（run `43777488838`，✓73/X0）。修复链 PR #102–#109（pwsh ParserError、`$rv:` scope 语法、Invoke-Logged 数组展平、msys2 工具链路径与安装、POSIX cmd_dynamic 守卫、coreutils link 遮蔽、A2 按 `_MSC_VER` 分拆、SA tag 下划线解析、SA-2 正则倒置、SA-5 目标/流程、shared 漏 `$crt`、Debug 链接漏 `/DEBUG`、`[NONAME] @ILT` 误判）。
- **待办 #2 native-macos ✅**（本会话）：全量 4 组合 runner 实跑全绿（run `43855274143`，✓9/X0）。修复链 PR #110–#123：`macos-14`→`macos-15`（GitHub 2026-11-02 退役 Sonoma 镜像，官方一比一替代）、BSD 兼容（`xargs -a`/`readlink -f`/bash 3.2 的 `declare -A`）、补齐缺失的 `scripts/macos/analyze.sh`、brew 移除 `pax-utils`、Mach-O 前导 `_`、SA-2/SA-3/SA-6 多源回退与 Debug 环境限制回退（详见踩坑）。
- develop 已同步对齐（PR #109、#123）。

## 状态快照

- 分支：`main` = `e6fffd9`；`develop` = `48c5be9`（内容对齐）；双分支受保护（lint strict）。
- 权威指纹：PLAN sha256 `f67e16d6…0a14`（本会话未动 PLAN.md）。
- `verify_card.sh --all`：43 卡全 PASS（本地 Linux，本会话验证 15+ 轮）。
- 缓存：macOS brew 缓存已热；msys2 pacman 工具链缓存已热；Windows 侧缓存正常。
- 本地已装：pwsh 7.7.0（~/.local/bin）、gcc-multilib、pax-utils、patchelf；系统 grep 是 ugrep 别名。

## 待办（下一会话，按优先级）

1. **make-windows / msbuild-windows / cmake-windows runner 实跑**（脚本层就绪）。预审已记录三个雷：
   - `scripts/windows/cmake.ps1` 的 msys2 分支**没有 `-G` 生成器参数**——会落到默认 VS 生成器（错工具链）。需补 `-G "MinGW Makefiles"` 并用 `CMAKE_MAKE_PROGRAM` 指向 `$env:RUNNER_TEMP\msys64\<env>\bin\make.exe`；
   - msvc/clang-cl 强制 Ninja（S9）但 **Ninja 不一定在 PATH**（setup-env 只缓存 `C:\tools\ninja` 未加 PATH）——需验证或补 PATH；
   - `make-windows.yml` 表头注释「msys2 8 + nmake 10」与实际矩阵 16+20=36 不一致——**先对照 PLAN 确认口径，勿贸然改矩阵**；
   - nmake/msbuild 依赖 vcvars：走 `_combo` 的 toolset=msvc 路径会自动跑 msvc-dev-cmd ✓。
2. **all.yml 全量 dispatch**（80 组合；建议非高峰，时长 30–60 分钟；A2 断言全绿 + 汇总报告）。
3. 全部完成后：更新本文件勾销待办、输出最终收官总结。

## 踩坑记录（防重蹈，含本会话新增）

- PowerShell **解析先于执行**：一处语法错误杀死所有分支的 job（`.ps1` 提交前用本地 pwsh Parser 全量扫描）。
- pwsh 7 无 `-Encoding Byte`（须 `-AsByteStream`）；`Get-Command` 守卫「缺失即记录」。
- Windows：Git usr/bin 的 coreutils `link(1)` 遮蔽 VS link.exe——VC 的 `Hostx64\<target>` bin 须前置 PATH；独立链接步 Debug 需显式 `/DEBUG`（`-g`/`/DEBUG` 是链接期旗标）。
- MSVC .def 的 `@5 NONAME` 契约只绑定 msvc/clang-cl（clang-cl 定义 `_MSC_VER`）；MinGW 按名全导出；dumpbin 对 Debug 增量链接以 `[NONAME] @ILT+n(...)` 引用底层符号——按名判定前剔除 `[NONAME]` 行。
- runner 的 `clang` 解析为 **brew LLVM clang**（producer 是 `clang version X` 而非 `Apple clang version X`）；该工具链的 Debug 产物**无可检测 DWARF**（无 LC_DEBUG_INFO、无 dSYM、`otool -l` 负载清单为空）——SA-3 Debug 以 cfg 标记为硬要求、调试信息多源检测回退编译日志 `-g` 意图（gflag），检测状态随报告记录。
- macOS：runner 默认 `/bin/bash` 是 **bash 3.2**（禁 `declare -A`/mapfile）；BSD 无 `xargs -a`/`readlink -f`/coreutils realpath；Mach-O 符号带前导 `_`；`cfg=`/producer 串在库代码内（shared 时在 dylib 不在 exe）。
- 取证消息**禁用裸 `|`**（markdown 表格单元格会被 A4 列数自检判错），用 `;`。
- Homebrew 公式会退役（`pax-utils` 已移除）；GitHub runner 镜像会退役（macos-14 → 2026-11-02）；macOS runner 排队可长达 10–20 分钟。
- job 级 `if` 不能引用 `matrix`；`workflow_call`-only 文件不可 dispatch；`_env`/`_combo` 是两个 runner（combo 首步重跑 setup-env）。
- `set -f` 禁 glob；yml args 分词不展开 glob/变量；grep 对 ELF 按 binary 跳行（nm 类取证走 nm 管道）；系统 grep 是 ugrep 别名。
- `| tail -1` 吞退出码——verify FAIL 拦截用 `PIPESTATUS` 或直跑重定向。
- **`verify_card.sh --all` 会向 `reports/v0.7.0/negative/stage2_no_extern_c.log.sig` 追加内容**——提交前 `git checkout -- reports/` 还原。
- 卡提交两次误落本地 main（均未推送、当场返工）——**每次提交前必查 `git branch --show-current`**。

## 纪律清单

- PLAN.md 仅勾选行可改（54/54 已完整）；实质修订走 `hotfix/plan-*` + 重跑 0.3.1 更新 BASE。
- 辅助脚本禁 gh（J7）；RV 与 SA 严格分 step/脚本/目录（P5/C18）。
- 每卡/每修复：分支（基于 origin/develop 或 origin/main）→ 实测断言 → 门禁（`check_encoding.sh` + `scan_dynamic_calls.sh` + `bash -n`/pwsh Parser）→ `verify_card.sh --all` → PR（lint strict）→ `--merge --delete-branch` → 同步 develop → 回执。
- dispatch 优先用过滤参数（`-f toolset/variant/cfg/kind`）做单组合快验，再全量。
- Windows 侧日志取证：`gh run view <run> --job <job-id> --log`（`--log-failed` 有时为空；run 未结束前日志不可拉）。
- 网络直连失败时按代理 `http://192.168.33.1:10808` 重试一次再下结论。
