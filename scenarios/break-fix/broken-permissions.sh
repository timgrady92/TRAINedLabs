#!/bin/bash
# LPIC-1 Break/Fix Scenario: Broken Permissions
# Creates permission problems for troubleshooting practice
# Can be run as regular user (creates problems in home directory)

set -euo pipefail

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
PRACTICE_DIR="${HOME}/lpic1-practice/permissions-challenge"
SNAPSHOT_DIR="${HOME}/.lpic1/snapshots"
SCENARIO_NAME="broken-permissions"

# Available scenarios
declare -A SCENARIOS
SCENARIOS["no-read"]="File exists but cannot be read"
SCENARIOS["no-execute"]="Script exists but cannot be executed"
SCENARIOS["no-write-dir"]="Directory exists but cannot create files in it"
SCENARIOS["wrong-owner"]="File owned by wrong user/group"
SCENARIOS["sticky-bit"]="Sticky bit preventing file deletion"
SCENARIOS["setuid-issue"]="SetUID bit causing unexpected behavior"
SCENARIOS["umask-chaos"]="Files created with wrong default permissions"

# List scenarios
list_scenarios() {
    print_header "Available Permission Scenarios"

    for id in "${!SCENARIOS[@]}"; do
        echo "  $id - ${SCENARIOS[$id]}"
    done

    echo
    print_info "These scenarios are safe and use your home directory."
}

# Setup practice directory
setup_practice_dir() {
    mkdir -p "$PRACTICE_DIR"
}

# Create snapshot
create_snapshot() {
    local scenario="$1"
    local snapshot_path="${SNAPSHOT_DIR}/${SCENARIO_NAME}-${scenario}"

    mkdir -p "$snapshot_path"

    # Save current state
    if [[ -d "$PRACTICE_DIR" ]]; then
        cp -a "$PRACTICE_DIR" "$snapshot_path/practice-backup" 2>/dev/null || true
    fi

    # Save umask
    umask > "$snapshot_path/umask"

    print_pass "Snapshot created"
}

# Restore from snapshot
restore_snapshot() {
    local scenario="$1"
    local snapshot_path="${SNAPSHOT_DIR}/${SCENARIO_NAME}-${scenario}"

    if [[ ! -d "$snapshot_path" ]]; then
        print_fail "No snapshot found for scenario: $scenario"
        exit 1
    fi

    # Restore practice directory
    rm -rf "$PRACTICE_DIR"
    if [[ -d "$snapshot_path/practice-backup" ]]; then
        cp -a "$snapshot_path/practice-backup" "$PRACTICE_DIR"
    fi

    print_pass "Restored from snapshot"
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

    setup_practice_dir
    create_snapshot "$scenario"

    case "$scenario" in
        no-read)
            start_no_read
            ;;
        no-execute)
            start_no_execute
            ;;
        no-write-dir)
            start_no_write_dir
            ;;
        wrong-owner)
            start_wrong_owner
            ;;
        sticky-bit)
            start_sticky_bit
            ;;
        setuid-issue)
            start_setuid_issue
            ;;
        umask-chaos)
            start_umask_chaos
            ;;
    esac

    echo
    print_header "Scenario Active"
    print_info "Directory: $PRACTICE_DIR"
    print_info "Your task: Identify and fix the permission issue."
    echo
    print_warn "When done, run: $0 --check $scenario"
}

# Scenario implementations
start_no_read() {
    local target="$PRACTICE_DIR/secret-config.txt"

    # Create file with content
    echo "DATABASE_PASSWORD=supersecret123" > "$target"
    echo "API_KEY=abcdef123456" >> "$target"

    # Remove read permission
    chmod 000 "$target"

    print_pass "Created: $target"
    echo
    echo "Problem: The config file exists but you can't read it."
    echo "Task: Make the file readable (but keep it secure)."
    echo
    echo "Try: cat $target"
    echo
    echo "Hint: What permission is needed to read a file?"
    echo "Hint: Consider who should be able to read it."
}

start_no_execute() {
    local target="$PRACTICE_DIR/backup.sh"

    # Create an executable script
    cat > "$target" << 'SCRIPT'
#!/bin/bash
echo "Backup started at $(date)"
echo "Backing up important files..."
tar -czf /tmp/backup-$(date +%Y%m%d).tar.gz ~/Documents 2>/dev/null || echo "No Documents folder"
echo "Backup complete!"
SCRIPT

    # Remove execute permission
    chmod 644 "$target"

    print_pass "Created: $target"
    echo
    echo "Problem: The backup script exists but won't run."
    echo "Task: Make the script executable."
    echo
    echo "Try: $target"
    echo
    echo "Hint: What makes a script executable?"
    echo "Hint: There are multiple ways to run a script..."
}

start_no_write_dir() {
    local target="$PRACTICE_DIR/logs"

    # Create directory
    mkdir -p "$target"

    # Remove write permission
    chmod 555 "$target"

    print_pass "Created: $target"
    echo
    echo "Problem: The logs directory exists but you can't create files in it."
    echo "Task: Make the directory writable so you can create log files."
    echo
    echo "Try: touch $target/test.log"
    echo
    echo "Hint: What permission is needed to create files in a directory?"
}

start_wrong_owner() {
    local target="$PRACTICE_DIR/shared-data"
    local file="$target/report.txt"

    mkdir -p "$target"
    echo "Monthly Report Data" > "$file"
    echo "Sales: \$100,000" >> "$file"

    # This will show wrong group (we can't change owner without root)
    chmod 640 "$file"

    print_pass "Created: $file"
    echo
    echo "Scenario: A file was created by another process with restricted permissions."
    echo "The file has permissions 640 (rw-r-----)."
    echo
    echo "Task: Change permissions so your group can read AND write the file."
    echo
    echo "Current permissions:"
    ls -la "$file"
    echo
    echo "Hint: What does 640 mean in terms of rwx?"
    echo "Hint: You need group write permission."
}

start_sticky_bit() {
    local target="$PRACTICE_DIR/shared-workspace"

    mkdir -p "$target"

    # Create some files
    echo "Alice's work" > "$target/alice-notes.txt"
    echo "Bob's work" > "$target/bob-notes.txt"
    echo "Your work" > "$target/my-notes.txt"

    # Set permissions with sticky bit
    chmod 1777 "$target"

    print_pass "Created: $target"
    echo
    echo "Scenario: This is a shared workspace directory with the sticky bit set."
    echo
    echo "Current permissions:"
    ls -lad "$target"
    echo
    echo "Contents:"
    ls -la "$target"
    echo
    echo "Task 1: Understand what the 't' in permissions means."
    echo "Task 2: Try to delete alice-notes.txt and explain what happens."
    echo "Task 3: Remove the sticky bit from the directory."
    echo
    echo "Hint: The sticky bit is the '1' in 1777 or 't' in drwxrwxrwt"
}

start_setuid_issue() {
    local target="$PRACTICE_DIR/check-disk.sh"

    cat > "$target" << 'SCRIPT'
#!/bin/bash
# This script checks disk usage
echo "Disk Usage Report"
echo "================="
df -h
echo
echo "Running as: $(whoami)"
echo "Effective UID: $EUID"
SCRIPT

    # Make executable with setuid (won't actually work for scripts, but educational)
    chmod 4755 "$target"

    print_pass "Created: $target"
    echo
    echo "Scenario: Someone tried to make this script run with elevated privileges"
    echo "by setting the SetUID bit."
    echo
    echo "Current permissions:"
    ls -la "$target"
    echo
    echo "Task 1: Identify the SetUID bit in the permissions."
    echo "Task 2: Understand why SetUID on scripts is a security risk."
    echo "Task 3: Remove the SetUID bit while keeping it executable."
    echo
    echo "Hint: The 's' in permissions indicates SetUID."
    echo "Hint: 4755 = SetUID + rwxr-xr-x"
}

start_umask_chaos() {
    local target="$PRACTICE_DIR/umask-test"
    mkdir -p "$target"

    print_info "Creating files with different umask values..."

    # Create files with restrictive umask
    (
        umask 077
        touch "$target/private-file.txt"
    )

    # Create files with permissive umask
    (
        umask 000
        touch "$target/wide-open-file.txt"
    )

    # Create with typical umask
    (
        umask 022
        touch "$target/normal-file.txt"
    )

    print_pass "Created: $target"
    echo
    echo "Scenario: Files were created with different umask settings."
    echo
    echo "Contents:"
    ls -la "$target"
    echo
    echo "Task 1: Identify which file was created with each umask."
    echo "Task 2: Determine your current umask."
    echo "Task 3: Create a new file and predict its permissions."
    echo
    echo "Hint: umask SUBTRACTS from default permissions."
    echo "Hint: Default file permission is 666, default dir is 777."
}

# Check if scenario is fixed
check_scenario() {
    local scenario="$1"
    local fixed=true
    local partial=false

    print_header "Checking Scenario: $scenario"

    case "$scenario" in
        no-read)
            local target="$PRACTICE_DIR/secret-config.txt"
            if [[ -r "$target" ]]; then
                print_pass "File is now readable"
                # Check if it's not world-readable
                local perms
                perms=$(stat -c %a "$target")
                if [[ "${perms:2:1}" == "0" ]]; then
                    print_pass "File is not world-readable (secure)"
                else
                    print_warn "File is world-readable - consider restricting access"
                    partial=true
                fi
            else
                print_fail "File is still not readable"
                fixed=false
            fi
            ;;

        no-execute)
            local target="$PRACTICE_DIR/backup.sh"
            if [[ -x "$target" ]]; then
                print_pass "Script is now executable"
            else
                print_fail "Script is still not executable"
                fixed=false
            fi
            ;;

        no-write-dir)
            local target="$PRACTICE_DIR/logs"
            if [[ -w "$target" ]]; then
                print_pass "Directory is now writable"
                # Test creating a file
                if touch "$target/test-write.tmp" 2>/dev/null; then
                    print_pass "Can create files in directory"
                    rm "$target/test-write.tmp"
                fi
            else
                print_fail "Directory is still not writable"
                fixed=false
            fi
            ;;

        wrong-owner)
            local target="$PRACTICE_DIR/shared-data/report.txt"
            local perms
            perms=$(stat -c %a "$target")
            if [[ "${perms:1:1}" -ge 6 ]]; then
                print_pass "Group has read+write access"
            else
                print_fail "Group still doesn't have write access"
                fixed=false
            fi
            ;;

        sticky-bit)
            local target="$PRACTICE_DIR/shared-workspace"
            local perms
            perms=$(stat -c %a "$target")
            if [[ "${perms:0:1}" == "1" ]] || [[ "${perms:0:1}" == "3" ]] || [[ "${perms:0:1}" == "5" ]] || [[ "${perms:0:1}" == "7" ]]; then
                print_fail "Sticky bit is still set"
                fixed=false
            else
                print_pass "Sticky bit has been removed"
            fi
            ;;

        setuid-issue)
            local target="$PRACTICE_DIR/check-disk.sh"
            local perms
            perms=$(stat -c %a "$target")
            if [[ "${perms:0:1}" -ge 4 ]]; then
                print_fail "SetUID bit is still set"
                fixed=false
            else
                print_pass "SetUID bit has been removed"
            fi
            if [[ -x "$target" ]]; then
                print_pass "Script is still executable"
            else
                print_warn "Script is no longer executable"
                partial=true
            fi
            ;;

        umask-chaos)
            # Just verify understanding
            print_info "This is an educational scenario."
            print_info "Check your understanding:"
            echo
            echo "Your current umask: $(umask)"
            echo
            echo "File permissions in test directory:"
            ls -la "$PRACTICE_DIR/umask-test"
            echo
            print_pass "Review the permissions and verify your understanding."
            ;;

        *)
            print_fail "Unknown scenario: $scenario"
            exit 1
            ;;
    esac

    echo
    if [[ "$fixed" == "true" && "$partial" == "false" ]]; then
        print_pass "Scenario $scenario: FIXED!"
    elif [[ "$partial" == "true" ]]; then
        print_warn "Scenario $scenario: Partially fixed"
    else
        print_fail "Scenario $scenario: Not yet fixed"
    fi
}

# Usage
usage() {
    cat << 'EOF'
LPIC-1 Break/Fix Scenario: Broken Permissions

Usage: broken-permissions.sh <action> [scenario]

Actions:
  --list              List available scenarios
  --start <scenario>  Start a scenario
  --check <scenario>  Check if scenario is fixed
  --restore <scenario> Restore from backup

Scenarios:
  no-read        File cannot be read
  no-execute     Script cannot be executed
  no-write-dir   Cannot create files in directory
  wrong-owner    File has wrong group permissions
  sticky-bit     Sticky bit preventing deletion
  setuid-issue   SetUID bit on a script
  umask-chaos    Files with unexpected permissions

Examples:
  ./broken-permissions.sh --list
  ./broken-permissions.sh --start no-execute
  ./broken-permissions.sh --check no-execute
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
            if [[ -z "$scenario" ]]; then
                print_fail "Please specify a scenario"
                list_scenarios
                exit 1
            fi
            start_scenario "$scenario"
            ;;
        --check|-c)
            if [[ -z "$scenario" ]]; then
                print_fail "Please specify a scenario"
                exit 1
            fi
            check_scenario "$scenario"
            ;;
        --restore|-r)
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
