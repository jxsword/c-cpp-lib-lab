#!/usr/bin/env bash
# deps_tree.sh —— SA-8 递归依赖树（F-02-03；PLAN 5.8.3 自实现解析器）
# 用法: deps_tree.sh <elf-artifact> [search-dir...] [-o <输出基名>] [--tag <标签>]
# 算法: BFS；readelf -d 静态读取 NEEDED；readlink -f 逐级解析符号链接并取 realpath；
#       关联数组按 realpath 去重；RUNPATH/$ORIGIN 展开；自带(bundle)/系统(system) 分类。
# 输出: <基名>.json（嵌套树 + symlink_chains + dedup）+ <基名>.md（缩进树）。
# 不调用 GitHub CLI（9.4 J7）。
# FORBIDDEN: 本脚本刻意不使用 ldd/LD_TRACE_LOADED_OBJECTS/pldd 等执行类依赖解析
# 手段（5.8.4 禁令），仅静态读取文件结构。
set -u

if [ "$#" -lt 1 ]; then
    echo "usage: deps_tree.sh <elf-artifact> [search-dir...] [-o <base>] [--tag <label>]" >&2
    exit 2
fi
ART="$1"; shift
OUT_BASE=""
DEPTAG=""
SEARCH=()
while [ "$#" -gt 0 ]; do
    case "$1" in
        -o)    OUT_BASE="$2"; shift 2 ;;
        --tag) DEPTAG="$2"; shift 2 ;;
        *)     SEARCH+=("$1"); shift ;;
    esac
done
[ -n "$OUT_BASE" ] || OUT_BASE="${ART}.deps"
[ -n "$DEPTAG" ] || DEPTAG=$(basename "$ART")
mkdir -p "$(dirname "$OUT_BASE")"

BUILD_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ART_DIR=$(dirname "$(readlink -f "$ART")")

needed_of()
{
    readelf -d "$1" 2>/dev/null | sed -n 's/.*(NEEDED).*\[\(.*\)\].*/\1/p'
}

runpath_of()
{
    local rp origin
    rp=$(readelf -d "$1" 2>/dev/null | sed -n 's/.*(RUNPATH).*\[\(.*\)\].*/\1/p')
    [ -n "$rp" ] || return 0
    origin=$(dirname "$(readlink -f "$1")")
    printf '%s\n' "$rp" | tr ':;' '\n' | sed "s|\$ORIGIN|$origin|g"
}

# 定位依赖并解析 realpath；优先 bundle 目录，其次 ldconfig 的 x86-64 条目
locate_lib()
{
    local name="$1" rp="$2"; shift 2
    local d cand="" p
    for d in $rp "$@"; do
        [ -n "$d" ] && [ -f "$d/$name" ] && { cand="$d/$name"; break; }
    done
    if [ -z "$cand" ] && command -v ldconfig >/dev/null 2>&1; then
        p=$(ldconfig -p 2>/dev/null | awk -v n="$name" '$1 == n && /x86-64/ {print $4; exit}')
        if [ -z "$p" ]; then
            p=$(ldconfig -p 2>/dev/null | awk -v n="$name" '$1 == n {print $4; exit}')
        fi
        [ -n "$p" ] && [ -f "$p" ] && cand="$p"
    fi
    if [ -n "$cand" ]; then
        readlink -f "$cand"
    fi
}

classify()
{
    case "$1" in
        "$BUILD_ROOT"/*) printf 'bundle' ;;
        *)               printf 'system' ;;
    esac
}

declare -A SEEN
MD_FILE="$OUT_BASE.md"
: > "$MD_FILE"

# 递归发射节点：JSON 写 stdout（由外层块统一重定向，避免交错）；
# MD 追加写（该文件只有本函数写入，无交错）。
# $1=real $2=name $3=logical $4=indent $5=suffix（","=还有兄弟节点，""=最后）
emit_node()
{
    local real="$1" name="$2" logical="$3" indent="$4" suffix="$5"
    local origin deps rp total idx=0 c_real c_name c_suffix connector

    origin=$(classify "$real")
    SEEN[$real]=1
    rp=$(runpath_of "$real")
    deps=$(needed_of "$real")
    total=$(printf '%s\n' "$deps" | grep -c . || true)

    if [ "$suffix" = "," ]; then connector='├─'; else connector='└─'; fi
    printf '%s%s %s [%s] real=%s\n' "$indent" "$connector" "$name" "$origin" "$real" >> "$MD_FILE"

    printf '{"name": "%s", "logical": "%s", "real": "%s", "origin": "%s", "children": [' \
        "$name" "$logical" "$real" "$origin"

    while IFS= read -r c_name; do
        [ -n "$c_name" ] || continue
        idx=$((idx + 1))
        if [ "$idx" -lt "$total" ]; then c_suffix=","; else c_suffix=""; fi
        c_real=$(locate_lib "$c_name" "$rp" "$ART_DIR" "${SEARCH[@]}")
        if [ -z "$c_real" ]; then
            printf '{"name": "%s", "logical": "%s", "real": null, "origin": "unresolved", "children": []}%s' \
                "$c_name" "$c_name" "$c_suffix"
            printf '%s├─ %s [unresolved]\n' "$indent    " "$c_name" >> "$MD_FILE"
            continue
        fi
        if [ -n "${SEEN[$c_real]:-}" ]; then
            printf '{"name": "%s", "real": "%s", "origin": "%s", "dedup": true, "children": []}%s' \
                "$c_name" "$c_real" "$(classify "$c_real")" "$c_suffix"
            printf '%s├─ %s [dedup]\n' "$indent    " "$c_name" >> "$MD_FILE"
            continue
        fi
        emit_node "$c_real" "$c_name" "$c_name" "$indent    " "$c_suffix"
    done <<EOF
$deps
EOF

    printf ']}%s' "$suffix"
}

JSON_FILE="$OUT_BASE.json"
{
    printf '{"tag": "%s", "root": {"path": "%s", "arch": "%s"}, "tree": ' \
        "$DEPTAG" "$(readlink -f "$ART")" \
        "$(file -b "$ART" | grep -oE 'ELF (32|64)-bit' | grep -oE '(32|64)')"
    emit_node "$(readlink -f "$ART")" "$(basename "$ART")" "$(basename "$ART")" "" ""
    printf ', "symlink_chains": ['
    n=0
    while IFS= read -r lnk; do
        tgt=$(readlink -f "$lnk" 2>/dev/null) || continue
        [ -n "$tgt" ] || continue
        [ "$tgt" = "$lnk" ] && continue
        n=$((n + 1))
        [ "$n" -gt 1 ] && printf ', '
        printf '["%s", "%s"]' "$(basename "$lnk")" "$(basename "$tgt")"
    done < <(find "$ART_DIR" -maxdepth 1 -type l 2>/dev/null)
    printf '], "dedup": ['
    first=1
    for r in "${!SEEN[@]}"; do
        [ "$first" = 1 ] || printf ', '
        printf '"%s"' "$r"
        first=0
    done
    printf ']}\n'
} > "$JSON_FILE"

echo "deps_tree: $JSON_FILE"
echo "deps_tree: $MD_FILE"
exit 0
