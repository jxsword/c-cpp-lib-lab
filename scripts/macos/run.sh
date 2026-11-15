#!/usr/bin/env bash
# run.sh —— RV-1…RV-4 运行输出采集·macOS 版（F-04-01；PLAN 5.7.2）
# 与 Linux 版同构：stdout+stderr+exit code → reports/<tag>/run/<tag>_<group>_<kind>.txt。
# 本脚本属 RV 通道：运行被测程序是本脚本职责（C18 隔离）。
# 不调用 GitHub CLI（9.4 J7）。
set -u

. "$(dirname "$0")/../common.sh"
. "$(dirname "$0")/common.sh"
export LC_ALL=C

if [ "$#" -ne 3 ]; then
    calc_log_fail "usage: run.sh <tag> <kind> <group>"
    exit 2
fi
TAG="$1"; KIND="$2"; GROUP="$3"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BIN="$ROOT/build/$GROUP/$TAG/$KIND/calctool"
OUT_DIR="$ROOT/reports/$TAG/run"
OUT_FILE="$OUT_DIR/${TAG}_${GROUP}_${KIND}.txt"

if [ ! -x "$BIN" ]; then
    calc_log_fail "executable not found: $BIN"
    exit 1
fi
mkdir -p "$OUT_DIR"

fails=0
: > "$OUT_FILE"

capture()
{
    local rv="$1" want="$2"; shift 2
    {
        printf '%s\n' "===== $rv ====="
        printf '%s\n' "\$ $*"
        "$@" 2>&1
        local rc=$?
        printf '%s\n' "----- exit code: $rc (expect $want) -----"
        printf '\n'
    } >> "$OUT_FILE"
    "$@" >/dev/null 2>&1
    local rc2=$?
    if [ "$rc2" != "$want" ]; then
        calc_log_fail "$rv: exit=$rc2 want=$want ($TAG/$KIND)"
        fails=$((fails + 1))
    else
        calc_log_pass "$rv: exit=$rc2 ($TAG/$KIND)"
    fi
}

capture RV-1 0 "$BIN" --self-test
capture RV-2 0 "$BIN" info
capture RV-3 0 "$BIN" add 1.5 2.5
capture RV-3 0 "$BIN" dot 1,2,3 4,5,6
capture RV-3 2 "$BIN" dot 1,2 1,2,3

if [ "$KIND" = shared ]; then
    LIBDIR="$(dirname "$BIN")"
    # RV-4：macOS 动态加载按 @rpath install_name 解析（按名；ordinal 属 PE）
    capture RV-4 0 "$BIN" --dynamic "$LIBDIR/libvmath.dylib" add 1 2
    capture RV-4 2 "$BIN" --dynamic /nonexistent/libvmath.dylib add 1 2
else
    printf '%s\n' "===== RV-4 =====" "(static form: dynamic loading demo not applicable)" "" >> "$OUT_FILE"
fi

if [ "$fails" -eq 0 ]; then
    calc_log_pass "run capture: $OUT_FILE"
    exit 0
fi
calc_log_fail "run capture: $fails RV item(s) failed"
exit 1
