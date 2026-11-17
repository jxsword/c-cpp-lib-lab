#!/usr/bin/env bash
# check_reports.sh —— reports/ 完整性校验（报告全量补齐 · 阶段 4）
# 枚举 42 个标签目录 × 各构建组 × static/shared，核对：
#   <组目录>/<tag>_<kind>.{json,md}   —— SA 结论（双格式）
#   deps/<tag>_<kind>.{json,md}      —— 依赖树（双格式；msys2 为 deferred 记录）
#   run/<tag>_<group>-<kind>.txt     —— RV 运行输出（group 斜杠归一为 -）
# 输出缺失清单；全部齐备 exit 0，否则 exit 1。
# 不调用 GitHub CLI（9.4 J7）。
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORTS="$ROOT/reports"

# 42 标签 × 组映射：标签 → 该标签下实跑的组目录列表
# native 组目录 native/；make/gnu → make/gnu/；make/nmake → make/nmake/；
# make/msbuild → make/msbuild/；cmake → cmake/
declare -A TAG_GROUPS

# ① 原生 24（linux 4 + macos 2 + windows 18）
for v in x86 x64; do
  for c in Debug Release; do
    TAG_GROUPS["linux_gcc_${v}_${c}"]="native cmake make/gnu"
  done
done
for c in Debug Release; do
  TAG_GROUPS["macos_clang_arm64_${c}"]="native cmake make/gnu"
done
for v in x86_MD x86_MT x64_MD x64_MT; do
  for c in Debug Release; do
    TAG_GROUPS["win_msvc_${v}_${c}"]="native cmake"
  done
done
for v in MINGW64 MINGW32 CLANG64 UCRT64; do
  for c in Debug Release; do
    TAG_GROUPS["win_msys2_${v}_${c}"]="native cmake make/gnu"
  done
done
for c in Debug Release; do
  TAG_GROUPS["win_clang-cl_x64_${c}"]="native cmake"
done
# ② make 组：nmake 10 + msbuild 8
for v in x86_MD x86_MT x64_MD x64_MT x64; do
  for c in Debug Release; do
    TAG_GROUPS["win_nmake_${v}_${c}"]="make/nmake"
  done
done
for v in x86_MD x86_MT x64_MD x64_MT; do
  for c in Debug Release; do
    TAG_GROUPS["win_msbuild_${v}_${c}"]="make/msbuild"
  done
done

# 组目录名（目录段）与 run 文件 group 段（斜杠归一 -）
group_dir() {
  case "$1" in
    native)        echo "native" ;;
    make/gnu)      echo "make/gnu" ;;
    make/nmake)    echo "make/nmake" ;;
    make/msbuild)  echo "make/msbuild" ;;
    cmake)         echo "cmake" ;;
  esac
}
group_safe() {
  echo "$1" | tr '/' '-'
}

missing=0
checked=0

for tag in "${!TAG_GROUPS[@]}"; do
  groups="${TAG_GROUPS[$tag]}"
  for g in $groups; do
    gd="$(group_dir "$g")"
    gs="$(group_safe "$g")"
    for kind in shared static; do
      # SA 结论双格式
      for ext in json md; do
        f="$REPORTS/$tag/$gd/${tag}_${kind}.$ext"
        if [ -f "$f" ]; then checked=$((checked + 1)); else
          echo "MISSING: $tag/$gd/${tag}_${kind}.$ext"; missing=$((missing + 1))
        fi
      done
      # deps 双格式
      for ext in json md; do
        f="$REPORTS/$tag/deps/${tag}_${kind}.$ext"
        if [ -f "$f" ]; then checked=$((checked + 1)); else
          echo "MISSING: $tag/deps/${tag}_${kind}.$ext"; missing=$((missing + 1))
        fi
      done
      # RV 运行输出
      f="$REPORTS/$tag/run/${tag}_${gs}_${kind}.txt"
      if [ -f "$f" ]; then checked=$((checked + 1)); else
        echo "MISSING: $tag/run/${tag}_${gs}_${kind}.txt"; missing=$((missing + 1))
      fi
    done
  done
done

echo "check_reports: 校验 $checked 个文件，缺失 $missing 个"
if [ "$missing" -eq 0 ]; then
  echo "check_reports: OK（42 标签 × 组 × 双形态齐全）"
  exit 0
fi
echo "check_reports: FAIL（缺失清单见上）"
exit 1
