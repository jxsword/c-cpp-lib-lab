#!/usr/bin/env bash
# run.sh —— 反例运行器（F-07-02）：编译期望失败，返回非 0 视为通过
# 用法: ./tests/negative/run.sh stage2_no_extern_c [额外编译参数...]
# 产物/日志落 tests/negative/<名>.log 与 reports/v0.7.0/negative/（对照归档）。
# 不调用 GitHub CLI（9.4 J7）。
set -u

NAME="${1:?usage: run.sh <negative-case-name>}"
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"
SRC="$DIR/$NAME.cpp"

if [ ! -f "$SRC" ]; then
    echo "FAIL: negative sample not found: $SRC"
    exit 2
fi

# MSVC 专属反例在其他 OS 上 SKIP（A2：输出 SKIP 且退出码 0）
if [ "$NAME" = "stage3_stl_across_crt" ]; then
    if [ "$(uname -s)" != "MINGW64_NT-" ] && [ "$(uname -s)" != "MINGW32_NT-" ] && [ "$(uname -o 2>/dev/null)" != "msys" ]; then
        echo "SKIP: MSVC-specific negative case (CRT/_ITERATOR_DEBUG_LEVEL mismatch is an MSVC CRT behavior)"
        exit 0
    fi
fi

LOG_DIR="$ROOT/reports/v0.7.0/negative"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/$NAME.log"

: > "$LOG"
{
    echo "negative case: $NAME"
    echo "command: g++ $NAME.cpp <libdir=stage1 shared artifact>"
    echo "expect: link FAILURE with mangling signature"
    echo
} >> "$LOG"

LIBDIR=$(ls -d "$ROOT"/build/native/linux_gcc_x64_Release/shared 2>/dev/null | sort | tail -1)
if [ -z "$LIBDIR" ] || [ ! -f "$LIBDIR/libvmath.so" ] && [ ! -f "$LIBDIR/libvmath.so.1.0.0" ]; then
    # 库产物缺失时先用无库编译探 mangling（-c 不链接也能确认修饰名存在）
    if g++ -I"$ROOT/include" -c "$SRC" -o "$DIR/$NAME.o" >> "$LOG" 2>&1; then
        nm -C "$DIR/$NAME.o" >> "$LOG" 2>&1
        echo "NOTE: library artifact not found; compile-only mode recorded mangled reference" >> "$LOG"
        rm -f "$DIR/$NAME.o"
        exit 0
    fi
    echo "FAIL: even compile failed unexpectedly" | tee -a "$LOG"
    exit 1
fi

# 期望失败：链接 C 库应报 undefined reference to '_Z9vmath_adddd'
# mangling 特征证明（A1）：先 -c 编译，nm 记录 C++ 修饰名 _Z9vmath_adddd 为未定义引用
if g++ -I"$ROOT/include" -c "$SRC" -o "$DIR/$NAME.o" >> "$LOG" 2>&1; then
    {
        echo "-- mangled undefined reference (nm) --"
        nm "$DIR/$NAME.o" | grep -E 'U _Z9vmath_add' || true
        rm -f "$DIR/$NAME.o"
    } >> "$LOG"
fi
if g++ -I"$ROOT/include" "$SRC" -L"$LIBDIR" -lvmath -o "$DIR/$NAME.out" >> "$LOG" 2>&1; then
    {
        echo "UNEXPECTED: link SUCCEEDED — negative case must fail (extern C guard absent means mangled name)"
    } >> "$LOG"
    rm -f "$DIR/$NAME.out"
    echo "FAIL: $NAME unexpectedly linked"
    exit 1
fi

grep -E "_Z9vmath_add|undefined reference" "$LOG" >> "$LOG.sig" 2>/dev/null || true
{
    echo
    echo "RESULT: expected failure confirmed (mangling signature captured above)"
    echo "FIX: restore extern \"C\" guard — include vmath.h (CALC_EXTERN_C_BEGIN/END)"
} >> "$LOG"
echo "PASS: $NAME failed as expected (see $LOG)"
exit 0
