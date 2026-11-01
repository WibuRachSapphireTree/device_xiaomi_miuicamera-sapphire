#
# Copyright (C) 2023 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/xiaomi/miuicamera-sapphire

# Inherit from the proprietary version
$(call inherit-product, vendor/xiaomi/miuicamera-sapphire/miuicamera-sapphire-vendor.mk)

# Public libraries
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/public.libraries-xiaomi.txt:$(TARGET_COPY_OUT_SYSTEM)/etc/public.libraries-xiaomi.txt

# Priv-app permission
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/privapp-permissions-miuicamera.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/privapp-permissions-miuicamera.xml

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Sysconfig
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/miuicamera-hiddenapi-package-allowlist.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/sysconfig/miuicamera-hiddenapi-package-allowlist.xml

# Patch
PRODUCT_COPY_FILES := $(filter-out vendor/xiaomi/sapphire/proprietary/vendor/lib64/camera/components/com.jigan.node.realtimebokeh.so:%,$(PRODUCT_COPY_FILES))
PRODUCT_COPY_FILES += \
    vendor/xiaomi/miuicamera-sapphire/proprietary/vendor/lib64/camera/components/com.jigan.node.realtimebokeh.so:$(TARGET_COPY_OUT_VENDOR)/lib64/camera/components/com.jigan.node.realtimebokeh.so
