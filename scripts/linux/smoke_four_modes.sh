#!/usr/bin/env bash
# smoke_four_modes.sh — 四模式冒烟（F-01-06；M1–M4 各编译一次 + 反例期望失败）
# 用法: smoke_four_modes.sh <compiler> <variant> <cfg>    例: ./smoke_four_modes.sh gcc x64 Release
# 产物全部落在 build/native/smoke/<os>_<compiler>_<variant>_<cfg>/（out-of-source）。
# 本脚本不调用 gh（9.4 J7）；不使用任何动态加载 / 依赖解析执行类手段（5.8.4，
# readelf 属静态检查、为 A2 明确要求）。
set -u

CC="${1:?usage: smoke_four_modes.sh <compiler> <variant> <cfg>}"
VARIANT="${2:?missing variant}"
CFG="${3:?missing cfg}"

# 参数加固：拒绝含 shell 元字符的取值（防注入；合法取值为工具链名/组合标签片段）
for a in "$CC" "$VARIANT" "$CFG"; do
  case "$a" in
    *[\\\;\|\&\$\`\(\)\>\<]* )
      printf 'REFUSE: suspicious argument: %s\n' "$a"
      exit 2
      ;;
  esac
done

SRC="$(cd "$(dirname "$0")/../.." && pwd)"
TAG="linux_${CC}_${VARIANT}_${CFG}"
OUT="$SRC/build/native/smoke/$TAG"
NEG="$SRC/tests/negative/static-with-dllimport"

rm -rf "$OUT"
mkdir -p "$OUT"

fails=0
note() { printf '%s\n' "$*"; }
pass() { printf 'PASS: %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*"; fails=$((fails+1)); }

CFLAGS="-Wall -Wextra -Werror"

# ── M1 CALC_STATIC：静态库 + 静态消费 ────────────────────────────────────────
note "== M1 static =="
if "$CC" $CFLAGS -DCALC_STATIC -I"$SRC/include" -c "$SRC/src/vmath_core.c"   -o "$OUT/core_m1.o" &&
   "$CC" $CFLAGS -DCALC_STATIC -I"$SRC/include" -c "$SRC/src/vmath_report.c" -o "$OUT/report_m1.o" &&
   "$CC" $CFLAGS -DCALC_STATIC -I"$SRC/include" -c "$SRC/src/calctool.c"     -o "$OUT/cli_m1.o" &&
   ar rcs "$OUT/libvmath.a" "$OUT/core_m1.o" "$OUT/report_m1.o" &&
   "$CC" "$OUT/cli_m1.o" -L"$OUT" -lvmath -lm -o "$OUT/calctool_m1" &&
   "$OUT/calctool_m1" --self-test >/dev/null 2>&1; then
  pass "M1 static: build + link + self-test"
else
  fail "M1 static"
fi

# ── M2 CALC_BUILD_DLL：动态库构建侧 ──────────────────────────────────────────
note "== M2 shared-build =="
if "$CC" $CFLAGS -fPIC -DCALC_BUILD_DLL -I"$SRC/include" -c "$SRC/src/vmath_core.c"   -o "$OUT/core_m2.o" &&
   "$CC" $CFLAGS -fPIC -DCALC_BUILD_DLL -I"$SRC/include" -c "$SRC/src/vmath_report.c" -o "$OUT/report_m2.o" &&
   "$CC" -shared "$OUT/core_m2.o" "$OUT/report_m2.o" -lm -o "$OUT/libvmath.so"; then
  pass "M2 shared-build: libvmath.so built"
else
  fail "M2 shared-build"
fi

# ── M3 CALC_USE_DLL：动态库使用侧 ────────────────────────────────────────────
note "== M3 shared-use =="
if "$CC" $CFLAGS -DCALC_USE_DLL -I"$SRC/include" -c "$SRC/src/calctool.c" -o "$OUT/cli_m3.o" &&
   "$CC" "$OUT/cli_m3.o" -L"$OUT" -lvmath -lm -o "$OUT/calctool_m3" &&
   LD_LIBRARY_PATH="$OUT" "$OUT/calctool_m3" --self-test >/dev/null 2>&1; then
  pass "M3 shared-use: build + link + self-test"
else
  fail "M3 shared-use"
fi

# ── M4 CALC_NO_LIB：源码直编（不链任何库文件） ───────────────────────────────
note "== M4 no-lib =="
if "$CC" $CFLAGS -DCALC_NO_LIB -I"$SRC/include" "$SRC"/src/*.c -lm -o "$OUT/calctool_m4" &&
   "$OUT/calctool_m4" --self-test >/dev/null 2>&1; then
  pass "M4 no-lib: direct compile + self-test"
else
  fail "M4 no-lib"
fi

# A2：M4 产物静态解析——动态段不得含 libvmath
if readelf -d "$OUT/calctool_m4" 2>/dev/null | grep -q 'libvmath'; then
  fail "A2 readelf: M4 binary unexpectedly depends on libvmath"
else
  pass "A2 readelf -d: M4 binary has no libvmath dependency"
fi

# ── 反例（A3）：静态库使用侧误开 dllimport（__imp_ 未解析）→ 期望失败 ────────
note "== negative: static consumer with dllimport semantics =="
if "$CC" $CFLAGS -I"$SRC/include" "$NEG/consumer.c" "$OUT/libvmath.a" -lm -o "$OUT/negative_expect_fail" 2>"$OUT/negative.log"; then
  fail "negative case unexpectedly SUCCEEDED — main flow must go red"
else
  firstline=$(head -1 "$OUT/negative.log" 2>/dev/null || true)
  pass "negative case failed as expected (${firstline})"
fi

note ""
if [ "$fails" -eq 0 ]; then
  note "SMOKE OK: $TAG"
  exit 0
fi
note "SMOKE FAILED: $fails failure(s)"
exit 1
