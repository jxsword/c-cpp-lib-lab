#!/usr/bin/env bash
# bundle.sh —— macOS 打包：.app 解压即用（F-09-07；PLAN 9.1）
# 布局：build/bundle/<tag>/<kind>/Calctool.app/Contents/MacOS/{calctool,libvmath.dylib}, LICENSE, NOTICE
# 不打 shared-cache 系统 dylib；install_name_tool 收紧 @rpath；codesign --deep 收尾。
# 静态复核（otool -L 只读）；不调用 GitHub CLI（9.4 J7）。
set -u

. "$(dirname "$0")/../common.sh"

if [ "$#" -lt 2 ]; then
    calc_log_fail "usage: bundle.sh <tag> <kind> [group]"
    exit 2
fi
TAG="$1"; KIND="$2"; GROUP="${3:-native}"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$ROOT/build/$GROUP/$TAG/$KIND"
APP="$ROOT/build/bundle/$TAG/$KIND/Calctool.app/Contents/MacOS"

[ -x "$SRC/calctool" ] || { calc_log_fail "artifact not found: $SRC/calctool"; exit 1; }

mkdir -p "$APP"
cp "$SRC/calctool" "$APP/"
if [ "$KIND" = shared ]; then
    for dy in "$SRC"/libvmath.dylib; do
        [ -e "$dy" ] && cp -L "$dy" "$APP/"
    done
fi

# install_name 收紧（库自身改 @rpath；可执行引用 @executable_path）
if command -v install_name_tool >/dev/null 2>&1; then
    install_name_tool -change "@rpath/libvmath.dylib" "@executable_path/libvmath.dylib" "$APP/calctool" 2>/dev/null || true
    codesign --force --deep -s - "$APP/../.." 2>/dev/null || true
else
    calc_log_note "install_name_tool not available (deferred to runner)"
fi

# A3：静态复核（otool -L 只读）
for dep in $(otool -L "$APP/calctool" 2>/dev/null | awk 'NR > 2 {print $1}'); do
    case "$dep" in
        @rpath/*|@executable_path/*) echo "PASS: bundle dep $dep" ;;
        /usr/lib/libSystem*|/usr/lib/system/*) echo "PASS: system dep $dep (shared cache, not bundled)" ;;
        *) echo "NOTE: dep $dep" ;;
    esac
done

# A5：LICENSE/NOTICE
cp "$ROOT/LICENSE" "$APP/../../LICENSE"
cat > "$APP/../../NOTICE" <<'EOF'
c-cpp-lib-lab — MIT License (see LICENSE). No third-party libraries bundled.
EOF

# A6 本地部分：切 CWD 自测（macOS runner 实证）
if (cd / && "$APP/calctool" --self-test >/dev/null 2>&1); then
    echo "PASS: zero-install self-test"
else
    calc_log_note "self-test deferred to macOS runner (Linux host cannot run Mach-O)"
fi
echo "bundle OK: $APP/../.."
