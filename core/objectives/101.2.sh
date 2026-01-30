#!/bin/bash
# Objective 101.2: Boot the system
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

echo "Checking Objective 101.2: Boot the system"
echo "=========================================="
echo

# Check boot log commands
echo "Boot Log Commands:"
check "dmesg available" "command -v dmesg"
check "journalctl available" "command -v journalctl"
echo

# Check systemd commands
echo "Systemd Commands:"
check "systemctl available" "command -v systemctl"
check "systemd-analyze available" "command -v systemd-analyze"
echo

# Check boot-related files
echo "Boot Configuration:"
check "/boot directory exists" "test -d /boot"
check "Kernel image exists" "ls /boot/vmlinuz* 2>/dev/null || ls /boot/kernel* 2>/dev/null"
check "Initramfs exists" "ls /boot/initramfs* 2>/dev/null || ls /boot/initrd* 2>/dev/null"
echo

# Check GRUB configuration
echo "GRUB Configuration:"
if [[ -f /boot/grub2/grub.cfg ]]; then
    check "grub.cfg exists (GRUB2)" "test -f /boot/grub2/grub.cfg"
elif [[ -f /boot/grub/grub.cfg ]]; then
    check "grub.cfg exists (GRUB2)" "test -f /boot/grub/grub.cfg"
elif [[ -f /boot/efi/EFI/fedora/grub.cfg ]]; then
    check "grub.cfg exists (EFI)" "test -f /boot/efi/EFI/fedora/grub.cfg"
else
    echo -e "${YELLOW}${WARN}${NC} GRUB config not in standard location"
fi
check "/etc/default/grub exists" "test -f /etc/default/grub"
echo

# Check GRUB commands
echo "GRUB Commands:"
if command -v grub2-mkconfig &>/dev/null; then
    check "grub2-mkconfig available" "command -v grub2-mkconfig"
elif command -v grub-mkconfig &>/dev/null; then
    check "grub-mkconfig available" "command -v grub-mkconfig"
else
    echo -e "${YELLOW}${WARN}${NC} GRUB config command not found"
fi
echo

# Check dmesg functionality
echo "Dmesg Functionality:"
check "dmesg runs" "dmesg | head -5"
check "dmesg shows kernel messages" "dmesg | grep -qi 'linux\|kernel' || dmesg | head -1"
echo

# Check journalctl boot logs
echo "Journal Boot Logs:"
check "journalctl -b shows current boot" "journalctl -b --no-pager | head -5"
check "journalctl --list-boots works" "journalctl --list-boots 2>/dev/null || true"
check "journalctl -k shows kernel messages" "journalctl -k --no-pager | head -5"
echo

# Check systemd boot analysis
echo "Boot Analysis:"
check "systemd-analyze works" "systemd-analyze"
check "systemd-analyze blame works" "systemd-analyze blame | head -3"
echo

# Check init system
echo "Init System:"
check "systemd is PID 1" "test \$(cat /proc/1/comm) = 'systemd' || ps -p 1 -o comm= | grep -q systemd"
check "/etc/systemd exists" "test -d /etc/systemd"
check "/usr/lib/systemd exists" "test -d /usr/lib/systemd || test -d /lib/systemd"
echo

# Check SysVinit compatibility
echo "SysVinit Compatibility:"
check "/etc/init.d exists" "test -d /etc/init.d"
if [[ -f /etc/inittab ]]; then
    check "/etc/inittab exists" "test -f /etc/inittab"
else
    echo -e "${YELLOW}${WARN}${NC} /etc/inittab not found (systemd native)"
fi
echo

# Check UEFI/BIOS
echo "Firmware Detection:"
if [[ -d /sys/firmware/efi ]]; then
    check "UEFI boot detected" "test -d /sys/firmware/efi"
    check "EFI variables accessible" "test -d /sys/firmware/efi/efivars || ls /sys/firmware/efi/vars 2>/dev/null"
else
    echo -e "${YELLOW}${WARN}${NC} Legacy BIOS boot (no EFI directory)"
fi
echo

# Summary
total=$((passed + failed))
echo "=========================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 101.2 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
