# scripts/common.sh —— 跨平台通用辅助（F-02-01；由 scripts/<os>/ 下脚本 source）
# 不调用 GitHub CLI（9.4 J7）；不使用任何动态加载 / 依赖解析执行类手段（5.8.4）。

# ---- 日志与断言输出格式 ----
calc_log_pass() { printf 'PASS: %s\n' "$*"; }
calc_log_fail() { printf 'FAIL: %s\n' "$*"; }
calc_log_note() { printf 'NOTE: %s\n' "$*"; }

# ---- 组合标签：<os>_<compiler>_<variant>_<cfg>（PLAN 1.3） ----
calc_make_tag()
{
    printf '%s_%s_%s_%s' "$1" "$2" "$3" "$4"
}

# ---- D2 断言：源码树无产物（排除 .git 与产物根 build/） ----
calc_assert_no_artifacts()
{
    root="$1"
    n=$(find "$root" \
        -path "$root/.git" -prune -o \
        -path "$root/build" -prune -o \
        -name '*.o' -print -o -name '*.obj' -print -o \
        -name '*.a' -print -o -name '*.lib' -print -o \
        -name '*.so' -print -o -name '*.so.*' -print -o \
        -name '*.dll' -print -o -name '*.dylib' -print -o \
        -name '*.pdb' -print -o -name '*.ilk' -print -o \
        -name 'CMakeCache.txt' -print 2>/dev/null | wc -l)
    [ "$n" -eq 0 ]
}

# ---- 值相等断言（供脚本内联使用） ----
calc_assert_eq()
{
    [ "$1" = "$2" ]
}
