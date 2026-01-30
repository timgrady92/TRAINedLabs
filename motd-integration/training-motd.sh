#!/bin/bash
# LPIC-1 Training - Enhanced Login Message
# Shows prominent call-to-action and progress tracking

# Configuration
LPIC_DIR="/opt/LPIC-1/data"
DB_FILE="${LPIC_DIR}/progress.db"
FIRST_LOGIN_FILE="${LPIC_DIR}/.first-login-shown"

# Colors and formatting
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Box drawing characters (Unicode)
# Using simple ASCII for maximum compatibility
BOX_TL="+"
BOX_TR="+"
BOX_BL="+"
BOX_BR="+"
BOX_H="-"
BOX_V="|"
BOX_ML="+"
BOX_MR="+"

# Get terminal width (default to 68 if can't determine)
get_width() {
    local width
    width=$(tput cols 2>/dev/null || echo 68)
    # Cap at 68 for consistent display
    [[ $width -gt 68 ]] && width=68
    echo "$width"
}

# Get progress from database
get_progress() {
    if [[ ! -f "$DB_FILE" ]]; then
        echo "0|42|0"
        return
    fi

    local total completed percent
    total=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM objectives;" 2>/dev/null || echo "42")
    completed=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM objectives WHERE completed=1;" 2>/dev/null || echo "0")

    if [[ "$total" -gt 0 ]]; then
        percent=$((completed * 100 / total))
    else
        percent=0
    fi

    echo "$completed|$total|$percent"
}

# Create visual progress bar
progress_bar() {
    local percent="$1"
    local width=25
    local filled=$((width * percent / 100))
    local empty=$((width - filled))

    printf "["
    [[ $filled -gt 0 ]] && printf "%${filled}s" | tr ' ' '#'
    [[ $empty -gt 0 ]] && printf "%${empty}s" | tr ' ' '-'
    printf "]"
}

# Check if this is first login
is_first_login() {
    [[ ! -f "$FIRST_LOGIN_FILE" ]]
}

# Mark first login as shown
mark_first_login_shown() {
    mkdir -p "$LPIC_DIR"
    touch "$FIRST_LOGIN_FILE" 2>/dev/null || true
}

# Print centered text
print_centered() {
    local text="$1"
    local width=66
    local text_len=${#text}
    local padding=$(( (width - text_len) / 2 ))
    [[ $padding -lt 0 ]] && padding=0
    printf "%${padding}s%s" "" "$text"
}

# Print a horizontal line
print_line() {
    local char="${1:-$BOX_H}"
    printf "%s" "$BOX_V"
    printf '%66s' | tr ' ' "$char"
    printf "%s\n" "$BOX_V"
}

# Main display
main() {
    local progress_data
    progress_data=$(get_progress)
    IFS='|' read -r completed total percent <<< "$progress_data"

    # Determine progress color
    local color
    if [[ $percent -ge 80 ]]; then
        color="$GREEN"
    elif [[ $percent -ge 40 ]]; then
        color="$YELLOW"
    else
        color="$CYAN"
    fi

    echo

    # Top border
    echo -e "${BOLD}${CYAN}+------------------------------------------------------------------+${NC}"

    # Title section
    echo -e "${BOLD}${CYAN}|${NC}                                                                  ${BOLD}${CYAN}|${NC}"
    echo -e "${BOLD}${CYAN}|${NC}${BOLD}${WHITE}$(print_centered "L P I C - 1   T R A I N I N G   E N V I R O N M E N T")${NC}${BOLD}${CYAN}|${NC}"
    echo -e "${BOLD}${CYAN}|${NC}                                                                  ${BOLD}${CYAN}|${NC}"

    # Middle divider
    echo -e "${BOLD}${CYAN}+------------------------------------------------------------------+${NC}"

    # Progress section
    echo -e "${BOLD}${CYAN}|${NC}                                                                  ${BOLD}${CYAN}|${NC}"

    # Progress bar
    local bar
    bar=$(progress_bar "$percent")
    local progress_text
    progress_text=$(printf "Progress: %s  %d/%d (%d%%)" "$bar" "$completed" "$total" "$percent")
    echo -e "${BOLD}${CYAN}|${NC}  ${color}${progress_text}${NC}              ${BOLD}${CYAN}|${NC}"

    echo -e "${BOLD}${CYAN}|${NC}                                                                  ${BOLD}${CYAN}|${NC}"

    # Call to action - THE MOST IMPORTANT PART
    echo -e "${BOLD}${CYAN}|${NC}  ${BOLD}${WHITE}>>> To start training, type:${NC}  ${GREEN}${BOLD}lpic1${NC}                           ${BOLD}${CYAN}|${NC}"

    echo -e "${BOLD}${CYAN}|${NC}                                                                  ${BOLD}${CYAN}|${NC}"

    # Bottom border
    echo -e "${BOLD}${CYAN}+------------------------------------------------------------------+${NC}"

    echo

    # First-login welcome message (only shown once)
    if is_first_login; then
        echo -e "${DIM}Welcome! This is your first time here.${NC}"
        echo -e "${DIM}The ${GREEN}lpic1${NC}${DIM} command launches an interactive menu that will${NC}"
        echo -e "${DIM}guide you through Linux certification training.${NC}"
        echo
        mark_first_login_shown
    fi

    # Context-aware tip (after the main banner)
    if [[ $percent -eq 0 ]]; then
        echo -e "${DIM}Tip: Start with 'Learn' mode to understand concepts, then 'Practice' to apply them.${NC}"
    elif [[ $percent -lt 50 ]]; then
        echo -e "${DIM}Tip: Use 'lpic1 smart' for personalized recommendations on what to study next.${NC}"
    elif [[ $percent -lt 100 ]]; then
        echo -e "${DIM}Tip: Try 'Exam Mode' to test yourself under timed conditions.${NC}"
    else
        echo -e "${GREEN}Congratulations! You've completed all objectives.${NC}"
        echo -e "${DIM}Consider retaking the exam simulation to reinforce your knowledge.${NC}"
    fi

    echo
}

main
