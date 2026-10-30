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
loaded() {
    if [ "$1" = qca_cld3_kiwi_v2 ]; then
        grep -Eq '^(qca_cld3_kiwi_v2|wlan) ' /proc/modules 2>/dev/null
    else
        grep -q "^$1 " /proc/modules 2>/dev/null
    fi
}

if [ -e /sys/class/net/wlan0 ]; then
    log "wlan0 already present; no WPSS re-boot"
    [ "$(prop wifi.driver.ready)" = true ] || setprop wifi.driver.ready true
    exit 0
fi
if [ "$(prop ro.aera.fastbootd)" = 1 ] || [ "$(prop ro.aera.fastbootd)" = true ] || \
   [ "$(prop sys.usb.config.aera_fastbootd)" = 1 ]; then
    log "fastbootd: skipping WLAN"
    exit 0
fi

log "Early WLAN requested; post.decrypt.modules=$(prop post.decrypt.modules)"

# 1. Paksa jalankan skrip rfkill
/system/bin/aera_load_rfkill.sh || log "WARNING: RFKill load failed, continuing..."

# 2. Cari dan muat driver WiFi
for mod in cfg80211 qca_cld3_kiwi_v2; do
    loaded "$mod" && continue
    
    candidate=$(find /system_dlkm /vendor_dlkm /vendor /lib/modules -name "$mod.ko" 2>/dev/null | head -n 1)
    
    if [ -z "$candidate" ]; then
        log "WLAN module missing on disk: $mod"
        fail "WLAN module $mod not found"
    fi
    
    if insmod "$candidate" 2>> "$LOG"; then
        log "Loaded WLAN module: $mod from $candidate"
    else
        log "Could not load WLAN module $mod from $candidate"
        fail "Failed to insmod $mod"
    fi
done

# 3. Pastikan firmware_mnt ter-mount (Mount sendiri jika belum)
if ! grep -q " /vendor/firmware_mnt " /proc/mounts; then
    log "Mounting firmware partition manually..."
    mkdir -p /firmware /vendor/firmware_mnt
    SLOT="$(getprop ro.boot.slot_suffix)"
    MODEM_DEV="/dev/block/bootdevice/by-name/modem${SLOT}"
    [ -b "${MODEM_DEV}" ] || MODEM_DEV="/dev/block/by-name/modem${SLOT}"
    
    mount -t vfat -o ro,uid=0,gid=0,fmask=0133,dmask=0022 "${MODEM_DEV}" /firmware
    mount -o bind /firmware /vendor/firmware_mnt
    mount -o remount,bind,ro /vendor/firmware_mnt
fi

# 4. Buat MAC Address
if [ ! -e /tmp/aera_wlan_wpss_requested ]; then
    [ -x /system/bin/aera-zorn-wlan-mac ] || log "Missing recovery MAC helper"
    /system/bin/aera-zorn-wlan-mac >> "$LOG" 2>&1 || log "Failed to generate MAC"
    log "Prepared per-device WLAN MAC file before WPSS boot"
fi

# 5. Nyalakan WPSS (WiFi Chip)
if [ ! -e /tmp/aera_wlan_wpss_requested ]; then
    : > /tmp/aera_wlan_wpss_requested
    log "Requesting WPSS boot"
    echo 1000 > /sys/kernel/icnss/wlan_en_delay || log "Cannot set WLAN delay"
    echo 1 > /sys/kernel/icnss/wpss_boot || log "Cannot start WPSS"
else
    log "WPSS was already requested; waiting without repeating boot"
fi

# 6. Tunggu wlan0 muncul
count=0
while [ "$count" -lt 45 ] && [ ! -e /sys/class/net/wlan0 ]; do
    sleep 1
    count=$((count+1))
done

[ -e /sys/class/net/wlan0 ] || fail "wlan0 absent after 45s"
log "wlan0 available after ${count}s; publishing wifi.driver.ready"
setprop wifi.driver.ready true
