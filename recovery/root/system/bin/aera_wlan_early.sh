#!/system/bin/sh
PATH=/system/bin:/sbin:/vendor/bin
export PATH
LOG=/tmp/aera_wlan_early.log

log() {
    echo "[aera-wlan-early] uptime=$(cut -d ' ' -f 1 /proc/uptime) $*" >> "$LOG"
    echo "[aera-wlan-early] $*" > /dev/kmsg 2>/dev/null || true
}

if [ -e /sys/class/net/wlan0 ]; then
    log "wlan0 already present"
    setprop wifi.driver.ready true
    exit 0
fi

log "=== WLAN Script Started ==="

# 1. BUKA KUNCI /VENDOR AGAR BISA TULIS MAC
log "Remounting / and /vendor to RW..."
mount -o rw,remount / 2>> "$LOG"
mount -o rw,remount /vendor 2>> "$LOG"

# 2. PASTIKAN FIRMWARE TER-MOUNT
if ! grep -q " /vendor/firmware_mnt " /proc/mounts; then
    log "Mounting firmware partition manually..."
    mkdir -p /firmware /vendor/firmware_mnt
    SLOT="$(getprop ro.boot.slot_suffix)"
    MODEM_DEV="/dev/block/bootdevice/by-name/modem${SLOT}"
    [ -b "${MODEM_DEV}" ] || MODEM_DEV="/dev/block/by-name/modem${SLOT}"
    
    mount -t vfat -o rw,uid=0,gid=0,fmask=0133,dmask=0022 "${MODEM_DEV}" /firmware
    mount -o bind /firmware /vendor/firmware_mnt
    mount -o remount,bind,rw /vendor/firmware_mnt
fi

# 3. TULIS MAC ADDRESS
mkdir -p /vendor/firmware/wlan/qca_cld/kiwi_v2
if [ ! -e /tmp/aera_wlan_wpss_requested ]; then
    if [ -x /system/bin/aera-zorn-wlan-mac ]; then
        log "Running MAC generator..."
        /system/bin/aera-zorn-wlan-mac >> "$LOG" 2>&1 || log "ERROR: Failed to generate MAC"
        log "MAC generation finished."
    fi
fi

# 4. NYALAKAN WPSS (CHIP WIFI)
if [ ! -e /tmp/aera_wlan_wpss_requested ]; then
    : > /tmp/aera_wlan_wpss_requested
    log "Requesting WPSS boot..."
    
    if [ -d /sys/kernel/icnss2 ]; then
        echo 1000 > /sys/kernel/icnss2/wlan_en_delay 2>/dev/null
        echo 1 > /sys/kernel/icnss2/wpss_boot 2>/dev/null && log "WPSS started via icnss2"
    elif [ -d /sys/kernel/icnss ]; then
        echo 1000 > /sys/kernel/icnss/wlan_en_delay 2>/dev/null
        echo 1 > /sys/kernel/icnss/wpss_boot 2>/dev/null && log "WPSS started via icnss"
    fi
fi

# 5. TUNGGU WLAN0
count=0
while [ "$count" -lt 30 ] && [ ! -e /sys/class/net/wlan0 ]; do
    sleep 1
    count=$((count+1))
done

if [ -e /sys/class/net/wlan0 ]; then
    log "SUCCESS: wlan0 available after ${count}s"
    setprop wifi.driver.ready true
else
    log "FAILED: wlan0 absent after 30s"
fi
