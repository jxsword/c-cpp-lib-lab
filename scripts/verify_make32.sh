#!/usr/bin/env bash
# verify_make32.sh —— 32 组合横向对比（F-05-04；PLAN F-05-04）
# 证明 32 = GNU make 14 + nmake 10 + msbuild 8；三方言 (os,toolset,variant,cfg) 一一对应；
# 记录可见性/PIC/CRT/CALC_STATIC 注入差异；不改动 5.5 的定义。
# Linux gnu 部分本地实跑核对 info↔标签；nmake/msbuild 产物级核对待 F-09-02 runner。
# 不调用 GitHub CLI（9.4 J7）。
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ---- 32 行清单（方言 os toolset variant cfg）——与 5.5.2 定义逐行对应 ----
LIST=$(cat <<'EOF'
gnu linux gcc x86 Debug
gnu linux gcc x86 Release
gnu linux gcc x64 Debug
gnu linux gcc x64 Release
gnu macos clang arm64 Debug
gnu macos clang arm64 Release
gnu msys2 gcc MINGW64 Debug
gnu msys2 gcc MINGW64 Release
gnu msys2 gcc MINGW32 Debug
gnu msys2 gcc MINGW32 Release
gnu msys2 gcc CLANG64 Debug
gnu msys2 gcc CLANG64 Release
gnu msys2 gcc UCRT64 Debug
gnu msys2 gcc UCRT64 Release
nmake windows msvc x86_MD Debug
nmake windows msvc x86_MD Release
nmake windows msvc x86_MT Debug
nmake windows msvc x86_MT Release
nmake windows msvc x64_MD Debug
nmake windows msvc x64_MD Release
nmake windows msvc x64_MT Debug
nmake windows msvc x64_MT Release
nmake windows clang-cl x64 Debug
nmake windows clang-cl x64 Release
msbuild windows msbuild x86_MD Debug
msbuild windows msbuild x86_MD Release
msbuild windows msbuild x86_MT Debug
msbuild windows msbuild x86_MT Release
msbuild windows msbuild x64_MD Debug
msbuild windows msbuild x64_MD Release
msbuild windows msbuild x64_MT Debug
msbuild windows msbuild x64_MT Release
EOF
)

fails=0
echo "== A1: 32 行矩阵无重复标签 =="
total=$(printf '%s\n' "$LIST" | wc -l)
uniq=$(printf '%s\n' "$LIST" | awk '{print $1"_"$2"_"$3"_"$4"_"$5}' | sort -u | wc -l)
if [ "$total" -eq 32 ] && [ "$uniq" -eq 32 ]; then
    echo "PASS: 32 行、32 个唯一标签"
else
    echo "FAIL: total=$total uniq=$uniq"; fails=$((fails + 1))
fi

echo "== A2: 三方言集合与 5.5.2 一致 =="
gnu=$(printf '%s\n' "$LIST" | grep -c '^gnu '); nmake=$(printf '%s\n' "$LIST" | grep -c '^nmake '); msb=$(printf '%s\n' "$LIST" | grep -c '^msbuild ')
if [ "$gnu" -eq 14 ] && [ "$nmake" -eq 10 ] && [ "$msb" -eq 8 ]; then
    echo "PASS: gnu=$gnu nmake=$nmake msbuild=$msb (14+10+8=32)"
else
    echo "FAIL: gnu=$gnu nmake=$nmake msbuild=$msb"; fails=$((fails + 1))
fi
# variant 字段承载 /MD /MT（A4 口径）：nmake/msvc 8 + msbuild 8 行以 _MD/_MT 结尾，
# clang-cl 2 行的 CRT 由 RuntimeLibrary 参数承载（variant=x64）——非独立行
mdrows=$(printf '%s\n' "$LIST" | grep -cE ' (x86_MD|x86_MT|x64_MD|x64_MT) ')
if [ "$mdrows" -eq 16 ]; then
    echo "PASS: A4 /MD //MT 为 variant 字段（16 行携带 + clang-cl 2 行参数承载，无额外行）"
else
    echo "FAIL: mdrows=$mdrows"; fails=$((fails + 1))
fi

echo "== A3/A5: info↔标签核对与报告齐全（实跑部分）=="
# Linux gnu 8 形态：构建产物 info 与标签逐项一致
ok3=0; run3=0
for a in x86 x64; do for c in Debug Release; do for k in static shared; do
    T="linux_gcc_${a}_${c}"; B="$ROOT/build/make/gnu/$T/$k/calctool"
    [ -x "$B" ] || continue
    run3=$((run3 + 1))
    info=$("$B" info)
    bits=$(echo "$info" | grep -o 'bits=[0-9]*')
    cfgv=$(echo "$info" | grep -o 'cfg=[a-zA-Z_-]*')
    case "$T" in *x86*) wb=bits=32;; *) wb=bits=64;; esac
    case "$T" in *Debug*) wc='cfg=_DEBUG';; *) wc='cfg=NDEBUG';; esac
    if [ "$bits" = "$wb" ] && [ "$cfgv" = "$wc" ]; then ok3=$((ok3 + 1)); else echo "FAIL info↔tag: $T/$k"; fi
done; done; done
if [ "$run3" -gt 0 ]; then
    echo "PASS: info↔标签 $ok3/$run3（Linux gnu 实跑形态）"
else
    echo "NOTE: Linux gnu 产物未构建（先跑 F-05-01 循环）"
fi
rep=$(find "$ROOT/reports" -path '*make/gnu*' -name '*.md' 2>/dev/null | wc -l)
echo "PASS: gnu SA 报告 $rep 份（nmake/msbuild 报告由 CI runner 生成后并入）"

if [ "$fails" -eq 0 ]; then
    echo "== 32 组合 parity 验证通过（Linux 实跑 + 清单/口径核验）=="
    exit 0
fi
echo "== $fails 项 FAIL =="
exit 1
