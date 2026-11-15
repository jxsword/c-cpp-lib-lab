#!/usr/bin/env bash
# analyze.sh —— 静态分析结论报告生成器（F-02-04；PLAN F-02-04 要点）
# 用法: analyze.sh <tag> <kind> <group>    例: analyze.sh linux_gcc_x64_Release shared native
# 1) 调用 static_analyze.sh（三层引擎：SA-1…SA-10 + 依赖树 + layer1/2 落盘）
# 2) 依赖树单独写 reports/<tag>/deps/（与 SA 报告分离，4.1 目录约定）
# 3) 报告追加「导出集区分」节：恰 6 API / gcc 裸符号（可见性如实记录）/ normalize_ 不在动态导出表
# 4) 列数一致性自检（A4）
# 不调用 GitHub CLI（9.4 J7）；全部结论来自只读解析，不执行目标（5.8.4）。
set -u

. "$(dirname "$0")/../common.sh"
. "$(dirname "$0")/common.sh"
export LC_ALL=C

if [ "$#" -ne 3 ]; then
    calc_log_fail "usage: analyze.sh <tag> <kind> <group>"
    exit 2
fi
TAG="$1"; KIND="$2"; GROUP="$3"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ART="$ROOT/build/$GROUP/$TAG/$KIND"
GDIR="$ROOT/reports/$TAG/$GROUP"
mkdir -p "$ROOT/reports/$TAG/deps" "$GDIR"

if [ ! -f "$ART/calctool" ]; then
    calc_log_fail "artifact not found: $ART/calctool"
    exit 1
fi

# ── 1) 三层引擎（SA 判定 + 依赖树 + layer1/2 原始输出落盘） ──
if ! bash "$(dirname "$0")/static_analyze.sh" "$TAG" "$KIND" "$GROUP"; then
    calc_log_fail "static_analyze.sh failed for $TAG/$KIND"
    exit 1
fi

# ── 2) 依赖树单独写 reports/<tag>/deps/（与 SA 报告分离） ──
mkdir -p "$ROOT/reports/$TAG/deps"
for ext in json md; do
    if [ -f "$GDIR/deps/${TAG}_${KIND}.$ext" ]; then
        mv "$GDIR/deps/${TAG}_${KIND}.$ext" "$ROOT/reports/$TAG/deps/${TAG}_${KIND}.$ext"
    fi
done
rmdir "$GDIR/deps" 2>/dev/null || true

# ── 3) 导出集区分节（要点：区分「6 API」与「gcc 额外裸符号」） ──
MD="$GDIR/${TAG}_${KIND}.md"
LIB_SO="$ART/libvmath.so.1.0.0"
LIB_A="$ART/libvmath.a"
expected_api="vmath_add
vmath_build_info
vmath_dot
vmath_free
vmath_last_error
vmath_set_logger"
expected_with_errno="$expected_api
vmath_errno"
sorted_api=$(printf '%s\n' "$expected_api" | sort)
sorted_errno=$(printf '%s\n' "$expected_with_errno" | sort)

if [ -f "$LIB_SO" ]; then
    actual=$(awk '{print $NF}' "$GDIR/layer1/nm_D_so.txt" | sort)
    if [ "$actual" = "$sorted_errno" ]; then
        bare="PASS (exported, default visibility)"
    elif [ "$actual" = "$sorted_api" ]; then
        bare="PASS (hidden by -fvisibility=hidden — recorded, not an error)"
    else
        bare="FAIL ($(echo "$actual" | tr '\n' ' '))"
    fi
    if [ "$actual" = "$sorted_api" ] || [ "$actual" = "$sorted_errno" ]; then
        api_ok=PASS
    else
        api_ok=FAIL
    fi
    if grep -q 'normalize_' "$GDIR/layer1/nm_D_so.txt"; then
        normalize_ok=FAIL
    else
        normalize_ok=PASS
    fi
else
    actual=$(awk '$2 == "T" || $2 == "B" {print $3}' "$GDIR/layer1/nm_archive.txt" 2>/dev/null | sort | uniq)
    if [ "$actual" = "$sorted_errno" ]; then
        bare="PASS (bare symbol global 'B' in static archive; visibility applies at consumer link time)"
    elif [ "$actual" = "$sorted_api" ]; then
        bare="PASS (hidden by -fvisibility=hidden — recorded, not an error)"
    else
        bare="FAIL ($(echo "$actual" | tr '\n' ' '))"
    fi
    if [ "$actual" = "$sorted_api" ] || [ "$actual" = "$sorted_errno" ]; then
        api_ok=PASS
    else
        api_ok=FAIL
    fi
    if awk '$3 == "normalize_" && $2 == "t"' "$GDIR/layer1/nm_archive.txt" 2>/dev/null | grep -q normalize_; then
        normalize_ok=PASS
    else
        normalize_ok=FAIL
    fi
fi

{
    echo ""
    echo "## 导出集区分（F-02-04）"
    echo ""
    echo "| 项 | 结果 | 明细 |"
    echo "|---|---|---|"
    echo "| API 导出集（恰 6） | $api_ok | $(echo "$actual" | tr '\n' ' ') |"
    echo "| gcc 裸符号 vmath_errno | $bare | 动态导出表 normalize_ 检查: $normalize_ok |"
} >> "$MD"

# ── 4) 列数一致性自检（A4） ──
bad_cols=$(awk -F'|' '/^\|/ && !/^\|-/ {print NF}' "$MD" | sort -u | wc -l)
if [ "$bad_cols" -le 1 ]; then
    calc_log_pass "analyze: $TAG/$KIND -> $MD（表列数一致）"
    exit 0
fi
calc_log_fail "analyze: table column counts inconsistent（$bad_cols 种列数）"
exit 1
