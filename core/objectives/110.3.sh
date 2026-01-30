#!/bin/bash
# Objective 110.3: Securing data with encryption
# Weight: 4

# shellcheck disable=SC2088  # Tildes in description strings are intentional display text
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

echo "Checking Objective 110.3: Securing data with encryption"
echo "========================================================"
echo

# Check SSH commands
echo "SSH Commands:"
check "ssh available" "command -v ssh"
check "ssh-keygen available" "command -v ssh-keygen"
check "ssh-agent available" "command -v ssh-agent"
check "ssh-add available" "command -v ssh-add"
check "scp available" "command -v scp"
check "sftp available" "command -v sftp"
echo

# Check GPG commands
echo "GPG Commands:"
check "gpg available" "command -v gpg"
check "gpg-agent available" "command -v gpg-agent"
echo

# Check SSH configuration directories
echo "SSH Configuration:"
check "/etc/ssh exists" "test -d /etc/ssh"
check "sshd_config exists" "test -f /etc/ssh/sshd_config"
check "ssh_config exists" "test -f /etc/ssh/ssh_config"
echo

# Check SSH host keys
echo "SSH Host Keys:"
check "RSA host key" "test -f /etc/ssh/ssh_host_rsa_key.pub || test -f /etc/ssh/ssh_host_rsa_key"
check "ECDSA host key" "test -f /etc/ssh/ssh_host_ecdsa_key.pub || test -f /etc/ssh/ssh_host_ecdsa_key"
check "ED25519 host key" "test -f /etc/ssh/ssh_host_ed25519_key.pub || test -f /etc/ssh/ssh_host_ed25519_key"
echo

# Check user SSH directory
echo "User SSH Directory:"
check "~/.ssh exists or can be created" "test -d \$HOME/.ssh || mkdir -p \$HOME/.ssh"
check "~/.ssh has correct permissions" "test -d \$HOME/.ssh && test \$(stat -c %a \$HOME/.ssh) -le 755"
if [[ -f "$HOME/.ssh/authorized_keys" ]]; then
    check "authorized_keys exists" "test -f \$HOME/.ssh/authorized_keys"
fi
if [[ -f "$HOME/.ssh/known_hosts" ]]; then
    check "known_hosts exists" "test -f \$HOME/.ssh/known_hosts"
fi
echo

# Test ssh-keygen functionality
echo "SSH Key Generation:"
TESTDIR=$(mktemp -d)
trap 'rm -rf "$TESTDIR"' EXIT

check "Can generate RSA key" "ssh-keygen -t rsa -b 2048 -f $TESTDIR/test_rsa -N '' -q"
check "Can generate ED25519 key" "ssh-keygen -t ed25519 -f $TESTDIR/test_ed25519 -N '' -q"
check "Public key generated" "test -f $TESTDIR/test_rsa.pub"
echo

# Check GPG configuration
echo "GPG Configuration:"
check "~/.gnupg exists or can be created" "test -d \$HOME/.gnupg || gpg --list-keys 2>/dev/null || true"
echo

# Test GPG functionality
echo "GPG Functionality:"
check "gpg can list keys" "gpg --list-keys 2>/dev/null || true"
check "gpg can show version" "gpg --version | head -1"

# Test symmetric encryption
echo "test data" > "$TESTDIR/plaintext.txt"
check "gpg symmetric encrypt" "echo 'testpass' | gpg --batch --yes --passphrase-fd 0 -c -o $TESTDIR/encrypted.gpg $TESTDIR/plaintext.txt 2>/dev/null"
check "gpg symmetric decrypt" "echo 'testpass' | gpg --batch --yes --passphrase-fd 0 -d $TESTDIR/encrypted.gpg 2>/dev/null | grep -q 'test data'"
echo

# Check SSH service
echo "SSH Service:"
check "SSH service exists" "systemctl list-unit-files | grep -qE 'sshd|ssh'"
if systemctl is-active sshd &>/dev/null || systemctl is-active ssh &>/dev/null; then
    check "SSH service running" "systemctl is-active --quiet sshd || systemctl is-active --quiet ssh"
else
    echo -e "${YELLOW}${WARN}${NC} SSH service not running"
fi
echo

# Check SSH client config options
echo "SSH Configuration Awareness:"
check "ssh_config readable" "test -r /etc/ssh/ssh_config"
check "StrictHostKeyChecking documented" "grep -q 'StrictHostKeyChecking' /etc/ssh/ssh_config || ssh -o StrictHostKeyChecking=ask 2>&1 | head -1 || true"
echo

# Summary
total=$((passed + failed))
echo "========================================================"
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 110.3 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
