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
AERA_MAINTAINER := Jonas Salo & Daniel Springer
AERA_UI_ADAPTIVE_RESOLUTION := true
AERA_SCREEN_H := 2400
AERA_STATUS_H := 114
AERA_STATUS_INDENT_LEFT := 50
AERA_STATUS_INDENT_RIGHT := 50
AERA_HIDE_NOTCH := 1
AERA_CLOCK_POS := 1
AERA_USE_GREEN_LED := 0
AERA_ALLOW_DISABLE_NAVBAR := 0
AERA_OPTIONS_LIST_NUM := 11
AERA_USE_LOCKSCREEN_BUTTON := 1
AERA_USE_MISANS_FONTS := 1
AERA_AB_DEVICE_WITH_RECOVERY_PARTITION := 1
AERA_VAB_ORS_WIPE_DATA_IS_FORMAT := 1
AERA_DYNAMIC_FULL_SIZE := 11811160064
AERA_QUICK_BACKUP_LIST := /boot;/data;
AERA_ENABLE_ALL_PARTITION_TOOLS := 1
AERA_USE_DMCTL := 1
AERA_USE_AIDL_BOOT_CONTROL := 1
AERA_DISPLAY_FORMAT_FILESYSTEMS_DEBUG_INFO := 1
AERA_NO_TREBLE_COMPATIBILITY_CHECK := 1
AERA_LOOP_DEVICE_ERRORS_TO_LOG := 1
AERA_DONT_KEEP_LOG_HISTORY := 1
AERA_BIND_MOUNT_SDCARD_ON_FORMAT := 1
AERA_DISABLE_ORS_AUTO_REBOOT := 1
AERA_NO_RELOAD_AFTER_DECRYPTION := 1
AERA_UNBIND_SDCARD_F2FS := 1
AERA_UNMOUNT_SDCARDS_BEFORE_REBOOT := 1
AERA_WIPE_METADATA_AFTER_DATAFORMAT := 1
AERA_FORCE_DATA_FORMAT_F2FS := 1
AERA_FORCE_CASEFOLDING := 1
AERA_FLASHLIGHT_ENABLE := 1
AERA_FL_PATH1 := /tmp/flashlight
AERA_FORCE_PREBUILT_KERNEL := 1
# lz4 compression
AERA_USE_LZ4_COMPRESSION := 1
ifeq ($(FIXED_DECRYPT),false)
	# Set to 1 to skip the FBE decryption routines when device-specific crypto hangs.
	AERA_SKIP_FBE_DECRYPTION := 1
endif
# Use this to change the default time zone
AERA_DEFAULT_TIMEZONE := GMT0;BST,M3.5.0,M10.5.0
# Set this to 1 to remove the toggleable "Reflash AERA after flashing a ROM" option.
# Implemented forced method using /system/bin/pre_rom_flash.sh and .../post_rom_flash.sh
# AERA_NO_REFLASH_CURRENT_RECOVERY := 1
# Set this to 1 to include an addon for removing factory reset protection (FRP)
AERA_ENABLE_FRP_WIPE := 1
# Set to 1 to include WLAN features
AERA_ENABLE_WLAN := 1
# Set to 1 to enable the flashlight feature
AERA_FLASHLIGHT_ENABLE := 1
AERA_FL_PATH1 := /tmp/flashlight
