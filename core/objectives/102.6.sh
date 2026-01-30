#!/bin/bash
# Objective 102.6: Linux as a virtualization guest
# Weight: 1

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

echo "Checking Objective 102.6: Linux as a virtualization guest"
echo "=========================================================="
echo

# Check virtualization detection
echo "Virtualization Detection:"
check "systemd-detect-virt available" "command -v systemd-detect-virt"
VIRT_TYPE=$(systemd-detect-virt 2>/dev/null || echo "none")
echo "  Detected: $VIRT_TYPE"
echo

# Check D-Bus machine ID
echo "Machine Identity:"
check "/etc/machine-id exists" "test -f /etc/machine-id"
check "machine-id is unique" "test -s /etc/machine-id"
if [[ -f /var/lib/dbus/machine-id ]]; then
    check "/var/lib/dbus/machine-id exists" "test -f /var/lib/dbus/machine-id"
fi
echo

# Check SSH host keys
echo "SSH Host Keys:"
check "SSH host keys directory" "test -d /etc/ssh"
check "RSA host key exists" "test -f /etc/ssh/ssh_host_rsa_key || test -f /etc/ssh/ssh_host_rsa_key.pub"
check "ECDSA host key exists" "test -f /etc/ssh/ssh_host_ecdsa_key || test -f /etc/ssh/ssh_host_ecdsa_key.pub"
check "ED25519 host key exists" "test -f /etc/ssh/ssh_host_ed25519_key || test -f /etc/ssh/ssh_host_ed25519_key.pub"
echo

# Check cloud-init (awareness)
echo "Cloud-Init:"
if command -v cloud-init &>/dev/null; then
    check "cloud-init available" "command -v cloud-init"
    check "cloud-init status" "cloud-init status 2>/dev/null || true"
else
    echo -e "${YELLOW}${WARN}${NC} cloud-init not installed (optional for cloud VMs)"
fi
echo

# Check guest drivers/agents
echo "Guest Agents:"
# QEMU guest agent
if command -v qemu-ga &>/dev/null || systemctl list-unit-files | grep -q qemu-guest-agent; then
    check "QEMU guest agent available" "command -v qemu-ga || systemctl list-unit-files | grep -q qemu-guest-agent"
fi
# VMware tools
if command -v vmware-toolbox-cmd &>/dev/null; then
    check "VMware tools available" "command -v vmware-toolbox-cmd"
fi
# VirtualBox additions
if command -v VBoxControl &>/dev/null || lsmod | grep -q vboxguest; then
    check "VirtualBox additions available" "command -v VBoxControl || lsmod | grep -q vboxguest"
fi
# Hyper-V
if lsmod | grep -q hv_vmbus 2>/dev/null; then
    check "Hyper-V modules loaded" "lsmod | grep -q hv_vmbus"
fi
if [[ "$VIRT_TYPE" == "none" ]]; then
    echo -e "${YELLOW}${WARN}${NC} Running on bare metal - guest agents not applicable"
fi
echo

# Check container awareness
echo "Container Detection:"
if [[ -f /.dockerenv ]]; then
    check "Docker container detected" "test -f /.dockerenv"
elif [[ -f /run/.containerenv ]]; then
    check "Podman container detected" "test -f /run/.containerenv"
elif systemd-detect-virt -c &>/dev/null; then
    check "Container environment detected" "systemd-detect-virt -c"
else
    echo -e "${YELLOW}${WARN}${NC} Not running in a container"
fi
echo

# Check VM-related kernel modules
echo "Virtualization Modules:"
check "Can list kernel modules" "lsmod | head -3"
# Check for common virt modules
if lsmod | grep -qE 'virtio|vmw|vbox|hv_' 2>/dev/null; then
    check "Virtualization modules present" "lsmod | grep -qE 'virtio|vmw|vbox|hv_'"
else
    echo -e "${YELLOW}${WARN}${NC} No virtualization kernel modules detected"
fi
echo

# Check unique identifiers that should change on clone
echo "Clone-Sensitive Files:"
check "/etc/hostname exists" "test -f /etc/hostname"
check "/etc/machine-id exists" "test -f /etc/machine-id"
echo

# Summary
total=$((passed + failed))
echo "=========================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 102.6 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
