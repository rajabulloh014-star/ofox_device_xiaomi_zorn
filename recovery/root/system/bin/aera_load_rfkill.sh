#!/system/bin/sh
# Ensure RFKill is available before WLAN OR audio modules

SCRIPT_NAME="$(basename "$0")"
LOGMSG() { echo "I:$@" >> /tmp/recovery.log; }
finish() { LOGMSG "---$SCRIPT_NAME end---"; exit "$1"; }
fail() { LOGMSG "ERROR: $*"; finish 1; }
rfkill_loaded() { grep -q '^rfkill ' /proc/modules || [ -d /sys/module/rfkill ]; }

LOGMSG "---$SCRIPT_NAME start---"

if rfkill_loaded; then
    LOGMSG "RFKill already available"
    finish 0
fi

# Cari file rfkill.ko secara agresif
RFKILL_MODULE=$(find /system_dlkm /vendor_dlkm /vendor /lib/modules -name "rfkill.ko" 2>/dev/null | head -n 1)

if [ -z "$RFKILL_MODULE" ]; then
    fail "rfkill.ko not found in any known module paths"
fi

if insmod "$RFKILL_MODULE" 2>> /tmp/recovery.log; then
    if rfkill_loaded; then
        LOGMSG "Loaded RFKill from $RFKILL_MODULE"
        finish 0
    else
        fail "insmod succeeded but RFKill not in /proc/modules"
    fi
else
    fail "insmod failed for $RFKILL_MODULE"
fi
