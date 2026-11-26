#!/system/bin/sh
# Ensure Beanpod Keymaster 4.0 sees the running ROM's OS version & security patch
# (avoids KM_ERROR_KEY_REQUIRES_UPGRADE -62 / -38 on Android 15 metadata encryption)

OS_REL="15"
SEC_PATCH="2025-02-05"

# Wait up to 15s for hwservicemanager and Microtrust TEE initialization
i=0
while [ $i -lt 75 ]; do
    HWS=$(getprop hwservicemanager.ready)
    TEE=$(getprop vendor.soter.teei.init)
    if [ "$HWS" = "true" ] && [ "$TEE" = "INIT_OK" ]; then
        break
    fi
    sleep 0.2
    i=$((i + 1))
done

if [ -e /dev/block/mapper/system ]; then
    mkdir -p /mnt_sys_tmp
    if mount -t ext4 -o ro /dev/block/mapper/system /mnt_sys_tmp 2>/dev/null; then
        BPROP=""
        if [ -f /mnt_sys_tmp/system/build.prop ]; then
            BPROP="/mnt_sys_tmp/system/build.prop"
        elif [ -f /mnt_sys_tmp/build.prop ]; then
            BPROP="/mnt_sys_tmp/build.prop"
        fi
        if [ -n "$BPROP" ]; then
            R=$(grep -m1 '^ro\.build\.version\.release=' "$BPROP" | cut -d= -f2 | tr -d '\r\n')
            P=$(grep -m1 '^ro\.build\.version\.security_patch=' "$BPROP" | cut -d= -f2 | tr -d '\r\n')
            [ -n "$R" ] && OS_REL="$R"
            [ -n "$P" ] && SEC_PATCH="$P"
        fi
        umount /mnt_sys_tmp 2>/dev/null || true
    fi
    rmdir /mnt_sys_tmp 2>/dev/null || true
fi

/system/bin/resetprop ro.build.version.release "$OS_REL"
/system/bin/resetprop ro.build.version.security_patch "$SEC_PATCH"
/system/bin/resetprop ro.vendor.build.security_patch "$SEC_PATCH"

LD_LIBRARY_PATH=/vendor/lib64:/vendor/lib64/hw:/system/lib64:/system/lib64/hw /vendor/bin/bp_kmsetkey_ca -c >/dev/null 2>&1 || true
setprop twrp.keymaster.ready 1
