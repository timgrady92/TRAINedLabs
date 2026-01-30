#!/bin/bash
# LPIC-1 Training - Lab Completion Validator
# Validates that lab exercises have been completed correctly
# Usage: lab-validator.sh <lab-id> [--verbose]

set -euo pipefail

# Get script directory (available for future use)
# shellcheck disable=SC2034
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
LPIC_DIR="${HOME}/.lpic1"
DB_FILE="${LPIC_DIR}/progress.db"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Symbols
PASS="✓"
FAIL="✗"
WARN="⚠"
INFO="ℹ"

# Output functions
print_pass() { echo -e "${GREEN}${PASS}${NC} $1"; }
print_fail() { echo -e "${RED}${FAIL}${NC} $1"; }
print_warn() { echo -e "${YELLOW}${WARN}${NC} $1"; }
print_info() { echo -e "${CYAN}${INFO}${NC} $1"; }
print_header() { echo -e "\n${BOLD}$1${NC}\n"; }

# Validation helper functions

# Check if file exists
check_file_exists() {
    local file="$1"
    local desc="${2:-File exists}"
    if [[ -e "$file" ]]; then
        print_pass "$desc: $file"
        return 0
    else
        print_fail "$desc: $file (not found)"
        return 1
    fi
}

# Check if directory exists
check_dir_exists() {
    local dir="$1"
    local desc="${2:-Directory exists}"
    if [[ -d "$dir" ]]; then
        print_pass "$desc: $dir"
        return 0
    else
        print_fail "$desc: $dir (not found)"
        return 1
    fi
}

# Check file permissions
check_permissions() {
    local file="$1"
    local expected="$2"
    local desc="${3:-Permissions correct}"

    if [[ ! -e "$file" ]]; then
        print_fail "$desc: $file (file not found)"
        return 1
    fi

    local actual
    actual=$(stat -c "%a" "$file")
    if [[ "$actual" == "$expected" ]]; then
        print_pass "$desc: $file ($expected)"
        return 0
    else
        print_fail "$desc: $file (expected $expected, got $actual)"
        return 1
    fi
}

# Check file ownership
check_ownership() {
    local file="$1"
    local expected_user="$2"
    local expected_group="${3:-$expected_user}"
    local desc="${4:-Ownership correct}"

    if [[ ! -e "$file" ]]; then
        print_fail "$desc: $file (file not found)"
        return 1
    fi

    local actual_user actual_group
    actual_user=$(stat -c "%U" "$file")
    actual_group=$(stat -c "%G" "$file")

    if [[ "$actual_user" == "$expected_user" && "$actual_group" == "$expected_group" ]]; then
        print_pass "$desc: $file ($expected_user:$expected_group)"
        return 0
    else
        print_fail "$desc: $file (expected $expected_user:$expected_group, got $actual_user:$actual_group)"
        return 1
    fi
}

# Check if service is running
check_service_running() {
    local service="$1"
    local desc="${2:-Service running}"

    if systemctl is-active --quiet "$service" 2>/dev/null; then
        print_pass "$desc: $service"
        return 0
    else
        print_fail "$desc: $service (not running)"
        return 1
    fi
}

# Check if service is enabled
check_service_enabled() {
    local service="$1"
    local desc="${2:-Service enabled}"

    if systemctl is-enabled --quiet "$service" 2>/dev/null; then
        print_pass "$desc: $service"
        return 0
    else
        print_fail "$desc: $service (not enabled)"
        return 1
    fi
}

# Check if user exists
check_user_exists() {
    local user="$1"
    local desc="${2:-User exists}"

    if id "$user" &>/dev/null; then
        print_pass "$desc: $user"
        return 0
    else
        print_fail "$desc: $user (not found)"
        return 1
    fi
}

# Check if group exists
check_group_exists() {
    local group="$1"
    local desc="${2:-Group exists}"

    if getent group "$group" &>/dev/null; then
        print_pass "$desc: $group"
        return 0
    else
        print_fail "$desc: $group (not found)"
        return 1
    fi
}

# Check if user is in group
check_user_in_group() {
    local user="$1"
    local group="$2"
    local desc="${3:-User in group}"

    if groups "$user" 2>/dev/null | grep -qw "$group"; then
        print_pass "$desc: $user in $group"
        return 0
    else
        print_fail "$desc: $user not in $group"
        return 1
    fi
}

# Check file contains string
check_file_contains() {
    local file="$1"
    local pattern="$2"
    local desc="${3:-File contains pattern}"

    if [[ ! -f "$file" ]]; then
        print_fail "$desc: $file (file not found)"
        return 1
    fi

    if grep -q "$pattern" "$file"; then
        print_pass "$desc"
        return 0
    else
        print_fail "$desc: pattern not found"
        return 1
    fi
}

# Check mount point
check_mount() {
    local device="$1"
    local mountpoint="$2"
    local desc="${3:-Filesystem mounted}"

    if mountpoint -q "$mountpoint" 2>/dev/null; then
        local mounted_dev
        mounted_dev=$(findmnt -n -o SOURCE "$mountpoint" 2>/dev/null || echo "unknown")
        if [[ "$mounted_dev" == "$device" || "$mounted_dev" == *"$device"* ]]; then
            print_pass "$desc: $device on $mountpoint"
            return 0
        else
            print_warn "$desc: $mountpoint mounted but with different device ($mounted_dev)"
            return 1
        fi
    else
        print_fail "$desc: $mountpoint (not mounted)"
        return 1
    fi
}

# Check symbolic link
check_symlink() {
    local link="$1"
    local target="$2"
    local desc="${3:-Symbolic link correct}"

    if [[ ! -L "$link" ]]; then
        print_fail "$desc: $link (not a symlink)"
        return 1
    fi

    local actual_target
    actual_target=$(readlink "$link")
    if [[ "$actual_target" == "$target" ]]; then
        print_pass "$desc: $link -> $target"
        return 0
    else
        print_fail "$desc: $link -> $actual_target (expected $target)"
        return 1
    fi
}

# Check hard link count
check_hard_links() {
    local file="$1"
    local expected="$2"
    local desc="${3:-Hard link count}"

    if [[ ! -f "$file" ]]; then
        print_fail "$desc: $file (file not found)"
        return 1
    fi

    local actual
    actual=$(stat -c "%h" "$file")
    if [[ "$actual" -ge "$expected" ]]; then
        print_pass "$desc: $file has $actual links (expected >= $expected)"
        return 0
    else
        print_fail "$desc: $file has $actual links (expected >= $expected)"
        return 1
    fi
}

# Check process running
check_process_running() {
    local process="$1"
    local desc="${2:-Process running}"

    if pgrep -x "$process" &>/dev/null; then
        print_pass "$desc: $process"
        return 0
    else
        print_fail "$desc: $process (not running)"
        return 1
    fi
}

# Check port listening
check_port_listening() {
    local port="$1"
    local proto="${2:-tcp}"
    local desc="${3:-Port listening}"

    if ss -tuln | grep -q ":$port "; then
        print_pass "$desc: $port/$proto"
        return 0
    else
        print_fail "$desc: $port/$proto (not listening)"
        return 1
    fi
}

# Check cron job exists
check_cron_job() {
    local user="$1"
    local pattern="$2"
    local desc="${3:-Cron job exists}"

    if crontab -l -u "$user" 2>/dev/null | grep -q "$pattern"; then
        print_pass "$desc"
        return 0
    else
        print_fail "$desc: pattern not found in $user's crontab"
        return 1
    fi
}

# Record lab result in database
record_lab_result() {
    local lab_id="$1"
    local passed="$2"
    local total="$3"
    local hints_used="${4:-0}"

    if [[ ! -f "$DB_FILE" ]]; then
        print_warn "Progress database not found - results not recorded"
        return
    fi

    local score=$((passed * 100 / total))

    sqlite3 "$DB_FILE" << SQL
INSERT INTO labs (lab_id, started_at, completed_at, hints_used, score)
VALUES ('$lab_id', datetime('now'), datetime('now'), $hints_used, $score)
ON CONFLICT(lab_id) DO UPDATE SET
    completed_at = datetime('now'),
    hints_used = hints_used + $hints_used,
    score = MAX(score, $score);
SQL

    print_info "Progress recorded: Lab $lab_id - Score: $score%"
}

# Lab validators by category

validate_filesystem_lab() {
    local checks_passed=0
    local checks_total=0

    print_header "Filesystem Lab Validation"

    # Check practice filesystems exist
    ((checks_total++)) || true
    check_dir_exists "/mnt/lpic1/ext4-practice" "ext4 practice mountpoint" && ((checks_passed++)) || true

    ((checks_total++)) || true
    check_dir_exists "/mnt/lpic1/xfs-practice" "XFS practice mountpoint" && ((checks_passed++)) || true

    ((checks_total++)) || true
    check_dir_exists "/mnt/lpic1/lvm-data" "LVM data mountpoint" && ((checks_passed++)) || true

    # Check filesystems are mounted
    ((checks_total++)) || true
    if mountpoint -q /mnt/lpic1/ext4-practice 2>/dev/null; then
        print_pass "ext4 filesystem mounted"
        ((checks_passed++)) || true
    else
        print_fail "ext4 filesystem not mounted"
    fi

    echo
    print_info "Checks passed: $checks_passed/$checks_total"

    record_lab_result "filesystem-basics" "$checks_passed" "$checks_total"

    [[ $checks_passed -eq $checks_total ]]
}

validate_permissions_lab() {
    local checks_passed=0
    local checks_total=0
    local practice_dir="${HOME}/lpic1-practice/permissions-lab"

    print_header "Permissions Lab Validation"

    # Check required files exist
    ((checks_total++)) || true
    check_file_exists "$practice_dir/public-read.txt" "Public read file" && ((checks_passed++)) || true

    ((checks_total++)) || true
    check_file_exists "$practice_dir/private.txt" "Private file" && ((checks_passed++)) || true

    ((checks_total++)) || true
    check_file_exists "$practice_dir/executable.sh" "Executable script" && ((checks_passed++)) || true

    # Check permissions
    ((checks_total++)) || true
    check_permissions "$practice_dir/public-read.txt" "644" "Public file permissions" && ((checks_passed++)) || true

    ((checks_total++)) || true
    check_permissions "$practice_dir/private.txt" "600" "Private file permissions" && ((checks_passed++)) || true

    ((checks_total++)) || true
    check_permissions "$practice_dir/executable.sh" "755" "Executable permissions" && ((checks_passed++)) || true

    echo
    print_info "Checks passed: $checks_passed/$checks_total"

    record_lab_result "permissions" "$checks_passed" "$checks_total"

    [[ $checks_passed -eq $checks_total ]]
}

validate_user_management_lab() {
    local checks_passed=0
    local checks_total=0

    print_header "User Management Lab Validation"

    # Check test users exist
    ((checks_total++)) || true
    check_user_exists "quotauser" "Quota test user" && ((checks_passed++)) || true

    # Check common groups
    ((checks_total++)) || true
    check_group_exists "wheel" "Wheel group" || check_group_exists "sudo" "Sudo group" && ((checks_passed++)) || true

    echo
    print_info "Checks passed: $checks_passed/$checks_total"

    record_lab_result "user-management" "$checks_passed" "$checks_total"

    [[ $checks_passed -eq $checks_total ]]
}

validate_services_lab() {
    local checks_passed=0
    local checks_total=0

    print_header "System Services Lab Validation"

    # Check essential services
    ((checks_total++)) || true
    check_service_running "sshd" "SSH daemon running" || check_service_running "ssh" "SSH daemon running" && ((checks_passed++)) || true

    ((checks_total++)) || true
    check_service_running "cron" "Cron daemon running" || check_service_running "crond" "Cron daemon running" && ((checks_passed++)) || true

    ((checks_total++)) || true
    check_service_running "rsyslog" "Rsyslog running" && ((checks_passed++)) || true

    # Check services enabled
    ((checks_total++)) || true
    check_service_enabled "sshd" "SSH enabled" || check_service_enabled "ssh" "SSH enabled" && ((checks_passed++)) || true

    echo
    print_info "Checks passed: $checks_passed/$checks_total"

    record_lab_result "system-services" "$checks_passed" "$checks_total"

    [[ $checks_passed -eq $checks_total ]]
}

validate_networking_lab() {
    local checks_passed=0
    local checks_total=0

    print_header "Networking Lab Validation"

    # Check network tools available
    ((checks_total++)) || true
    if command -v ip &>/dev/null; then
        print_pass "ip command available"
        ((checks_passed++)) || true
    else
        print_fail "ip command not found"
    fi

    ((checks_total++)) || true
    if command -v ss &>/dev/null; then
        print_pass "ss command available"
        ((checks_passed++)) || true
    else
        print_fail "ss command not found"
    fi

    # Check network interface exists
    ((checks_total++)) || true
    if ip link show | grep -q "state UP"; then
        print_pass "Network interface is UP"
        ((checks_passed++)) || true
    else
        print_warn "No network interface in UP state"
    fi

    # Check SSH port listening
    ((checks_total++)) || true
    check_port_listening 22 "tcp" "SSH port" && ((checks_passed++)) || true

    echo
    print_info "Checks passed: $checks_passed/$checks_total"

    record_lab_result "networking" "$checks_passed" "$checks_total"

    [[ $checks_passed -eq $checks_total ]]
}

# Main validation dispatcher
validate_lab() {
    local lab_id="$1"
    local verbose="${2:-false}"

    case "$lab_id" in
        filesystem*|fs-*)
            validate_filesystem_lab
            ;;
        perm*)
            validate_permissions_lab
            ;;
        user*)
            validate_user_management_lab
            ;;
        service*|systemd*)
            validate_services_lab
            ;;
        network*|net-*)
            validate_networking_lab
            ;;
        all)
            local all_passed=true
            validate_filesystem_lab || all_passed=false
            validate_permissions_lab || all_passed=false
            validate_user_management_lab || all_passed=false
            validate_services_lab || all_passed=false
            validate_networking_lab || all_passed=false
            $all_passed
            ;;
        *)
            print_fail "Unknown lab: $lab_id"
            echo
            echo "Available labs:"
            echo "  filesystem   - Filesystem creation and mounting"
            echo "  permissions  - File permissions and ownership"
            echo "  user         - User and group management"
            echo "  services     - System service management"
            echo "  networking   - Network configuration"
            echo "  all          - Run all validations"
            exit 1
            ;;
    esac
}

# Usage
usage() {
    cat << 'EOF'
LPIC-1 Lab Validator

Usage: lab-validator.sh <lab-id> [options]

Lab IDs:
  filesystem    Filesystem creation and mounting
  permissions   File permissions and ownership
  user          User and group management
  services      System service management
  networking    Network configuration
  all           Run all validations

Options:
  -v, --verbose  Show detailed output
  -h, --help     Show this help

Examples:
  lab-validator.sh filesystem
  lab-validator.sh permissions --verbose
  lab-validator.sh all
EOF
}

# Main
main() {
    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi

    local lab_id="$1"
    shift

    local verbose=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_fail "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    validate_lab "$lab_id" "$verbose"
}

main "$@"
