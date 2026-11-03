# 📸 device_xiaomi_miuicamera-sapphire

**MIUI Camera (HyperOS Camera) device tree for Redmi Note 13 4G (`sapphire` / `sapphiren`) on AOSP-based ROMs (LineageOS 24.0 / Android 17).**

[![Device](https://img.shields.io/badge/device-sapphire%20%2F%20sapphiren-6E56CF?style=flat-square)](https://github.com/WibuRachSapphireTree/device_xiaomi_miuicamera-sapphire)
[![Platform](https://img.shields.io/badge/Android-17%20%2F%20LineageOS%2024.0-3DDC84?style=flat-square&logo=android)](https://github.com/WibuRachSapphireTree/device_xiaomi_miuicamera-sapphire)
[![Camera](https://img.shields.io/badge/MiuiCamera-HyperOS%20Port-orange?style=flat-square)](https://github.com/WibuRachSapphireTree/vendor_xiaomi_miuicamera-sapphire)
[![License](https://img.shields.io/badge/license-Apache--2.0-green?style=flat-square)](https://www.apache.org/licenses/LICENSE-2.0)

---

## Overview

This repository provides the device-side tree required to integrate Xiaomi's stock **MiuiCamera (HyperOS Camera)** into AOSP-based custom ROMs for the Xiaomi Redmi Note 13 4G (`sapphire` / `sapphiren`, Qualcomm SM6225 Snapdragon 685).

Xiaomi's camera stack is proprietary and tightly coupled with HyperOS framework services and background daemons. This tree bridges the gap through automated Smali bytecode patching, SELinux policies, vendor properties, and hidden-API allowlists, allowing the stock camera app to operate natively on vanilla AOSP.

The proprietary binaries, decompiled APK targets, and prebuilt native libraries are hosted in the companion vendor repository:
➡️ [`vendor_xiaomi_miuicamera-sapphire`](https://github.com/WibuRachSapphireTree/vendor_xiaomi_miuicamera-sapphire)

---

## Working Features

- [x] **Photo Mode**: 12MP binned capture, HDR, Flash, Creative Filters, Beauty, AI scene detection.
- [x] **108MP Ultra HD**: Full sensor readout without the proprietary HyperOS parallel post-proc daemon.
- [x] **Portrait Mode**: Bokeh depth effect blur and aperture adjustment.
- [x] **Night Mode**: Long exposure low-light processing via standard capture sessions.
- [x] **Short Video (MiLive)**: Stable camera session without HAL crashes.
- [x] **Document Mode**: Standalone document scanning and cropping without requiring MiuiGallery.
- [x] **Video Recording**: 1080p / 720p video capture, EIS stabilization, slow motion.
- [x] **Pro Mode**: Manual ISO, shutter speed, EV, manual focus, white balance, and lens selection.
- [x] **Watermarks**: Device watermark (`REDMI Note 13`), timestamp, custom text watermark, and Leica/CV styles via CPU/Skia offline rendering.
- [x] **Gallery Support**: Seamless integration with both third-party galleries (AOSP, Google Photos) and HyperOS Gallery.
- [x] **Modern UI**: Adaptive icon and monochrome themed icon for Material You.

---

## Repository Layout

```
device_xiaomi_miuicamera-sapphire/
├── Android.bp                  # Soong namespace and package definitions
├── BoardConfig.mk              # Inherits vendor board config, sepolicy, and system.prop
├── device.mk                   # Inherits vendor product makefiles and config copying
├── system.prop                 # Camera-specific vendor system properties
├── configs/                    # Priv-app permissions, hidden-API allowlists, public libraries
├── sepolicy/                   # SELinux policies for camera vendor components
├── extract-files.py            # Blob extraction and automated smali patch script
├── setup-makefiles.py          # Proprietary files scaffolding generator
└── patches/                    # Chronological smali patches (0001–0020) applied to MiuiCamera.apk
```

---

## Patches Applied to `MiuiCamera.apk`

All modifications to `MiuiCamera.apk` are tracked as clean, reproducible `git format-patch` diffs under `patches/`:

| # | Patch | Summary |
|:---:|---|---|
| **0001** | `Support third party galleries + start gallery as new task` | Opens standard gallery intents (`APP_GALLERY`) and isolates gallery in a separate task. |
| **0002** | `Force enable StartActivityWhenLocked + read AOSP int` | Handles AOSP integer `camera_launch_source` and enables lockscreen camera launch. |
| **0003** | `Assume that mod_device is global` | Normalizes regional device detection for custom ROMs. |
| **0004** | `Support 13-arg CaptureResultExtras constructor` | Adapts capture result extras for modern Android framework APIs (Android 15+). |
| **0005** | `Disable parallel processing and preview thumbnail` | Disables proprietary ChiNode background parallel daemon for instant capture. |
| **0006** | `MiuiCamera: Add adaptive icon and monochrome themed icon` | Adds modern Material You monochrome and adaptive launcher icons. |
| **0007** | `FragmentBeauty: Support beauty type 1 and prevent crash` | Fixes NPE crashes when opening Beauty controls on AOSP. |
| **0008** | `Disable parallel processing in night and other modules` | Ensures Night and specialized modules route capture data directly through HAL streams. |
| **0009** | `Fix portrait mode depth stream and night mode raw capture` | Bypasses unhandled depth and raw stream requests that caused camera HAL capture hangs. |
| **0010** | `Fix shortcut menu crash, portrait capture and night capture` | Fixes QuickSettings shortcut menu crashes and aligns shot types. |
| **0011** | `Fix NullPointerException and corrupted image when saving watermark` | Prevents crash and corruption during Exif extraction on JPEG capture buffers. |
| **0012** | `Force standard session operating mode for Night mode` | Replaces proprietary session operating modes (`0xef03` / `0xef08`) with standard `0x0`. |
| **0013** | `MiuiCamera: Support 108MP Ultra Pixel capture without parallel daemon` | Connects 108MP raw stream output directly to offline saver for full-res capture. |
| **0014** | `MiuiCamera: Load xiaomi.scaler.availableStreamConfigurations` | Parses Xiaomi vendor scaler tags to resolve accurate resolution lists. |
| **0015** | `MiuiCamera: Force standard session operating mode for Short Video` | Fixes SIGSEGV crash in `libmorpho_video_stabilizer` when entering Short Video mode. |
| **0016** | `MiuiCamera: Support standalone Document mode without MiuiGallery` | Allows Document scanning mode to function without proprietary `com.miui.gallery`. |
| **0017** | `MiuiCamera: Fix 108MP resolution selection in normal photo mode` | Prevents Photo mode from selecting 108MP when standard 12MP binned mode is desired. |
| **0018** | `MiuiCamera: Suppress masterCameraId lookup spam in preview callback` | Eliminates repetitive logcat spam caused by missing vendor metadata tags. |
| **0019** | `MiuiCamera: Fix portrait bokeh blur and prevent capture hang` | Corrects portrait shot type to trigger dual-camera bokeh and handles optional depth maps. |
| **0020** | `MiuiCamera: Enable offline watermark and filter rendering` | Routes watermarked shots through Skia/RenderEngine offline pipeline on Qualcomm bengal. |

---

## Building

Add the device tree and vendor tree to your local manifest (e.g. `.repo/local_manifests/sapphire.xml`):

```xml
<manifest>
    <project path="device/xiaomi/miuicamera-sapphire" name="WibuRachSapphireTree/device_xiaomi_miuicamera-sapphire" remote="github" revision="lineage-24.0" />
    <project path="vendor/xiaomi/miuicamera-sapphire" name="WibuRachSapphireTree/vendor_xiaomi_miuicamera-sapphire" remote="github" revision="lineage-24.0" />
</manifest>
```

Then inherit the device configuration in your target ROM's `device.mk`:

```makefile
# MiuiCamera
$(call inherit-product, device/xiaomi/miuicamera-sapphire/device.mk)
```

---

## Extracting & Regenerating Blobs

To re-extract proprietary files from a stock HyperOS dump and automatically apply all patches:

```bash
cd device/xiaomi/miuicamera-sapphire
./extract-files.py /path/to/sapphire_dump/out
```

The script will unpack `MiuiCamera.apk`, sequentially apply all 20 patches in `patches/`, rebuild the APK with `apktool`, and place the resulting blobs into `vendor/xiaomi/miuicamera-sapphire`.

---

## License

* Device tree configuration, makefiles, and Smali patches: [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
* Proprietary camera APKs and vendor libraries remain the property of Xiaomi Corporation and are redistributed strictly for personal, non-commercial use on compatible devices.
