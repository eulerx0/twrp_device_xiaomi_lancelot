LOCAL_PATH := device/xiaomi/lancelot

# VNDK & Shipping API (MIUI 12.5.6.0 Android 11 vendor on Android 10 launch)
PRODUCT_TARGET_VNDK_VERSION := 30
PRODUCT_SHIPPING_API_LEVEL := 29

# Health HAL
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service

# FBEv2 Metadata Encryption
PRODUCT_PROPERTY_OVERRIDES += \
    ro.crypto.dm_default_key.options_format.version=2
