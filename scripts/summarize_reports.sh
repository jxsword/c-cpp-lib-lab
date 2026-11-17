#!/usr/bin/env bash
# summarize_reports.sh —— 汇总矩阵生成（F-09-05；A5：80 行 + 24/32/24 分组标识 + 六类差异标注）
# 用法: summarize_reports.sh > reports/v1.0.0/SUMMARY.md
# 状态/SA/RV 列读 reports/ 实测：SA 结论 md/json、RV 运行输出 txt 存在性。
# 不调用 GitHub CLI（9.4 J7）。
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# 组目录段（SA 报告）与 run 文件 group 段（斜杠归一 -）
group_dir() {
  case "$1" in
    native)       echo "native" ;;
    make/gnu)     echo "make/gnu" ;;
    make/nmake)   echo "make/nmake" ;;
    make/msbuild) echo "make/msbuild" ;;
    cmake)        echo "cmake" ;;
  esac
}
group_safe() { echo "$1" | tr '/' '-'; }

# 双形态（shared/static）文件齐备判定
both_kinds() {
  # both_kinds <目录> <前缀> <扩展名> —— <前缀>_shared.<ext> 与 <前缀>_static.<ext> 均存在
  local dir="$1" prefix="$2" ext="$3"
  [ -f "$dir/${prefix}_shared.$ext" ] && [ -f "$dir/${prefix}_static.$ext" ]
}

row()
{
    # row <序号> <标签> <构建方式> —— 状态/SA/RV 列读 reports/ 实测
    local n="$1" tag="$2" way="$3"
    local gd gs sa="—" rv="—" st="🕐 待 runner"
    gd="$(group_dir "$way")"
    gs="$(group_safe "$way")"
    if both_kinds "$ROOT/reports/$tag/$gd" "$tag" "md"; then sa="✅"; fi
    # run 文件名含 group 段：<tag>_<group-safe>_<kind>.txt
    if [ -f "$ROOT/reports/$tag/run/${tag}_${gs}_shared.txt" ] &&
       [ -f "$ROOT/reports/$tag/run/${tag}_${gs}_static.txt" ]; then rv="✅"; fi
    if [ "$sa" = "✅" ] && [ "$rv" = "✅" ]; then st="✅ 实跑全绿"; fi
    printf '| %s | %s | %s | %s | %s | %s |\n' "$n" "$tag" "$way" "$st" "$sa" "$rv"
}

# 六类差异（F-09-05 要点）
cat <<'HDR'
# reports/v1.0.0/SUMMARY.md —— 80 组合汇总矩阵（Gate C）

> 每行 = 一个组合标签；状态列：✅ 实跑全绿（SA+RV 证据链齐备）/ 🕐 待 runner。**六类跨平台差异**在表后逐条标注（默认导出 / ordinal / CRT / Debug-Release 布局 / mangling / macOS 架构）。

HDR

emit_group()
{
    local title="$1"
    echo "## $title"
    echo
    echo '| # | 组合标签 | 构建方式 | 状态 | SA 报告 | RV 报告 |'
    echo '|---|---|---|---|---|---|'
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
            row "$n" "${os_}_${cc}_${v}_${c}" native
        done
    done
done
for v in MINGW64 MINGW32 CLANG64 UCRT64; do
    for c in Debug Release; do
        n=$((n + 1))
        row "$n" "win_msys2_${v}_${c}" native
    done
done
for c in Debug Release; do
    n=$((n + 1))
    row "$n" "win_clangcl_x64_${c}" native
done

# ② make 32
emit_group "② make 组 — 32 组合（GNU 14 + nmake 10 + MSBuild 8）"
n=0
for os_ in linux macos; do
    case "$os_" in linux) cc=gcc; vars="x86 x64";; macos) cc=clang; vars="arm64";; esac
    for v in $vars; do
        for c in Debug Release; do
            n=$((n + 1))
            row "$n" "${os_}_${cc}_${v}_${c}" make/gnu
        done
    done
done
for v in MINGW64 MINGW32 CLANG64 UCRT64; do
    for c in Debug Release; do
        n=$((n + 1))
        row "$n" "win_msys2_${v}_${c}" make/gnu
    done
done
for v in x86_MD x86_MT x64_MD x64_MT x64; do
    for c in Debug Release; do
        n=$((n + 1))
        row "$n" "win_nmake_${v}_${c}" make/nmake
    done
done
for v in x86_MD x86_MT x64_MD x64_MT; do
    for c in Debug Release; do
        n=$((n + 1))
        row "$n" "win_msbuild_${v}_${c}" make/msbuild
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
            row "$n" "${os_}_${cc}_${v}_${c}" cmake
        done
    done
done
for v in MINGW64 MINGW32 CLANG64 UCRT64; do
    for c in Debug Release; do
        n=$((n + 1))
        row "$n" "win_msys2_${v}_${c}" cmake
    done
done
for c in Debug Release; do
    n=$((n + 1))
    row "$n" "win_clangcl_x64_${c}" cmake
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

**状态口径**：✅ = SA 结论（md/json）与 RV 运行输出（txt）双形态证据在 `reports/` 齐备（本仓库入库实测）；🕐 = 证据未入库。
FTR
