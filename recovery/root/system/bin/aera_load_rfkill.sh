#!/system/bin/sh
# Ensure RFKill is available before WLAN OR audio modules

SCRIPT_NAME="$(basename "$0")"
LOGMSG() {
    echo "I:$@" >> /tmp/recovery.log
}

finish() {
    LOGMSG "---$SCRIPT_NAME end---"
    exit "$1"
}

fail() {
    LOGMSG "ERROR: $*"
    finish 1
}

rfkill_loaded() {
    grep -q '^rfkill ' /proc/modules || [ -d /sys/module/rfkill ]
}

LOGMSG "---$SCRIPT_NAME start---"

if rfkill_loaded; then
    LOGMSG "RFKill already available"
    finish 0
fi

SLOT="$(getprop ro.boot.slot_suffix)"
case "$SLOT" in
    _a|_b) ;;
    *) fail "Invalid active slot: $SLOT" ;;
esac

# Cek semua kemungkinan lokasi rfkill.ko
for MODULE in \
    /system_dlkm/lib/modules/6.1*/kernel/net/rfkill/rfkill.ko \
    /system_dlkm/lib/modules/rfkill.ko \
    /vendor_dlkm/lib/modules/6.1*/kernel/net/rfkill/rfkill.ko \
    /vendor_dlkm/lib/modules/rfkill.ko \
    /vendor/lib/modules/6.1*/kernel/net/rfkill/rfkill.ko \
    /vendor/lib/modules/rfkill.ko; do
    
    [ -f "$MODULE" ] || continue

    if rfkill_loaded; then
        LOGMSG "RFKill was loaded by another service"
        finish 0
    fi

    insmod "$MODULE"
    rfkill_loaded || fail "Unable to load RFKill from $MODULE"
    LOGMSG "Loaded RFKill from $MODULE"
    finish 0
done

fail "rfkill.ko not found in any known module paths"
