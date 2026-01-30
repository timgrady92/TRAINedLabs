#!/bin/bash
# LPIC-1 Break/Fix Scenario: Broken Boot
# Simulates common boot problems for troubleshooting practice
# MUST be run as root

set -euo pipefail

# Cleanup trap for interrupted operations
cleanup_on_exit() {
    if [[ -n "${MODIFYING_SYSTEM:-}" ]]; then
        echo
        echo "Interrupted! Please run --restore to clean up partial changes."
    fi
}
trap cleanup_on_exit INT TERM

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASS="✓"
FAIL="✗"
WARN="⚠"
INFO="ℹ"

print_pass() { echo -e "${GREEN}${PASS}${NC} $1"; }
print_fail() { echo -e "${RED}${FAIL}${NC} $1"; }
print_warn() { echo -e "${YELLOW}${WARN}${NC} $1"; }
print_info() { echo -e "${CYAN}${INFO}${NC} $1"; }
print_header() { echo -e "\n${BOLD}═══ $1 ═══${NC}\n"; }

# Configuration
SNAPSHOT_DIR="/opt/LPIC-1/data/snapshots"
SCENARIO_NAME="broken-boot"

# Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_fail "This script must be run as root"
        echo "Use: sudo $0 $*"
        exit 1
    fi
}

# Available scenarios
declare -A SCENARIOS
SCENARIOS["grub-timeout"]="GRUB timeout set to 0 (no boot menu)"
SCENARIOS["grub-default"]="GRUB default entry points to non-existent kernel"
SCENARIOS["fstab-typo"]="Invalid entry in /etc/fstab causing mount failure"
SCENARIOS["missing-module"]="Essential kernel module blacklisted"
SCENARIOS["init-target"]="Default systemd target changed to rescue"

# List scenarios
list_scenarios() {
    print_header "Available Boot Scenarios"

    echo "Safe scenarios (can be fixed without reboot):"
    for id in "${!SCENARIOS[@]}"; do
        echo "  $id - ${SCENARIOS[$id]}"
    done

    echo
    print_warn "These scenarios modify system configuration files."
    print_warn "Always create a snapshot before starting!"
}

# Create snapshot
create_snapshot() {
    local scenario="$1"
    local snapshot_path="${SNAPSHOT_DIR}/${SCENARIO_NAME}-${scenario}"

    mkdir -p "$snapshot_path"

    # Backup critical files
    cp /etc/default/grub "$snapshot_path/" 2>/dev/null || true
    cp /etc/fstab "$snapshot_path/" 2>/dev/null || true
    cp -r /etc/modprobe.d "$snapshot_path/" 2>/dev/null || true

    # Record default target
    systemctl get-default > "$snapshot_path/default-target" 2>/dev/null || true

    print_pass "Snapshot created at $snapshot_path"
}

# Restore from snapshot
restore_snapshot() {
    local scenario="$1"
    local snapshot_path="${SNAPSHOT_DIR}/${SCENARIO_NAME}-${scenario}"

    if [[ ! -d "$snapshot_path" ]]; then
        print_fail "No snapshot found for scenario: $scenario"
        exit 1
    fi

    print_info "Restoring from snapshot..."

    # Restore files
    [[ -f "$snapshot_path/grub" ]] && cp "$snapshot_path/grub" /etc/default/grub
    [[ -f "$snapshot_path/fstab" ]] && cp "$snapshot_path/fstab" /etc/fstab
    [[ -d "$snapshot_path/modprobe.d" ]] && cp -r "$snapshot_path/modprobe.d"/* /etc/modprobe.d/ 2>/dev/null || true

    # Restore default target
    if [[ -f "$snapshot_path/default-target" ]]; then
        local target
        target=$(cat "$snapshot_path/default-target")
        systemctl set-default "$target" 2>/dev/null || true
    fi

    # Regenerate GRUB config
    if command -v grub2-mkconfig &>/dev/null; then
        grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true
    elif command -v grub-mkconfig &>/dev/null; then
        grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
    fi

    print_pass "System restored from snapshot"
    print_info "Changes applied. A reboot may be required for full effect."
}

# Start scenario
start_scenario() {
    local scenario="$1"

    if [[ -z "${SCENARIOS[$scenario]:-}" ]]; then
        print_fail "Unknown scenario: $scenario"
        list_scenarios
        exit 1
    fi

    print_header "Starting Scenario: $scenario"
    echo "${SCENARIOS[$scenario]}"
    echo

    # Create snapshot first
    create_snapshot "$scenario"

    case "$scenario" in
        grub-timeout)
            start_grub_timeout
            ;;
        grub-default)
            start_grub_default
            ;;
        fstab-typo)
            start_fstab_typo
            ;;
        missing-module)
            start_missing_module
            ;;
        init-target)
            start_init_target
            ;;
    esac

    echo
    print_header "Scenario Active"
    print_info "The system has been modified."
    print_info "Your task: Identify and fix the issue."
    echo
    print_warn "When done, run: $0 --check $scenario"
    print_warn "If stuck, run: $0 --restore $scenario"
}

# Scenario implementations
start_grub_timeout() {
    print_info "Modifying GRUB timeout..."

    if [[ -f /etc/default/grub ]]; then
        sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub

        # Regenerate GRUB
        if command -v grub2-mkconfig &>/dev/null; then
            grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null
        elif command -v grub-mkconfig &>/dev/null; then
            grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null
        fi

        print_pass "GRUB timeout set to 0"
        echo
        echo "Problem: On next reboot, GRUB menu will not appear."
        echo "Hint: How do you access GRUB menu when timeout is 0?"
        echo "Hint: Where is the GRUB configuration stored?"
    else
        print_fail "/etc/default/grub not found"
    fi
}

start_grub_default() {
    print_info "Modifying GRUB default entry..."

    if [[ -f /etc/default/grub ]]; then
        # Set to a high number that doesn't exist
        sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=99/' /etc/default/grub

        # Regenerate GRUB
        if command -v grub2-mkconfig &>/dev/null; then
            grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null
        elif command -v grub-mkconfig &>/dev/null; then
            grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null
        fi

        print_pass "GRUB default set to non-existent entry"
        echo
        echo "Problem: GRUB will try to boot entry 99, which doesn't exist."
        echo "Hint: What happens when GRUB can't find the default entry?"
        echo "Hint: How do you select a different entry at boot?"
    else
        print_fail "/etc/default/grub not found"
    fi
}

start_fstab_typo() {
    print_info "Adding problematic fstab entry..."

    # Add a comment and a bad entry
    cat >> /etc/fstab << 'EOF'

# LPIC-1 Training - Broken entry (DO NOT BOOT WITH THIS!)
/dev/nonexistent_device  /mnt/broken  ext4  defaults  0 0
EOF

    print_pass "Invalid fstab entry added"
    echo
    echo "Problem: /etc/fstab contains an entry for a non-existent device."
    echo "Hint: What happens during boot when fstab has errors?"
    echo "Hint: How can you test fstab without rebooting?"
    echo
    print_warn "DO NOT REBOOT! Fix the issue first, or the system may hang."
}

start_missing_module() {
    print_info "Blacklisting a kernel module..."

    # Blacklist the loop module (used for mounting images)
    cat > /etc/modprobe.d/lpic1-training-blacklist.conf << 'EOF'
# LPIC-1 Training - Module blacklist scenario
blacklist loop
EOF

    print_pass "Module 'loop' has been blacklisted"
    echo
    echo "Problem: The 'loop' kernel module is now blacklisted."
    echo "Hint: Where are module blacklists configured?"
    echo "Hint: How do you load a module manually?"
    echo
    echo "Test: Try to mount an ISO file and see what happens."
}

start_init_target() {
    print_info "Changing default systemd target..."

    # Change to rescue target
    systemctl set-default rescue.target

    print_pass "Default target changed to rescue.target"
    echo
    echo "Problem: System will boot to single-user rescue mode."
    echo "Hint: What is the current default target?"
    echo "Hint: How do you change the default target?"
    echo
    print_warn "If you reboot, you'll be in rescue mode (root password required)."
}

# Check if scenario is fixed
check_scenario() {
    local scenario="$1"
    local fixed=true

    print_header "Checking Scenario: $scenario"

    case "$scenario" in
        grub-timeout)
            local timeout
            timeout=$(grep "^GRUB_TIMEOUT=" /etc/default/grub | cut -d= -f2)
            if [[ "$timeout" -gt 0 ]]; then
                print_pass "GRUB timeout is now $timeout seconds"
            else
                print_fail "GRUB timeout is still 0"
                fixed=false
            fi
            ;;

        grub-default)
            local default
            default=$(grep "^GRUB_DEFAULT=" /etc/default/grub | cut -d= -f2)
            if [[ "$default" != "99" ]]; then
                print_pass "GRUB default is now: $default"
            else
                print_fail "GRUB default is still 99"
                fixed=false
            fi
            ;;

        fstab-typo)
            if grep -q "nonexistent_device" /etc/fstab; then
                print_fail "Invalid fstab entry still present"
                fixed=false
            else
                print_pass "Invalid fstab entry removed"
            fi

            # Also check if fstab is valid
            if mount -a 2>/dev/null; then
                print_pass "fstab validates correctly"
            else
                print_fail "fstab still has errors"
                fixed=false
            fi
            ;;

        missing-module)
            if [[ -f /etc/modprobe.d/lpic1-training-blacklist.conf ]]; then
                print_fail "Blacklist file still exists"
                fixed=false
            else
                print_pass "Blacklist file removed"
            fi

            if lsmod | grep -q "^loop"; then
                print_pass "Loop module is loaded"
            else
                print_warn "Loop module not currently loaded (may need modprobe)"
            fi
            ;;

        init-target)
            local target
            target=$(systemctl get-default)
            if [[ "$target" == "multi-user.target" ]] || [[ "$target" == "graphical.target" ]]; then
                print_pass "Default target is now: $target"
            else
                print_fail "Default target is still: $target"
                fixed=false
            fi
            ;;

        *)
            print_fail "Unknown scenario: $scenario"
            exit 1
            ;;
    esac

    echo
    if [[ "$fixed" == "true" ]]; then
        print_pass "Scenario $scenario: FIXED!"
        print_info "Great job! The issue has been resolved."
    else
        print_fail "Scenario $scenario: Not yet fixed"
        print_info "Keep trying! Use 'man' and online resources."
    fi
}

# Usage
usage() {
    cat << 'EOF'
LPIC-1 Break/Fix Scenario: Broken Boot

Usage: broken-boot.sh <action> [scenario]

Actions:
  --list              List available scenarios
  --start <scenario>  Start a scenario (creates backup first)
  --check <scenario>  Check if scenario is fixed
  --restore <scenario> Restore system from backup

Scenarios:
  grub-timeout     GRUB timeout set to 0
  grub-default     GRUB default points to invalid entry
  fstab-typo       Invalid /etc/fstab entry
  missing-module   Essential kernel module blacklisted
  init-target      Default systemd target changed

Examples:
  sudo ./broken-boot.sh --list
  sudo ./broken-boot.sh --start fstab-typo
  sudo ./broken-boot.sh --check fstab-typo
  sudo ./broken-boot.sh --restore fstab-typo

WARNING: Some scenarios modify boot configuration.
         Always have a backup or recovery method available.
EOF
}

# Main
main() {
    if [[ $# -lt 1 ]]; then
        usage
        exit 0
    fi

    local action="$1"
    local scenario="${2:-}"

    case "$action" in
        --list|-l)
            list_scenarios
            ;;
        --start|-s)
            check_root "$@"
            if [[ -z "$scenario" ]]; then
                print_fail "Please specify a scenario"
                list_scenarios
                exit 1
            fi
            start_scenario "$scenario"
            ;;
        --check|-c)
            check_root "$@"
            if [[ -z "$scenario" ]]; then
                print_fail "Please specify a scenario"
                exit 1
            fi
            check_scenario "$scenario"
            ;;
        --restore|-r)
            check_root "$@"
            if [[ -z "$scenario" ]]; then
                print_fail "Please specify a scenario"
                exit 1
            fi
            restore_snapshot "$scenario"
            ;;
        --help|-h)
            usage
            ;;
        *)
            print_fail "Unknown action: $action"
            usage
            exit 1
            ;;
    esac
}

main "$@"
