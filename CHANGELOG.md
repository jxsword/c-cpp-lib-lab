# Changelog

本文件记录 c-cpp-lib-lab 的所有显著变更。每个里程碑发布对应一个 `v<semver>` 附注 tag（落在 `main`），版本语义见 CONTRIBUTING.md「版本与 tag 策略」一节。

## v0.0.0 (in progress)

- F-00-01 · 仓库与 git flow 初始化：建立 `main`/`develop` 长期分支并以 SSH 关联 `origin`；首次推送成功后为 `main` 设置分支保护（禁止直接 push、只接受 PR、禁止强制推送与删除）；`docs/PLAN.md`（v1.3）作为唯一权威计划原样纳入首个提交；新增 `.gitignore`（out-of-source 全量忽略）、`.gitattributes` 初版、MIT `LICENSE`、`README.md` 与 `CONTRIBUTING.md` 初版；建立计划 4.1 占位目录骨架。
- F-00-02 · lint 门禁：新增 `.github/workflows/lint.yml`（`pull_request` → `develop`/`main`），检查行尾空白、UTF-8、`*.ps1` UTF-8 BOM、`*.bat` CRLF 且无 BOM、`*.sh` LF 且无 BOM、禁止二进制入库与跟踪被忽略路径、`5.8.4` 禁用调用关键字扫描（`FORBIDDEN:` 注释白名单）、`docs/PLAN.md` 3.1 卡号格式与 Z1 越界章节引用、`scripts/` 内 `gh` 调用（J7 / K22）；不编译、不跑矩阵。
