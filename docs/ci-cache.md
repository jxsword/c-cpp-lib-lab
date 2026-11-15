# CI 缓存规格与落地（F-00-03，S1 / PLAN 5.9、8.3）

本文档是 `.github/actions/setup-env` composite action 的缓存登记表：key、path、失效条件与命中率记录方式。key 规则遵守计划 `5.9.3` K1–K8。

## 缓存对象登记表（7 类）

| # | 对象 | 平台 | key 模板 | path | 失效条件 |
|---|---|---|---|---|---|
| 1 | apt deb 包 | Linux | `apt-Linux-<hash(apt-packages.txt)>` | `/var/cache/apt/archives`（安装前后收敛属主，保证 tar 可读） | `.github/apt-packages.txt` 变更（K2） |
| 2 | ccache | Linux | `cc-linux-<toolset>-<variant>-<cfg>-<kind>-<run_id>`，restore-keys 同前缀 | `~/.cache/ccache` | 每 run 新 key（run_id）；同组合前缀回退（K3） |
| 3 | Homebrew 下载 | macOS | `brew-macOS-<arch>-<hash(brew-packages.txt)>` | `~/Library/Caches/Homebrew`、`~/.brew-cache` | `.github/brew-packages.txt` 变更（K2） |
| 4 | ccache | macOS | 同 #2（`cc-macOS-…`） | `~/.cache/ccache` | 同 #2 |
| 5 | MSYS2 pacman | Windows | 由 `msys2/setup-msys2@v2`（`cache: true`）按 `msystem` 内部管理 | 内部 `/var/cache/pacman/pkg` | setup-msys2 内部策略 |
| 6 | win tools | Windows | `win-tools-<toolset>-<hash(tool-versions.env)>` | `C:\tools\llvm`、`C:\tools\ninja`、`C:\tools\deps` | `.github/tool-versions.env` 任一版本行变更（K2） |
| 7 | sccache | Windows | `sc-Windows-<toolset>-<variant>-<cfg>-<kind>-<run_id>`，restore-keys 同前缀 | `%LOCALAPPDATA%\sccache` | 同 #2 |

> **不缓存**：MSVC 工具集与 Windows SDK —— runner 预装，体积过大、缓存无收益（PLAN 5.9.2）。

## key 规则（K1–K8 摘要）

- **K1**：编译缓存 key 必含 `OS + toolset + variant（位数/CRT）+ cfg + kind`；32/64 与 `/MD`/`/MT` 目标文件不可跨组合复用。
- **K2**：包/工具清单变更 → `hashFiles` 变化 → 自动失效。
- **K3**：`restore-keys` 只允许同前缀回退（同一 OS+toolset+variant+cfg+kind 内），禁止跨 toolset/variant。
- **K4**：跨 job 传构建产物用 `upload/download-artifact`，不用 cache。
- **K5**：命中/未命中写入 `$GITHUB_STEP_SUMMARY`（action 末步）与卡回执（D11）。
- **K7**：恢复/保存分离——`actions/cache/restore@v4` + `actions/cache/save@v4`，save 步骤均带 `if: always()`，失败 job 也保存已下载包；各 save 前有「Ensure … path exists」步骤兜底建目录（`save@v4` 对不存在路径会静默跳过——冷启动零缓存作用域下曾致演练 verify 必然 miss）。（上游 combined action 的 `save-always` 输入已弃用且声明不按预期工作，故不用。）
- **K8**：缓存只读恢复；构建脚本不得写缓存目录以外路径。

## 命中率记录方式

1. action 末步将 7 类对象的 key 与 hit 状态写入 `$GITHUB_STEP_SUMMARY`（表格，见上）；
2. 每张涉及 CI 的卡，把命中率（hit/miss）记入卡回执「缓存命中」栏（D11）；
3. `all.yml` 全量编排（F-09-06）复用前三组已建立缓存（K6），汇总命中率入 run summary。

## 演练（F-00-03 A4）

`.github/workflows/cache-drill.yml`：`warm` job 首次调用 setup-env（未命中 → 保存），`verify` job（`needs: warm`，同一 `github.run_id` → key 相同）第二次调用，断言 `cache-hit == true` 与 `apt-cache-hit == true`。支持 `workflow_dispatch` 手动演练，且在本目录相关文件变更的 PR 上自动触发。

## MSYS2 分段清单消费约定

`.github/msys2-packages.txt` 按 `[MINGW64]`/`[MINGW32]`/`[CLANG64]`/`[UCRT64]` 分段；本卡 composite action 仅安装基础工具（`git`、`make`），按 msystem 提取对应段传给 `setup-msys2` 的解析逻辑由 F-09-01 / F-09-03 的工作流实现。
