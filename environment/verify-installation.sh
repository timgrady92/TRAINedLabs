#!/bin/bash
# LPIC-1 Training Platform - Installation Verification
#
# Post-install health check that validates all components are working correctly.
# Returns exit code 0 if all checks pass, non-zero otherwise.
#
# Usage: sudo /opt/LPIC-1/environment/verify-installation.sh [--quiet]

set -euo pipefail

# Configuration
INSTALL_DIR="/opt/LPIC-1"
PRACTICE_DIR="/opt/lpic1-practice"
MOUNT_BASE="/mnt/lpic1"
LVM_VG="lpic1_vg"

# Parse arguments
QUIET=false
[[ "${1:-}" == "--quiet" ]] && QUIET=true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Counters
PASSED=0
FAILED=0
WARNED=0

# Output functions
print_header() {
    [[ "$QUIET" == true ]] && return
    echo -e "\n${BOLD}$1${NC}"
}

print_pass() {
    PASSED=$((PASSED + 1))
    [[ "$QUIET" == true ]] && return
    echo -e "  ${GREEN}✓${NC} $1"
}

print_fail() {
    FAILED=$((FAILED + 1))
    [[ "$QUIET" == true ]] && return
    echo -e "  ${RED}✗${NC} $1"
}

print_warn() {
    WARNED=$((WARNED + 1))
    [[ "$QUIET" == true ]] && return
    echo -e "  ${YELLOW}!${NC} $1"
}

print_info() {
    [[ "$QUIET" == true ]] && return
    echo -e "  ${CYAN}i${NC} $1"
}

# ============================================================================
# Verification Checks
# ============================================================================

verify_core_installation() {
    print_header "Core Installation"

    # Check install directory
    if [[ -d "$INSTALL_DIR" ]]; then
        print_pass "$INSTALL_DIR directory exists"
    else
        print_fail "$INSTALL_DIR directory missing"
    fi

    # Check lpic1 launcher
    if [[ -x "$INSTALL_DIR/lpic1" ]]; then
        print_pass "lpic1 launcher executable"
    else
        print_fail "lpic1 launcher not executable or missing"
    fi

    # Check symlink
    if [[ -L /usr/local/bin/lpic1 ]]; then
        if [[ -x /usr/local/bin/lpic1 ]]; then
            print_pass "/usr/local/bin/lpic1 symlink works"
        else
            print_fail "/usr/local/bin/lpic1 symlink broken"
        fi
    else
        print_fail "/usr/local/bin/lpic1 symlink missing"
    fi

    # Check feedback system
    if [[ -d "$INSTALL_DIR/feedback-system" ]]; then
        print_pass "Feedback system installed"
    else
        print_fail "Feedback system missing"
    fi

    # Check scenarios
    if [[ -d "$INSTALL_DIR/scenarios" ]]; then
        print_pass "Scenarios installed"
    else
        print_warn "Scenarios directory missing"
    fi

    # Check MOTD script
    if [[ -x "$INSTALL_DIR/motd-integration/training-motd.sh" ]]; then
        print_pass "MOTD script installed"
    else
        print_warn "MOTD script missing or not executable"
    fi
}

verify_critical_commands() {
    print_header "Critical Commands"

    local commands=(
        "dialog:TUI dialogs"
        "sqlite3:Progress tracking"
        "grep:Text processing"
        "sed:Text processing"
        "awk:Text processing"
        "tar:Archive operations"
        "vim:Text editing"
        "systemctl:Service management"
        "mount:Filesystem mounting"
        "lsblk:Block device listing"
    )

    for entry in "${commands[@]}"; do
        local cmd="${entry%%:*}"
        local desc="${entry#*:}"

        if command -v "$cmd" &>/dev/null; then
            print_pass "$cmd ($desc)"
        else
            print_fail "$cmd missing ($desc)"
        fi
    done
}

verify_user_environment() {
    print_header "User Environment"

    # Find the training user (check common names)
    local training_user=""
    for user in student trainee lpic1; do
        if id "$user" &>/dev/null; then
            training_user="$user"
            break
        fi
    done

    # Also check SUDO_USER
    if [[ -z "$training_user" ]] && [[ -n "${SUDO_USER:-}" ]]; then
        training_user="$SUDO_USER"
    fi

    if [[ -n "$training_user" ]]; then
        print_pass "Training user: $training_user"

        # Check sudo access
        if groups "$training_user" | grep -qw sudo; then
            print_pass "User has sudo access"
        else
            print_warn "User not in sudo group"
        fi
    else
        print_warn "No training user found (student, trainee, or lpic1)"
    fi

    # Check shared data directory
    if [[ -d "$INSTALL_DIR/data" ]]; then
        print_pass "Data directory exists ($INSTALL_DIR/data)"

        # Check progress database
        if [[ -f "$INSTALL_DIR/data/progress.db" ]]; then
            print_pass "Progress database initialized"
        else
            print_warn "Progress database not yet created (will initialize on first run)"
        fi
    else
        print_warn "Data directory not found (will create on first run)"
    fi

    # Check practice files
    if [[ -d "$INSTALL_DIR/practice" ]]; then
        print_pass "Practice files directory exists ($INSTALL_DIR/practice)"
    else
        print_warn "Practice files directory not found"
    fi
}

verify_practice_filesystems() {
    print_header "Practice Filesystems"

    # Check if practice dir exists
    if [[ ! -d "$PRACTICE_DIR" ]]; then
        print_info "Practice filesystems not configured (optional)"
        return
    fi

    # Check image files
    local images=(ext4.img xfs.img btrfs.img vfat.img quota.img lvm-pv1.img lvm-pv2.img lvm-pv3.img)
    local images_found=0

    for img in "${images[@]}"; do
        if [[ -f "${PRACTICE_DIR}/loop-images/${img}" ]]; then
            images_found=$((images_found + 1))
        fi
    done

    if [[ $images_found -eq ${#images[@]} ]]; then
        print_pass "All loop image files present ($images_found/${#images[@]})"
    elif [[ $images_found -gt 0 ]]; then
        print_warn "Some loop images missing ($images_found/${#images[@]})"
    else
        print_info "No loop images found (filesystems not set up)"
        return
    fi

    # Check mount points
    local mounts=(ext4-practice xfs-practice btrfs-practice vfat-practice quota-test lvm-data lvm-logs lvm-backup)
    local mounted=0

    for mount in "${mounts[@]}"; do
        if mountpoint -q "${MOUNT_BASE}/${mount}" 2>/dev/null; then
            mounted=$((mounted + 1))
        fi
    done

    if [[ $mounted -eq ${#mounts[@]} ]]; then
        print_pass "All practice filesystems mounted ($mounted/${#mounts[@]})"
    elif [[ $mounted -gt 0 ]]; then
        print_warn "Some filesystems not mounted ($mounted/${#mounts[@]})"
        print_info "Try: sudo systemctl start lpic1-filesystems"
    else
        print_warn "No practice filesystems mounted"
        print_info "After reboot, filesystems should mount automatically"
    fi

    # Check systemd service
    if [[ -f /etc/systemd/system/lpic1-filesystems.service ]]; then
        if systemctl is-enabled lpic1-filesystems.service &>/dev/null; then
            print_pass "Filesystem persistence service enabled"
        else
            print_warn "Filesystem service not enabled"
        fi
    else
        print_warn "Filesystem persistence service not installed"
    fi

    # Check LVM
    if vgdisplay "$LVM_VG" &>/dev/null; then
        print_pass "LVM volume group '$LVM_VG' available"
    else
        print_info "LVM volume group not active (normal if not mounted)"
    fi
}

verify_motd() {
    print_header "Login Banner (MOTD)"

    if [[ -f /etc/update-motd.d/99-lpic1-training ]]; then
        if [[ -x /etc/update-motd.d/99-lpic1-training ]]; then
            print_pass "MOTD script installed and executable"
        else
            print_warn "MOTD script not executable"
        fi
    elif [[ -f /etc/profile.d/lpic1-training.sh ]]; then
        print_pass "MOTD fallback installed in /etc/profile.d/"
    else
        print_warn "MOTD not installed"
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    if [[ "$QUIET" != true ]]; then
        echo -e "${BOLD}${CYAN}"
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║         LPIC-1 Installation Verification                       ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
    fi

    verify_core_installation
    verify_critical_commands
    verify_user_environment
    verify_practice_filesystems
    verify_motd

    # Summary
    if [[ "$QUIET" != true ]]; then
        echo
        echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}Summary:${NC} ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}, ${YELLOW}$WARNED warnings${NC}"
        echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo
    fi

    if [[ $FAILED -eq 0 ]]; then
        if [[ "$QUIET" != true ]]; then
            echo -e "${GREEN}${BOLD}All critical checks passed!${NC}"
            if [[ $WARNED -gt 0 ]]; then
                echo -e "${YELLOW}Review warnings above for optional improvements.${NC}"
            fi
            echo
            echo -e "The LPIC-1 training environment is ready."
            echo -e "Type ${GREEN}${BOLD}lpic1${NC} to start training."
            echo
        fi
        exit 0
    else
        if [[ "$QUIET" != true ]]; then
            echo -e "${RED}${BOLD}Some checks failed!${NC}"
            echo -e "Please resolve the issues above and run verification again:"
            echo -e "  sudo $INSTALL_DIR/environment/verify-installation.sh"
            echo
        fi
        exit 1
    fi
}

main
