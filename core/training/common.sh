#!/bin/bash
# LPIC-1 Training - Common Functions
# Shared utilities for lessons, exercises, and sandbox modes

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Symbols - with ASCII fallback for non-UTF-8 terminals
if [[ "${LANG:-}" == *UTF-8* ]] || [[ "${LC_ALL:-}" == *UTF-8* ]] || [[ "${LC_CTYPE:-}" == *UTF-8* ]]; then
    PASS="✓"
    FAIL="✗"
    WARN="⚠"
    INFO="ℹ"
    ARROW="→"
    BULLET="•"
    BAR_FILL="█"
    BAR_EMPTY="░"
else
    PASS="[OK]"
    FAIL="[FAIL]"
    WARN="[!]"
    INFO="[i]"
    ARROW="->"
    BULLET="*"
    BAR_FILL="#"
    BAR_EMPTY="-"
fi

# Configuration
LPIC_DIR="/opt/LPIC-1/data"
DB_FILE="${LPIC_DIR}/progress.db"
PRACTICE_DIR="/opt/LPIC-1/practice"

# ============================================================================
# Output Functions
# ============================================================================

print_pass() { echo -e "${GREEN}${PASS}${NC} $1"; }
print_fail() { echo -e "${RED}${FAIL}${NC} $1"; }
print_warn() { echo -e "${YELLOW}${WARN}${NC} $1"; }
print_info() { echo -e "${CYAN}${INFO}${NC} $1"; }

print_header() {
    local title="$1"
    local width=60
    echo
    echo -e "${BOLD}${BLUE}$(printf '═%.0s' $(seq 1 $width))${NC}"
    echo -e "${BOLD}${BLUE}  $title${NC}"
    echo -e "${BOLD}${BLUE}$(printf '═%.0s' $(seq 1 $width))${NC}"
    echo
}

print_subheader() {
    echo -e "\n${BOLD}${CYAN}──── $1 ────${NC}\n"
}

print_section() {
    echo -e "\n${BOLD}$1${NC}"
}

print_example() {
    echo -e "\n${CYAN}Example:${NC} $1"
}

print_command() {
    echo -e "  ${BOLD}\$ $1${NC}"
}

print_output() {
    echo -e "  ${DIM}$1${NC}"
}

print_tip() {
    echo -e "${YELLOW}${BULLET} Tip:${NC} $1"
}

print_exam_note() {
    echo -e "${MAGENTA}${BULLET} Exam Note:${NC} $1"
}

# ============================================================================
# Interactive Functions
# ============================================================================

wait_for_user() {
    local prompt="${1:-Press Enter to continue...}"
    echo
    echo -en "${DIM}${prompt}${NC} "
    read -r _
}

# Ask yes/no question
confirm() {
    local prompt="${1:-Continue?}"
    local response
    echo -en "${prompt} [y/N] "
    read -r response
    [[ "$response" =~ ^[Yy] ]]
}

# Get user choice from menu
choose_option() {
    local prompt="$1"
    shift
    local options=("$@")

    echo -e "\n${prompt}"
    for i in "${!options[@]}"; do
        echo "  $((i + 1)). ${options[$i]}"
    done
    echo

    local choice
    while true; do
        echo -en "Enter choice [1-${#options[@]}]: "
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#options[@]}" ]]; then
            return $((choice - 1))
        fi
        echo "Invalid choice. Please enter a number between 1 and ${#options[@]}."
    done
}

# ============================================================================
# Progress Bar
# ============================================================================

show_progress_bar() {
    local current="$1"
    local total="$2"
    local width="${3:-40}"
    local label="${4:-Progress}"

    local percent=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))

    printf "\r${label}: ["
    printf "%${filled}s" | tr ' ' "${BAR_FILL}"
    printf "%${empty}s" | tr ' ' "${BAR_EMPTY}"
    printf "] %3d%%" "$percent"
}

# ============================================================================
# Exercise Framework
# ============================================================================

print_exercise() {
    local title="$1"
    echo
    echo -e "${BOLD}${GREEN}═══ Exercise: $title ═══${NC}"
    echo
}

print_scenario() {
    echo -e "${BOLD}SCENARIO:${NC}"
    echo -e "${DIM}$1${NC}"
    echo
}

print_task() {
    echo -e "${BOLD}${YELLOW}Your task:${NC} $1"
    echo
}

# Show hint with level
show_hint() {
    local level="$1"
    local hint="$2"
    echo -e "\n${YELLOW}Hint $level:${NC}"
    echo -e "  $hint"
}

# Show solution after max hints
show_solution() {
    local solution="$1"
    echo -e "\n${YELLOW}Solution:${NC}"
    echo -e "  ${CYAN}$solution${NC}"
}

# Command timeout (seconds) - prevents hanging on blocking commands
COMMAND_TIMEOUT="${COMMAND_TIMEOUT:-5}"

# Validate user command against expected output
validate_command() {
    local user_cmd="$1"
    local expected_file="$2"
    local working_dir="${3:-$PRACTICE_DIR}"

    # Execute user command safely with timeout
    local user_output
    local exit_code
    user_output=$(cd "$working_dir" && timeout "$COMMAND_TIMEOUT" bash -c "$user_cmd" 2>&1)
    exit_code=$?

    # Check for timeout (exit code 124)
    if [[ $exit_code -eq 124 ]]; then
        echo -e "\n${YELLOW}Command timed out (${COMMAND_TIMEOUT}s limit). Try a different approach.${NC}"
        return 1
    fi

    # Get expected output
    local expected_output
    expected_output=$(cat "$expected_file" 2>/dev/null) || return 1

    # Compare
    if [[ "$user_output" == "$expected_output" ]]; then
        return 0
    else
        return 1
    fi
}

# Execute user command with timeout (for exercise files)
# Returns output via stdout, sets COMMAND_EXIT_CODE and COMMAND_TIMED_OUT
execute_user_command() {
    local user_cmd="$1"
    local working_dir="${2:-$PRACTICE_DIR}"

    COMMAND_TIMED_OUT=0
    local output
    output=$(cd "$working_dir" && timeout "$COMMAND_TIMEOUT" bash -c "$user_cmd" 2>&1)
    COMMAND_EXIT_CODE=$?

    if [[ $COMMAND_EXIT_CODE -eq 124 ]]; then
        COMMAND_TIMED_OUT=1
        echo -e "${YELLOW}Command timed out (${COMMAND_TIMEOUT}s limit)${NC}" >&2
    fi

    echo "$output"
}

# Flexible command validation using key patterns
validate_command_pattern() {
    local user_cmd="$1"
    shift
    local required_patterns=("$@")

    local matches=0
    for pattern in "${required_patterns[@]}"; do
        if [[ "$user_cmd" == *"$pattern"* ]]; then
            ((matches++)) || true
        fi
    done

    [[ $matches -eq ${#required_patterns[@]} ]]
}

# ============================================================================
# Progress Tracking
# ============================================================================

record_exercise_attempt() {
    local topic="$1"
    local exercise="$2"
    local success="${3:-0}"

    [[ ! -f "$DB_FILE" ]] && return

    local cmd_name="${topic}"
    if [[ $success -eq 1 ]]; then
        sqlite3 "$DB_FILE" "UPDATE commands SET successes = successes + 1, attempts = attempts + 1, last_practiced = datetime('now') WHERE command LIKE '%$cmd_name%' LIMIT 1;" 2>/dev/null || true
    else
        sqlite3 "$DB_FILE" "UPDATE commands SET attempts = attempts + 1, last_practiced = datetime('now') WHERE command LIKE '%$cmd_name%' LIMIT 1;" 2>/dev/null || true
    fi
}

record_lesson_complete() {
    local topic="$1"

    [[ ! -f "$DB_FILE" ]] && return

    sqlite3 "$DB_FILE" "INSERT INTO sessions (started_at, ended_at, objectives_practiced) VALUES (datetime('now'), datetime('now'), 'lesson-$topic');" 2>/dev/null || true
}

get_mastery_level() {
    local topic="$1"

    [[ ! -f "$DB_FILE" ]] && echo "unknown" && return

    local stats
    stats=$(sqlite3 "$DB_FILE" "SELECT SUM(successes), SUM(attempts) FROM commands WHERE command LIKE '%$topic%';" 2>/dev/null) || {
        echo "unknown"
        return
    }

    local successes attempts
    IFS='|' read -r successes attempts <<< "$stats"

    successes=${successes:-0}
    attempts=${attempts:-0}

    if [[ $attempts -eq 0 ]]; then
        echo "novice"
    elif [[ $attempts -lt 5 ]]; then
        echo "beginner"
    elif [[ $successes -ge $((attempts * 8 / 10)) ]]; then
        echo "proficient"
    elif [[ $successes -ge $((attempts * 6 / 10)) ]]; then
        echo "intermediate"
    else
        echo "practicing"
    fi
}

# ============================================================================
# Lesson Display Helpers
# ============================================================================

show_option() {
    local flag="$1"
    local desc="$2"
    printf "  ${CYAN}%-8s${NC} %s\n" "$flag" "$desc"
}

show_option_table() {
    local -n options=$1
    for opt in "${!options[@]}"; do
        printf "  ${CYAN}%-8s${NC} %s\n" "$opt" "${options[$opt]}"
    done
}

# Show live command example with actual output
show_live_example() {
    local description="$1"
    local command="$2"
    local working_dir="${3:-$PRACTICE_DIR}"

    echo -e "\n${CYAN}Example:${NC} $description"
    echo -e "${BOLD}Command:${NC} $command"
    echo -e "${DIM}Output:${NC}"

    # Execute and show output (limit to first 10 lines)
    (cd "$working_dir" && eval "$command" 2>&1) | head -10 | sed 's/^/  /'

    local total_lines
    total_lines=$((cd "$working_dir" && eval "$command" 2>&1) | wc -l)
    if [[ $total_lines -gt 10 ]]; then
        echo -e "  ${DIM}... ($((total_lines - 10)) more lines)${NC}"
    fi
}

# Show command comparison (before/after or alternatives)
show_comparison() {
    local title="$1"
    local cmd1="$2"
    local desc1="$3"
    local cmd2="$4"
    local desc2="$5"

    echo -e "\n${BOLD}$title${NC}"
    echo -e "  ${CYAN}$cmd1${NC}"
    echo -e "    ${DIM}$desc1${NC}"
    echo
    echo -e "  ${CYAN}$cmd2${NC}"
    echo -e "    ${DIM}$desc2${NC}"
}

# ============================================================================
# Real-World Context
# ============================================================================

show_real_world_uses() {
    local -n uses=$1
    echo -e "\n${BOLD}Real-World Uses:${NC}"
    for use in "${uses[@]}"; do
        echo -e "  ${BULLET} $use"
    done
}

show_common_mistakes() {
    local -n mistakes=$1
    echo -e "\n${BOLD}${RED}Common Mistakes:${NC}"
    for mistake in "${mistakes[@]}"; do
        echo -e "  ${WARN} $mistake"
    done
}

# ============================================================================
# Topic Information
# ============================================================================

# Get practice file path
get_practice_file() {
    local type="$1"
    local name="$2"

    case "$type" in
        text)   echo "${PRACTICE_DIR}/text/${name}" ;;
        log)    echo "${PRACTICE_DIR}/logs/${name}" ;;
        config) echo "${PRACTICE_DIR}/configs/${name}" ;;
        grep)   echo "${PRACTICE_DIR}/text/grep-practice/${name}" ;;
        sed)    echo "${PRACTICE_DIR}/text/sed-practice/${name}" ;;
        awk)    echo "${PRACTICE_DIR}/text/awk-practice/${name}" ;;
        find)   echo "${PRACTICE_DIR}/find-practice/${name}" ;;
        perm)   echo "${PRACTICE_DIR}/permissions-lab/${name}" ;;
        *)      echo "${PRACTICE_DIR}/${name}" ;;
    esac
}

# Check if practice files exist
check_practice_files() {
    if [[ ! -d "$PRACTICE_DIR" ]]; then
        print_warn "Practice files not found at: $PRACTICE_DIR"
        print_info "Run the seed-data.sh script to create practice files"
        return 1
    fi
    return 0
}

# ============================================================================
# Topic Categories
# ============================================================================

declare -A TOPIC_CATEGORIES
TOPIC_CATEGORIES=(
    ["grep"]="text"
    ["sed"]="text"
    ["awk"]="text"
    ["find"]="files"
    ["tar"]="files"
    ["permissions"]="files"
    ["chmod"]="files"
    ["chown"]="files"
    ["processes"]="system"
    ["ps"]="system"
    ["kill"]="system"
    ["users"]="admin"
    ["useradd"]="admin"
    ["networking"]="network"
    ["ip"]="network"
    ["ss"]="network"
    ["filesystems"]="storage"
    ["mount"]="storage"
    ["systemd"]="services"
    ["systemctl"]="services"
)

declare -A TOPIC_OBJECTIVES
TOPIC_OBJECTIVES=(
    ["grep"]="103.2"
    ["sed"]="103.2"
    ["awk"]="103.2"
    ["find"]="103.3"
    ["tar"]="103.3"
    ["permissions"]="104.5"
    ["processes"]="103.5"
    ["users"]="107.1"
    ["networking"]="109.1-109.4"
    ["filesystems"]="104.1-104.3"
    ["systemd"]="101.3"
)

get_topic_objective() {
    local topic="$1"
    echo "${TOPIC_OBJECTIVES[$topic]:-unknown}"
}

get_topic_category() {
    local topic="$1"
    echo "${TOPIC_CATEGORIES[$topic]:-general}"
}

# ============================================================================
# TUI Detection and Helpers
# ============================================================================

# Detect available TUI tools
HAS_DIALOG=""
HAS_WHIPTAIL=""
HAS_GUM=""
HAS_FZF=""

_detect_tui_tools() {
    command -v dialog &>/dev/null && HAS_DIALOG="1" || true
    command -v whiptail &>/dev/null && HAS_WHIPTAIL="1" || true
    command -v gum &>/dev/null && HAS_GUM="1" || true
    command -v fzf &>/dev/null && HAS_FZF="1" || true
}

# Call detection once when sourced
_detect_tui_tools

# Check if TUI is available
tui_available() {
    [[ -n "$HAS_DIALOG" || -n "$HAS_WHIPTAIL" ]]
}

# Get best available TUI tool name
tui_tool() {
    if [[ -n "$HAS_DIALOG" ]]; then
        echo "dialog"
    elif [[ -n "$HAS_WHIPTAIL" ]]; then
        echo "whiptail"
    else
        echo "none"
    fi
}

# Simple TUI menu wrapper (for use without full widgets.sh)
# Usage: tui_simple_menu "Title" "opt1" "desc1" "opt2" "desc2" ...
tui_simple_menu() {
    local title="$1"
    shift
    local items=("$@")

    if [[ -n "$HAS_DIALOG" ]]; then
        dialog --clear --title "$title" \
            --menu "Select option:" 15 50 8 \
            "${items[@]}" 3>&1 1>&2 2>&3
    elif [[ -n "$HAS_WHIPTAIL" ]]; then
        whiptail --title "$title" \
            --menu "Select option:" 15 50 8 \
            "${items[@]}" 3>&1 1>&2 2>&3
    else
        # Fallback to numbered selection
        echo -e "\n${BOLD}${CYAN}$title${NC}\n"
        local tags=()
        local i=0
        while [[ $i -lt ${#items[@]} ]]; do
            tags+=("${items[$i]}")
            printf "  %2d) %-15s %s\n" "$((${#tags[@]}))" "${items[$i]}" "${items[$((i+1))]}"
            ((i+=2))
        done
        echo
        local choice
        echo -en "Enter choice [1-${#tags[@]}]: "
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#tags[@]}" ]]; then
            echo "${tags[$((choice-1))]}"
        fi
    fi
}

# Simple TUI yes/no wrapper
tui_simple_yesno() {
    local title="$1"
    local question="$2"

    if [[ -n "$HAS_GUM" ]]; then
        gum confirm "$question"
    elif [[ -n "$HAS_DIALOG" ]]; then
        dialog --clear --title "$title" --yesno "$question" 8 50
    elif [[ -n "$HAS_WHIPTAIL" ]]; then
        whiptail --title "$title" --yesno "$question" 8 50
    else
        local response
        echo -en "$question [y/N] "
        read -r response
        [[ "$response" =~ ^[Yy] ]]
    fi
}
