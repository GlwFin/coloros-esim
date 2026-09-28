# ColorOS eSIM

作者：**星坠青川**

恢复 ColorOS 的 eSIM 设置入口，可在系统设置中管理插入卡槽的实体 eUICC 卡。

模块内文件全部取自 Find X8（CPH2651）官方固件，未做任何二进制修改。

---

## 模块结构

    customize.sh            安装脚本，负责特性注入与权限标签设置
    common/feature_patch.sh 特性注入实现
    initrc/                 init 服务定义
    system/                 部署文件（按目标路径组织）
    system.prop             系统属性

## 文件落点

| 目标路径 | 固件来源 | 大小 |
|---|---|---|
| `/system_ext/priv-app/EuiccGoogle/EuiccGoogle.apk` | my_product.img | 15,640,835 |
| `/system_ext/etc/permissions/privapp_whitelist_com.google.android.euicc.xml` | my_product.img | 1,443 |
| `/system_ext/etc/permissions/euicc-restoration.xml` | 生成 | 124 |
| `/system_ext/etc/default-permissions/default-permissions-euicc.xml` | my_product.img | 254 |
| `/odm/bin/hw/vendor.oplus.hardware.esim@1.0-service` | odm.img | 52,176 |
| `/odm/lib64/vendor.oplus.hardware.esim-V1-ndk.so` | odm.img | 52,296 |
| `/odm/etc/init/esim@1.0-service.rc` | odm.img | 160 |
| `/odm/etc/permissions/android.hardware.telephony.euicc.xml` | odm.img | 800 |
| `/odm/etc/vintf/manifest/manifest_oplus_esim.xml` | odm.img | 958 |

## 系统属性

    ro.vendor.oplus.radio.esim.feature=2
    setupwizard.feature.esim_enabled=true
    ro.vendor.oplus.esim.support=2

后两项为国内版实测必需，固件内无此配置。

## 特性注入

OPLUS 的 Radio/Telephony 层依据以下 feature 决定是否启用 eSIM 流程：

    oplus.software.radio.esim_support
    oplus.software.radio.esim_support_sn220u

海外版固件自带，国内版缺失。注入流程：

1. 读取设备上的 `/my_product/etc/extension/com.oplus.oplus-feature.xml`
2. 检测两条 feature 是否已存在
3. 缺失时插入到 `</oplus-config>` 之前
4. 输出到模块暂存区并挂载覆盖

不打包成品 XML，特性内容由设备上的原始文件现场生成。
源文件出现重复定义（计数 > 1）时跳过注入，不做推测性修补。

## 挂载机制

全部文件经 KernelSU / Magisk 元模块挂载进入系统，不写入系统分区。

已用挂载表验证：

    overlay on /my_product/etc type overlay (ro)
      lowerdir=/mnt/vendor/<module-work-dir>/my_product/etc:/my_product/etc

`/my_product` 为 erofs 只读分区，无法写入。卸载模块后挂载释放，
系统恢复原状，包括被覆盖的特性 XML（回到固件原始的 15,372 字节版本）。

## SELinux 标签

| 文件 | 标签 |
|---|---|
| system_ext 下的 apk 与权限 xml | `system_file` |
| odm 下的 so | `vendor_file` |
| odm/etc 下的 rc 与 xml | `vendor_configs_file` |
| esim HAL 可执行文件 | `hal_esim_default_exec` |

HAL 使用 `hal_esim_default_exec`：init 依此转入 `hal_esim_default` 域，
该域才具备 esim_en_device / esim_gpio_device / esim_det_device 的访问权限。

## 依赖

仅系统自带工具（toybox 的 sed / grep / awk / cut），不使用 busybox。
