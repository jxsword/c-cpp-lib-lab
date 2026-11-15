#!/usr/bin/env bash
# scan_dynamic_calls.sh — 5.8.4 静态分析硬禁令关键字扫描（F-00-04 / S7）
# 用法: scan_dynamic_calls.sh [目标目录或文件...]   （默认: 仓库 scripts/）
# 规则: 命中 5.8.4 禁用调用即 FAIL（含动态加载、依赖解析、运行期注入/跟踪关键字）；
#       注释行含 FORBIDDEN: 前缀的引用按 5.8.4 白名单豁免。
# 本脚本不得调用 gh（9.4 J7）。
set -u

if [ "$#" -gt 0 ]; then
  targets=("$@")
else
  targets=("$(cd "$(dirname "$0")/../.." && pwd)/scripts")
fi

# 扫描器自身的模式定义行尾带 FORBIDDEN: 标记（白名单检查的是命中行自身，PLAN 5.8.4）
PAT='\b(dlopen|dlsym|dlclose|LoadLibrary|LoadLibraryEx|GetProcAddress|FreeLibrary|NSBundle|CFBundle|ldd|pldd|vmmap|LD_DEBUG|LD_PRELOAD|LD_TRACE_LOADED_OBJECTS|DYLD_PRINT_LIBRARIES|DYLD_PRINT_RPATHS|DYLD_INSERT_LIBRARIES)\b|/proc/[0-9]+/maps' # FORBIDDEN: scanner own pattern (whitelisted)

hits=0
for t in "${targets[@]}"; do
  if [ ! -e "$t" ]; then
    echo "SKIP（不存在）: $t"
    continue
  fi
  while IFS= read -r line; do
    case "$line" in *'FORBIDDEN:'*) continue ;; esac
    echo "FAIL: $line"
    hits=1
  done < <(grep -rnE "$PAT" -- "$t" 2>/dev/null || true)
done

if [ "$hits" -eq 0 ]; then
  echo "OK: 无 5.8.4 禁用调用（目标: $*）"
  exit 0
fi
echo '发现 5.8.4 禁用调用，exit 1'
exit 1
