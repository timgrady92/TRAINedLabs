#!/bin/bash
# LPIC-1 Break/Fix Scenario: Full Disk
# Simulates disk space exhaustion for troubleshooting practice
# Can be run as regular user (uses home directory)

set -euo pipefail

# Cleanup trap for interrupted operations
cleanup_on_exit() {
    # Only cleanup if we were in the middle of creating files
    if [[ -n "${CREATING_FILES:-}" ]]; then
        echo
        echo "Interrupted! Cleaning up partial scenario..."
        rm -rf "${PRACTICE_DIR:-}" 2>/dev/null || true
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
PRACTICE_DIR="${HOME}/lpic1-practice/disk-scenario"
SNAPSHOT_DIR="${HOME}/.lpic1/snapshots"
SCENARIO_NAME="full-disk"

# Available scenarios
declare -A SCENARIOS
SCENARIOS["large-files"]="Large files consuming space"
SCENARIOS["many-small-files"]="Many small files filling inodes"
SCENARIOS["hidden-space"]="Deleted files still holding space"
SCENARIOS["log-explosion"]="Runaway log files"

# List scenarios
list_scenarios() {
    print_header "Available Disk Space Scenarios"

    for id in "${!SCENARIOS[@]}"; do
        echo "  $id - ${SCENARIOS[$id]}"
    done

    echo
    print_info "These scenarios are safe and limited to ~100MB."
    print_info "They demonstrate disk troubleshooting techniques."
}

# Create snapshot
create_snapshot() {
    local scenario="$1"
    local snapshot_path="${SNAPSHOT_DIR}/${SCENARIO_NAME}-${scenario}"
    mkdir -p "$snapshot_path"
    print_pass "Snapshot created"
}

# Restore from snapshot
restore_snapshot() {
    local scenario="$1"

    print_info "Cleaning up scenario: $scenario"

    # Clean up based on scenario
    case "$scenario" in
        large-files)
            rm -rf "${PRACTICE_DIR}/large-files" 2>/dev/null || true
            ;;
        many-small-files)
            rm -rf "${PRACTICE_DIR}/small-files" 2>/dev/null || true
            ;;
        hidden-space)
            rm -rf "${PRACTICE_DIR}/hidden-space" 2>/dev/null || true
            # Kill any processes holding deleted files
            pkill -f "tail -f ${PRACTICE_DIR}" 2>/dev/null || true
            ;;
        log-explosion)
            rm -rf "${PRACTICE_DIR}/logs" 2>/dev/null || true
            ;;
        *)
            rm -rf "${PRACTICE_DIR}" 2>/dev/null || true
            ;;
    esac

    print_pass "Cleanup complete"
}

# Setup practice directory
setup_practice_dir() {
    mkdir -p "$PRACTICE_DIR"
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
        large-files)
            start_large_files
            ;;
        many-small-files)
            start_many_small_files
            ;;
        hidden-space)
            start_hidden_space
            ;;
        log-explosion)
            start_log_explosion
            ;;
    esac

    echo
    print_header "Scenario Active"
    print_info "Directory: $PRACTICE_DIR"
    echo
    print_warn "When done, run: $0 --check $scenario"
    print_warn "To cleanup, run: $0 --restore $scenario"
}

# Scenario implementations
start_large_files() {
    local target="${PRACTICE_DIR}/large-files"
    mkdir -p "$target"

    CREATING_FILES=1
    print_info "Creating large files..."

    # Create some large files with misleading names
    dd if=/dev/zero of="$target/system-backup.tar.gz" bs=1M count=30 2>/dev/null
    dd if=/dev/zero of="$target/.cache-data" bs=1M count=20 2>/dev/null  # Hidden file
    dd if=/dev/zero of="$target/old-database.sql" bs=1M count=25 2>/dev/null

    # Create a deeply nested large file
    mkdir -p "$target/var/lib/app/data/cache/temp"
    dd if=/dev/zero of="$target/var/lib/app/data/cache/temp/session-store.db" bs=1M count=15 2>/dev/null

    CREATING_FILES=""
    print_pass "Created ~90MB of files"
    echo
    echo "Problem: Disk usage has suddenly increased."
    echo "Location: $target"
    echo
    echo "Current usage in practice directory:"
    du -sh "$target"
    echo
    echo "Task: Find and identify the largest files."
    echo
    echo "Useful commands:"
    echo "  du -sh *              # Size of each item"
    echo "  du -ah | sort -h      # All files sorted by size"
    echo "  find . -size +10M     # Files larger than 10MB"
    echo "  ncdu                  # Interactive disk usage (if installed)"
    echo
    echo "Hint: Don't forget to check hidden files!"
}

start_many_small_files() {
    local target="${PRACTICE_DIR}/small-files"
    mkdir -p "$target"

    CREATING_FILES=1
    print_info "Creating many small files..."

    # Create thousands of small files
    for i in $(seq 1 1000); do
        echo "Log entry $i: $(date)" > "$target/log-$i.txt"
    done

    # Create files in subdirectories
    for dir in session cache temp old; do
        mkdir -p "$target/$dir"
        for i in $(seq 1 500); do
            echo "Data $i" > "$target/$dir/file-$i.dat"
        done
    done

    local file_count
    file_count=$(find "$target" -type f | wc -l)

    CREATING_FILES=""
    print_pass "Created $file_count files"
    echo
    echo "Problem: The filesystem is running out of inodes."
    echo "Location: $target"
    echo
    echo "Total files created: $file_count"
    echo "Space used: $(du -sh "$target" | cut -f1)"
    echo
    echo "Task: Understand the difference between disk space and inodes."
    echo
    echo "Useful commands:"
    echo "  df -h           # Disk space"
    echo "  df -i           # Inode usage"
    echo "  find . -type f | wc -l    # Count files"
    echo
    echo "Hint: Many small files can exhaust inodes before disk space."
}

start_hidden_space() {
    local target="${PRACTICE_DIR}/hidden-space"
    mkdir -p "$target"

    print_info "Creating a deleted-but-open file scenario..."

    # Create a large file
    dd if=/dev/zero of="$target/app.log" bs=1M count=50 2>/dev/null

    # Start a process that holds the file open
    (tail -f "$target/app.log" >/dev/null 2>&1 &)

    # Give it a moment to start
    sleep 1

    # Delete the file (but it's still held open)
    rm "$target/app.log"

    print_pass "Created scenario with deleted-but-open file"
    echo
    echo "Problem: Disk space shows as used, but you can't find the files."
    echo "Location: $target"
    echo
    echo "Check it yourself:"
    echo "  ls -la $target    # Should be empty"
    echo "  du -sh $target    # Should show ~50MB"
    echo
    echo "Wait... the directory is empty but still using 50MB?"
    echo
    echo "Task: Find where the space is actually being used."
    echo
    echo "Useful commands:"
    echo "  lsof +L1          # List deleted files still open"
    echo "  lsof | grep deleted"
    echo "  fuser -v $target"
    echo
    echo "Hint: A process is holding a deleted file open."
    echo "Hint: The space won't be freed until the process releases the file."
}

start_log_explosion() {
    local target="${PRACTICE_DIR}/logs"
    mkdir -p "$target"

    print_info "Simulating runaway log files..."

    # Create log files that look like they're from different dates
    for day in $(seq 1 30); do
        date_str=$(date -d "-$day days" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)
        # Larger logs for recent days
        if [[ $day -lt 7 ]]; then
            dd if=/dev/urandom of="$target/app-$date_str.log" bs=1K count=$((1024 * (8 - day))) 2>/dev/null
        else
            dd if=/dev/urandom of="$target/app-$date_str.log" bs=1K count=100 2>/dev/null
        fi
    done

    # Create a "current" log that's huge
    dd if=/dev/urandom of="$target/app.log" bs=1M count=20 2>/dev/null

    print_pass "Created log files"
    echo
    echo "Problem: Log files are consuming too much space."
    echo "Location: $target"
    echo
    echo "Current log space usage:"
    du -sh "$target"
    echo
    echo "File count and sizes:"
    # shellcheck disable=SC2012  # ls used for human-readable display, not parsing
    ls -lh "$target" | head -10
    echo "..."
    echo
    echo "Task: Implement a log rotation/cleanup strategy."
    echo
    echo "Questions to consider:"
    echo "  - Which logs are oldest?"
    echo "  - Which logs are largest?"
    echo "  - How would you automate this cleanup?"
    echo
    echo "Useful commands:"
    echo "  ls -lt           # Sort by time"
    echo "  ls -lS           # Sort by size"
    echo "  find . -mtime +7 # Files older than 7 days"
    echo "  logrotate        # System log rotation tool"
}

# Check if scenario is fixed
check_scenario() {
    local scenario="$1"
    local fixed=true

    print_header "Checking Scenario: $scenario"

    case "$scenario" in
        large-files)
            local target="${PRACTICE_DIR}/large-files"
            if [[ -d "$target" ]]; then
                local size
                size=$(du -sm "$target" 2>/dev/null | cut -f1)
                if [[ "$size" -lt 50 ]]; then
                    print_pass "Directory size reduced to ${size}MB"
                else
                    print_fail "Directory still using ${size}MB"
                    fixed=false
                fi
            else
                print_pass "Directory cleaned up"
            fi
            ;;

        many-small-files)
            local target="${PRACTICE_DIR}/small-files"
            if [[ -d "$target" ]]; then
                local count
                count=$(find "$target" -type f 2>/dev/null | wc -l)
                if [[ "$count" -lt 1000 ]]; then
                    print_pass "File count reduced to $count"
                else
                    print_fail "Still have $count files"
                    fixed=false
                fi
            else
                print_pass "Directory cleaned up"
            fi
            ;;

        hidden-space)
            # Check if process is still running
            if pgrep -f "tail -f ${PRACTICE_DIR}/hidden-space" >/dev/null 2>&1; then
                print_fail "Process still holding file open"
                print_info "Find it with: lsof +L1 | grep lpic1"
                fixed=false
            else
                print_pass "No processes holding deleted files"
            fi
            ;;

        log-explosion)
            local target="${PRACTICE_DIR}/logs"
            if [[ -d "$target" ]]; then
                local size
                size=$(du -sm "$target" 2>/dev/null | cut -f1)
                local count
                count=$(find "$target" -type f 2>/dev/null | wc -l)
                if [[ "$size" -lt 20 ]] || [[ "$count" -lt 10 ]]; then
                    print_pass "Logs cleaned up (${size}MB, $count files)"
                else
                    print_warn "Logs still at ${size}MB with $count files"
                    print_info "Consider removing logs older than 7 days"
                    fixed=false
                fi
            else
                print_pass "Log directory cleaned up"
            fi
            ;;

        *)
            print_fail "Unknown scenario: $scenario"
            exit 1
            ;;
    esac

    echo
    if [[ "$fixed" == "true" ]]; then
        print_pass "Scenario $scenario: Space recovered!"
    else
        print_fail "Scenario $scenario: More cleanup needed"
    fi
}

# Usage
usage() {
    cat << 'EOF'
LPIC-1 Break/Fix Scenario: Full Disk

Usage: full-disk.sh <action> [scenario]

Actions:
  --list              List available scenarios
  --start <scenario>  Start a scenario
  --check <scenario>  Check if scenario is fixed
  --restore <scenario> Cleanup scenario files

Scenarios:
  large-files        Large files consuming space
  many-small-files   Many files filling inodes
  hidden-space       Deleted files still using space
  log-explosion      Runaway log files

Examples:
  ./full-disk.sh --list
  ./full-disk.sh --start large-files
  ./full-disk.sh --check large-files
  ./full-disk.sh --restore large-files

Note: Scenarios use ~100MB in your home directory.
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
