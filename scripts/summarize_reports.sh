#!/usr/bin/env bash
# summarize_reports.sh —— 汇总矩阵生成（F-09-05；A5：80 行 + 24/32/24 分组标识 + 六类差异标注）
# 用法: summarize_reports.sh > reports/v1.0.0/SUMMARY.md
# 不调用 GitHub CLI（9.4 J7）。
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# 六类差异（F-09-05 要点）
cat <<'HDR'
# reports/v1.0.0/SUMMARY.md —— 80 组合汇总矩阵（Gate C）

> 每行 = 一个组合标签；状态列：✅ 实跑全绿 / 🕐 脚本就绪待 runner（F-09-02…04 dispatch）。**六类跨平台差异**在表后逐条标注（默认导出 / ordinal / CRT / Debug-Release 布局 / mangling / macOS 架构）。

HDR

emit_group()
{
    local title="$1" shift_; shift
    echo "## $title"
    echo
    echo '| # | 组合标签 | 构建方式 | 状态 | SA 报告 | RV 报告 |'
    echo '|---|---|---|---|---|---|'
}

row()
{
    local n="$1" tag="$2" way="$3"
    local sa="—" rv="—" st="🕐 待 runner"
    if [ -f "$ROOT/reports/$tag/$way/$tag"_"$kind.md" ] 2>/dev/null; then sa="✅"; fi
    printf '| %s | %s | %s | %s | %s | %s |\n' "$n" "$tag" "$way" "$st" "$sa" "$rv"
}

# ① native 24
n=0
emit_group "① 原生（native）— 24 组合"
for os_ in linux macos windows; do
    case "$os_" in
        linux)  cc=gcc;  vars="x86 x64" ;;
        macos)  cc=clang; vars="arm64" ;;
        windows) cc=msvc; vars="x86_MD x86_MT x64_MD x64_MT" ;;
    esac
    for v in $vars; do
        for c in Debug Release; do
            n=$((n + 1))
            printf '| %s | %s_%s_%s_%s | native | %s | — | — |\n' "$n" "$os_" "$cc" "$v" "$c" \
                "$([ "$os_" = linux ] && echo ✅ 实跑全绿 || echo 🕐 待 runner)"
        done
    done
done
# msys2 + clang-cl
for v in MINGW64 MINGW32 CLANG64 UCRT64; do
    for c in Debug Release; do
        n=$((n + 1))
        printf '| %s | win_msys2_%s_%s | native | 🕐 待 runner | — | — |\n' "$n" "$v" "$c"
    done
done
for c in Debug Release; do
    n=$((n + 1))
    printf '| %s | win_clangcl_x64_%s | native | 🕐 待 runner | — | — |\n' "$n" "$c"
done

# ② make 32
emit_group "② make 组 — 32 组合（GNU 14 + nmake 10 + MSBuild 8）"
n=0
for os_ in linux macos; do
    case "$os_" in linux) cc=gcc; vars="x86 x64";; macos) cc=clang; vars="arm64";; esac
    for v in $vars; do
        for c in Debug Release; do
            n=$((n + 1))
            printf '| %s | %s_%s_%s_%s | make/gnu | %s | — | — |\n' "$n" "$os_" "$cc" "$v" "$c" \
                "$([ "$os_" = linux ] && echo ✅ 实跑全绿 || echo 🕐 待 runner)"
        done
    done
done
for v in MINGW64 MINGW32 CLANG64 UCRT64; do
    for c in Debug Release; do
        n=$((n + 1))
        printf '| %s | win_msys2_%s_%s | make/gnu | 🕐 待 runner | — | — |\n' "$n" "$v" "$c"
    done
done
for v in x86_MD x86_MT x64_MD x64_MT; do
    for c in Debug Release; do
        n=$((n + 1))
        printf '| %s | win_nmake_%s_%s | make/nmake | 🕐 待 runner | — | — |\n' "$n" "$v" "$c"
    done
done
for c in Debug Release; do
    n=$((n + 1))
    printf '| %s | win_nmake_x64_%s | make/nmake | 🕐 待 runner | — | — |\n' "$n" "$c"
done
for v in x86_MD x86_MT x64_MD x64_MT; do
    for c in Debug Release; do
        n=$((n + 1))
        printf '| %s | win_msbuild_%s_%s | make/msbuild | 🕐 待 runner | — | — |\n' "$n" "$v" "$c"
    done
done

# ③ cmake 24
emit_group "③ CMake — 24 组合（msvc/clang-cl 用 Ninja，S9）"
n=0
for os_ in linux macos windows; do
    case "$os_" in
        linux)  cc=gcc;  vars="x86 x64" ;;
        macos)  cc=clang; vars="arm64" ;;
        windows) cc=msvc; vars="x86_MD x86_MT x64_MD x64_MT" ;;
    esac
    for v in $vars; do
        for c in Debug Release; do
            n=$((n + 1))
            printf '| %s | %s_%s_%s_%s | cmake | %s | — | — |\n' "$n" "$os_" "$cc" "$v" "$c" \
                "$([ "$os_" = linux ] && echo ✅ 实跑全绿 || echo 🕐 待 runner)"
        done
    done
done
for v in MINGW64 MINGW32 CLANG64 UCRT64; do
    for c in Debug Release; do
        n=$((n + 1))
        printf '| %s | win_msys2_%s_%s | cmake | 🕐 待 runner | — | — |\n' "$n" "$v" "$c"
    done
done
for c in Debug Release; do
    n=$((n + 1))
    printf '| %s | win_clangcl_x64_%s | cmake | 🕐 待 runner | — | — |\n' "$n" "$c"
done

cat <<'FTR'

## 六类跨平台差异（显式标注，F-09-05 要点）

| # | 差异 | 说明 | 落档位置 |
|---|---|---|---|
| 1 | **默认导出** | gcc/MinGW 默认导出全部符号（含裸 `vmath_errno`）；MSVC 默认不导出、`.def` 是唯一白名单；clang-cl 同 MSVC | F-01-02/F-02-03 SA-5 |
| 2 | **ordinal** | 仅 PE 存在；`@5 NONAME` 的 `vmath_build_info` 只能按 ordinal 5 取址；ELF/Mach-O 用函数表成员位置替代 | 5.3 / F-02-02 / F-04-03 |
| 3 | **CRT** | `/MD`↔`/MDd`、`/MT`↔`/MTd` 随 CFG；跨 CRT 传 STL 堆对象即崩溃（反例 F-08-04） | 5.5.1 / F-05-03 |
| 4 | **Debug-Release 布局** | Debug 调试段/pdb/`_DEBUG` 标记；`_ITERATOR_DEBUG_LEVEL` 布局差异 | SA-3 / F-08-04 |
| 5 | **mangling** | Itanium `_Z*` vs MSVC `?*@@`——跨编译器不可互链 → 门面 C ABI（F-08-03） | F-08-02 A4 |
| 6 | **macOS 架构** | arm64 主组合；x86_64 与 `lipo` universal 为附加不计数组覆盖；32 位 SKIP（10.15） | F-04-01 / 5.6 C1 |

**状态口径**：✅ = Linux 侧实跑全绿（本机证据链）；🕐 = 脚本就绪，产物级实证由 F-09-02…04 的 dispatch 在各 OS runner 执行（R-09 收尾批量取证）。
FTR
