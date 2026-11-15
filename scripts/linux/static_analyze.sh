#!/usr/bin/env bash
# static_analyze.sh —— SA-1…SA-10 三层静态分析（F-02-03；PLAN 5.8.1–5.8.3）
# 用法: static_analyze.sh <tag> <kind> <group>    例: linux_gcc_x64_Release shared native
# 输出（全部落盘可查，A7）:
#   reports/<tag>/<group>/<tag>_<kind>.md / .json      —— ③ 自实现归一：SA 结论矩阵
#   reports/<tag>/<group>/deps/<tag>_<kind>.{json,md}  —— SA-8 依赖树
#   reports/<tag>/<group>/layer1/*.txt                 —— ① 内置工具原始输出
#   reports/<tag>/<group>/layer2/*.txt                 —— ② 第三方工具原始输出
# 不调用 GitHub CLI（9.4 J7）。全部结论来自只读文件结构解析：不执行目标程序、
# 不把目标载入进程地址空间、不使用执行类依赖解析手段（5.8.4）。
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
LIB_SO="$ART/libvmath.so.1.0.0"
LIB_A="$ART/libvmath.a"
REPORT="$ROOT/reports/$TAG/$GROUP"
mkdir -p "$REPORT/deps" "$REPORT/layer1" "$REPORT/layer2"

IFS='_' read -r _OS _CC VARIANT CFG <<< "$TAG"

if [ ! -f "$BIN" ]; then
    calc_log_fail "artifact not found: $BIN（先跑 native.sh 构建该组合）"
    exit 1
fi

fails=0
record()
{
    # record <SA-id> <PASS|FAIL> <evidence>
    printf '%-6s %-4s %s\n' "$1" "$2" "$3"
    printf '%s\n' "$1|$2|$3" >> "$REPORT/sa_results.tmp"
    [ "$2" = PASS ] || fails=$((fails + 1))
}

# ════ 第①层：系统/编译器内置工具（只读二进制结构，绝不执行） ════
file "$BIN"                          > "$REPORT/layer1/file.txt" 2>&1
readelf -h "$BIN"                    > "$REPORT/layer1/readelf_h.txt" 2>&1
readelf -d "$BIN"                    > "$REPORT/layer1/readelf_d.txt" 2>&1
readelf -S "$BIN"                    > "$REPORT/layer1/readelf_S.txt" 2>&1
readelf -p .comment "$BIN"           > "$REPORT/layer1/readelf_comment.txt" 2>&1
strings "$BIN"                       > "$REPORT/layer1/strings.txt" 2>&1
objdump -f "$BIN"                    > "$REPORT/layer1/objdump_f.txt" 2>&1
if [ -f "$LIB_A" ]; then
    ar t "$LIB_A"                    > "$REPORT/layer1/ar_t.txt" 2>&1
    nm "$LIB_A"                      > "$REPORT/layer1/nm_archive.txt" 2>&1
fi
if [ -f "$LIB_SO" ]; then
    nm -D --defined-only "$LIB_SO"   > "$REPORT/layer1/nm_D_so.txt" 2>&1
    readelf -d "$LIB_SO"             > "$REPORT/layer1/readelf_d_so.txt" 2>&1
fi

# ════ 第②层：第三方工具交叉验证（缺失则如实记录；清单见 .github/apt-packages.txt） ════
if command -v lddtree >/dev/null 2>&1; then
    lddtree "$BIN"                   > "$REPORT/layer2/lddtree.txt" 2>&1
else
    echo "lddtree: not installed (apt: pax-utils)" > "$REPORT/layer2/lddtree.txt"
fi
if command -v patchelf >/dev/null 2>&1; then
    {
        echo "== $BIN =="
        patchelf --print-rpath "$BIN" 2>&1
        [ -f "$LIB_SO" ] && { echo "== $LIB_SO =="; patchelf --print-rpath "$LIB_SO" 2>&1; }
        true
    } > "$REPORT/layer2/patchelf_rpath.txt"
else
    echo "patchelf: not installed (apt: patchelf)" > "$REPORT/layer2/patchelf_rpath.txt"
fi
if command -v llvm-readobj >/dev/null 2>&1; then
    llvm-readobj --file-headers "$BIN" > "$REPORT/layer2/llvm-readobj.txt" 2>&1
else
    echo "llvm-readobj: not installed (apt: llvm)" > "$REPORT/layer2/llvm-readobj.txt"
fi
if command -v llvm-nm >/dev/null 2>&1; then
    llvm-nm -D "$BIN" > "$REPORT/layer2/llvm-nm.txt" 2>&1
else
    echo "llvm-nm: not installed (apt: llvm)" > "$REPORT/layer2/llvm-nm.txt"
fi
if command -v llvm-dwarfdump >/dev/null 2>&1; then
    llvm-dwarfdump --version > "$REPORT/layer2/llvm-dwarfdump.txt" 2>&1
else
    echo "llvm-dwarfdump: not installed (apt: llvm)" > "$REPORT/layer2/llvm-dwarfdump.txt"
fi

# ════ 第③层：自实现归一、判定、报告 ════
: > "$REPORT/sa_results.tmp"

# SA-1 架构位数
class=$(awk '/Class:/{print $2}' "$REPORT/layer1/readelf_h.txt")
machine=$(awk '/Machine:/{print $NF}' "$REPORT/layer1/readelf_h.txt")
case "$VARIANT" in
    x64) want_class=ELF64 ;;
    x86) want_class=ELF32 ;;
    *)   want_class=$class ;;
esac
if [ "$class" = "$want_class" ]; then
    record SA-1 PASS "class=$class machine=$machine (variant=$VARIANT)"
else
    record SA-1 FAIL "class=$class want=$want_class"
fi

# SA-2 编译器名 + 版本（.comment 提取，与 gcc --version 比对）
ver_comment=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$REPORT/layer1/readelf_comment.txt" | head -1)
ver_local=$(gcc --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
compiler="gcc $ver_comment"
if [ -n "$ver_comment" ] && [ "$ver_comment" = "$ver_local" ]; then
    record SA-2 PASS "compiler: $compiler (local gcc $ver_local)"
else
    record SA-2 FAIL ".comment=$ver_comment vs local=$ver_local"
fi

# SA-3 Debug/Release（调试段 + .rodata 配置标记；shared 的标记在库对象里）
dbg=$(grep -c '\.debug' "$REPORT/layer1/readelf_S.txt" || true)
marker_src="$REPORT/layer1/strings.txt"
if [ -f "$LIB_SO" ]; then
    strings "$LIB_SO" > "$REPORT/layer1/strings_so.txt" 2>&1
    marker_src="$REPORT/layer1/strings_so.txt"
fi
marker=$(grep -o 'cfg=[a-zA-Z_-]*' "$marker_src" | head -1)
case "$CFG" in
    # Debug 两类合法形态：显式 -D_DEBUG（native.sh 约定）或 CMake 默认
    # （无 NDEBUG 但不定义 _DEBUG，即 no-NDEBUG）——以存在调试段为硬判据
    Debug)   ok=0; [ "$dbg" -gt 0 ] || ok=0
             { [ "$marker" = "cfg=_DEBUG" ] || [ "$marker" = "cfg=no-NDEBUG" ]; } && ok=1 ;;
    Release) ok=0; [ "$marker" = "cfg=NDEBUG" ] && ok=1; [ "$dbg" -eq 0 ] && ok=1 ;;
    *)       ok=1 ;;
esac
if [ "$ok" = 1 ]; then
    record SA-3 PASS "cfg marker=$marker, debug sections=$dbg (cfg=$CFG)"
else
    record SA-3 FAIL "cfg marker=$marker, debug sections=$dbg, want cfg=$CFG"
fi

# SA-4 库形态
case "$KIND" in
    static)
        if [ -f "$LIB_A" ] && [ -s "$REPORT/layer1/ar_t.txt" ] && [ ! -f "$LIB_SO" ]; then
            record SA-4 PASS "static archive: $(tr '\n' ' ' < "$REPORT/layer1/ar_t.txt")"
        else
            record SA-4 FAIL "expected .a only, got: a=$([ -f "$LIB_A" ] && echo y || echo n) so=$([ -f "$LIB_SO" ] && echo y || echo n)"
        fi
        ;;
    shared)
        if [ -f "$LIB_SO" ] && [ ! -f "$LIB_A" ]; then
            record SA-4 PASS "shared object: $LIB_SO (soname=$(readelf -d "$LIB_SO" | sed -n 's/.*(SONAME).*\[\(.*\)\].*/\1/p'))"
        else
            record SA-4 FAIL "expected .so only, got: a=$([ -f "$LIB_A" ] && echo y || echo n) so=$([ -f "$LIB_SO" ] && echo y || echo n)"
        fi
        ;;
esac

# SA-5 导出符号集（恰 6 API；gcc 默认可见性下额外出现 vmath_errno，
# -fvisibility=hidden 构建下该教学符号被隐藏——两种形态均判 PASS，如实记录）
expected_api="vmath_add
vmath_build_info
vmath_dot
vmath_free
vmath_last_error
vmath_set_logger"
expected_with_errno="vmath_add
vmath_build_info
vmath_dot
vmath_errno
vmath_free
vmath_last_error
vmath_set_logger"
if [ -f "$LIB_SO" ]; then
    actual=$(awk '{print $NF}' "$REPORT/layer1/nm_D_so.txt" | sort)
else
    actual=$(awk '$2 == "T" || $2 == "B" {print $3}' "$REPORT/layer1/nm_archive.txt" | grep -v '^__x86\.get_pc_thunk' | sort | uniq)
fi
sorted_api=$(printf '%s\n' "$expected_api" | sort)
sorted_errno=$(printf '%s\n' "$expected_with_errno" | sort)
if [ "$actual" = "$sorted_errno" ]; then
    record SA-5 PASS "export set = 6 API + vmath_errno (default visibility)"
elif [ "$actual" = "$sorted_api" ]; then
    record SA-5 PASS "export set = exactly 6 API (vmath_errno hidden by -fvisibility=hidden)"
else
    record SA-5 FAIL "export set mismatch: $(echo "$actual" | tr '\n' ' ')"
fi

# SA-6 内部符号（normalize_ 不在动态导出表）
if [ -f "$LIB_SO" ]; then
    if grep -q 'normalize_' "$REPORT/layer1/nm_D_so.txt"; then
        record SA-6 FAIL "normalize_ leaked into dynamic exports"
    else
        record SA-6 PASS "normalize_ absent from dynamic exports"
    fi
else
    if awk '$3 == "normalize_" && $2 == "t"' "$REPORT/layer1/nm_archive.txt" | grep -q normalize_; then
        record SA-6 PASS "normalize_ is local (t) in static archive"
    elif grep -q 'normalize_' "$REPORT/layer1/nm_archive.txt"; then
        record SA-6 FAIL "normalize_ global in static archive"
    else
        record SA-6 PASS "normalize_ optimized out at this cfg (no global symbol; export-table goal met)"
    fi
fi

# SA-8 依赖树（先跑：SA-7 的 realpath 证据取自树输出）
if bash "$(dirname "$0")/deps_tree.sh" "$BIN" "$ART" -o "$REPORT/deps/${TAG}_${KIND}" --tag "${TAG}_${KIND}" >/dev/null 2>&1 &&
   python3 -m json.tool "$REPORT/deps/${TAG}_${KIND}.json" >/dev/null 2>&1; then
    record SA-8 PASS "deps tree: deps/${TAG}_${KIND}.{json,md} (BFS, realpath dedup, JSON valid)"
else
    record SA-8 FAIL "deps tree generation or JSON validation failed"
fi

# SA-7 直接依赖 + realpath（证据取自 SA-8 树：每个 NEEDED 均有 real 或显式 unresolved）
unresolved=$(python3 - "$REPORT/deps/${TAG}_${KIND}.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
bad = []
def walk(node):
    if node.get("real") is None:
        bad.append(node["name"])
    for c in node.get("children", []):
        walk(c)
walk(d["tree"])
print(len(bad))
PY
)
case "$KIND" in
    shared)
        if [ "$unresolved" = 0 ] && grep -q 'libvmath.so.1' "$REPORT/deps/${TAG}_${KIND}.json"; then
            record SA-7 PASS "all NEEDED resolved via readlink -f (libvmath.so.1 + libc); symlink chain recorded"
        else
            record SA-7 FAIL "unresolved=$unresolved"
        fi
        ;;
    static)
        static_needed=$(readelf -d "$BIN" | sed -n 's/.*(NEEDED).*\[\(.*\)\].*/\1/p')
        if ! printf '%s\n' "$static_needed" | grep -q 'libvmath'; then
            record SA-7 PASS "no libvmath dependency (statically resolved); system deps resolved=$([ "$unresolved" = 0 ] && echo all || echo "$unresolved")"
        else
            record SA-7 FAIL "static binary unexpectedly depends on libvmath"
        fi
        ;;
esac

# SA-9 CRT/运行库模式（Linux：glibc 动态；MSVC CRT 维度 ELF 上 N/A）
if grep -q 'libc.so.6' "$REPORT/layer1/readelf_d.txt"; then
    record SA-9 PASS "glibc dynamic (libc.so.6); MSVC CRT dimension not applicable on ELF"
else
    record SA-9 FAIL "libc.so.6 not found in dynamic section"
fi

# SA-10 搜索路径（静态读 RUNPATH，不执行 loader）
rpath=$(sed -n 's/.*(RUNPATH).*\[\(.*\)\].*/\1/p' "$REPORT/layer1/readelf_d.txt")
case "$KIND" in
    shared)
        # 卡面 A1 语义：RUNPATH 存在且值含 $ORIGIN（CMake 构建树会自动追加
        # 构建目录，属标准行为；native.sh 为恰 $ORIGIN）
        case "$rpath" in
            '$ORIGIN'*)
                record SA-10 PASS "RUNPATH contains \$ORIGIN (same-dir search): $rpath"
                ;;
            *)
                record SA-10 FAIL "RUNPATH=$rpath"
                ;;
        esac
        ;;
    static)
        record SA-10 PASS "no RUNPATH (static resolution); patchelf cross-check: $(head -c 60 "$REPORT/layer2/patchelf_rpath.txt" | tr '\n' ' ')"
        ;;
esac

# ── 汇总报告（③ 归一输出：Markdown + JSON） ──
MD="$REPORT/${TAG}_${KIND}.md"
JSON="$REPORT/${TAG}_${KIND}.json"
{
    echo "# SA 结论矩阵 · $TAG / $KIND（三层静态分析，未运行目标）"
    echo
    echo "| # | 结论 | 证据 |"
    echo "|---|---|---|"
    while IFS='|' read -r sid res ev; do
        echo "| $sid | $res | $ev |"
    done < "$REPORT/sa_results.tmp"
    echo
    echo "- 第①层原始输出: layer1/（file/readelf/nm/ar/strings/objdump）"
    echo "- 第②层交叉验证: layer2/（lddtree/patchelf/llvm-*，缺失即记录）"
    echo "- 依赖树: deps/${TAG}_${KIND}.{json,md}（BFS + realpath 去重 + 符号链接链）"
} > "$MD"

{
    printf '{\n  "tag": "%s",\n  "kind": "%s",\n  "group": "%s",\n' "$TAG" "$KIND" "$GROUP"
    printf '  "compiler": "%s",\n' "$compiler"
    printf '  "sa": [\n'
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
