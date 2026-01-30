#!/bin/bash
# LPIC-1 Build Scenario: User and Group Management Challenge
# Tests user/group administration skills
# MUST be run as root

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
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
print_header() { echo -e "\n${BOLD}${BLUE}═══ $1 ═══${NC}\n"; }

# Configuration
HINTS_USED=0
PREFIX="lpic1"

# Users and groups for the challenge
CHALLENGE_USERS=("${PREFIX}_alice" "${PREFIX}_bob" "${PREFIX}_charlie")
CHALLENGE_GROUPS=("${PREFIX}_developers" "${PREFIX}_admins" "${PREFIX}_project")

# Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_fail "This script must be run as root"
        echo "Use: sudo $0 $*"
        exit 1
    fi
}

# Start the challenge
start_challenge() {
    print_header "User and Group Management Challenge"

    echo "Your mission: Set up a team structure with users and groups"
    echo
    echo "LPIC-1 Objective 107.1: Manage user and group accounts"
    echo
    echo "Scenario:"
    echo "  You're setting up a development server. Create the following:"
    echo
    echo "  Groups:"
    for group in "${CHALLENGE_GROUPS[@]}"; do
        echo "    - $group"
    done
    echo
    echo "  Users:"
    echo "    - ${CHALLENGE_USERS[0]} (developer, in developers group)"
    echo "    - ${CHALLENGE_USERS[1]} (admin, in admins group)"
    echo "    - ${CHALLENGE_USERS[2]} (contractor, in project group only)"
    echo
    echo "  Additional requirements:"
    echo "    - All users should have home directories"
    echo "    - ${CHALLENGE_USERS[0]} and ${CHALLENGE_USERS[1]} should be in project group"
    echo "    - ${CHALLENGE_USERS[1]} should be in the developers group too"
    echo "    - ${CHALLENGE_USERS[2]} password should expire in 30 days"
    echo

    print_info "Challenge started!"
    print_info "Run: $0 --check  to verify your setup"
    print_info "Run: $0 --hint   to get a hint"
}

# Provide hints
give_hint() {
    local hint_num="${1:-1}"
    ((HINTS_USED++)) || true

    print_header "Hint #$hint_num"

    case "$hint_num" in
        1)
            echo "Creating groups:"
            echo "  groupadd groupname"
            echo
            echo "For this challenge:"
            for group in "${CHALLENGE_GROUPS[@]}"; do
                echo "  groupadd $group"
            done
            ;;
        2)
            echo "Creating users with home directories:"
            echo "  useradd -m username"
            echo
            echo "Creating users in a specific primary group:"
            echo "  useradd -m -g primary_group username"
            echo
            echo "Creating users in additional groups:"
            echo "  useradd -m -G group1,group2 username"
            ;;
        3)
            echo "Adding user to additional groups:"
            echo "  usermod -aG groupname username"
            echo
            echo "IMPORTANT: Use -a (append) to avoid removing existing groups!"
            echo
            echo "Check user's groups:"
            echo "  groups username"
            echo "  id username"
            ;;
        4)
            echo "Setting password expiry with chage:"
            echo "  chage -M 30 username    # Password expires in 30 days"
            echo "  chage -l username       # View expiry info"
            echo
            echo "Other chage options:"
            echo "  chage -E 2024-12-31 user  # Account expires on date"
            echo "  chage -I 7 user           # Inactive days"
            echo "  chage -W 7 user           # Warning days"
            ;;
        5)
            echo "Quick reference for user files:"
            echo "  /etc/passwd   - User accounts"
            echo "  /etc/shadow   - Password info (including expiry)"
            echo "  /etc/group    - Group definitions"
            echo "  /etc/gshadow  - Group passwords"
            echo
            echo "Viewing entries:"
            echo "  getent passwd username"
            echo "  getent group groupname"
            ;;
        *)
            print_warn "No more hints available"
            ;;
    esac

    echo
    print_warn "Hints used: $HINTS_USED"
}

# Check the challenge
check_challenge() {
    print_header "Checking User/Group Setup"

    local passed=0
    local total=0

    # Check groups exist
    print_info "Checking groups..."
    for group in "${CHALLENGE_GROUPS[@]}"; do
        ((total++)) || true
        if getent group "$group" &>/dev/null; then
            print_pass "Group exists: $group"
            ((passed++)) || true
        else
            print_fail "Group missing: $group"
        fi
    done

    echo

    # Check users exist
    print_info "Checking users..."
    for user in "${CHALLENGE_USERS[@]}"; do
        ((total++)) || true
        if id "$user" &>/dev/null; then
            print_pass "User exists: $user"
            ((passed++)) || true
        else
            print_fail "User missing: $user"
        fi
    done

    echo

    # Check home directories
    print_info "Checking home directories..."
    for user in "${CHALLENGE_USERS[@]}"; do
        ((total++)) || true
        if [[ -d "/home/$user" ]]; then
            print_pass "Home directory exists: /home/$user"
            ((passed++)) || true
        else
            print_fail "Home directory missing: /home/$user"
        fi
    done

    echo

    # Check group memberships
    print_info "Checking group memberships..."

    # alice in developers
    ((total++)) || true
    if groups "${CHALLENGE_USERS[0]}" 2>/dev/null | grep -qw "${CHALLENGE_GROUPS[0]}"; then
        print_pass "${CHALLENGE_USERS[0]} is in ${CHALLENGE_GROUPS[0]}"
        ((passed++)) || true
    else
        print_fail "${CHALLENGE_USERS[0]} should be in ${CHALLENGE_GROUPS[0]}"
    fi

    # alice in project
    ((total++)) || true
    if groups "${CHALLENGE_USERS[0]}" 2>/dev/null | grep -qw "${CHALLENGE_GROUPS[2]}"; then
        print_pass "${CHALLENGE_USERS[0]} is in ${CHALLENGE_GROUPS[2]}"
        ((passed++)) || true
    else
        print_fail "${CHALLENGE_USERS[0]} should be in ${CHALLENGE_GROUPS[2]}"
    fi

    # bob in admins
    ((total++)) || true
    if groups "${CHALLENGE_USERS[1]}" 2>/dev/null | grep -qw "${CHALLENGE_GROUPS[1]}"; then
        print_pass "${CHALLENGE_USERS[1]} is in ${CHALLENGE_GROUPS[1]}"
        ((passed++)) || true
    else
        print_fail "${CHALLENGE_USERS[1]} should be in ${CHALLENGE_GROUPS[1]}"
    fi

    # bob in developers
    ((total++)) || true
    if groups "${CHALLENGE_USERS[1]}" 2>/dev/null | grep -qw "${CHALLENGE_GROUPS[0]}"; then
        print_pass "${CHALLENGE_USERS[1]} is in ${CHALLENGE_GROUPS[0]}"
        ((passed++)) || true
    else
        print_fail "${CHALLENGE_USERS[1]} should be in ${CHALLENGE_GROUPS[0]}"
    fi

    # bob in project
    ((total++)) || true
    if groups "${CHALLENGE_USERS[1]}" 2>/dev/null | grep -qw "${CHALLENGE_GROUPS[2]}"; then
        print_pass "${CHALLENGE_USERS[1]} is in ${CHALLENGE_GROUPS[2]}"
        ((passed++)) || true
    else
        print_fail "${CHALLENGE_USERS[1]} should be in ${CHALLENGE_GROUPS[2]}"
    fi

    # charlie in project only
    ((total++)) || true
    if groups "${CHALLENGE_USERS[2]}" 2>/dev/null | grep -qw "${CHALLENGE_GROUPS[2]}"; then
        print_pass "${CHALLENGE_USERS[2]} is in ${CHALLENGE_GROUPS[2]}"
        ((passed++)) || true
    else
        print_fail "${CHALLENGE_USERS[2]} should be in ${CHALLENGE_GROUPS[2]}"
    fi

    echo

    # Check password expiry for charlie
    print_info "Checking password policies..."
    ((total++)) || true
    if id "${CHALLENGE_USERS[2]}" &>/dev/null; then
        local max_days
        max_days=$(chage -l "${CHALLENGE_USERS[2]}" 2>/dev/null | grep "Maximum" | grep -oE '[0-9]+' || echo "0")
        if [[ "$max_days" == "30" ]]; then
            print_pass "${CHALLENGE_USERS[2]} password expires in 30 days"
            ((passed++)) || true
        else
            print_fail "${CHALLENGE_USERS[2]} password should expire in 30 days (currently: $max_days)"
        fi
    else
        print_fail "Cannot check - user ${CHALLENGE_USERS[2]} doesn't exist"
    fi

    # Calculate score
    echo
    print_header "Results"

    local base_score=$((passed * 100 / total))
    local hint_penalty=$((HINTS_USED * 5))
    local final_score=$((base_score - hint_penalty))
    [[ $final_score -lt 0 ]] && final_score=0

    echo "Checks passed: $passed/$total"
    echo "Hints used: $HINTS_USED"
    echo "Final score: $final_score%"
    echo

    if [[ $passed -eq $total ]]; then
        print_pass "CHALLENGE COMPLETE!"
        echo
        echo "Excellent work on user management!"
        echo
        echo "Key commands for LPIC-1:"
        echo "  useradd, usermod, userdel - User management"
        echo "  groupadd, groupmod, groupdel - Group management"
        echo "  passwd - Set passwords"
        echo "  chage - Manage password expiry"
        echo "  id, groups - Check user/group membership"
        echo "  getent - Query user/group databases"
    else
        print_warn "Keep working on it!"
    fi
}

# Cleanup
cleanup() {
    print_header "Cleanup"

    print_info "Removing challenge users..."
    for user in "${CHALLENGE_USERS[@]}"; do
        if id "$user" &>/dev/null; then
            userdel -r "$user" 2>/dev/null || true
            print_info "Removed user: $user"
        fi
    done

    print_info "Removing challenge groups..."
    for group in "${CHALLENGE_GROUPS[@]}"; do
        if getent group "$group" &>/dev/null; then
            groupdel "$group" 2>/dev/null || true
            print_info "Removed group: $group"
        fi
    done

    print_pass "Cleanup complete"
}

# Usage
usage() {
    cat << 'EOF'
LPIC-1 Build Scenario: User and Group Management

Usage: create-users.sh <action>

Actions:
  --start      Begin the challenge
  --check      Verify your setup
  --hint [N]   Get hint #N
  --cleanup    Remove all challenge users and groups

LPIC-1 Objective 107.1 Coverage:
  - Create users with useradd
  - Create groups with groupadd
  - Modify users with usermod
  - Manage group membership
  - Set password policies with chage
  - Understand /etc/passwd, /etc/group, /etc/shadow

Examples:
  sudo ./create-users.sh --start
  sudo ./create-users.sh --hint 1
  sudo ./create-users.sh --check
  sudo ./create-users.sh --cleanup
EOF
}

# Main
main() {
    if [[ $# -lt 1 ]]; then
        usage
        exit 0
    fi

    local action="$1"
    shift 2>/dev/null || true

    case "$action" in
        --start|-s)
            check_root "$@"
            start_challenge
            ;;
        --check|-c)
            check_root "$@"
            check_challenge
            ;;
        --hint|-h)
            give_hint "${1:-$((HINTS_USED + 1))}"
            ;;
        --cleanup)
            check_root "$@"
            cleanup
            ;;
        --help)
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
