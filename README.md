# 📸 device_xiaomi_miuicamera-sapphire

**MIUI Camera on AOSP-based ROMs, for the Xiaomi `sapphire` device — with a companion HyperOS Gallery port.**

[![Device](https://img.shields.io/badge/device-sapphire-6E56CF?style=flat-square)](https://github.com/The-Angel-Place-Sapphire/device_xiaomi_miuicamera-sapphire)
[![Camera](https://img.shields.io/badge/MiuiCamera-5.3.001050.2-orange?style=flat-square)](https://github.com/The-Angel-Place-Sapphire/vendor_xiaomi_miuicamera-sapphire)
[![Gallery](https://img.shields.io/badge/Gallery-HyperOS%20port-blue?style=flat-square)](https://github.com/The-Angel-Place-Sapphire/vendor_xiaomi_miuicamera-sapphire)
[![License](https://img.shields.io/badge/license-Apache--2.0-green?style=flat-square)](https://www.apache.org/licenses/LICENSE-2.0)

---

## What this is

This is the **device tree** that plugs Xiaomi's own `MiuiCamera.apk` — and a ported HyperOS Gallery (`MIUIGalleryGlobal.apk`, `com.miui.gallery`) — into an AOSP-based ROM for the `sapphire` device. Xiaomi's camera stack is closed-source and tightly coupled to MIUI/HyperOS; this project decompiles, patches (via smali diffs, tracked as plain patch files) and repackages it so it runs cleanly on top of a custom ROM, alongside the vendor blobs and native libraries it needs.

The proprietary binaries themselves (the APKs and `.so` libraries) live in the companion repo:
➡️ [`vendor_xiaomi_miuicamera-sapphire`](https://github.com/The-Angel-Place-Sapphire/vendor_xiaomi_miuicamera-sapphire)

This repo carries the **device-side glue**: board config, sepolicy, priv-app permissions, hidden-API allowlists, shims — and the full history of `smali` patches applied to the camera and gallery APKs.

## Repository layout

```
device_xiaomi_miuicamera-sapphire/
├── Android.bp                  Soong namespace
├── BoardConfig.mk               Inherits vendor board config, wires sepolicy/system.prop
├── device.mk                    Inherits the vendor product makefile, copies configs
├── system.prop                  Camera-related system properties
├── configs/                     Public library list, priv-app permissions, hidden-API allowlist
├── sepolicy/                    SELinux policy for the camera vendor components
├── shims/                       Compatibility shims
├── extract-files.py             Blob extraction script
├── setup-makefiles.py           Proprietary-files.txt scaffolding
└── patches/                     smali patches applied to MiuiCamera.apk (chronological, 0001–NNNN)
```

## Patches applied to `MiuiCamera.apk`

Each entry below is a numbered `git format-patch`-style diff against MIUI Camera's decompiled smali, kept for history and so future camera version bumps can be re-applied/re-derived.

| # | Patch | What it does |
|---|-------|---------------|
| 0001 | `ICustomCaptureResult: Add readout timestamp` | Adds a missing readout timestamp field used by capture results |
| 0002 | `Assume that mod_device is global` | Fixes a device-detection assumption for non-MIUI builds |
| 0003 | `Add Ultra HDR heic configurations` | Registers Ultra HDR HEIC stream configurations |
| 0004 | `Revert icon to cupid V14.0.2.0.TLCMICM` | Restores an older, better-looking app icon |
| 0005 | `Redo shortcut icon drawables` | Fixes broken launcher shortcut icons |
| 0006 | `Support third party galleries` | Opens the general Gallery entry point via `android.intent.category.APP_GALLERY` instead of hardcoding `com.miui.gallery` |
| 0007 | `Change REVIEW action to the AOSP standard` | Attempted standardization — later found to break the shipped Gallery, see 0013 |
| 0008 | `Read AOSP integer camera_launch_source` | MIUI sends this launch-source as a string; AOSP sends an int — reads both correctly |
| 0009 | `Force enable StartActivityWhenLocked` | AOSP doesn't set this intent extra the way MIUI expects; forces it on |
| 0010 | `Start gallery as a new task` | Prevents the Gallery from being hosted inside the Camera's own task/process |
| 0011 | `Fix low-res photo bug via raw YUV→JPEG bypass` | Works around a downscaled-photo bug in the capture pipeline |
| 0012 | `Fix Nocturno save / hide duplicate "Video corto"` | Cleans up duplicate/incorrect gallery entries from Night mode captures |
| 0013 | **`Fix gallery not opening from the capture thumbnail (camera freeze)`** | See below |

### 🐛 Patch 0013 in detail: the thumbnail → Gallery freeze

**Symptom:** taking a photo, then tapping the capture thumbnail, did nothing — the Gallery never opened and the camera preview stayed frozen/unresponsive.

**Root cause:** patch 0007 changed the thumbnail's "review" intent to use the action `android.provider.action.REVIEW`, which our ported Gallery (`MIUIGalleryGlobal` / `com.miui.gallery`) never registered an `<intent-filter>` for. `startActivity()` threw `ActivityNotFoundException`; the built-in fallback also failed (it targets `com.miui.mediaviewer`, a component this ROM doesn't ship), and both failures were silently swallowed — after the camera had already paused its preview to prepare for the hand-off. Net effect: nothing opens, and the camera looks stuck.

**Fix:** point the intent at `com.android.camera.action.REVIEW`, which the shipped Gallery *does* declare (routing to `ExternalPhotoPageActivity`). An intermediate attempt using `com.miui.camera.action.REVIEW` also fixed the freeze but introduced a **180° rotation** on the opened photo/video — that action routes through `TranslucentExternalPhotoPageActivity`, MIUI's animated camera→gallery transition activity, which reads a `device_orientation` extra to line up its transition animation and misinterprets it on this Gallery build. `com.android.camera.action.REVIEW` skips that transition entirely and just honors the image's EXIF orientation.

## Building

This tree is meant to be `roomservice`d or checked out under `device/xiaomi/miuicamera-sapphire` in your ROM's manifest, alongside `vendor/xiaomi/miuicamera-sapphire`:

```xml
<project path="device/xiaomi/miuicamera-sapphire" name="The-Angel-Place-Sapphire/device_xiaomi_miuicamera-sapphire" remote="github" revision="bka" />
<project path="vendor/xiaomi/miuicamera-sapphire" name="The-Angel-Place-Sapphire/vendor_xiaomi_miuicamera-sapphire" remote="github" revision="sapphire" />
```

Then inherit it from your target device's `device.mk`:

```makefile
$(call inherit-product, device/xiaomi/miuicamera-sapphire/device.mk)
```

### 🔑 Signing / multi-ROM use

`MiuiCamera.apk` and `MIUIGalleryGlobal.apk` are imported via `android_app_import` with `certificate: "platform"` (see `vendor_xiaomi_miuicamera-sapphire/Android.bp`). That means **any** ROM building this tree gets both apps stripped of their checked-in signature and re-signed at build time with whatever key it points `PRODUCT_DEFAULT_DEV_CERTIFICATE` at — Lunaris, AOSPA, Statix, or anyone else, each with their own key.

To keep the repo itself ROM-agnostic, the binaries checked in here carry AOSP's well-known **public** default platform dev key (`build/target/product/security/platform.{pk8,x509.pem}`, `CN=Android`) rather than any one ROM's real private key. It's not secret — every unmodified AOSP checkout ships the exact same key pair — and it only matters if you plan to swap the APK onto an already-running system *without* rebuilding: in that case, re-sign it yourself first with your own ROM's platform key (`apksigner sign --key platform.pk8 --cert platform.x509.pem ...` after `zipalign`) so its signature matches what's already installed.

## Credits

- Original smali patch series by **Arian** (`arian.kulmer@web.de`)
- MIUIGalleryGlobal (HyperOS Gallery) port and packaging by the repo maintainer
- Patch 0013 (thumbnail → Gallery freeze / rotation fix) contributed via Claude

## License

Released under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0), matching the rest of the LineageOS-style device tree ecosystem this project builds on. The proprietary APKs and native libraries in the companion `vendor_xiaomi_miuicamera-sapphire` repo remain the property of Xiaomi Corporation and are redistributed here only as extracted device blobs, as is standard practice for AOSP-based ROM device trees.
