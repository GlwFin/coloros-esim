# coloros-esim

A KernelSU / Magisk module that adds the native eSIM entry to China ColorOS, allowing you to manage a pluggable physical eUICC card from system Settings.

All files in the module are extracted from the Find X8 global firmware, with no binary modification.

## Tested on

| Device | SoC | Result |
|---|---|---|
| OnePlus Ace5 Ultra | Dimensity 9400e | Working |
| OnePlus Ace2 Pro | Snapdragon 8 Gen 2 | Working |

## Requirements

- KernelSU or Magisk
- ColorOS 16 (China)
- eUICC card (eSTK.me, 9eSIM, etc.)
- If the eSIM toggle is unavailable, make sure **both SIM slots have cards inserted** (dual SIM mode activates eSIM)

## Install

Flash the module zip, select your SoC platform with volume keys (MTK = Vol Up, Qualcomm = Vol Down), and reboot.

## Uninstall

Disable and remove the module in the manager, then reboot. The system is fully restored.

## Notes

- Feature injection is generated from the device's own OPLUS feature XML at install time, preserving region-specific features.
- If the eSIM toggle still fails after enabling, a companion LSPosed module (PseudoEuicc) may be needed for slot identification on some devices.

## Releases

Grab the flashable zip from [Releases](https://github.com/GlwFin/coloros-esim/releases).
