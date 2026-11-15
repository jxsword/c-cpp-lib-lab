#!/usr/bin/env bash
# security_hijack_demo.sh —— macOS 劫持面演示（F-09-08；DYLD_* 注入与 SIP/Hardened Runtime）
# 用法: security_hijack_demo.sh before|after
# RV 通道；不修改系统目录、不写全局环境变量（A3）。
set -u
MODE="${1:?usage: security_hijack_demo.sh before|after}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIBDIR="$ROOT/build/native/macos_clang_arm64_Release/shared"

case "$MODE" in
    before)
        echo "== BEFORE（未加固）：DYLD_LIBRARY_PATH 前置同名 dylib =="
        echo "-- macOS 上 DYLD 注入类环境变量可加载同名库"
        echo "-- SIP / Hardened Runtime 会对特权程序清除 DYLD_*（见 docs/baseline.md 安全章节）"
        echo "BEFORE-DEMO-OK (notes only — reproduction on macOS runner)"
        exit 0
        ;;
    after)
        echo "== AFTER（加固）=="
        echo "1. @rpath + install_name 固定（F-04-01 native.sh）"
        echo "2. codesign --deep -s - 演示签名（bundle.sh）"
        echo "3. Hardened Runtime：库验证 + 禁 DYLD 注入"
        echo "AFTER-DEMO-OK (notes only — runner)"
        exit 0
        ;;
esac
