# TWRP Device Tree for Xiaomi Redmi 9 (`lancelot`) — crDroid 11.2 (Android 15)

Tailored for `lancelot` running **crDroid 11.2 (Android 15)** with MIUI `V12.5.6.0.RJCMIXM` (Android 11) vendor, kernel `4.14.355-openela-proton`, dynamic partition group `main` (`7516192768` bytes), and Microtrust/Beanpod `keymaster@4.0` + `gatekeeper@1.0`.

## Build
Triggered automatically via GitHub Actions (`.github/workflows/build-twrp.yml`) using `minimal-manifest-twrp` (`twrp-14.1`).

## Safe Flashing
```bash
fastboot flash recovery recovery.img
```
Hold **Volume Up + Power** immediately after flashing to enter TWRP.
If anything fails, re-flash your original crDroid `recovery.img` in Fastboot.
