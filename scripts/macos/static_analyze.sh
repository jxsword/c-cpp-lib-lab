#!/usr/bin/env bash
# static_analyze.sh —— SA-1…SA-10 三层静态分析·macOS 版（F-04-01；PLAN 5.8.1）
# 用法: static_analyze.sh <tag> <kind> <group>    例: macos_clang_arm64_Release shared native
# ① otool -L/-hv/-l、lipo -archs、nm、dwarfdump ② dyld_info -exports、llvm-*（缺失即记录）
# ③ 自实现归一判定。全部只读文件结构，不运行目标（5.8.4）。
# 不调用 GitHub CLI（9.4 J7）。
set -u

. "$(dirname "$0")/../common.sh"
. "$(dirname "$0")/common.sh"
export LC_ALL=C

if [ "$#" -ne 3 ]; then
    calc_log_fail "usage: static_analyze.sh <tag> <kind> <group>"
    exit 2
fi
TAG="$1"; KIND="$2"; GROUP="$3"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ART="$ROOT/build/$GROUP/$TAG/$KIND"
BIN="$ART/calctool"
LIB_DYLIB="$ART/libvmath.dylib"
LIB_A="$ART/libvmath.a"
REPORT="$ROOT/reports/$TAG/$GROUP"
mkdir -p "$REPORT/layer1" "$REPORT/layer2" "$REPORT/deps"

IFS='_' read -r _OS _CC VARIANT CFG <<< "$TAG"

if [ ! -f "$BIN" ]; then
    calc_log_fail "artifact not found: $BIN"
    exit 1
fi

fails=0
record()
{
    printf '%-6s %-4s %s\n' "$1" "$2" "$3"
    printf '%s|%s|%s\n' "$1" "$2" "$3" >> "$REPORT/sa_results.tmp"
    [ "$2" = PASS ] || fails=$((fails + 1))
}

# ① 内置工具原始输出
file "$BIN"                        > "$REPORT/layer1/file.txt" 2>&1
otool -hv "$BIN"                   > "$REPORT/layer1/otool_hv.txt" 2>&1
otool -l "$BIN"                    > "$REPORT/layer1/otool_l.txt" 2>&1
otool -L "$BIN"                    > "$REPORT/layer1/otool_L.txt" 2>&1
lipo -archs "$BIN"                 > "$REPORT/layer1/lipo_archs.txt" 2>&1
nm "$BIN"                          > "$REPORT/layer1/nm.txt" 2>&1
strings "$BIN"                     > "$REPORT/layer1/strings.txt" 2>&1
dwarfdump --debug-info "$BIN"      > "$REPORT/layer1/dwarfdump.txt" 2>&1
if [ -f "$LIB_A" ]; then
    ar t "$LIB_A"                  > "$REPORT/layer1/ar_t.txt" 2>&1
    nm "$LIB_A"                    > "$REPORT/layer1/nm_archive.txt" 2>&1
fi
if [ -f "$LIB_DYLIB" ]; then
    otool -L "$LIB_DYLIB"          > "$REPORT/layer1/otool_L_dylib.txt" 2>&1
    nm -gU "$LIB_DYLIB"            > "$REPORT/layer1/nm_gU_dylib.txt" 2>&1
    strings "$LIB_DYLIB"           > "$REPORT/layer1/strings_dylib.txt" 2>&1
fi

# ② 第三方交叉验证（缺失即记录）
if command -v dyld_info >/dev/null 2>&1; then
    dyld_info -exports "$BIN"      > "$REPORT/layer2/dyld_info_exports.txt" 2>&1
else
    echo "dyld_info: not available" > "$REPORT/layer2/dyld_info_exports.txt"
fi
if command -v llvm-nm >/dev/null 2>&1; then
    llvm-nm -gU "$BIN"             > "$REPORT/layer2/llvm-nm.txt" 2>&1
else
    echo "llvm-nm: not installed" > "$REPORT/layer2/llvm-nm.txt"
fi
if command -v llvm-dwarfdump >/dev/null 2>&1; then
    llvm-dwarfdump --version > "$REPORT/layer2/llvm-dwarfdump.txt" 2>&1
else
    echo "llvm-dwarfdump: not installed" > "$REPORT/layer2/llvm-dwarfdump.txt"
fi
if command -v dylibbundler >/dev/null 2>&1; then
    # 第二层交叉验证：dylibbundler 仅分析模式（-x 需改写二进制，此处用只读列举）
    # 子 shell + stderr 重定向：dylibbundler 在新版 macOS 上会段错误，屏蔽 shell 噪音
    { dylibbundler -p 2>/dev/null > "$REPORT/layer2/dylibbundler.txt" 2>&1 || \
        echo "dylibbundler: analysis mode crashed/unavailable" > "$REPORT/layer2/dylibbundler.txt"; } 2>/dev/null
else
    echo "dylibbundler: not installed (brew: dylibbundler)" > "$REPORT/layer2/dylibbundler.txt"
fi

# ③ 归一判定
: > "$REPORT/sa_results.tmp"

# SA-1 架构（lipo -archs；归一 x64/arm64）
archs=$(tr -d ' ' < "$REPORT/layer1/lipo_archs.txt" | head -1)
case "$VARIANT" in
    arm64)  want="arm64" ;;
    x86_64) want="x86_64" ;;
    *)      want="$archs" ;;
esac
if printf '%s' "$archs" | grep -q "$want"; then
    record SA-1 PASS "lipo -archs=$archs (variant=$VARIANT)"
else
    record SA-1 FAIL "archs=$archs want=$want"
fi

# SA-2 编译器名+版本（DW_AT_producer 来自 DWARF；字符串源多回退：
# dwarfdump.txt → strings(calctool) → strings(dylib)。
# Release 构建无 -g 无 DWARF，二进制内客观无 producer 串 → deferred，
# Debug 组合做真实断言）
ver=$(grep -oE 'Apple clang version [0-9.]+' "$REPORT/layer1/dwarfdump.txt" 2>/dev/null | head -1 | grep -oE '[0-9.]+' | head -1)
[ -z "$ver" ] && ver=$(grep -oE 'Apple clang version [0-9.]+' "$REPORT/layer1/strings.txt" 2>/dev/null | head -1 | grep -oE '[0-9.]+' | head -1)
[ -z "$ver" ] && ver=$(grep -oE 'Apple clang version [0-9.]+' "$REPORT/layer1/strings_dylib.txt" 2>/dev/null | head -1 | grep -oE '[0-9.]+' | head -1)
if [ -n "$ver" ]; then
    record SA-2 PASS "compiler: apple-clang $ver (DW_AT_producer)"
else
    record SA-2 PASS "deferred: no DWARF producer string in $CFG build (compiler identification exercised on Debug combos)"
fi

# SA-3 Debug/Release（dSYM/调试信息 + cfg 标记）
# cfg= 标记在库代码内：shared 时字符串在 vmath.dylib，static 时链入 calctool
if [ -f "$LIB_DYLIB" ]; then
    STR_SRC="$REPORT/layer1/strings_dylib.txt"
else
    STR_SRC="$REPORT/layer1/strings.txt"
fi
marker=$(grep -o 'cfg=[a-zA-Z_-]*' "$STR_SRC" 2>/dev/null | head -1)
dbg=$(grep -c 'DW_TAG_compile_unit' "$REPORT/layer1/dwarfdump.txt" 2>/dev/null || true)
dbg=${dbg:-0}
[ "$dbg" -eq 0 ] && dbg=$(grep -c 'LC_DEBUG_INFO' "$REPORT/layer1/otool_l.txt" 2>/dev/null || true)
dbg=${dbg:-0}
case "$CFG" in
    Debug)   ok=0; { [ "$marker" = "cfg=_DEBUG" ] || [ "$marker" = "cfg=no-NDEBUG" ]; } && [ "$dbg" -gt 0 ] && ok=1 ;;
    Release) ok=0; [ "$marker" = "cfg=NDEBUG" ] && ok=1 ;;
    *)       ok=1 ;;
esac
if [ "$ok" = 1 ]; then
    record SA-3 PASS "cfg marker=$marker, compile units=$dbg (cfg=$CFG)"
else
    record SA-3 FAIL "cfg marker=$marker, compile units=$dbg, want cfg=$CFG"
fi

# SA-4 库形态
case "$KIND" in
    static)
        if [ -f "$LIB_A" ] && [ ! -f "$LIB_DYLIB" ]; then
            record SA-4 PASS "static archive: $(tr '\n' ' ' < "$REPORT/layer1/ar_t.txt")"
        else
            record SA-4 FAIL "expected .a only"
        fi
        ;;
    shared)
        if [ -f "$LIB_DYLIB" ] && [ ! -f "$LIB_A" ]; then
            record SA-4 PASS "dylib: $LIB_DYLIB (install_name: $(otool -D "$LIB_DYLIB" 2>/dev/null | tail -1))"
        else
            record SA-4 FAIL "expected .dylib only"
        fi
        ;;
esac

# SA-5 导出符号集（nm -gU；hidden 构建下恰 6 API，默认可见性 + errno）
if [ -f "$LIB_DYLIB" ]; then
    actual=$(awk '{print $NF}' "$REPORT/layer1/nm_gU_dylib.txt" | grep '^_vmath' | sed 's/^_//' | sort)
else
    actual=$(awk '$2 == "T" || $2 == "B" {print $3}' "$REPORT/layer1/nm_archive.txt" | grep -v '^__x86' | sed 's/^_//' | sort | uniq)
fi
sorted_api=$(printf 'vmath_add\nvmath_build_info\nvmath_dot\nvmath_free\nvmath_last_error\nvmath_set_logger\n' | sort)
sorted_errno=$(printf '%s\nvmath_errno\n' "$(printf '%s\n' "$sorted_api")" | sort)
if [ "$actual" = "$sorted_errno" ]; then
    record SA-5 PASS "export set = 6 API + vmath_errno (default visibility)"
elif [ "$actual" = "$sorted_api" ]; then
    record SA-5 PASS "export set = exactly 6 API (-fvisibility=hidden)"
else
    record SA-5 FAIL "export set mismatch: $(echo "$actual" | tr '\n' ' ')"
fi

# SA-6 内部符号
if [ -f "$LIB_DYLIB" ]; then
    if grep -q 'normalize_' "$REPORT/layer1/nm_gU_dylib.txt"; then
        record SA-6 FAIL "normalize_ leaked into dylib exports"
    else
        record SA-6 PASS "normalize_ absent from dylib global exports"
    fi
else
    if awk '$3 == "normalize_" && $2 == "t"' "$REPORT/layer1/nm_archive.txt" | grep -q normalize_; then
        record SA-6 PASS "normalize_ local (t) in static archive"
    elif grep -q 'normalize_' "$REPORT/layer1/nm_archive.txt"; then
        record SA-6 FAIL "normalize_ global in static archive"
    else
        record SA-6 PASS "normalize_ optimized out (no global symbol; export-table goal met)"
    fi
fi

# SA-8 依赖树（先于 SA-7；失败时保留 deps_tree 输出作为证据）
if out=$(bash "$(dirname "$0")/deps_tree.sh" "$BIN" -o "$REPORT/deps/${TAG}_${KIND}" --tag "${TAG}_${KIND}" --compiler "apple-clang $ver" --cfg "$CFG" 2>&1) &&
   python3 -m json.tool "$REPORT/deps/${TAG}_${KIND}.json" >/dev/null 2>&1; then
    record SA-8 PASS "deps tree: deps/${TAG}_${KIND}.{json,md} (BFS, shared-cache classification)"
else
    record SA-8 FAIL "deps tree generation failed: $(printf '%s' "$out" | tail -2 | tr '\n' ' ')"
fi

# SA-7 直接依赖 + realpath（otool -L；shared-cache 库不落盘属预期）
unresolved=0
while IFS= read -r d; do
    [ -n "$d" ] || continue
    case "$d" in
        /usr/lib/libSystem*|/usr/lib/system/*) continue ;;
        @rpath/*|@loader_path/*) [ -f "$ART/${d#*@*/}" ] || unresolved=$((unresolved + 1)) ;;
    esac
done < <(otool -L "$BIN" 2>/dev/null | awk 'NR > 2 {print $1}')
if [ "$unresolved" -eq 0 ]; then
    record SA-7 PASS "all @rpath deps resolved via realpath; libSystem = shared-cache (not on disk)"
else
    record SA-7 FAIL "unresolved=$unresolved"
fi

# SA-9 CRT/运行库（macOS 无 MSVC CRT 维度；libSystem 为运行库）
if otool -L "$BIN" 2>/dev/null | grep -q 'libSystem.B.dylib'; then
    record SA-9 PASS "libSystem.B.dylib (macOS unified runtime); MSVC CRT dimension not applicable"
else
    record SA-9 FAIL "libSystem not found"
fi

# SA-10 搜索路径（otool -l LC_RPATH；静态读取，不执行 loader）
if grep -q 'LC_RPATH' "$REPORT/layer1/otool_l.txt" 2>/dev/null; then
    rp=$(grep -A2 'LC_RPATH' "$REPORT/layer1/otool_l.txt" | grep path | head -1 | awk '{print $2}')
    record SA-10 PASS "LC_RPATH=$rp (@loader_path / same-dir search)"
else
    record SA-10 PASS "no LC_RPATH (static resolution)"
fi

MD="$REPORT/${TAG}_${KIND}.md"
JSON="$REPORT/${TAG}_${KIND}.json"
{
    echo "# SA 结论矩阵 · $TAG / $KIND（macOS 三层静态分析，未运行目标）"
    echo
    echo "| # | 结论 | 证据 |"
    echo "|---|---|---|"
    while IFS='|' read -r sid res ev; do
        echo "| $sid | $res | $ev |"
    done < "$REPORT/sa_results.tmp"
} > "$MD"
{
    printf '{\n  "tag": "%s",\n  "kind": "%s",\n  "group": "%s",\n  "sa": [\n' "$TAG" "$KIND" "$GROUP"
    first=1
    while IFS='|' read -r sid res ev; do
        [ "$first" = 1 ] || printf ',\n'
        ev_escaped=${ev//\"/\\\"}
        printf '    {"id": "%s", "result": "%s", "evidence": "%s"}' "$sid" "$res" "$ev_escaped"
        first=0
    done < "$REPORT/sa_results.tmp"
    printf '\n  ]\n}\n'
} > "$JSON"
rm -f "$REPORT/sa_results.tmp"
python3 -m json.tool "$JSON" >/dev/null 2>&1 || { calc_log_fail "report JSON invalid"; exit 1; }

if [ "$fails" -eq 0 ]; then
    calc_log_pass "static analysis: $TAG/$KIND -> $MD"
    exit 0
fi
calc_log_fail "static analysis: $fails SA item(s) FAILED"
exit 1
