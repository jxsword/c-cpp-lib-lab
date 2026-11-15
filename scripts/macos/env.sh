#!/usr/bin/env bash
# env.sh —— macOS 环境自检（F-04-01）
# 不调用 GitHub CLI（9.4 J7）。
set -u
for t in clang clang++ make cmake ninja otool lipo nm dwarfdump; do
    if command -v "$t" >/dev/null 2>&1; then
        printf '[ok] %s -> %s\n' "$t" "$(command -v "$t")"
    else
        printf '[--] %s not found\n' "$t"
    fi
done
clang --version 2>/dev/null | head -1 || true
exit 0
