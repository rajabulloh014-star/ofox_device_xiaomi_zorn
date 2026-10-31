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

# =========================================================================
# BAGIAN 1: PEMUATAN MODUL KERNEL (MENGIKUTI modules.softdep)
# =========================================================================
# AERA mengabaikan modul GKI (rfkill, cfg80211) saat build.
# Kita harus memuatnya manual secara berurutan agar tidak error.

load_module() {
    MOD_NAME="$1"
    if ! grep -q "^${MOD_NAME} " /proc/modules && [ ! -d "/sys/module/${MOD_NAME}" ]; then
        # Cari file .ko (Prioritaskan /lib/modules sesuai temuan di Terminal)
        MOD_FILE=$(find /lib/modules /vendor/lib/modules /system_dlkm/lib/modules -name "${MOD_NAME}.ko" 2>/dev/null | head -n 1)
        
        if [ -n "$MOD_FILE" ]; then
            insmod "$MOD_FILE" 2>> "$LOG"
            if [ $? -eq 0 ]; then
                log "Berhasil memuat $MOD_NAME dari $MOD_FILE"
            else
                log "ERROR: Gagal memuat $MOD_NAME dari $MOD_FILE"
            fi
        else
            log "ERROR: File ${MOD_NAME}.ko tidak ditemukan!"
        fi
    else
        log "$MOD_NAME sudah termuat"
    fi
}

# Urutan ini WAJIB sesuai dengan aturan modules.softdep Qualcomm
log "Memuat modul kernel secara berurutan..."
load_module "rfkill"
load_module "cfg80211"
load_module "mac80211"
load_module "wlan_firmware_service"

# Muat driver WLAN utama (biasanya namanya dinamis, cari qca_cld3)
WLAN_DRV_NAME="qca_cld3_kiwi_v2"
WLAN_DRV_FILE=$(find /lib/modules /vendor/lib/modules -name "qca_cld3_*.ko" 2>/dev/null | head -n 1)
if [ -n "$WLAN_DRV_FILE" ] && ! grep -q "qca_cld3" /proc/modules; then
    insmod "$WLAN_DRV_FILE" 2>> "$LOG"
    log "Memuat driver WLAN: $WLAN_DRV_FILE"
fi

# Beri jeda 1 detik agar kernel selesai memproses pendaftaran modul
sleep 1

# =========================================================================
# BAGIAN 2: PERSIAPAN HARDWARE & FIRMWARE
# =========================================================================

# 1. BUKA KUNCI /VENDOR AGAR BISA TULIS MAC
log "Remounting / dan /vendor ke RW..."
mount -o rw,remount / 2>> "$LOG"
mount -o rw,remount /vendor 2>> "$LOG"

# 2. PASTIKAN FIRMWARE TER-MOUNT
if ! grep -q " /vendor/firmware_mnt " /proc/mounts; then
    log "Mounting partisi firmware secara manual..."
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
        log "Menjalankan generator MAC..."
        /system/bin/aera-zorn-wlan-mac >> "$LOG" 2>&1 || log "ERROR: Gagal generate MAC"
        log "Generate MAC selesai."
    fi
fi

# 4. NYALAKAN WPSS (CHIP WIFI)
if [ ! -e /tmp/aera_wlan_wpss_requested ]; then
    : > /tmp/aera_wlan_wpss_requested
    log "Meminta WPSS boot (Hardware)..."
    
    if [ -d /sys/kernel/icnss2 ]; then
        echo 1000 > /sys/kernel/icnss2/wlan_en_delay 2>/dev/null
        echo 1 > /sys/kernel/icnss2/wpss_boot 2>/dev/null && log "WPSS dinyalakan via icnss2"
    elif [ -d /sys/kernel/icnss ]; then
        echo 1000 > /sys/kernel/icnss/wlan_en_delay 2>/dev/null
        echo 1 > /sys/kernel/icnss/wpss_boot 2>/dev/null && log "WPSS dinyalakan via icnss"
    fi
fi

# =========================================================================
# BAGIAN 3: TUNGGU INTERFACE WLAN0
# =========================================================================
count=0
while [ "$count" -lt 30 ] && [ ! -e /sys/class/net/wlan0 ]; do
    sleep 1
    count=$((count+1))
done

if [ -e /sys/class/net/wlan0 ]; then
    log "SUKSES: wlan0 tersedia setelah ${count}s"
    setprop wifi.driver.ready true
else
    log "GAGAL: wlan0 tidak muncul setelah 30s"
fi
