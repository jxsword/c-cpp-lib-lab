#!/usr/bin/env bash
# common.sh —— macOS 通用辅助（F-04-01；由 scripts/macos/ 下脚本 source）
# 不调用 GitHub CLI（9.4 J7）。
calc_log_pass() { printf 'PASS: %s\n' "$*"; }
calc_log_fail() { printf 'FAIL: %s\n' "$*"; }
calc_log_note() { printf 'NOTE: %s\n' "$*"; }

# macOS 组合标签：<os>_<compiler>_<variant>_<cfg>；主组合 arm64（PLAN 5.5 P7），
# x86_64 为附加不计数组的架构覆盖验证。
calc_make_tag()
{
    printf '%s_%s_%s_%s' "$1" "$2" "$3" "$4"
}

# cfg → 旗标（与 native.sh 约定一致）
calc_macos_cfg_flags()
{
    case "$1" in
        Debug)   printf '%s' '-g -O0 -D_DEBUG' ;;
        Release) printf '%s' '-O2 -DNDEBUG' ;;
        *) return 1 ;;
    esac
}

# variant → 架构；x86（32 位）客观不可实现（5.6 C1）→ 返回 SKIP 标记
calc_macos_arch_flags()
{
    case "$1" in
        arm64)  printf '%s' '-arch arm64' ;;
        x86_64) printf '%s' '-arch x86_64' ;;
        x86)    printf '%s' 'SKIP' ;;
        *)      return 1 ;;
    esac
}

# D2：源码树无产物
calc_assert_no_artifacts()
{
    root="$1"
    n=$(find "$root" \
        -path "$root/.git" -prune -o \
        -path "$root/build" -prune -o \
        -name '*.o' -print -o -name '*.a' -print -o \
        -name '*.so' -print -o -name '*.dylib' -print -o \
        -name '*.dll' -print -o -name '*.pdb' -print 2>/dev/null | wc -l)
    [ "$n" -eq 0 ]
}
