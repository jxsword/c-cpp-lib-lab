#!/usr/bin/env bash
# bundle.sh —— Linux 打包：解压即用目录（F-09-07；PLAN 9.1）
# 用法: bundle.sh <tag> <kind> [group]    例: bundle.sh linux_gcc_x64_Release shared native
# 布局：build/bundle/<tag>/<kind>/{bin/calctool, lib/libvmath.so.1*}, LICENSE, NOTICE
# 收尾全部**静态复核**（readelf -d，不用运行期跟踪——C13/5.8.4）；
# 绝不打包 glibc/ld-linux/NSS（系统库）；许可证/NOTICE 随包（A5）。
# 不调用 GitHub CLI（9.4 J7）。
set -u

. "$(dirname "$0")/../common.sh"

if [ "$#" -lt 2 ]; then
    calc_log_fail "usage: bundle.sh <tag> <kind> [group]"
    exit 2
fi
TAG="$1"; KIND="$2"; GROUP="${3:-native}"

# 参数加固：拒绝含 shell 元字符的取值（Mimosa 建议，对齐 smoke 脚本先例）
for a in "$TAG" "$KIND" "$GROUP"; do
  case "$a" in
    *[\\\;\|\&\$\`\(\)\>\<]* )
      echo "REFUSE: suspicious argument: $a"
      exit 2
      ;;
  esac
done

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$ROOT/build/$GROUP/$TAG/$KIND"
BUNDLE="$ROOT/build/bundle/$TAG/$KIND"

[ -x "$SRC/calctool" ] || { calc_log_fail "artifact not found: $SRC/calctool"; exit 1; }

rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/bin" "$BUNDLE/lib"

# ---- 收集：自带库 + 可执行（不打系统库） ----
cp "$SRC/calctool" "$BUNDLE/bin/"
if [ "$KIND" = shared ]; then
    for so in "$SRC"/libvmath.so*; do
        [ -e "$so" ] && cp -L "$so" "$BUNDLE/lib/"
    done
fi

# ---- rpath 收紧到包内（$ORIGIN/../lib） ----
if command -v patchelf >/dev/null 2>&1; then
    patchelf --set-rpath '$ORIGIN/../lib' "$BUNDLE/bin/calctool" 2>/dev/null || true
else
    calc_log_note "patchelf not installed; rpath left as-is (apt: patchelf)"
fi

# ---- strip（减小体积；不影响功能） ----
if command -v strip >/dev/null 2>&1; then
    strip "$BUNDLE/bin/calctool" 2>/dev/null || true
    for f in "$BUNDLE"/lib/*; do
        [ -f "$f" ] && strip "$f" 2>/dev/null || true
    done
fi

# ---- A3：静态复核（SA-7/SA-8 思路：readelf -d 只读解析） ----
FAILS=0
NEEDED=$(readelf -d "$BUNDLE/bin/calctool" 2>/dev/null | sed -n 's/.*(NEEDED).*\[\(.*\)\].*/\1/p')
for dep in $NEEDED; do
    case "$dep" in
        libvmath*)
            if [ -e "$BUNDLE/lib/$dep" ]; then
                echo "PASS: bundle dep $dep -> $(readlink -f "$BUNDLE/lib/$dep")"
            else
                echo "FAIL: bundle dep $dep missing in lib/"
                FAILS=$((FAILS + 1))
            fi
            ;;
        libc.so.*|libm.so.*|libdl.so.*|ld-linux*)
            echo "PASS: system dep $dep (not bundled, per 9.1)"
            ;;
        *)
            echo "NOTE: dep $dep (system)"
            ;;
    esac
done
RUNPATH=$(readelf -d "$BUNDLE/bin/calctool" 2>/dev/null | sed -n 's/.*(RUNPATH).*\[\(.*\)\].*/\1/p')
case "$RUNPATH" in
    '$ORIGIN'*) echo "PASS: RUNPATH=$RUNPATH" ;;
    *) echo "NOTE: RUNPATH=$RUNPATH (patchelf unavailable?)" ;;
esac

# ---- A4：包内无 Debug CRT（Linux 无 *d.dll 概念——校验无 *d.so 副本） ----
if ls "$BUNDLE"/lib/*d.so* >/dev/null 2>&1; then
    echo "FAIL: debug runtime copy found"
    FAILS=$((FAILS + 1))
fi

# ---- A5：许可证 / NOTICE 随包 ----
cp "$ROOT/LICENSE" "$BUNDLE/LICENSE"
cat > "$BUNDLE/NOTICE" <<'EOF'
c-cpp-lib-lab
Copyright (c) 2026 jxsword — MIT License (see LICENSE)

This bundle contains only first-party code (libvmath + calctool) and the C/C++
standard runtime of the host system, which is NOT bundled (see PLAN 9.1).
No third-party libraries are included; therefore no third-party notices apply.
EOF
[ -f "$BUNDLE/LICENSE" ] && [ -f "$BUNDLE/NOTICE" ] && echo "PASS: LICENSE + NOTICE bundled"

# ---- A6（本地可测部分）：切 CWD 再跑自测（相对路径无关性） ----
if (cd / && "$BUNDLE/bin/calctool" --self-test >/dev/null 2>&1); then
    echo "PASS: zero-install self-test from unrelated CWD"
else
    echo "FAIL: self-test failed from unrelated CWD"
    FAILS=$((FAILS + 1))
fi

if [ "$FAILS" -eq 0 ]; then
    echo "bundle OK: $BUNDLE"
    exit 0
fi
echo "bundle FAILED: $FAILS item(s)"
exit 1
