#!/system/bin/sh
# 向 OPLUS 特性 XML 注入 eSIM feature（幂等）

set -u

pick() {
    for c in "$@"; do
        [ -n "$c" ] || continue
        if command -v "$c" >/dev/null 2>&1; then echo "$c"; return 0; fi
        if [ -x "$c" ]; then echo "$c"; return 0; fi
    done
    echo ""
}

BB=$(pick "${BUSYBOX:-}" /data/adb/ksu/bin/busybox /data/adb/magisk/busybox /system/bin/busybox)
if [ -n "$BB" ]; then
    AWK="$BB awk"; GREP="$BB grep"; MV="$BB mv"; RM="$BB rm"; MKDIR="$BB mkdir"
else
    A=$(pick awk /system/bin/awk /usr/bin/awk)
    G=$(pick grep /system/bin/grep /usr/bin/grep)
    [ -n "$A" ] && [ -n "$G" ] || { echo "feature_patch: 缺少 awk/grep" >&2; exit 1; }
    AWK="$A"; GREP="$G"; MV="mv"; RM="rm"; MKDIR="mkdir"
fi

fail() { echo "feature_patch: $*" >&2; exit 1; }

[ "$#" -eq 2 ] || fail "usage: feature_patch.sh INPUT OUTPUT"
IN=$1
OUT=$2

[ -r "$IN" ] || fail "无法读取输入: $IN"
[ ! -e "$OUT" ] || fail "输出已存在: $OUT"

$AWK '
BEGIN {
    a = "oplus.software.radio.esim_support"
    b = "oplus.software.radio.esim_support_sn220u"
}
index($0, "name=\"" a "\"")  { have_a = 1 }
index($0, "name=\"" b "\"")  { have_b = 1 }
/^[ \t]*<\/oplus-config>[ \t]*$/ {
    if (!have_a) print "\t<oplus-feature name=\"oplus.software.radio.esim_support\"/>"
    if (!have_b) print "\t<oplus-feature name=\"oplus.software.radio.esim_support_sn220u\"/>"
}
{ print }
' "$IN" > "$OUT" 2>/dev/null || { $RM -f "$OUT"; fail "生成失败"; }

[ -s "$OUT" ] || { $RM -f "$OUT"; fail "输出为空"; }

n1=$($GREP -c 'name="oplus.software.radio.esim_support"/>' "$OUT")
n2=$($GREP -c 'name="oplus.software.radio.esim_support_sn220u"/>' "$OUT")
[ "$n1" = "1" ] || { $RM -f "$OUT"; fail "esim_support 数量=$n1"; }
[ "$n2" = "1" ] || { $RM -f "$OUT"; fail "esim_support_sn220u 数量=$n2"; }

exit 0