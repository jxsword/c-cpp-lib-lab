#!/usr/bin/env bash
# verify_card.sh —— 断言验收入口（F-02-05；PLAN 2.6 D1，自本卡起为唯一断言入口）
# 用法: verify_card.sh <卡号>    例: verify_card.sh F-02-01
# 读 tests/assertions/<卡号>.yml 的 checks 块，逐条执行并输出 0.4 回执所需的
# PASS/FAIL 表（Markdown 行）。
#
# 安全设计（Mimosa 命令注入建议采纳）：不执行 yml 中的任意 shell 串——
# yml 的 check 是「受限指令集」：action ∈ {run, grep, filecount, exists}，
# 参数经白名单校验后以参数列表方式调用固定工具，无 shell 中间层。
# expect 语法: exit0 | exit:<n> | regex:<ERE>
# 不调用 GitHub CLI（9.4 J7）。
set -u
# noglob：args 分词不做文件名展开（glob 字面传给受限动作，由其内部引用处理）
set -f

if [ "$#" -ne 1 ]; then
    echo "usage: verify_card.sh <card-id|--all>" >&2
    exit 2
fi
CARD="$1"
YML="$(cd "$(dirname "$0")/.." && pwd)/tests/assertions/$CARD.yml"

# --all：遍历全部断言基线逐卡回归（F-09-09 A3 入口）
if [ "$CARD" = "--all" ]; then
    total_fail=0
    total=0
    # set -f（noglob）下用 find 展开
    while IFS= read -r y; do
        c=$(basename "$y" .yml)
        total=$((total + 1))
        out=$(bash "$0" "$c" < /dev/null 2>&1)
        rc=$?
        line=$(printf '%s\n' "$out" | grep -E 'verify_card:' | tail -1)
        printf '%s\n' "$line"
        [ "$rc" -eq 0 ] || total_fail=$((total_fail + 1))
    done < <(find "$(cd "$(dirname "$0")/.." && pwd)/tests/assertions" -name 'F-*.yml' ! -name 'F-09-09.yml' | sort)
    if [ "$total_fail" -eq 0 ]; then
        echo "--all: $total card baselines, all PASS"
        exit 0
    fi
    echo "--all: $total_fail/$total card(s) FAILED"
    exit 1
fi

if [ ! -f "$YML" ]; then
    echo "FAIL: assertion file not found: $YML" >&2
    exit 1
fi

fails=0
rows=0

printf '| # | 断言 | 检查 | PASS/FAIL |\n'
printf '|---|---|---|---|\n'

# ---- 受限动作执行器：参数化，不经过 shell ----
do_run()
{
    # do_run <命令> [参数...] —— 带斜杠的路径须存在且可执行；纯命令名走 PATH
    local prog="$1"; shift
    case "$prog" in
        */*) [ -x "$prog" ] || { echo "prog not executable: $prog"; return 125; } ;;
    esac
    "$prog" "$@" < /dev/null
}
do_grep()
{
    # do_grep <pattern> <file...> —— ERE，静态文本匹配
    local pat="$1"; shift
    grep -qE -- "$pat" "$@"
}
do_filecount()
{
    # do_filecount <glob-dir> <pattern> <期望数>
    local dir="$1" pat="$2" want="$3"
    local n
    n=$(find "$dir" -name "$pat" 2>/dev/null | wc -l)
    [ "$n" -eq "$want" ]
}
do_exists()
{
    [ -e "$1" ]
}
do_script()
{
    # do_script <脚本路径> [参数...] —— 白名单：仅允许 ./scripts/ 前缀的仓库内可执行脚本
    local prog="$1"; shift
    case "$prog" in
        ./scripts/*) ;;
        *) echo "script action restricted to ./scripts/*: $prog"; return 125 ;;
    esac
    [ -x "$prog" ] || { echo "script not executable: $prog"; return 125; }
    "$prog" "$@"
}

# 解析 checks 块："- id:" 开块，action:/args:/expect: 三键（缩进 4 空格）
id=""; action=""; args=""; expect=""
flush()
{
    [ -n "$id" ] || return 0
    rows=$((rows + 1))
    local out rc ok=0 detail="$action $args"
    out=$(case "$action" in
        run)       do_run $args ;;
        grep)      do_grep $args ;;
        filecount) do_filecount $args ;;
        exists)    do_exists $args ;;
        script)    do_script $args ;;
        *)         echo "unknown action: $action"; exit 125 ;;
    esac 2>&1)
    rc=$?
    case "$expect" in
        exit0)   [ "$rc" -eq 0 ] && ok=1 ;;
        exit:*)  [ "$rc" -eq "${expect#exit:}" ] && ok=1 ;;
        regex:*) printf '%s\n' "$out" | grep -qE -- "${expect#regex:}" && ok=1 ;;
        *)       ok=0 ;;
    esac
    if [ "$ok" = 1 ]; then
        printf '| %s | %s | `%s` | PASS |\n' "$id" "$id" "$detail"
    else
        printf '| %s | %s | `%s` | FAIL (rc=%s, out: %s) |\n' "$id" "$id" "$detail" "$rc" "$(printf '%s' "$out" | head -c 120)"
        fails=$((fails + 1))
    fi
    id=""; action=""; args=""; expect=""
}

while IFS= read -r line; do
    case "$line" in
        '  - id: '*)
            flush
            id=${line#'  - id: '}
            ;;
        '    action: '*)
            action=${line#'    action: '}
            ;;
        '    args: '*)
            args=${line#'    args: '}
            ;;
        '    expect: '*)
            expect=${line#'    expect: '}
            ;;
    esac
done < <(cat "$YML")
# 注意：用 process substitution 预读 yml，防止被检命令（如 gcc -）吞噬循环 stdin；
# 被检命令的 stdin 统一指向 /dev/null
flush

if [ "$fails" -eq 0 ]; then
    printf '\nverify_card: %s — %d checks, all PASS\n' "$CARD" "$rows"
    exit 0
fi
printf '\nverify_card: %s — %d/%d checks FAILED\n' "$CARD" "$fails" "$rows"
exit 1
