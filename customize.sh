#!/system/bin/sh
# Ace5 Ultra eSIM (v1.1: MTK + Qualcomm platform detection)
#
# 1. Detect SoC platform and pick the matching eSIM HAL
# 2. Inject eSIM features into the OPLUS feature config
# 3. Set permissions and SELinux labels for module files

ui_print "- Ace5 Ultra eSIM"

MODDIR=${0%/*}
[ -n "$MODPATH" ] || MODPATH=$MODDIR
BB=""
for c in /data/adb/ksu/bin/busybox /data/adb/magisk/busybox /system/bin/busybox; do
    [ -x "$c" ] && BB="$c" && break
done

# ---------- 0. Platform selection (volume keys) ----------
# 音量上 = MTK / 音量下 = 高通（Magisk 官方模板同款交互方式）
ui_print " "
ui_print "请选择处理器平台："
ui_print "  音量上键 = MTK (天玑)"
ui_print "  音量下键 = 高通 (骁龙)"
ui_print " "

# 用原始键码读取：VOLUMEUP=115, VOLUMEDOWN=114（getevent 数字键码，跨设备稳定）
PLATFORM=mtk
# keycheck 循环：无限等待，直到用户按键
while :; do
    EVT=$(timeout 1 getevent -c 1 2>/dev/null | grep "0001" || true)
    case "$EVT" in
        *"0073"*) PLATFORM=mtk;  break ;;   # KEY_VOLUMEUP
        *"0072"*) PLATFORM=qcom; break ;;   # KEY_VOLUMEDOWN
    esac
done

if [ "$PLATFORM" = "mtk" ]; then
    ui_print "- 已选择: MTK 平台"
else
    ui_print "- 已选择: 高通平台"
fi

# ---------- 1. Inject eSIM features ----------
FEATURE_SRC=
for c in \
    /my_product/etc/extension/com.oplus.oplus-feature.xml \
    /system/my_product/etc/extension/com.oplus.oplus-feature.xml
do
    if [ -r "$c" ] && [ -f "$c" ]; then FEATURE_SRC="$c"; break; fi
done

if [ -z "$FEATURE_SRC" ]; then
    ui_print "! 未找到 OPLUS 特性配置文件，跳过"
else
    DEST_DIR="$MODPATH/system/my_product/etc/extension"
    DEST="$DEST_DIR/com.oplus.oplus-feature.xml"
    TMP="$DEST_DIR/.esim-feature.$$"
    if [ -n "$BB" ]; then $BB mkdir -p "$DEST_DIR"; $BB rm -f "$TMP"; else mkdir -p "$DEST_DIR"; rm -f "$TMP"; fi

    if [ -n "$BB" ]; then
        BUSYBOX="$BB" $BB ash "$MODPATH/common/feature_patch.sh" "$FEATURE_SRC" "$TMP"
    else
        sh "$MODPATH/common/feature_patch.sh" "$FEATURE_SRC" "$TMP"
    fi
    RC=$?

    if [ "$RC" = "0" ] && [ -s "$TMP" ]; then
        if [ -n "$BB" ]; then $BB mv -f "$TMP" "$DEST"; else mv -f "$TMP" "$DEST"; fi
        chmod 0644 "$DEST" 2>/dev/null
        chcon u:object_r:system_file:s0 "$DEST" 2>/dev/null
    else
        if [ -n "$BB" ]; then $BB rm -f "$TMP"; else rm -f "$TMP"; fi
        ui_print "! 特性注入失败"
    fi
fi

# ---------- 2. Deploy platform HAL ----------
# MTK HAL lives in system/odm, Qualcomm HAL in system-qcom/odm.
# Move the matching one into place, drop the other.
if [ "$PLATFORM" = "qcom" ]; then
    ui_print "- Deploying Qualcomm eSIM HAL"
    if [ -n "$BB" ]; then $BB mv -f "$MODPATH/system-qcom/odm/bin/hw/vendor.oplus.hardware.esim@1.0-service" "$MODPATH/system/odm/bin/hw/"; $BB mv -f "$MODPATH/system-qcom/odm/lib64/vendor.oplus.hardware.esim-V1-ndk.so" "$MODPATH/system/odm/lib64/"; else mv -f "$MODPATH/system-qcom/odm/bin/hw/vendor.oplus.hardware.esim@1.0-service" "$MODPATH/system/odm/bin/hw/"; mv -f "$MODPATH/system-qcom/odm/lib64/vendor.oplus.hardware.esim-V1-ndk.so" "$MODPATH/system/odm/lib64/"; fi
else
    ui_print "- Deploying MTK eSIM HAL"
fi
# remove the unused platform dir so nothing stale ships
if [ -n "$BB" ]; then $BB rm -rf "$MODPATH/system-qcom"; else rm -rf "$MODPATH/system-qcom"; fi

# ---------- 3. Permissions ----------
set_perm "$MODPATH/customize.sh" 0 0 0755
set_perm "$MODPATH/common/feature_patch.sh" 0 0 0755
set_perm_recursive "$MODPATH/initrc" 0 0 0755 0644
set_perm "$MODPATH/system/system_ext/priv-app/EuiccGoogle/EuiccGoogle.apk" 0 0 0644
set_perm "$MODPATH/system/system_ext/etc/permissions/privapp_whitelist_com.google.android.euicc.xml" 0 0 0644
set_perm "$MODPATH/system/system_ext/etc/permissions/euicc-restoration.xml" 0 0 0644
set_perm "$MODPATH/system/system_ext/etc/default-permissions/default-permissions-euicc.xml" 0 0 0644
set_perm_recursive "$MODPATH/system/odm" 0 2000 0755 0644
set_perm "$MODPATH/system/odm/bin/hw/vendor.oplus.hardware.esim@1.0-service" 0 2000 0755

# ---------- 4. SELinux labels ----------
chcon u:object_r:system_file:s0 "$MODPATH/system/system_ext/priv-app/EuiccGoogle/EuiccGoogle.apk" 2>/dev/null
chcon u:object_r:system_file:s0 "$MODPATH/system/system_ext/etc/permissions/privapp_whitelist_com.google.android.euicc.xml" 2>/dev/null
chcon u:object_r:system_file:s0 "$MODPATH/system/system_ext/etc/permissions/euicc-restoration.xml" 2>/dev/null
chcon u:object_r:system_file:s0 "$MODPATH/system/system_ext/etc/default-permissions/default-permissions-euicc.xml" 2>/dev/null
chcon u:object_r:vendor_configs_file:s0 "$MODPATH/initrc/esim@1.0-service.rc" 2>/dev/null
chcon u:object_r:vendor_configs_file:s0 "$MODPATH/system/odm/etc/permissions/android.hardware.telephony.euicc.xml" 2>/dev/null
chcon u:object_r:vendor_configs_file:s0 "$MODPATH/system/odm/etc/vintf/manifest/manifest_oplus_esim.xml" 2>/dev/null
chcon u:object_r:vendor_file:s0 "$MODPATH/system/odm/lib64/vendor.oplus.hardware.esim-V1-ndk.so" 2>/dev/null
chcon u:object_r:hal_esim_default_exec:s0 "$MODPATH/system/odm/bin/hw/vendor.oplus.hardware.esim@1.0-service" 2>/dev/null

ui_print "- 完成，重启后生效"
