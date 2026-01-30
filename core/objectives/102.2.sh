#!/bin/bash
# Objective 102.2: Install a boot manager
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

echo "Checking Objective 102.2: Install a boot manager"
echo "================================================="
echo

# Check GRUB commands
echo "GRUB Commands:"
if command -v grub2-install &>/dev/null; then
    check "grub2-install available" "command -v grub2-install"
    check "grub2-mkconfig available" "command -v grub2-mkconfig"
elif command -v grub-install &>/dev/null; then
    check "grub-install available" "command -v grub-install"
    check "grub-mkconfig available" "command -v grub-mkconfig"
else
    echo -e "${YELLOW}${WARN}${NC} GRUB commands not found"
fi
echo

# Check GRUB configuration files
echo "GRUB Configuration Files:"
# Check for grub.cfg in various locations
if [[ -f /boot/grub2/grub.cfg ]]; then
    check "grub.cfg exists" "test -f /boot/grub2/grub.cfg"
elif [[ -f /boot/grub/grub.cfg ]]; then
    check "grub.cfg exists" "test -f /boot/grub/grub.cfg"
elif [[ -f /boot/efi/EFI/fedora/grub.cfg ]]; then
    check "grub.cfg exists (EFI)" "test -f /boot/efi/EFI/fedora/grub.cfg"
elif [[ -f /boot/efi/EFI/debian/grub.cfg ]]; then
    check "grub.cfg exists (EFI)" "test -f /boot/efi/EFI/debian/grub.cfg"
else
    echo -e "${YELLOW}${WARN}${NC} grub.cfg not in standard location"
fi

check "/etc/default/grub exists" "test -f /etc/default/grub"

# Check for grub.d directory
if [[ -d /etc/grub.d ]]; then
    check "/etc/grub.d exists" "test -d /etc/grub.d"
fi
echo

# Check /etc/default/grub contents
echo "GRUB Default Configuration:"
check "GRUB_TIMEOUT defined" "grep -q 'GRUB_TIMEOUT' /etc/default/grub"
check "GRUB_DEFAULT defined" "grep -q 'GRUB_DEFAULT' /etc/default/grub"
check "GRUB_CMDLINE_LINUX defined" "grep -q 'GRUB_CMDLINE_LINUX' /etc/default/grub"
echo

# Check /boot contents
echo "Boot Directory Contents:"
check "/boot directory exists" "test -d /boot"
check "Kernel images present" "ls /boot/vmlinuz* 2>/dev/null || ls /boot/kernel* 2>/dev/null"
check "Initramfs/initrd present" "ls /boot/initramfs* 2>/dev/null || ls /boot/initrd* 2>/dev/null"
echo

# Check MBR/EFI awareness
echo "Boot Method:"
if [[ -d /sys/firmware/efi ]]; then
    check "UEFI boot detected" "test -d /sys/firmware/efi"
    check "EFI partition mounted" "mount | grep -qE '/boot/efi|/efi' || df /boot/efi 2>/dev/null"
    if command -v efibootmgr &>/dev/null; then
        check "efibootmgr available" "command -v efibootmgr"
    fi
else
    echo -e "${YELLOW}${WARN}${NC} Legacy BIOS/MBR boot"
fi
echo

# Check GRUB modules
echo "GRUB Modules:"
if [[ -d /usr/lib/grub ]]; then
    check "GRUB modules directory exists" "test -d /usr/lib/grub"
elif [[ -d /usr/share/grub ]]; then
    check "GRUB modules directory exists" "test -d /usr/share/grub"
fi
echo

# Check grub.d scripts
echo "GRUB Scripts:"
if [[ -d /etc/grub.d ]]; then
    check "00_header exists" "test -f /etc/grub.d/00_header"
    check "10_linux exists" "test -f /etc/grub.d/10_linux"
    check "40_custom exists" "test -f /etc/grub.d/40_custom"
fi
echo

# Summary
total=$((passed + failed))
echo "================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 102.2 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
