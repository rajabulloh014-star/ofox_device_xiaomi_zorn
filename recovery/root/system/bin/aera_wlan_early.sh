#!/system/bin/sh
# Start WPSS after pd-mapper exposes firmware
PATH=/system/bin:/sbin:/vendor/bin
export PATH
LOG=/tmp/aera_wlan_early.log

log() {
    echo "[aera-wlan-early] uptime=$(cut -d ' ' -f 1 /proc/uptime) $*" >> "$LOG"
    echo "[aera-wlan-early] $*" > /dev/kmsg 2>/dev/null || true
}
fail() { log "STOP: $*"; exit 1; }
prop() { getprop "$1" 2>/dev/null; }

if [ -e /sys/class/net/wlan0 ]; then
    log "wlan0 already present; no WPSS re-boot"
    [ "$(prop wifi.driver.ready)" = true ] || setprop wifi.driver.ready true
    exit 0
fi

log "Early WLAN requested; post.decrypt.modules=$(prop post.decrypt.modules)"

# =========================================================================
# SANGAT PENTING: Buka kunci partisi /vendor agar bisa ditulisi (RW)
# =========================================================================
log "Remounting / and /vendor to RW..."
mount -o rw,remount / 2>> "$LOG"
mount -o rw,remount /vendor 2>> "$LOG"

# 1. Pastikan firmware_mnt ter-mount (Mode RW)
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

# 2. Buat MAC Address
mkdir -p /vendor/firmware/wlan/qca_cld/kiwi_v2
if [ ! -e /tmp/aera_wlan_wpss_requested ]; then
    if [ -x /system/bin/aera-zorn-wlan-mac ]; then
        /system/bin/aera-zorn-wlan-mac >> "$LOG" 2>&1 || log "Failed to generate MAC"
        log "Prepared per-device WLAN MAC file before WPSS boot"
    else
        log "Missing recovery MAC helper /system/bin/aera-zorn-wlan-mac"
    fi
fi

# 3. Nyalakan WPSS (WiFi Chip)
if [ ! -e /tmp/aera_wlan_wpss_requested ]; then
    : > /tmp/aera_wlan_wpss_requested
    log "Requesting WPSS boot"
    if [ -d /sys/kernel/icnss2 ]; then
        echo 1000 > /sys/kernel/icnss2/wlan_en_delay 2>/dev/null
        echo 1 > /sys/kernel/icnss2/wpss_boot 2>/dev/null && log "WPSS started via icnss2"
    elif [ -d /sys/kernel/icnss ]; then
        echo 1000 > /sys/kernel/icnss/wlan_en_delay 2>/dev/null
        echo 1 > /sys/kernel/icnss/wpss_boot 2>/dev/null && log "WPSS started via icnss"
    elif [ -d /sys/kernel/boot_wlan ]; then
        echo 1 > /sys/kernel/boot_wlan/boot 2>/dev/null && log "WPSS started via boot_wlan"
    else
        log "WARNING: Cannot find WPSS boot node!"
    fi
fi

# 4. Tunggu wlan0 muncul
count=0
while [ "$count" -lt 45 ] && [ ! -e /sys/class/net/wlan0 ]; do
    sleep 1
    count=$((count+1))
done

if [ -e /sys/class/net/wlan0 ]; then
    log "wlan0 available after ${count}s; publishing wifi.driver.ready"
    setprop wifi.driver.ready true
else
    fail "wlan0 absent after 45s"
fi
