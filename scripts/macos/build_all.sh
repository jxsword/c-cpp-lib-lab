#!/usr/bin/env bash
# build_all.sh —— macOS 全组合编排（F-04-01；7.0 统一入口）
# 用法: build_all.sh <group> [arch cfg kind 过滤…]
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
GROUP="${1:-native}"; shift || true
case "$GROUP" in
    native)  script="$DIR/native.sh"  ;;
    make)    script="$DIR/make.sh"    ;;
    cmake)   script="$DIR/cmake.sh"   ;;
    *) echo "usage: build_all.sh <native|make|cmake> [filters]" >&2; exit 2 ;;
esac
fails=0
for arch in arm64 x86_64 x86; do
    for cfg in Debug Release; do
        for kind in static shared; do
            "$script" "$arch" "$cfg" "$kind" || fails=$((fails + 1))
        done
    done
done
[ "$fails" -eq 0 ] && { echo "build_all($GROUP): all OK (SKIP counts as OK)"; exit 0; }
echo "build_all($GROUP): $fails failure(s)"
exit 1
