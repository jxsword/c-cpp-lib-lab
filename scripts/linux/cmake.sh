#!/usr/bin/env bash
# cmake.sh —— ③ CMake·Linux（F-06-01；三 OS 24 组合收口）
# 用法: cmake.sh <arch> <cfg> <kind>    例: cmake.sh x64 Release shared
# 一律 -S <src> -B build/cmake/<tag>/<kind>（out-of-source）。
# 不调用 GitHub CLI（9.4 J7）。
set -u
. "$(dirname "$0")/../common.sh"
. "$(dirname "$0")/common.sh"

if [ "$#" -ne 3 ]; then
    calc_log_fail "usage: cmake.sh <arch> <cfg> <kind>"
    exit 2
fi
ARCH="$1"; CFG="$2"; KIND="$3"
case "$ARCH" in x86|x64) ;; *) calc_log_fail "bad arch"; exit 2 ;; esac
case "$CFG" in Debug|Release) ;; *) calc_log_fail "bad cfg"; exit 2 ;; esac
case "$KIND" in static|shared) ;; *) calc_log_fail "bad kind"; exit 2 ;; esac

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TAG=$(calc_make_tag linux gcc "$ARCH" "$CFG")
B="$ROOT/build/cmake/$TAG/$KIND"
SH=OFF
[ "$KIND" = shared ] && SH=ON
M32=-m64
[ "$ARCH" = x86 ] && M32=-m32

cmake -S "$ROOT" -B "$B" -DCMAKE_BUILD_TYPE="$CFG" -DBUILD_SHARED_LIBS=$SH -DCMAKE_C_FLAGS="$M32" || exit 1
cmake --build "$B" || exit 1
ctest --test-dir "$B" --output-on-failure || exit 1
calc_log_pass "cmake build: $TAG/$KIND -> $B"
