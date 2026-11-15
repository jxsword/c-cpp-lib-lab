#!/usr/bin/env bash
# native.sh —— ① 原生命令构建（F-02-01）：native.sh <arch> <cfg> <kind>
# 产物 → build/native/linux_gcc_<arch>_<cfg>/<kind>/（全部 out-of-source）
# 静态 .o 必须以 -DCALC_STATIC 重编（C9），绝不复用动态 .o；
# 每条命令写入 compile.log（A4 编译记录断言依据）。
# 不调用 GitHub CLI（9.4 J7）；不使用任何动态加载 / 依赖解析执行类手段（5.8.4）。
set -u

. "$(dirname "$0")/../common.sh"
. "$(dirname "$0")/common.sh"

if [ "$#" -ne 3 ]; then
    calc_log_fail "usage: native.sh <arch> <cfg> <kind>"
    exit 2
fi
ARCH="$1"; CFG="$2"; KIND="$3"
case "$ARCH" in x86|x64) ;; *) calc_log_fail "arch must be x86|x64"; exit 2 ;; esac
case "$CFG" in Debug|Release) ;; *) calc_log_fail "cfg must be Debug|Release"; exit 2 ;; esac
case "$KIND" in static|shared) ;; *) calc_log_fail "kind must be static|shared"; exit 2 ;; esac

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CC=gcc
TAG=$(calc_make_tag linux gcc "$ARCH" "$CFG")
OUT="$ROOT/build/native/$TAG/$KIND"
mkdir -p "$OUT"
LOG="$OUT/compile.log"
: > "$LOG"

if ! calc_assert_no_artifacts "$ROOT"; then
    calc_log_fail "D2 pre: source tree already has artifacts"
    exit 1
fi

CFG_FLAGS=$(calc_linux_cfg_flags "$CFG") || { calc_log_fail "bad cfg"; exit 2; }
ARCH_FLAGS=$(calc_linux_arch_flags "$ARCH") || { calc_log_fail "bad arch"; exit 2; }

# 记录并执行：命令原文入 compile.log（A4 断言依据）
run_cmd()
{
    printf '%s\n' "$*" >> "$LOG"
    "$@"
}

rc=0

if [ "$KIND" = "static" ]; then
    # 静态：库对象与消费端均以 -DCALC_STATIC 重编（C9）
    run_cmd "$CC" $CFG_FLAGS $ARCH_FLAGS -DCALC_STATIC -I"$ROOT/include" -c "$ROOT/src/vmath_core.c" -o "$OUT/vmath_core.o" && \
    run_cmd "$CC" $CFG_FLAGS $ARCH_FLAGS -DCALC_STATIC -I"$ROOT/include" -c "$ROOT/src/vmath_report.c" -o "$OUT/vmath_report.o" && \
    run_cmd "$CC" $CFG_FLAGS $ARCH_FLAGS -DCALC_STATIC -I"$ROOT/include" -c "$ROOT/src/calctool.c" -o "$OUT/calctool.o" && \
    run_cmd ar rcs "$OUT/libvmath.a" "$OUT/vmath_core.o" "$OUT/vmath_report.o" && \
    run_cmd "$CC" $ARCH_FLAGS "$OUT/calctool.o" -L"$OUT" -lvmath -lm -o "$OUT/calctool" || rc=1
else
    # 动态：库侧 BUILD_DLL + fPIC + hidden，soname 三级链接；
    # 消费端 USE_DLL，rpath=$ORIGIN，-ldl 预留 RV 动态加载通道
    run_cmd "$CC" $CFG_FLAGS $ARCH_FLAGS -DCALC_BUILD_DLL -fPIC -fvisibility=hidden -I"$ROOT/include" -c "$ROOT/src/vmath_core.c" -o "$OUT/vmath_core.o" && \
    run_cmd "$CC" $CFG_FLAGS $ARCH_FLAGS -DCALC_BUILD_DLL -fPIC -fvisibility=hidden -I"$ROOT/include" -c "$ROOT/src/vmath_report.c" -o "$OUT/vmath_report.o" && \
    run_cmd "$CC" $ARCH_FLAGS -shared -Wl,-soname,libvmath.so.1 -Wl,--enable-new-dtags "$OUT/vmath_core.o" "$OUT/vmath_report.o" -lm -o "$OUT/libvmath.so.1.0.0" && \
    calc_linux_soname_links "$OUT" && \
    run_cmd "$CC" $CFG_FLAGS $ARCH_FLAGS -DCALC_USE_DLL -I"$ROOT/include" -c "$ROOT/src/calctool.c" -o "$OUT/calctool.o" && \
    run_cmd "$CC" $ARCH_FLAGS "$OUT/calctool.o" -L"$OUT" -lvmath -Wl,-rpath,'$ORIGIN' -ldl -lm -o "$OUT/calctool" || rc=1
fi

if [ "$rc" -ne 0 ]; then
    calc_log_fail "build failed: $TAG/$KIND"
    exit 1
fi

# 构建后功能自证（--self-test 为 CI 唯一功能判据）
if "$OUT/calctool" --self-test >/dev/null 2>&1; then
    calc_log_pass "build + self-test: $TAG/$KIND -> $OUT"
    exit 0
fi
calc_log_fail "self-test failed: $TAG/$KIND"
exit 1
