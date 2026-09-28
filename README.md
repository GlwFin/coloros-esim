# coloros-esim

A KernelSU / Magisk module that adds the native eSIM entry to China ColorOS, allowing you to manage a pluggable physical eUICC card from system Settings.

All files in the module are extracted from the Find X8 (CPH2651) global firmware, with no binary modification.

## Tested on

| Item | Value |
|---|---|
| Device | OnePlus Ace5 Ultimate (MT6991 / Dimensity 9400e) |
| System | ColorOS 16 (China) |

Theoretically works on Dimensity 9400 devices. Do **not** attempt on Snapdragon (Qualcomm) devices.

## What it does

- Adds the native eSIM management entry to system Settings
- Deploys the LPA (eSIM manager app) and its permission configs
- Deploys the eSIM HAL service with proper SELinux labels
- Enables system eSIM properties and Radio layer features

## Deployed files

| Target path | Purpose |
|---|---|
| `/system_ext/priv-app/EuiccGoogle/` | LPA (eSIM manager app) + privapp whitelist |
| `/odm/bin/hw/vendor.oplus.hardware.esim@1.0-service` | eSIM HAL service + dependency |
| `/odm/etc/vintf/manifest/manifest_oplus_esim.xml` | HAL VINTF declaration |
| `/odm/etc/permissions/android.hardware.telephony.euicc.xml` | System feature declaration |
| `/system_ext/etc/permissions/`, `default-permissions/` | LPA permission configs |

## Module structure

```
customize.sh             installer: feature injection and SELinux labels
common/feature_patch.sh  feature injection implementation
initrc/                  init service definition
system/                  deployed files (organized by target path)
system.prop              system properties
```

## Notes

- Slot identification for pluggable eUICC cards depends on the card's ATR announcement (T=15 interface byte per ETSI TS 102 221). Some environments fail to auto-identify; pair this module with a companion LSPosed module or an EasyEuicc switch if needed.

## Releases

Grab the flashable zip from [Releases](https://github.com/GlwFin/coloros-esim/releases).
