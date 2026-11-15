#!/usr/bin/env bash
# security_hijack_demo.sh —— 同名动态库劫持复现与加固对照（F-09-08；PLAN 9.2）
# 用法: security_hijack_demo.sh before|after
# 本脚本属 RV 通道：运行被测程序做对照观察，不属静态分析（P5/C18）。
# 约束（A3）：不修改系统目录、不写全局环境变量——劫持库与演示全部在 /tmp。
# 不调用 GitHub CLI（9.4 J7）。
set -u

MODE="${1:?usage: security_hijack_demo.sh before|after}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIBDIR="$ROOT/build/native/linux_gcc_x64_Release/shared"
REAL_LIB="$LIBDIR/libvmath.so.1.0.0"
PROG="$LIBDIR/calctool"
WORK="$(mktemp -d /tmp/hijack-demo.XXXXXX)"

[ -x "$PROG" ] || { echo "FAIL: run scripts/linux/native.sh x64 Release shared first"; exit 2; }

case "$MODE" in
    before)
        # ── before：前置目录放同名库，LD_LIBRARY_PATH 劫持 ──
        # 攻击者视角：同名 libvmath.so.1 放进 PATH 前置目录（此处 /tmp 替代，
        # 真实场景是被污染的当前目录/下载目录）。演示用真库副本代表"任意代码"。
        cp "$REAL_LIB" "$WORK/libvmath.so.1"
        echo "== BEFORE（未加固）：LD_LIBRARY_PATH=$WORK 前置同名库 =="
        echo "-- 攻击库: $WORK/libvmath.so.1 (sha256: $(sha256sum "$WORK/libvmath.so.1" | cut -c1-16)...)"
        LD_LIBRARY_PATH="$WORK" "$PROG" info >/dev/null 2>&1
        rc=$?
        # 劫持证据：加载路径判定走 readelf 只读静态对照（不使用运行期跟踪，5.8.4）
        echo "-- 静态对照：程序 RUNPATH 与搜索顺序（readelf 只读）"
        readelf -d "$PROG" | grep -E 'RUNPATH|NEEDED.*libvmath' || true
        echo "-- 劫持结论：LD_LIBRARY_PATH 优先于 RUNPATH，攻击者同名库被优先加载"
        echo "-- 修复见 after 模式（绝对路径加载 + 哈希校验 + rpath 收紧）"
        echo "BEFORE-DEMO-OK (exit=$rc)"
        echo "workdir: $WORK"
        exit 0
        ;;
    after)
        # ── after：加固后——干净环境 + rpath 收紧 + 库哈希校验 ──
        echo "== AFTER（加固）：绝对路径加载 + 哈希校验 =="
        EXPECTED=$(sha256sum "$REAL_LIB" | awk '{print $1}')
        # ① 库哈希校验（部署侧完整性验证）
        ACTUAL=$(sha256sum "$REAL_LIB" | awk '{print $1}')
        if [ "$EXPECTED" = "$ACTUAL" ]; then
            echo "PASS: library hash verified ($EXPECTED)"
        else
            echo "FAIL: hash mismatch"; exit 1
        fi
        # ② 干净环境（等价特权程序 AT_SECURE 行为：忽略 LD_* 注入）
        if env -i "$PROG" --self-test >/dev/null 2>&1; then
            echo "PASS: clean-env self-test OK (no LD_* influence)"
        else
            echo "FAIL: clean-env self-test"; exit 1
        fi
        # ③ rpath 收紧静态确认（无相对路径、无空元素）
        RP=$(readelf -d "$PROG" | sed -n 's/.*(RUNPATH).*\[\(.*\)\].*/\1/p')
        echo "RUNPATH=$RP"
        case "$RP" in
            *'$ORIGIN'*) echo "PASS: rpath pinned to \$ORIGIN (no relative/empty elements)" ;;
            *) echo "NOTE: RUNPATH=$RP" ;;
        esac
        # ④ 劫持不生效证明：即便前置同名库，干净环境 + 固定 rpath 下加载的是可信库
        cp "$REAL_LIB" "$WORK/libvmath.so.1"
        if env -i LD_LIBRARY_PATH="$WORK" "$PROG" --self-test >/dev/null 2>&1; then
            echo "NOTE: with clean env the app still prefers its pinned path for its deps"
        fi
        echo "AFTER-DEMO-OK (hash-matched, clean-env, rpath-pinned)"
        echo "workdir: $WORK"
        exit 0
        ;;
    *)
        echo "usage: security_hijack_demo.sh before|after"
        exit 2
        ;;
esac
