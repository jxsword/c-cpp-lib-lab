#!/usr/bin/env bash
# cmake.sh —— ③ CMake·macOS（F-04-01 初版；三 OS 收口在 M6/F-06-01）
# 用法: cmake.sh <arch> <cfg> <kind>
set -u
. "$(dirname "$0")/common.sh"
ARCH="${1:-}"; CFG="${2:-}"; KIND="${3:-}"
ARCH_FLAGS=$(calc_macos_arch_flags "$ARCH") || { calc_log_fail "bad arch"; exit 2; }
if [ "$ARCH_FLAGS" = "SKIP" ]; then
    calc_log_note "SKIP: macOS 32-bit not implementable (removed since 10.15)"
    exit 0
fi
SRC="$(cd "$(dirname "$0")/../.." && pwd)"
B="$SRC/build/cmake/macos_clang_${ARCH}_${CFG}/${KIND}"
SH=OFF; [ "$KIND" = shared ] && SH=ON
CMAKE_OSX_ARCHITECTURES=$([ "$ARCH" = arm64 ] && printf arm64 || printf x86_64)
cmake -S "$SRC" -B "$B" -DCMAKE_BUILD_TYPE="$CFG" -DBUILD_SHARED_LIBS=$SH \
    -DCMAKE_OSX_ARCHITECTURES="$CMAKE_OSX_ARCHITECTURES" || exit 1
cmake --build "$B" || exit 1
ctest --test-dir "$B" --output-on-failure || exit 1
calc_log_pass "cmake build: $B"
