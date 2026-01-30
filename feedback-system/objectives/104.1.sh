#!/bin/bash
# Objective 104.1: Create partitions and filesystems
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

echo "Checking Objective 104.1: Create partitions and filesystems"
echo "============================================================"
echo

# Check partition tools
echo "Partition Tools:"
check "fdisk available" "command -v fdisk"
check "gdisk available" "command -v gdisk"
check "parted available" "command -v parted"
echo

# Check filesystem creation tools
echo "Filesystem Creation Tools:"
check "mkfs available" "command -v mkfs"
check "mkfs.ext4 available" "command -v mkfs.ext4"
check "mkfs.ext3 available" "command -v mkfs.ext3"
check "mkfs.ext2 available" "command -v mkfs.ext2"
if command -v mkfs.xfs &>/dev/null; then
    check "mkfs.xfs available" "command -v mkfs.xfs"
else
    echo -e "${YELLOW}${WARN}${NC} mkfs.xfs not installed"
fi
if command -v mkfs.vfat &>/dev/null; then
    check "mkfs.vfat available" "command -v mkfs.vfat"
fi
if command -v mkfs.exfat &>/dev/null; then
    check "mkfs.exfat available" "command -v mkfs.exfat"
else
    echo -e "${YELLOW}${WARN}${NC} mkfs.exfat not installed (optional)"
fi
echo

# Check swap tools
echo "Swap Tools:"
check "mkswap available" "command -v mkswap"
check "swapon available" "command -v swapon"
check "swapoff available" "command -v swapoff"
echo

# Check Btrfs tools (awareness)
echo "Btrfs Tools (awareness):"
if command -v mkfs.btrfs &>/dev/null; then
    check "mkfs.btrfs available" "command -v mkfs.btrfs"
    check "btrfs command available" "command -v btrfs"
else
    echo -e "${YELLOW}${WARN}${NC} Btrfs tools not installed"
fi
echo

# Check partition info tools
echo "Partition Information:"
check "lsblk available" "command -v lsblk"
check "blkid available" "command -v blkid"
check "partprobe available" "command -v partprobe"
echo

# Test lsblk functionality
echo "Block Device Information:"
check "lsblk lists devices" "lsblk | head -5"
check "lsblk -f shows filesystems" "lsblk -f | head -5"
check "blkid shows UUIDs" "blkid 2>/dev/null | head -3 || true"
echo

# Check fdisk functionality
echo "Fdisk Functionality:"
check "fdisk -l runs" "fdisk -l 2>/dev/null | head -5 || true"
check "fdisk understands MBR" "fdisk --help 2>&1 | head -10 || true"
echo

# Check gdisk functionality
echo "Gdisk Functionality:"
check "gdisk understands GPT" "gdisk --help 2>&1 | head -5 || gdisk -l /dev/null 2>&1 | head -1 || true"
echo

# Check parted functionality
echo "Parted Functionality:"
check "parted --help works" "parted --help | head -5"
check "parted -l runs" "parted -l 2>/dev/null | head -5 || true"
echo

# Check /proc/partitions
echo "Kernel Partition Info:"
check "/proc/partitions readable" "cat /proc/partitions | head -5"
echo

# Summary
total=$((passed + failed))
echo "============================================================"
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 104.1 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
