#!/usr/bin/env bash
# native.sh —— ① macOS 原生命令构建（F-04-01）：native.sh <arch> <cfg> <kind>
# 主组合 arm64；x86_64 为附加不计数组的架构覆盖；x86（32 位）SKIP（5.6 C1）。
# 产物 → build/native/macos_clang_<arch>_<cfg>/<kind>/（out-of-source）。
# 动态库：-dynamiclib -Wl,-install_name,@rpath/libvmath.dylib -fvisibility=hidden
# 不调用 GitHub CLI（9.4 J7）；不使用任何动态加载 / 依赖解析执行类手段（5.8.4）。
set -u

. "$(dirname "$0")/common.sh"

if [ "$#" -ne 3 ]; then
    calc_log_fail "usage: native.sh <arch> <cfg> <kind>"
    exit 2
fi
ARCH="$1"; CFG="$2"; KIND="$3"

ARCH_FLAGS=$(calc_macos_arch_flags "$ARCH") || { calc_log_fail "bad arch"; exit 2; }
if [ "$ARCH_FLAGS" = "SKIP" ]; then
    # A6：macOS 32 位客观不可实现——Catalina(10.15) 起移除 32 位支持，SKIP 且成功返回
    calc_log_note "SKIP: macOS 32-bit ($ARCH) is not implementable — 32-bit support removed since macOS 10.15 Catalina (PLAN 5.6 C1)"
    exit 0
fi
case "$CFG" in Debug|Release) ;; *) calc_log_fail "bad cfg"; exit 2 ;; esac
case "$KIND" in static|shared) ;; *) calc_log_fail "bad kind"; exit 2 ;; esac

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CC=clang
TAG=$(calc_make_tag macos clang "$ARCH" "$CFG")
OUT="$ROOT/build/native/$TAG/$KIND"
mkdir -p "$OUT"
LOG="$OUT/compile.log"
: > "$LOG"

if ! calc_assert_no_artifacts "$ROOT"; then
    calc_log_fail "D2 pre: source tree already has artifacts"
    exit 1
fi

CFG_FLAGS=$(calc_macos_cfg_flags "$CFG") || { calc_log_fail "bad cfg"; exit 2; }
# 链接期旗标：clang 链接不显式带 -g 时调试信息不进最终产物（macOS 侧
# 与 Windows 侧 /DEBUG 同类）——Debug 链接显式补 -g，SA-2/SA-3 依赖
LINK_DBG=""
[ "$CFG" = "Debug" ] && LINK_DBG="-g"

run_cmd()
{
    printf '%s\n' "$*" >> "$LOG"
    "$@"
}

rc=0
if [ "$KIND" = "static" ]; then
    run_cmd "$CC" $CFG_FLAGS $ARCH_FLAGS -DCALC_STATIC -I"$ROOT/include" -c "$ROOT/src/vmath_core.c" -o "$OUT/vmath_core.o" && \
    run_cmd "$CC" $CFG_FLAGS $ARCH_FLAGS -DCALC_STATIC -I"$ROOT/include" -c "$ROOT/src/vmath_report.c" -o "$OUT/vmath_report.o" && \
    run_cmd "$CC" $CFG_FLAGS $ARCH_FLAGS -DCALC_STATIC -I"$ROOT/include" -c "$ROOT/src/calctool.c" -o "$OUT/calctool.o" && \
    run_cmd ar rcs "$OUT/libvmath.a" "$OUT/vmath_core.o" "$OUT/vmath_report.o" && \
    run_cmd "$CC" $ARCH_FLAGS "$OUT/calctool.o" -L"$OUT" -lvmath -o "$OUT/calctool" $LINK_DBG || rc=1
else
    run_cmd "$CC" $CFG_FLAGS $ARCH_FLAGS -DCALC_BUILD_DLL -fvisibility=hidden -I"$ROOT/include" -c "$ROOT/src/vmath_core.c" -o "$OUT/vmath_core.o" && \
    run_cmd "$CC" $CFG_FLAGS $ARCH_FLAGS -DCALC_BUILD_DLL -fvisibility=hidden -I"$ROOT/include" -c "$ROOT/src/vmath_report.c" -o "$OUT/vmath_report.o" && \
    run_cmd "$CC" $ARCH_FLAGS -dynamiclib -Wl,-install_name,@rpath/libvmath.dylib -Wl,-rpath,@loader_path "$OUT/vmath_core.o" "$OUT/vmath_report.o" -o "$OUT/libvmath.dylib" $LINK_DBG && \
    run_cmd "$CC" $CFG_FLAGS $ARCH_FLAGS -DCALC_USE_DLL -I"$ROOT/include" -c "$ROOT/src/calctool.c" -o "$OUT/calctool.o" && \
    run_cmd "$CC" $ARCH_FLAGS "$OUT/calctool.o" -L"$OUT" -lvmath -Wl,-rpath,@loader_path -o "$OUT/calctool" $LINK_DBG || rc=1
fi

if [ "$rc" -ne 0 ]; then
    calc_log_fail "build failed: $TAG/$KIND"
    exit 1
fi

"$OUT/calctool" --self-test >/dev/null 2>&1
calc_log_pass "build + self-test: $TAG/$KIND -> $OUT"
exit 0
