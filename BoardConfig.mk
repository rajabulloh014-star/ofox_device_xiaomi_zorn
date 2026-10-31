#
# Copyright (C) 2023 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2025 The OrangeFox Recovery Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := kryo

# Bootloader
PRODUCT_PLATFORM := pineapple
TARGET_BOOTLOADER_BOARD_NAME := pineapple
TARGET_NO_BOOTLOADER := true
TARGET_USES_UEFI := true

# Platform
TARGET_BOARD_PLATFORM := pineapple
TARGET_BOARD_PLATFORM_GPU := qcom-adreno750
QCOM_BOARD_PLATFORMS += pineapple

# Assert
TARGET_OTA_ASSERT_DEVICE := zorn

# Kernel
BOARD_KERNEL_PAGESIZE         := 4096
BOARD_KERNEL_IMAGE_NAME       := Image
BOARD_BOOT_HEADER_VERSION     := 4
BOARD_MKBOOTIMG_ARGS          += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS          += --pagesize $(BOARD_KERNEL_PAGESIZE)
TARGET_PREBUILT_KERNEL        := $(DEVICE_PATH)/prebuilt/kernel
BOARD_USES_GENERIC_KERNEL_IMAGE := true

# Ramdisk use lz4
BOARD_RAMDISK_USE_LZ4 := true

# A/B
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true

AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    init_boot \
    vendor_boot \
    dtbo \
    vbmeta \
    vbmeta_system \
    odm \
    product \
    system \
    system_ext \
    system_dlkm \
    vendor \
    vendor_dlkm

# Verified Boot
BOARD_AVB_ENABLE := true

# Partitions
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600

# Dynamic Partition
BOARD_SUPER_PARTITION_SIZE := 11811160064
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 11806965760
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := odm product system system_dlkm system_ext vendor vendor_dlkm

BOARD_PARTITION_LIST := $(call to-upper, $(BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST))
$(foreach p, $(BOARD_PARTITION_LIST), $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := erofs))
$(foreach p, $(BOARD_PARTITION_LIST), $(eval TARGET_COPY_OUT_$(p) := $(call to-lower, $(p))))

BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs

# File systems
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_USES_VENDOR_DLKMIMAGE := true
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true

# Workaround for error copying vendor files to recovery ramdisk
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4

# Recovery
TARGET_SCREEN_DENSITY := 380
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888

# Crypto
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
BOARD_USES_QCOM_FBE_DECRYPTION := true
TW_USE_FSCRYPT_POLICY := 2
TW_INCLUDE_OMAPI := true
BOARD_USES_METADATA_PARTITION := true
PLATFORM_VERSION := 99.87.36
PLATFORM_SECURITY_PATCH := 2127-12-31
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
VENDOR_SECURITY_PATCH   := $(PLATFORM_SECURITY_PATCH)
BOOT_SECURITY_PATCH     := $(PLATFORM_SECURITY_PATCH)

# Board
TARGET_BOARD_INFO_FILE := $(DEVICE_PATH)/board-info.txt
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop

# Tool
AERA_INCLUDE_REPACKTOOLS := true
AERA_INCLUDE_RESETPROP := true
AERA_INCLUDE_LIBRESETPROP := true
AERA_INCLUDE_LPDUMP := true
AERA_INCLUDE_LPTOOLS := true

# Debug
TARGET_USES_LOGD := true
AERA_INCLUDE_LOGCAT := true

# Fastbootd
AERA_INCLUDE_FASTBOOTD := true

# Other AERA Configurations
AERA_THEME := portrait_hdpi
AERA_FRAMERATE := 120
RECOVERY_SDCARD_ON_DATA := true
BOARD_HAS_NO_REAL_SDCARD := true
TARGET_RECOVERY_QCOM_RTC_FIX := true
AERA_EXCLUDE_DEFAULT_USB_INIT := true
AERA_INCLUDE_NTFS_3G := true
AERA_NO_EXFAT_FUSE := true
AERA_USE_TOOLBOX := true
TARGET_USES_MKE2FS := true
AERA_INPUT_BLACKLIST := "hbtp_vm"
AERA_BRIGHTNESS_PATH := "/sys/class/backlight/panel0-backlight/brightness"
AERA_MAX_BRIGHTNESS := 2047
AERA_EXTRA_LANGUAGES := true
AERA_DEFAULT_LANGUAGE := en
AERA_DEFAULT_BRIGHTNESS := 200
AERA_NO_SCREEN_BLANK := true
AERA_EXCLUDE_APEX := true
AERA_HAS_EDL_MODE := true
AERA_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true
AERA_LOAD_VENDOR_BOOT_MODULES := true

# Haptic
AERA_SUPPORT_INPUT_AIDL_HAPTICS := true
AERA_SUPPORT_INPUT_AIDL_HAPTICS_FQNAME := "IVibrator/vibratorfeature"

# --- Modules (Termasuk WiFi) ---
# FIX: Menambahkan mac80211.ko dan wlan_firmware_service.ko
AERA_LOAD_VENDOR_MODULES := "adsp_loader_dlkm.ko focaltech_touch.ko nxp-nci.ko qti_battery_charger.ko xiaomi_touch.ko rfkill.ko cfg80211.ko mac80211.ko wlan_firmware_service.ko gsim.ko rmnet_mem.ko ipam.ko qca_cld3_kiwi_v2.ko"
AERA_POST_DECRYPT_MODULES := "aera_post_decrypt_stage_only.ko"
AERA_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true

# Thermal & Battery
AERA_CUSTOM_CPU_TEMP_PATH := "/sys/class/thermal/thermal_zone48/temp"
AERA_BATTERY_SYSFS_WAIT_SECONDS := 6
