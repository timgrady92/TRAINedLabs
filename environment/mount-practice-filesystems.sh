#!/bin/bash
# LPIC-1 Practice Filesystems - Mount Script
# Called by systemd at boot to restore practice filesystem mounts
#
# This script:
# 1. Attaches loop devices to existing image files
# 2. Activates LVM volume group
# 3. Mounts all practice filesystems
# 4. Enables disk quotas
#
# Usage: sudo /opt/LPIC-1/environment/mount-practice-filesystems.sh

# Note: We intentionally don't use 'set -e' here because partial failures
# should not prevent other filesystems from mounting. The script will
# log errors but continue attempting to mount remaining filesystems.
set -uo pipefail

# Configuration
PRACTICE_DIR="/opt/lpic1-practice"
LOOP_DIR="${PRACTICE_DIR}/loop-images"
MOUNT_BASE="/mnt/lpic1"
LVM_VG="lpic1_vg"
LOG_FILE="/var/log/lpic1-mounts.log"

# Track errors (but don't exit on them)
MOUNT_ERRORS=0

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
log_error()   { log ERROR "$@"; MOUNT_ERRORS=$((MOUNT_ERRORS + 1)); }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
fi

# Initialize log
echo "=== LPIC-1 Filesystem Mount ===" >> "$LOG_FILE"
echo "Started: $(date)" >> "$LOG_FILE"

# Check if image files exist
if [[ ! -d "$LOOP_DIR" ]] || [[ ! -f "${LOOP_DIR}/ext4.img" ]]; then
    log_error "Practice filesystem images not found at $LOOP_DIR"
    log_error "Run the installer first: sudo /opt/LPIC-1/install.sh"
    exit 1
fi

log_info "Mounting LPIC-1 practice filesystems..."

# Ensure mount point directories exist
mkdir -p "${MOUNT_BASE}"/{ext4-practice,xfs-practice,btrfs-practice,vfat-practice}
mkdir -p "${MOUNT_BASE}"/{lvm-data,lvm-logs,lvm-backup}
mkdir -p "${MOUNT_BASE}"/quota-test

# Function to check if loop device is in use
loop_in_use() {
    local loop="$1"
    losetup "$loop" &>/dev/null
}

# Function to check if already mounted
is_mounted() {
    local mount="$1"
    mountpoint -q "$mount" 2>/dev/null
}

# Setup loop devices (only if not already attached)
setup_loop_device() {
    local loop="$1"
    local image="$2"
    local name="$3"

    if loop_in_use "$loop"; then
        log_info "$name: Loop device $loop already attached"
        return 0
    fi

    if [[ ! -f "$image" ]]; then
        log_warn "$name: Image file not found: $image"
        return 1
    fi

    if losetup "$loop" "$image" 2>/dev/null; then
        log_success "$name: Attached $loop -> $image"
        return 0
    else
        log_error "$name: Failed to attach $loop"
        return 1
    fi
}

# Setup all loop devices
log_info "Attaching loop devices..."
setup_loop_device /dev/loop10 "${LOOP_DIR}/ext4.img" "ext4"
setup_loop_device /dev/loop11 "${LOOP_DIR}/xfs.img" "xfs"
setup_loop_device /dev/loop12 "${LOOP_DIR}/btrfs.img" "btrfs"
setup_loop_device /dev/loop13 "${LOOP_DIR}/vfat.img" "vfat"
setup_loop_device /dev/loop14 "${LOOP_DIR}/quota.img" "quota"
setup_loop_device /dev/loop15 "${LOOP_DIR}/lvm-pv1.img" "lvm-pv1"
setup_loop_device /dev/loop16 "${LOOP_DIR}/lvm-pv2.img" "lvm-pv2"
setup_loop_device /dev/loop17 "${LOOP_DIR}/lvm-pv3.img" "lvm-pv3"

# Activate LVM volume group
log_info "Activating LVM volume group..."
if vgdisplay "$LVM_VG" &>/dev/null; then
    if vgchange -ay "$LVM_VG" 2>/dev/null; then
        log_success "LVM volume group '$LVM_VG' activated"
    else
        log_warn "LVM activation returned non-zero (may already be active)"
    fi
else
    log_warn "LVM volume group '$LVM_VG' not found - LVM filesystems will not be available"
fi

# Function to mount filesystem
mount_fs() {
    local device="$1"
    local mountpoint="$2"
    local options="${3:-defaults}"
    local name="$4"

    if is_mounted "$mountpoint"; then
        log_info "$name: Already mounted at $mountpoint"
        return 0
    fi

    if [[ ! -e "$device" ]]; then
        log_warn "$name: Device $device not found"
        return 1
    fi

    if mount -o "$options" "$device" "$mountpoint" 2>/dev/null; then
        log_success "$name: Mounted $device -> $mountpoint"
        return 0
    else
        log_error "$name: Failed to mount $device -> $mountpoint"
        return 1
    fi
}

# Mount filesystems
log_info "Mounting filesystems..."
mount_fs /dev/loop10 "${MOUNT_BASE}/ext4-practice" "defaults" "ext4"
mount_fs /dev/loop11 "${MOUNT_BASE}/xfs-practice" "defaults" "xfs"
mount_fs /dev/loop12 "${MOUNT_BASE}/btrfs-practice" "defaults" "btrfs"
mount_fs /dev/loop13 "${MOUNT_BASE}/vfat-practice" "defaults" "vfat"
mount_fs /dev/loop14 "${MOUNT_BASE}/quota-test" "usrquota,grpquota" "quota"

# Mount LVM logical volumes
if vgdisplay "$LVM_VG" &>/dev/null; then
    mount_fs "/dev/${LVM_VG}/lv_data" "${MOUNT_BASE}/lvm-data" "defaults" "lvm-data"
    mount_fs "/dev/${LVM_VG}/lv_logs" "${MOUNT_BASE}/lvm-logs" "defaults" "lvm-logs"
    mount_fs "/dev/${LVM_VG}/lv_backup" "${MOUNT_BASE}/lvm-backup" "defaults" "lvm-backup"
fi

# Enable quotas
log_info "Enabling disk quotas..."
if is_mounted "${MOUNT_BASE}/quota-test"; then
    if quotaon "${MOUNT_BASE}/quota-test" 2>/dev/null; then
        log_success "Quotas enabled on ${MOUNT_BASE}/quota-test"
    else
        log_warn "Could not enable quotas (may need quotacheck first)"
    fi
fi

# Summary
log_info "Mount complete. Summary:"
echo "" >> "$LOG_FILE"
echo "Mounted filesystems:" >> "$LOG_FILE"
df -h "${MOUNT_BASE}"/* 2>/dev/null >> "$LOG_FILE" || true

if [[ -t 1 ]]; then
    echo
    echo -e "${GREEN}Practice filesystems mounted:${NC}"
    df -h "${MOUNT_BASE}"/* 2>/dev/null || echo "  (some filesystems may not be mounted)"
    echo
fi

log_info "Finished: $(date)"

# Exit with success even if some mounts failed - systemd service should not fail
# on partial success, as some filesystems being available is better than none
if [[ $MOUNT_ERRORS -gt 0 ]]; then
    log_warn "Completed with $MOUNT_ERRORS error(s) - some filesystems may not be available"
fi
exit 0
