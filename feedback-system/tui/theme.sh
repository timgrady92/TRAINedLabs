#!/bin/bash
# LPIC-1 Professional Theme System
# Unified visual identity with semantic colors and consistent styling

# ═══════════════════════════════════════════════════════════════════════════════
# BRAND COLORS (Semantic)
# Using $'...' ANSI-C quoting for proper escape sequence interpretation
# ═══════════════════════════════════════════════════════════════════════════════
THEME_PRIMARY=$'\033[38;5;33m'      # Blue - main brand color
THEME_SECONDARY=$'\033[38;5;245m'   # Gray - secondary text
THEME_ACCENT=$'\033[38;5;214m'      # Orange - highlights
THEME_SUCCESS=$'\033[38;5;34m'      # Green - success states
THEME_ERROR=$'\033[38;5;196m'       # Red - errors
THEME_WARNING=$'\033[38;5;220m'     # Yellow - warnings
THEME_MUTED=$'\033[2m'              # Dim - de-emphasized text
THEME_BOLD=$'\033[1m'
THEME_RESET=$'\033[0m'

# ═══════════════════════════════════════════════════════════════════════════════
# BOX DRAWING (Consistent Unicode with ASCII fallback)
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "${LANG:-}" == *UTF-8* ]] || [[ "${LC_ALL:-}" == *UTF-8* ]] || [[ "${LC_CTYPE:-}" == *UTF-8* ]]; then
    BOX_TL="╭"  BOX_TR="╮"  BOX_BL="╰"  BOX_BR="╯"  # Rounded corners
    BOX_H="─"   BOX_V="│"                            # Lines
    BOX_T="┬"   BOX_B="┴"   BOX_L="├"   BOX_R="┤"   # Junctions
    BOX_DOUBLE_H="═"
else
    BOX_TL="+"  BOX_TR="+"  BOX_BL="+"  BOX_BR="+"
    BOX_H="-"   BOX_V="|"
    BOX_T="+"   BOX_B="+"   BOX_L="+"   BOX_R="+"
    BOX_DOUBLE_H="="
fi

# ═══════════════════════════════════════════════════════════════════════════════
# ICONS (Minimal, Professional with ASCII fallback)
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "${LANG:-}" == *UTF-8* ]] || [[ "${LC_ALL:-}" == *UTF-8* ]] || [[ "${LC_CTYPE:-}" == *UTF-8* ]]; then
    ICON_CHECK="✓"   ICON_CROSS="✗"   ICON_ARROW="→"
    ICON_DOT="•"     ICON_STAR="★"    ICON_INFO="ℹ"
    ICON_WARN="⚠"    ICON_BAR_FILL="█" ICON_BAR_EMPTY="░"
else
    ICON_CHECK="[OK]"  ICON_CROSS="[X]"  ICON_ARROW="->"
    ICON_DOT="*"       ICON_STAR="*"     ICON_INFO="[i]"
    ICON_WARN="[!]"    ICON_BAR_FILL="#" ICON_BAR_EMPTY="-"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# LAYOUT FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Professional header with clean branding
# Usage: theme_header "Title Text"
theme_header() {
    local title="$1"
    local width="${2:-64}"
    local title_len=${#title}
    local padding=$(( (width - title_len - 2) / 2 ))
    local right_padding=$(( width - padding - title_len - 2 ))

    echo
    echo -e "${THEME_PRIMARY}${BOX_TL}$(printf '%*s' "$width" | tr ' ' "$BOX_H")${BOX_TR}${THEME_RESET}"
    echo -e "${THEME_PRIMARY}${BOX_V}${THEME_RESET}$(printf '%*s' "$padding")${THEME_BOLD} $title ${THEME_RESET}$(printf '%*s' "$right_padding")${THEME_PRIMARY}${BOX_V}${THEME_RESET}"
    echo -e "${THEME_PRIMARY}${BOX_BL}$(printf '%*s' "$width" | tr ' ' "$BOX_H")${BOX_BR}${THEME_RESET}"
    echo
}

# Subtle section divider
# Usage: theme_divider [width]
theme_divider() {
    local width="${1:-64}"
    echo -e "${THEME_SECONDARY}$(printf '%*s' "$width" | tr ' ' "$BOX_H")${THEME_RESET}"
}

# Status messages with icons
theme_success() { echo -e " ${THEME_SUCCESS}${ICON_CHECK}${THEME_RESET} $1"; }
theme_error()   { echo -e " ${THEME_ERROR}${ICON_CROSS}${THEME_RESET} $1"; }
theme_warning() { echo -e " ${THEME_WARNING}${ICON_WARN}${THEME_RESET} $1"; }
theme_info()    { echo -e " ${THEME_PRIMARY}${ICON_INFO}${THEME_RESET} $1"; }

# Clean prompt (uses echo to avoid read -p escape issues)
# Usage: theme_prompt "Your command:"
#        read -r user_input
theme_prompt() {
    local prompt="$1"
    echo -en "${THEME_PRIMARY}${ICON_ARROW}${THEME_RESET} ${prompt} "
}

# Muted helper text
# Usage: theme_muted "Some dimmed text"
theme_muted() {
    echo -e "${THEME_MUTED}$1${THEME_RESET}"
}

# Exercise header (used by exercise files)
# Usage: theme_exercise "Exercise Title"
theme_exercise() {
    local title="$1"
    echo
    echo -e "${THEME_PRIMARY}${BOX_TL}$(printf '%*s' 58 | tr ' ' "$BOX_H")${BOX_TR}${THEME_RESET}"
    echo -e "${THEME_PRIMARY}${BOX_V}${THEME_RESET}  ${THEME_BOLD}Exercise: ${title}${THEME_RESET}$(printf '%*s' $((54 - ${#title})))${THEME_PRIMARY}${BOX_V}${THEME_RESET}"
    echo -e "${THEME_PRIMARY}${BOX_BL}$(printf '%*s' 58 | tr ' ' "$BOX_H")${BOX_BR}${THEME_RESET}"
    echo
}

# Task/instruction highlight
# Usage: theme_task "Your task description"
theme_task() {
    echo -e "${THEME_BOLD}${THEME_ACCENT}Task:${THEME_RESET} $1"
}

# Hint display with level
# Usage: theme_hint 1 "This is hint level 1"
theme_hint() {
    local level="$1"
    local hint="$2"
    echo -e "\n${THEME_WARNING}Hint $level:${THEME_RESET}"
    echo -e "  $hint"
}

# Solution display
# Usage: theme_solution "grep -i 'error' file.log"
theme_solution() {
    local solution="$1"
    echo -e "\n${THEME_WARNING}Solution:${THEME_RESET}"
    echo -e "  ${THEME_PRIMARY}$solution${THEME_RESET}"
}

# Progress bar
# Usage: theme_progress_bar 75 40 "Progress"
theme_progress_bar() {
    local percent="$1"
    local width="${2:-30}"
    local label="${3:-Progress}"
    local filled=$((width * percent / 100))
    local empty=$((width - filled))

    printf "%s: [" "$label"
    printf "%${filled}s" | tr ' ' "${ICON_BAR_FILL}"
    printf "%${empty}s" | tr ' ' "${ICON_BAR_EMPTY}"
    printf "] %3d%%\n" "$percent"
}

# Session header for practice/test sessions
# Usage: theme_session_header "grep Practice Session" "5 exercises"
theme_session_header() {
    local title="$1"
    local subtitle="${2:-}"

    echo
    echo -e "${THEME_BOLD}${THEME_PRIMARY}$title${THEME_RESET}"
    if [[ -n "$subtitle" ]]; then
        theme_muted "$subtitle"
    fi
    echo
}

# Wait for user with proper escape handling
# Usage: theme_wait "Press Enter to continue..."
theme_wait() {
    local prompt="${1:-Press Enter to continue...}"
    echo
    echo -en "${THEME_MUTED}${prompt}${THEME_RESET} "
    read -r _
}

# Confirm yes/no with proper escape handling
# Usage: if theme_confirm "Continue?"; then ...
theme_confirm() {
    local prompt="${1:-Continue?}"
    local response
    echo -en "${prompt} [y/N] "
    read -r response
    [[ "$response" =~ ^[Yy] ]]
}

# Command display (for showing example commands)
# Usage: theme_command "grep -i 'error' logs/system.log"
theme_command() {
    echo -e "  ${THEME_BOLD}\$ $1${THEME_RESET}"
}

# Output display (dimmed, for showing command output)
# Usage: theme_output "line 1 of output"
theme_output() {
    echo -e "  ${THEME_MUTED}$1${THEME_RESET}"
}

# Tip display
# Usage: theme_tip "Use -i for case-insensitive matching"
theme_tip() {
    echo -e "${THEME_ACCENT}${ICON_DOT} Tip:${THEME_RESET} $1"
}

# Exam note display
# Usage: theme_exam_note "This is commonly tested on the LPIC-1 exam"
theme_exam_note() {
    echo -e "${THEME_PRIMARY}${ICON_DOT} Exam Note:${THEME_RESET} $1"
}

# Section header (smaller than main header)
# Usage: theme_section "Options and Flags"
theme_section() {
    echo -e "\n${THEME_BOLD}$1${THEME_RESET}"
}

# Subheader with decorative line
# Usage: theme_subheader "Basic Usage"
theme_subheader() {
    echo -e "\n${THEME_BOLD}${THEME_PRIMARY}${BOX_H}${BOX_H}${BOX_H}${BOX_H} $1 ${BOX_H}${BOX_H}${BOX_H}${BOX_H}${THEME_RESET}\n"
}
