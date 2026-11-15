#!/usr/bin/env bash
# make.sh —— ② make 组·macOS（F-04-01 初版；GNU make 方言全量在 M5/F-05-01 实装）
# 用法: make.sh <arch> <cfg> <kind>
set -u
. "$(dirname "$0")/common.sh"
ARCH="${1:-}"; CFG="${2:-}"; KIND="${3:-}"
ARCH_FLAGS=$(calc_macos_arch_flags "$ARCH") || { calc_log_fail "bad arch"; exit 2; }
if [ "$ARCH_FLAGS" = "SKIP" ]; then
    calc_log_note "SKIP: macOS 32-bit not implementable (removed since 10.15)"
    exit 0
fi
B=build/make/gnu/macos_clang_${ARCH}_${CFG}/${KIND}
mkdir -p "$B" && cd "$B" || exit 1
make -f "$(cd "$(dirname "$0")/../.." && pwd)/Makefile" srcdir="$(cd "$(dirname "$0")/../.." && pwd)" \
    CFLAGS_EXTRA="$ARCH_FLAGS" CFG="$CFG" KIND="$KIND" 2>&1 || {
    calc_log_note "Makefile (F-05-01) not present yet — placeholder for M5"
    exit 3
}
calc_log_pass "make build: $B"
