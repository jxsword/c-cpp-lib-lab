#!/usr/bin/env bash
# check_encoding.sh — D9 编码/换行校验（Unix 侧，PLAN 5.10 / F-00-04）
# 用法: check_encoding.sh [目标目录]   （默认: 仓库根，即本脚本上两级）
# 规则: *.ps1 需 UTF-8 BOM；*.bat/*.cmd 无 BOM 且 CRLF（无裸 LF）；*.sh 无 BOM 且 LF；
#       Makefile.nmake CRLF；全部文件 UTF-8 有效。
# 本脚本不得调用 GitHub CLI（9.4 J7）。
set -u

target="${1:-}"
if [ -z "$target" ]; then
  target="$(cd "$(dirname "$0")/../.." && pwd)"
fi

viol=0
report() { echo "FAIL: $1"; viol=1; }
bom=$'\xef\xbb\xbf'

while IFS= read -r f; do
  rel="${f#"$target"/}"
  case "$rel" in
    *.ps1)          t=ps1 ;;
    *.bat|*.cmd)    t=bat ;;
    *.sh)           t=sh ;;
    Makefile.nmake) t=nmake ;;
    *)              t=other ;;
  esac
  if [ "$t" = other ]; then
    # 非脚本类只做 UTF-8 有效性检查（跳过二进制与空文件）
    [ -s "$f" ] || continue
    [ "$(file --mime-encoding -b "$f")" = binary ] && continue
    iconv -f UTF-8 -t UTF-8 "$f" >/dev/null 2>&1 || report "$rel: 非 UTF-8 编码"
    continue
  fi
  if [ ! -s "$f" ]; then
    [ "$t" = ps1 ] && report "$rel: 空 ps1 缺 UTF-8 BOM"
    continue
  fi
  head3=$(head -c 3 "$f")
  case "$t" in
    ps1)
      [ "$head3" = "$bom" ] || report "$rel: ps1 缺 UTF-8 BOM（前 3 字节非 EF BB BF）" ;;
    bat)
      [ "$head3" != "$bom" ] || report "$rel: bat 有 BOM（禁止，cmd.exe 无法识别）"
      cr=$(tr -dc '\r' < "$f" | wc -c); lf=$(tr -dc '\n' < "$f" | wc -c)
      [ "$cr" -eq "$lf" ] || report "$rel: bat 换行非法（CR=$cr LF=$lf，需 CRLF 且无裸 LF）" ;;
    sh)
      [ "$head3" != "$bom" ] || report "$rel: sh 有 BOM（禁止）"
      cr=$(tr -dc '\r' < "$f" | wc -c)
      [ "$cr" -eq 0 ] || report "$rel: sh 含 CR（需纯 LF）" ;;
    nmake)
      cr=$(tr -dc '\r' < "$f" | wc -c); lf=$(tr -dc '\n' < "$f" | wc -c)
      [ "$cr" -eq "$lf" ] || report "$rel: Makefile.nmake 需 CRLF（CR=$cr LF=$lf）" ;;
  esac
  iconv -f UTF-8 -t UTF-8 "$f" >/dev/null 2>&1 || report "$rel: 非 UTF-8 编码"
done < <(find "$target" -type f \
          -not -path '*/.git/*' -not -path '*/.mimosa/*' -not -path '*/.zcode/*' \
          -not -path '*/build/*' -not -path '*/out/*' \
          -not -path '*/tests/fixtures/corrupt/*' 2>/dev/null | sort)

if [ "$viol" -eq 0 ]; then
  echo "OK: 编码/换行检查全部通过（目标: $target）"
  exit 0
fi
echo "发现违规，exit 1"
exit 1
