#!/bin/bash
# Objective 104.3: Control mounting and unmounting of filesystems
# Weight: 3

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

echo "Checking Objective 104.3: Control mounting and unmounting of filesystems"
echo "========================================================================="
echo

# Check essential commands
echo "Essential Commands:"
check "mount available" "command -v mount"
check "umount available" "command -v umount"
check "lsblk available" "command -v lsblk"
check "blkid available" "command -v blkid"
echo

# Check fstab configuration
echo "Fstab Configuration:"
check "/etc/fstab exists" "test -f /etc/fstab"
check "/etc/fstab readable" "test -r /etc/fstab"
check "fstab has entries" "grep -v '^#' /etc/fstab | grep -v '^$' | head -1"
check "fstab uses UUID or device" "grep -qE 'UUID=|/dev/' /etc/fstab"
echo

# Check mount point directories
echo "Standard Mount Points:"
check "/mnt exists" "test -d /mnt"
check "/media exists" "test -d /media"
echo

# Test mount functionality
echo "Mount Functionality:"
check "mount shows current mounts" "mount | head -5"
check "mount -t shows by type" "mount -t ext4 2>/dev/null || mount -t xfs 2>/dev/null || mount | head -1"
check "findmnt available" "command -v findmnt"
check "findmnt shows mounts" "findmnt | head -5"
echo

# Test lsblk and blkid
echo "Device Information:"
check "lsblk shows devices" "lsblk | head -5"
check "lsblk -f shows filesystems" "lsblk -f | head -5"
check "blkid shows UUIDs" "blkid 2>/dev/null | head -3 || true"
echo

# Check /proc/mounts
echo "Kernel Mount Information:"
check "/proc/mounts readable" "test -r /proc/mounts"
check "/proc/mounts shows mounts" "cat /proc/mounts | head -3"
check "/etc/mtab or symlink" "test -f /etc/mtab || test -L /etc/mtab"
echo

# Check systemd mount units (awareness)
echo "Systemd Mount Units:"
check "systemctl list mount units" "systemctl list-units --type=mount --no-pager | head -5"
check "Can check mount status" "systemctl status tmp.mount 2>/dev/null || systemctl list-units --type=mount | head -1"
echo

# Test UUID/LABEL usage awareness
echo "UUID and LABEL:"
check "lsblk shows UUIDs" "lsblk -o NAME,UUID | head -5"
check "blkid shows LABELs" "blkid -o list 2>/dev/null | head -3 || blkid | head -3"
echo

# Check mount options awareness
echo "Mount Options Awareness:"
check "mount --help shows options" "mount --help 2>&1 | grep -qE 'options|ro|rw'"
check "Can view mount options" "findmnt -o OPTIONS / || mount | grep ' / '"
echo

# Summary
total=$((passed + failed))
echo "========================================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 104.3 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
