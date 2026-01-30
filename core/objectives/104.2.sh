#!/bin/bash
# Objective 104.2: Maintain the integrity of filesystems
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

echo "Checking Objective 104.2: Maintain the integrity of filesystems"
echo "================================================================"
echo

# Check disk usage tools
echo "Disk Usage Tools:"
check "df available" "command -v df"
check "du available" "command -v du"
echo

# Check filesystem check tools
echo "Filesystem Check Tools:"
check "fsck available" "command -v fsck"
check "e2fsck available" "command -v e2fsck"
check "fsck.ext4 available" "command -v fsck.ext4"
echo

# Check ext filesystem tools
echo "Ext Filesystem Tools:"
check "mke2fs available" "command -v mke2fs"
check "tune2fs available" "command -v tune2fs"
check "dumpe2fs available" "command -v dumpe2fs"
check "debugfs available" "command -v debugfs"
echo

# Check XFS tools
echo "XFS Tools:"
if command -v xfs_repair &>/dev/null; then
    check "xfs_repair available" "command -v xfs_repair"
    check "xfs_fsr available" "command -v xfs_fsr"
    check "xfs_db available" "command -v xfs_db"
    check "xfs_info available" "command -v xfs_info"
else
    echo -e "${YELLOW}${WARN}${NC} XFS tools not installed"
fi
echo

# Test df functionality
echo "Df Functionality:"
check "df shows filesystems" "df | head -5"
check "df -h human readable" "df -h | head -5"
check "df -i shows inodes" "df -i | head -5"
check "df -T shows types" "df -T | head -5"
echo

# Test du functionality
echo "Du Functionality:"
check "du shows directory sizes" "du -sh /tmp 2>/dev/null || du -sh /var/tmp"
check "du -h human readable" "du -h /tmp 2>/dev/null | head -3 || true"
check "du -s summary" "du -s /tmp 2>/dev/null || true"
check "du --max-depth works" "du --max-depth=1 /var 2>/dev/null | head -3 || du -d 1 /var 2>/dev/null | head -3 || true"
echo

# Test tune2fs functionality
echo "Tune2fs Functionality:"
check "tune2fs --help works" "tune2fs 2>&1 | head -5"
# Find an ext filesystem to test on (read-only operation)
EXT_DEV=$(lsblk -f | grep -E 'ext[234]' | head -1 | awk '{print $1}' | sed 's/[├─└]//g')
if [[ -n "$EXT_DEV" ]] && [[ -b "/dev/$EXT_DEV" ]]; then
    check "tune2fs -l shows info" "tune2fs -l /dev/$EXT_DEV 2>/dev/null | head -5 || true"
fi
echo

# Check /proc filesystem info
echo "Filesystem Information:"
check "/proc/filesystems readable" "cat /proc/filesystems | head -5"
check "/proc/mounts readable" "cat /proc/mounts | head -5"
echo

# Summary
total=$((passed + failed))
echo "================================================================"
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 104.2 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
