#!/usr/bin/env bash
# assert_tree.sh —— verify_card.sh 的受限断言子命令集（F-02-05）
# 每个子命令 = 一个固定检查（参数列表，成功 exit 0 / 失败非 0）。
# 管道、循环等 shell 表达力封装在此脚本内（审查面），yml 侧无 shell。
# 不调用 GitHub CLI（9.4 J7）。
set -u

cmd="${1:-}"; shift || true

case "$cmd" in
    # count <dir> <name-pattern> <期望数> —— find|wc 封装
    count)
        n=$(find "$1" -name "$2" 2>/dev/null | wc -l)
        [ "$n" -eq "$3" ]
        ;;
    # countdirs <dir> <深度> <期望数> —— 目录计数（排除 smoke/ 冒烟演练子树）
    countdirs)
        n=$(find "$1" -mindepth "$2" -maxdepth "$2" -type d -not -path '*smoke*' 2>/dev/null | wc -l)
        [ "$n" -eq "$3" ]
        ;;
    # grepeq <pattern> <file...> —— ERE 静态匹配（-a：ELF 等二进制按文本行搜）
    grepeq)
        pat="$1"; shift
        grep -aqE -- "$pat" "$@"
        ;;
    # grepctx <pattern> <after行数> <子pattern> <file> —— 命中后 N 行内再命中
    grepctx)
        pat="$1"; n="$2"; sub="$3"; f="$4"
        grep -A"$n" -E -- "$pat" "$f" | grep -qE -- "$sub"
        ;;
    # notgrep <pattern> <file或目录> —— 不得命中（命中=失败；目录递归）
    notgrep)
        ! grep -qrE -- "$1" "$2"
        ;;
    # elfclass <file> <32|64> —— ELF 类别
    elfclass)
        file "$1" | grep -q "ELF ${2}-bit"
        ;;
    # needed <elf> <lib子串> —— 动态段含该依赖
    needed)
        readelf -d "$1" 2>/dev/null | grep -q "$2"
        ;;
    # notneeded <elf> <lib子串> —— 动态段不含该依赖
    notneeded)
        ! readelf -d "$1" 2>/dev/null | grep -q "$2"
        ;;
    # nmglobal <obj> <type T|B|D> <符号名ERE> <期望数>
    nmglobal)
        n=$(nm "$1" 2>/dev/null | awk -v t="$2" '$2 == t' | grep -cE "$3")
        [ "$n" -eq "$4" ]
        ;;
    # nmsym <obj> <符号> <类型小写> —— 局部符号类型（t/d/b）
    nmsym)
        nm "$1" 2>/dev/null | awk -v s="$2" '$3 == s {print $2}' | grep -qx "$3"
        ;;
    # srcnoartifacts <root> —— D2：源码树无产物
    srcnoartifacts)
        ! find "$1" -path "$1/build" -prune -o -name '*.o' -print 2>/dev/null | grep -q .
        ;;
    # ymlpresent <卡号...> —— 断言文件齐备
    ymlpresent)
        for c in "$@"; do
            [ -f "tests/assertions/$c.yml" ] || exit 1
        done
        ;;
    # selftest <可执行> —— --self-test 退出 0
    selftest)
        "$1" --self-test >/dev/null 2>&1
        ;;
    # bom <file> —— 首 3 字节 EF BB BF
    bom)
        [ "$(head -c 3 "$1" | od -An -tx1 | tr -d ' \n')" = "efbbbf" ]
        ;;
    # crlf <file> —— CRLF 换行（每行均以 CR 结尾）且无 BOM
    crlf)
        cr=$(tr -dc '\r' < "$1" | wc -c)
        lf=$(tr -dc '\n' < "$1" | wc -c)
        [ "$cr" -eq "$lf" ] && [ "$cr" -gt 0 ] && [ "$(head -c 3 "$1" | od -An -tx1 | tr -d ' \n')" != "efbbbf" ]
        ;;
    # cardchecked <卡号> —— PLAN 3.1 中该卡已打勾
    cardchecked)
        grep -qE "^- \[x\] \`$1\`" docs/PLAN.md
        ;;
    # filecount <dir> <name-pattern> <期望数> —— find|wc（pattern 可含通配）
    filecount)
        n=$(find "$1" -name "$2" 2>/dev/null | wc -l)
        [ "$n" -eq "$3" ]
        ;;
    # makevar <名> <值> —— Makefile 的 ?= 变量默认值断言
    makevar)
        grep -qE "^$1[[:space:]]*\?= $2" Makefile
        ;;
    # makenovis <workdir> <srcdir> <variant> <cfg> —— make -n 静态干跑不含可见性旗标
    makenovis)
        w="$1"; s="$2"; v="$3"; c="$4"
        n=$(cd "$w" && make -n -f "$s/Makefile" srcdir="$s" VARIANT="$v" CFG="$c" KIND=static 2>/dev/null | grep -cE 'fPIC|fvisibility')
        [ "$n" -eq 0 ]
        ;;
    # stage3build <out> <cfg-flags...> —— 阶段 3 三源固定编译（noglob 下显式列文件）
    stage3build)
        out="$1"; shift
        g++ -std=c++17 "$@" -Istage3/include \
            stage3/src/vector.cpp stage3/src/stats.cpp stage3/src/main.cpp -o "$out"
        ;;
    # nmclass <obj> <类名> —— nm -C 的类成员 mangled 符号判定
    nmclass)
        nm -C "$1" 2>/dev/null | grep -q "$2"
        ;;
    # nmsymref <elf> <符号> —— 未定义引用判定（nm 的 U 行；卡 A2 未修饰名证据）
    nmsymref)
        nm "$1" 2>/dev/null | grep -qE " U $2\$"
        ;;
    # xmlvalid <file> —— XML 可解析（python minidom）
    xmlvalid)
        python3 -c "import xml.dom.minidom, sys; xml.dom.minidom.parse(sys.argv[1])" "$1"
        ;;
    # wfcount <workflow.yml> <期望组合形态行数> —— 全部 job 的 matrix include 行数累计（YAML 解析）
    wfcount)
        n=$(python3 -c "
import yaml, sys
d = yaml.safe_load(open(sys.argv[1]))
total = 0
for j in d['jobs'].values():
    m = j.get('strategy', {}).get('matrix', {})
    total += len(m.get('include', []))
print(total)
" "$1")
        [ "$n" -eq "$2" ]
        ;;
    # rpath <elf> <子串> —— RUNPATH 值含该子串
    rpath)
        readelf -d "$1" 2>/dev/null | grep RUNPATH | grep -q "$2"
        ;;
    # sacount <报告md> <期望数> —— SA 结论矩阵行数（| SA-n | PASS/FAIL）
    sacount)
        n=$(grep -cE '^\| SA-[0-9]+ \| (PASS|FAIL)' "$1")
        [ "$n" -eq "$2" ]
        ;;
    # errnoonly <目录> <文件> —— 裸符号仅出现在指定源文件（grep -rln 封装）
    errnoonly)
        [ "$(grep -rln "$1" "$2" 2>/dev/null | sort | tr '\n' ' ' | sed 's/ $//')" = "$3" ]
        ;;
    *)
        echo "unknown assert_tree command: $cmd" >&2
        exit 125
        ;;
esac
