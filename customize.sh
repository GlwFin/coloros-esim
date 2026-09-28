#!/system/bin/sh
# Ace5 至尊版 eSIM
#
# 1. 注入 eSIM 特性到系统的 OPLUS 特性配置
# 2. 设置模块内文件的权限与 SELinux 标签

ui_print "- Ace5 至尊版 eSIM"

MODDIR=${0%/*}
[ -n "$MODPATH" ] || MODPATH=$MODDIR
BB=""
for c in /data/adb/ksu/bin/busybox /data/adb/magisk/busybox /system/bin/busybox; do
    [ -x "$c" ] && BB="$c" && break
done

# ---------- 1. 注入 eSIM 特性 ----------
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

# ---------- 2. 权限 ----------
set_perm "$MODPATH/customize.sh" 0 0 0755
set_perm "$MODPATH/common/feature_patch.sh" 0 0 0755
set_perm_recursive "$MODPATH/initrc" 0 0 0755 0644
set_perm "$MODPATH/system/system_ext/priv-app/EuiccGoogle/EuiccGoogle.apk" 0 0 0644
set_perm "$MODPATH/system/system_ext/etc/permissions/privapp_whitelist_com.google.android.euicc.xml" 0 0 0644
set_perm "$MODPATH/system/system_ext/etc/permissions/euicc-restoration.xml" 0 0 0644
set_perm "$MODPATH/system/system_ext/etc/default-permissions/default-permissions-euicc.xml" 0 0 0644
set_perm_recursive "$MODPATH/system/odm" 0 2000 0755 0644
set_perm "$MODPATH/system/odm/bin/hw/vendor.oplus.hardware.esim@1.0-service" 0 2000 0755

# ---------- 3. SELinux 标签 ----------
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
