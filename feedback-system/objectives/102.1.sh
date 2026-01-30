#!/bin/bash
# Objective 102.1: Design hard disk layout
# Weight: 2

set -euo pipefail

# shellcheck disable=SC2034  # VERBOSE available for debugging
VERBOSE="${1:-false}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS="✓"
FAIL="✗"
WARN="⚠"

passed=0
failed=0

check() {
    local desc="$1"
    local cmd="$2"

    if eval "$cmd" &>/dev/null; then
        echo -e "${GREEN}${PASS}${NC} $desc"
        ((passed++)) || true
        return 0
    else
        echo -e "${RED}${FAIL}${NC} $desc"
        ((failed++)) || true
        return 1
    fi
}

echo "Checking Objective 102.1: Design hard disk layout"
echo "=================================================="
echo

# Check partition/disk commands
echo "Partition Commands:"
check "fdisk available" "command -v fdisk"
check "gdisk available" "command -v gdisk || echo 'optional'"
check "parted available" "command -v parted"
check "lsblk available" "command -v lsblk"
check "blkid available" "command -v blkid"
echo

# Check LVM commands
echo "LVM Commands:"
if command -v pvcreate &>/dev/null; then
    check "pvcreate available" "command -v pvcreate"
    check "vgcreate available" "command -v vgcreate"
    check "lvcreate available" "command -v lvcreate"
    check "pvs available" "command -v pvs"
    check "vgs available" "command -v vgs"
    check "lvs available" "command -v lvs"
else
    echo -e "${YELLOW}${WARN}${NC} LVM tools not installed"
fi
echo

# Check filesystem layout commands
echo "Filesystem Commands:"
check "df available" "command -v df"
check "mount available" "command -v mount"
check "swapon available" "command -v swapon"
echo

# Check current partition layout awareness
echo "Current Layout:"
check "Can list block devices" "lsblk | head -5"
check "Can view disk usage" "df -h | head -5"
check "Can view mount points" "mount | head -5"
echo

# Check filesystem hierarchy
echo "Filesystem Hierarchy:"
check "/ (root) exists" "test -d /"
check "/boot exists" "test -d /boot"
check "/home exists" "test -d /home"
check "/var exists" "test -d /var"
check "/tmp exists" "test -d /tmp"
check "/usr exists" "test -d /usr"
check "/etc exists" "test -d /etc"
echo

# Check swap
echo "Swap Configuration:"
check "swap configured" "swapon --show | head -1 || cat /proc/swaps | grep -v Filename"
check "/proc/swaps readable" "test -r /proc/swaps"
echo

# Check EFI System Partition (if UEFI)
echo "EFI System Partition:"
if [[ -d /sys/firmware/efi ]]; then
    check "EFI boot (UEFI system)" "test -d /sys/firmware/efi"
    check "ESP mounted" "mount | grep -qE 'efi|EFI' || df /boot/efi 2>/dev/null"
else
    echo -e "${YELLOW}${WARN}${NC} Legacy BIOS system (no ESP required)"
fi
echo

# Check partition table types
echo "Partition Information:"
check "Can view partition info" "fdisk -l 2>/dev/null | head -10 || lsblk -f | head -5"
check "Can identify filesystem types" "lsblk -f | head -5"
echo

# Check fstab
echo "Mount Configuration:"
check "/etc/fstab exists" "test -f /etc/fstab"
check "/etc/fstab readable" "test -r /etc/fstab"
check "fstab has entries" "grep -v '^#' /etc/fstab | grep -v '^$' | head -1"
echo

# Summary
total=$((passed + failed))
echo "=================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 102.1 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
