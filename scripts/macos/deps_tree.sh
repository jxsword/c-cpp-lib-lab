#!/usr/bin/env bash
# deps_tree.sh —— SA-8 递归依赖树·macOS 版（F-04-01；PLAN 5.8.3）
# BFS；otool -L 静态读取依赖；readlink/realpath 解析；libSystem.B.dylib 等
# 系统库标记为 shared-cache（不落盘实体，A4）。
# FORBIDDEN: 刻意不使用执行类依赖解析手段（5.8.4），仅静态读取文件结构。
set -u

if [ "$#" -lt 1 ]; then
    echo "usage: deps_tree.sh <macho-artifact> [-o <base>] [--tag <label>]" >&2
    exit 2
fi
ART="$1"; shift
OUT_BASE=""
DEPTAG=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        -o)    OUT_BASE="$2"; shift 2 ;;
        --tag) DEPTAG="$2"; shift 2 ;;
        *)     shift ;;
    esac
done
[ -n "$OUT_BASE" ] || OUT_BASE="${ART}.deps"
[ -n "$DEPTAG" ] || DEPTAG=$(basename "$ART")
mkdir -p "$(dirname "$OUT_BASE")"

ART_DIR=$(dirname "$(dirname "$(readlink -f "$ART")")")
BUILD_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

deps_of()
{
    otool -L "$1" 2>/dev/null | awk 'NR > 2 {print $1}'
}

classify()
{
    case "$1" in
        "$BUILD_ROOT"/*) printf 'bundle' ;;
        /usr/lib/libSystem*|/usr/lib/system/*) printf 'shared-cache' ;;
        /usr/lib/*|/System/*) printf 'system' ;;
        *) printf 'system' ;;
    esac
}

locate_lib()
{
    local name="$1" p
    case "$name" in
        @rpath/*)
            p="$ART_DIR/${name#@rpath/}"
            [ -f "$p" ] && { readlink -f "$p"; return; }
            return
            ;;
        @loader_path/*)
            p="$ART_DIR/${name#@loader_path/}"
            [ -f "$p" ] && { readlink -f "$p"; return; }
            return
            ;;
        /usr/lib/*|/System/*)
            printf '%s (shared-cache, not materialized on disk)' "$name"
            return
            ;;
    esac
    [ -f "$ART_DIR/$name" ] && readlink -f "$ART_DIR/$name"
}

declare -A SEEN
MD_FILE="$OUT_BASE.md"
: > "$MD_FILE"

emit_node()
{
    local name="$1" real="$2" indent="$3" suffix="$4"
    local origin deps total=0 idx=0 c_name c_real c_suffix connector
    origin=$(classify "$real")
    SEEN["$name"]=1
    deps=$(deps_of "$real" 2>/dev/null || true)
    total=$(printf '%s\n' "$deps" | grep -c . || true)

    if [ "$suffix" = "," ]; then connector='├─'; else connector='└─'; fi
    printf '%s%s %s [%s] real=%s\n' "$indent" "$connector" "$name" "$origin" "$real" >> "$MD_FILE"

    printf '{"name": "%s", "real": "%s", "origin": "%s", "children": [' "$name" "$real" "$origin"
    while IFS= read -r c_name; do
        [ -n "$c_name" ] || continue
        idx=$((idx + 1))
        if [ "$idx" -lt "$total" ]; then c_suffix=","; else c_suffix=""; fi
        case "$c_name" in
            /usr/lib/libSystem*|/usr/lib/system/*)
                printf '{"name": "%s", "real": null, "origin": "shared-cache", "note": "not materialized on disk", "children": []}%s' "$c_name" "$c_suffix"
                printf '%s├─ %s [shared-cache, not on disk]\n' "$indent    " "$c_name" >> "$MD_FILE"
                continue
                ;;
        esac
        c_real=$(locate_lib "$c_name")
        if [ -n "${SEEN[$c_name]:-}" ]; then
            printf '{"name": "%s", "dedup": true, "children": []}%s' "$c_name" "$c_suffix"
            printf '%s├─ %s [dedup]\n' "$indent    " "$c_name" >> "$MD_FILE"
            continue
        fi
        if [ -z "$c_real" ]; then
            printf '{"name": "%s", "real": null, "origin": "unresolved", "children": []}%s' "$c_name" "$c_suffix"
            printf '%s├─ %s [unresolved]\n' "$indent    " "$c_name" >> "$MD_FILE"
            continue
        fi
        emit_node "$c_name" "$c_real" "$indent    " "$c_suffix"
    done <<EOF
$deps
EOF
    printf ']}%s' "$suffix"
}

{
    printf '{"tag": "%s", "root": {"path": "%s", "arch": "%s"}, "tree": ' \
        "$DEPTAG" "$(readlink -f "$ART")" "$(lipo -archs "$ART" 2>/dev/null | tr ' ' ',')"
    emit_node "$(basename "$ART")" "$(readlink -f "$ART")" "" ""
    printf ', "note": "libSystem.B.dylib 等 /usr/lib/system 库为 macOS shared cache，不落盘"}\n'
} > "$OUT_BASE.json"

echo "deps_tree: $OUT_BASE.json"
echo "deps_tree: $MD_FILE"
exit 0
