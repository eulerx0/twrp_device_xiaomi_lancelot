# TWRP 3.7.1_12 for Xiaomi Redmi 9 (`lancelot`) — Android 15 (crDroid 11.2)

Ready-to-flash **TWRP (`twrp-12.1`)** device tree and prebuilt recovery image for **Xiaomi Redmi 9 (`lancelot`)** running **crDroid 11.2 (Android 15)** on the MIUI `V12.5.6.0.RJCMIXM` (Android 11) vendor, with **working cold-boot Android 15 FBEv2 + Metadata decryption**.

> **Tested & Verified on Real Hardware:**
> Redmi 9 (`lancelot`) · crDroid `11.2` (`crDroidAndroid-15.0-20250215-lancelot-v11.2.zip`) · Beanpod/Microtrust TEE (`keymaster@4.0` + `gatekeeper@1.0`) · Touch (`fts_ts`) · PIN decryption · `/sdcard` access · Dynamic Partitions (`super`).

---

## Prebuilt Download (No Build Required)

Go to the [**Releases page**](https://github.com/eulerx0/twrp_device_xiaomi_lancelot/releases/latest) and download:
- `recovery.img` (`67,108,864` bytes)
- `recovery.img.sha256sum`

Verify integrity before flashing (Windows PowerShell):
```powershell
Get-FileHash .\recovery.img -Algorithm SHA256
```
Or on Linux/macOS:
```bash
sha256sum -c recovery.img.sha256sum
```

---

## What Works

| Feature | Status | Notes |
| --- | --- | --- |
| Cold-boot FBEv2 + Metadata decryption | Working | Prompts for PIN/password automatically (~60–70s initial `/data` scan) |
| Internal Storage (`/sdcard` & `/data`) | Working | Accessible immediately after entering PIN |
| Touchscreen (`fts_ts`) & Brightness | Working | Max brightness `2047`, default `1024` |
| Dynamic Partitions (`super`) & `fastbootd` | Working | Group `main` (`system`, `system_ext`, `vendor`, `product`) |
| ADB, MTP & USB OTG | Working | Active on recovery boot |
| Flashing ZIPs, IMGs & Nandroid Backup | Working | Supports `Boot`, `DTBO`, `Data`, `Recovery`, etc. |

---

## Important Warnings Before Flashing

1. **Back up your original `recovery.img` and MediaTek factory partitions first!**
   If you have root/SSH or an existing recovery, keep a safe copy of `recovery`, `nvram`, `nvdata`, `protect1`, `protect2`, `persist`, and `proinfo`. **Never wipe or format those factory partitions.**
2. **MediaTek (`MT6768`) note:** `fastboot boot recovery.img` is not supported by the bootloader (`unknown command`). You must use `fastboot flash recovery recovery.img`.
3. **Wait ~60–70 seconds on the TWRP logo:** On boot, TWRP decrypts `dm-4` and scans `/data` (`Updating partition details...`) before switching to the PIN screen. Do not force-reboot during that first minute.
4. **"Unmodified System Partition" screen:** Tap **Keep Read Only** unless you specifically need `/system` modifications, to keep crDroid/OTA compatibility intact.

---

## Flashing Instructions

1. Extract `recovery.img` from your original crDroid ROM zip (or back up your current `recovery`) so you always have a fallback.
2. Reboot your phone into **Fastboot** (`adb reboot bootloader` or hold **Volume Down + Power**).
3. Flash and boot TWRP:
   ```bash
   fastboot flash recovery recovery.img
   fastboot reboot recovery
   ```
   *(Alternatively, after `fastboot flash recovery recovery.img`, hold **Volume Up + Power** while running `fastboot reboot` until the Redmi/TWRP logo appears.)*
4. Wait ~60–70 seconds on the TWRP splash screen until the PIN prompt appears, enter your lockscreen PIN, and your files in `/sdcard` will be decrypted.

### Rollback
If you ever want to restore the original ROM recovery:
```bash
fastboot flash recovery original_recovery.img
```

---

## Technical Details & Key Fixes Baked Into This Tree

Getting TWRP working with Android 15 FBEv2 decryption on MediaTek `MT6768` + Microtrust/Beanpod TEE requires four specific fixes included in this repository:

1. **Isolated `/vendor/lib64` `LD_LIBRARY_PATH` ([init.recovery.mt6768.rc](recovery/root/init.recovery.mt6768.rc) & [init.microtrust.rc](recovery/root/init.microtrust.rc)):**
   Android 15 vendor binaries (`teei_daemon`, `android.hardware.keymaster@4.0-service.beanpod`, `android.hardware.gatekeeper@1.0-service`, `vendor.microtrust.hardware.soter@1.0-service`, `bp_kmsetkey_ca`) require `/vendor/lib64` first, whereas TWRP 12.1 `/system/bin/*` binaries (`recovery`, `adbd`, `vold`) crash if loaded against vendor `libc++.so`/`libbase.so`. Global `LD_LIBRARY_PATH` keeps `/system/lib64` first, while each vendor HAL uses `setenv LD_LIBRARY_PATH /vendor/lib64:/vendor/lib64/hw:/system/lib64:/system/lib64/hw`.
2. **Dynamic OS Version & Security Patch Matching ([prep_keymaster.sh](recovery/root/system/bin/prep_keymaster.sh)):**
   Beanpod Keymaster 4.0 rejects decryption with `KM_ERROR_KEY_REQUIRES_UPGRADE (-62 / -38)` when recovery reports `99.87.36` / `2099-12-31`. `prep_keymaster.sh` sets Android 15 defaults in `on post-fs`, waits non-blocking for `hwservicemanager.ready=true` and `vendor.soter.teei.init=INIT_OK`, reads `ro.build.version.release` and `ro.build.version.security_patch` from `/dev/block/mapper/system` if mapped, applies them via `resetprop`, runs `bp_kmsetkey_ca -c`, and triggers `twrp.keymaster.ready=1`.
3. **VINTF Compatibility for TWRP 12.1 `libvintf` ([recovery/root/vendor/etc/vintf](recovery/root/vendor/etc/vintf) & [recovery/root/system/etc/vintf](recovery/root/system/etc/vintf)):**
   Provides `system/etc/vintf` manifests/matrices and normalizes manifest `version="2.0"` and `<sepolicy><version>30.0</version>` so `libvintf` resolves `android.hardware.keymaster@4.0::IKeymasterDevice/default` cleanly.
4. **Boot Image Header v2 & Prebuilt Kernel ([BoardConfig.mk](BoardConfig.mk)):**
   Matched directly to crDroid 11.2 (`header_version=2`, `pagesize=2048`, `base=0x40078000`, `ramdisk_offset=0x07c08000`, `dtb_offset=0x0bc08000`, `64 MB` partition size) with `Image.gz`, `dtb.img`, and `dtbo.img` extracted from crDroid 11.2 (`kernel 4.14.355-openela-proton`).

---

## Building via GitHub Actions

This repository includes a ready-to-run workflow ([.github/workflows/build-twrp.yml](.github/workflows/build-twrp.yml)):

1. **Fork** this repository.
2. Open the **Actions** tab and run **Build TWRP 12.1 (Android 15 Compatible) for Redmi 9 (lancelot)** via **Run workflow**.
3. Wait ~35–55 minutes and download the `twrp-lancelot-a15-twrp12.1` artifact.

> **Why `twrp-12.1`?** The workflow syncs `minimal-manifest-twrp` (`twrp-12.1`), frees runner disk space, allocates up to 12 GB swap on `/mnt`, prunes `.repo`/`.git` after sync, and builds with `GOGC=20`, `GOMEMLIMIT=10GiB`, and `mka recoveryimage -j3` so it completes cleanly inside standard 16 GB GitHub Actions runners.

### Adapting for Another Kernel / ROM Build
- If your ROM uses a different kernel, replace `prebuilt/Image.gz`, `prebuilt/dtb.img`, and `prebuilt/dtbo.img` with the ones unpacked from your target ROM's `recovery.img` (or `boot.img` + `dtbo.img`).
- If your ROM reports a different Android version or security patch date, `prep_keymaster.sh` automatically reads it from `/dev/block/mapper/system` when available, or you can update the fallback values at the top of [prep_keymaster.sh](recovery/root/system/bin/prep_keymaster.sh).

---

## Disclaimer

Flashing custom recovery images always carries risk. Make full backups first—you flash at your own responsibility.
