#!/bin/bash
# LPIC-1 Practice Filesystems - Unmount Script
# Called by systemd at shutdown or manually to cleanly unmount practice filesystems
#
# This script:
# 1. Disables disk quotas
# 2. Unmounts all practice filesystems
# 3. Deactivates LVM volume group
# 4. Detaches loop devices
#
# Usage: sudo /opt/LPIC-1/content/environment/unmount-practice-filesystems.sh

set -euo pipefail

# Configuration
PRACTICE_DIR="/opt/lpic1-practice"
LOOP_DIR="${PRACTICE_DIR}/loop-images"
MOUNT_BASE="/mnt/lpic1"
LVM_VG="lpic1_vg"
LOG_FILE="/var/log/lpic1-mounts.log"

# Colors (for interactive use)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging
log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $level: $msg" >> "$LOG_FILE" 2>/dev/null || true

    # Also output to terminal if interactive
    if [[ -t 1 ]]; then
        case "$level" in
            INFO)  echo -e "${CYAN}[INFO]${NC} $msg" ;;
            OK)    echo -e "${GREEN}[OK]${NC} $msg" ;;
            WARN)  echo -e "${YELLOW}[WARN]${NC} $msg" ;;
            ERROR) echo -e "${RED}[ERROR]${NC} $msg" ;;
        esac
    fi
}

log_info()    { log INFO "$@"; }
log_success() { log OK "$@"; }
log_warn()    { log WARN "$@"; }
log_error()   { log ERROR "$@"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
fi

# Initialize log
echo "=== LPIC-1 Filesystem Unmount ===" >> "$LOG_FILE"
echo "Started: $(date)" >> "$LOG_FILE"

log_info "Unmounting LPIC-1 practice filesystems..."

# Function to check if mounted
is_mounted() {
    local mount="$1"
    mountpoint -q "$mount" 2>/dev/null
}

# Function to unmount filesystem
unmount_fs() {
    local mountpoint="$1"
    local name="$2"

    if ! is_mounted "$mountpoint"; then
        log_info "$name: Not mounted"
        return 0
    fi

    # Disable quotas first if this is the quota filesystem
    if [[ "$mountpoint" == *"quota"* ]]; then
        quotaoff "$mountpoint" 2>/dev/null || true
    fi

    # Sync before unmount
    sync

    # Try regular unmount
    if umount "$mountpoint" 2>/dev/null; then
        log_success "$name: Unmounted $mountpoint"
        return 0
    fi

    # Try lazy unmount if regular fails
    log_warn "$name: Regular unmount failed, trying lazy unmount..."
    if umount -l "$mountpoint" 2>/dev/null; then
        log_success "$name: Lazy unmounted $mountpoint"
        return 0
    fi

    log_error "$name: Failed to unmount $mountpoint"
    return 1
}

# Disable quotas first
log_info "Disabling disk quotas..."
if is_mounted "${MOUNT_BASE}/quota-test"; then
    quotaoff "${MOUNT_BASE}/quota-test" 2>/dev/null && log_success "Quotas disabled" || log_warn "Could not disable quotas"
fi

# Unmount LVM logical volumes first
log_info "Unmounting LVM volumes..."
unmount_fs "${MOUNT_BASE}/lvm-data" "lvm-data"
unmount_fs "${MOUNT_BASE}/lvm-logs" "lvm-logs"
unmount_fs "${MOUNT_BASE}/lvm-backup" "lvm-backup"

# Unmount regular filesystems
log_info "Unmounting loop filesystems..."
unmount_fs "${MOUNT_BASE}/quota-test" "quota"
unmount_fs "${MOUNT_BASE}/vfat-practice" "vfat"
unmount_fs "${MOUNT_BASE}/btrfs-practice" "btrfs"
unmount_fs "${MOUNT_BASE}/xfs-practice" "xfs"
unmount_fs "${MOUNT_BASE}/ext4-practice" "ext4"

# Deactivate LVM volume group
log_info "Deactivating LVM volume group..."
if vgdisplay "$LVM_VG" &>/dev/null; then
    if vgchange -an "$LVM_VG" 2>/dev/null; then
        log_success "LVM volume group '$LVM_VG' deactivated"
    else
        log_warn "Could not deactivate LVM (may have active mounts)"
    fi
else
    log_info "LVM volume group '$LVM_VG' not found"
fi

# Detach loop devices
log_info "Detaching loop devices..."
detach_loop() {
    local loop="$1"
    local name="$2"

    if ! losetup "$loop" &>/dev/null; then
        log_info "$name: $loop not attached"
        return 0
    fi

    if losetup -d "$loop" 2>/dev/null; then
        log_success "$name: Detached $loop"
        return 0
    else
        log_warn "$name: Could not detach $loop"
        return 1
    fi
}

detach_loop /dev/loop10 "ext4"
detach_loop /dev/loop11 "xfs"
detach_loop /dev/loop12 "btrfs"
detach_loop /dev/loop13 "vfat"
detach_loop /dev/loop14 "quota"
detach_loop /dev/loop15 "lvm-pv1"
detach_loop /dev/loop16 "lvm-pv2"
detach_loop /dev/loop17 "lvm-pv3"
detach_loop /dev/loop18 "raid1"
detach_loop /dev/loop19 "raid2"

log_success "Unmount complete"
log_info "Finished: $(date)"

if [[ -t 1 ]]; then
    echo
    echo -e "${GREEN}All practice filesystems unmounted.${NC}"
    echo
fi

exit 0
