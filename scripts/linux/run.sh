#!/usr/bin/env bash
# run.sh —— RV-1…RV-4 运行输出采集（F-02-05；PLAN 5.7.2，S8）
# 用法: run.sh <tag> <kind> <group>    例: run.sh linux_gcc_x64_Release shared native
# 采集 RV-1（--self-test）/ RV-2（info）/ RV-3（add/dot）的 stdout+stderr+exit code
# → reports/<组合标签>/run/<组合标签>_<kind>.txt；shared 形态追加 RV-4（--dynamic）。
# 本脚本属 RV 通道：**运行被测程序是本脚本职责**；分析脚本（analyze/static_analyze/
# deps_tree）不得执行目标（5.8.4 / C18 隔离）。不调用 GitHub CLI（9.4 J7）。
set -u

. "$(dirname "$0")/../common.sh"
export LC_ALL=C

if [ "$#" -ne 3 ]; then
    calc_log_fail "usage: run.sh <tag> <kind> <group>"
    exit 2
fi
TAG="$1"; KIND="$2"; GROUP="$3"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BIN="$ROOT/build/$GROUP/$TAG/$KIND/calctool"
OUT_DIR="$ROOT/reports/$TAG/run"
OUT_FILE="$OUT_DIR/${TAG}_${KIND}.txt"

if [ ! -x "$BIN" ]; then
    calc_log_fail "executable not found: $BIN"
    exit 1
fi
mkdir -p "$OUT_DIR"

fails=0
: > "$OUT_FILE"

capture()
{
    # capture <RV-id> <期望退出码> <命令...>
    local rv="$1" want="$2"; shift 2
    {
        printf '%s\n' "===== $rv ====="
        printf '%s\n' "\$ $*"
        "$@" 2>&1
        local rc=$?
        printf '%s\n' "----- exit code: $rc (expect $want) -----"
        printf '\n'
    } >> "$OUT_FILE"
    # 退出码核对在调用方二次判定：这里记录是否与期望一致
    "$@" >/dev/null 2>&1
    local rc2=$?
    if [ "$rc2" != "$want" ]; then
        calc_log_fail "$rv: exit=$rc2 want=$want ($TAG/$KIND)"
        fails=$((fails + 1))
    else
        calc_log_pass "$rv: exit=$rc2 ($TAG/$KIND)"
    fi
}

# RV-1: --self-test（CI 唯一功能判据）
capture RV-1 0 "$BIN" --self-test
# RV-2: info（组合自证；与组合标签的一致性由 verify_card 的 A3 型断言比对）
capture RV-2 0 "$BIN" info
# RV-3: add / dot 功能输出与错误码
capture RV-3 0 "$BIN" add 1.5 2.5
capture RV-3 0 "$BIN" dot 1,2,3 4,5,6
capture RV-3 2 "$BIN" dot 1,2 1,2,3

# RV-4: --dynamic（仅 shared 形态存在动态库；功能演示，非分析）
if [ "$KIND" = shared ]; then
    LIBDIR="$(dirname "$BIN")"
    capture RV-4 0 "$BIN" --dynamic "$LIBDIR/libvmath.so.1.0.0" add 1 2
    capture RV-4 2 "$BIN" --dynamic /nonexistent/libvmath.so add 1 2
else
    {
        printf '===== RV-4 =====\n(static form: dynamic loading demo not applicable)\n\n'
    } >> "$OUT_FILE"
fi

if [ "$fails" -eq 0 ]; then
    calc_log_pass "run capture: $OUT_FILE"
    exit 0
fi
calc_log_fail "run capture: $fails RV item(s) failed"
exit 1
