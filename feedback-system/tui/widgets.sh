#!/bin/bash
# LPIC-1 TUI - Reusable Widget Library
# Provides menu, progress bar, message box, and input widgets
# with graceful fallback from dialog → whiptail → basic terminal

# ============================================================================
# Tool Detection
# ============================================================================

# Detect available TUI tools (set once at source time)
HAS_DIALOG=""
HAS_WHIPTAIL=""
HAS_GUM=""
HAS_FZF=""

_detect_tui_tools() {
    command -v dialog &>/dev/null && HAS_DIALOG="1"
    command -v whiptail &>/dev/null && HAS_WHIPTAIL="1"
    command -v gum &>/dev/null && HAS_GUM="1"
    command -v fzf &>/dev/null && HAS_FZF="1"
}
_detect_tui_tools

# ============================================================================
# UTF-8 Detection - ASCII fallback for non-UTF-8 terminals
# ============================================================================

if [[ "${LANG:-}" == *UTF-8* ]] || [[ "${LC_ALL:-}" == *UTF-8* ]] || [[ "${LC_CTYPE:-}" == *UTF-8* ]]; then
    TUI_SYM_PASS="✓"
    TUI_SYM_FAIL="✗"
    TUI_SYM_WARN="⚠"
    TUI_SYM_INFO="ℹ"
    TUI_SYM_BULLET="•"
    TUI_SYM_HLINE="═"
    TUI_SYM_BAR_FILL="█"
    TUI_SYM_BAR_EMPTY="░"
    TUI_SYM_NAV="↑↓ Navigate  Enter Select  Q Quit"
else
    TUI_SYM_PASS="[OK]"
    TUI_SYM_FAIL="[FAIL]"
    TUI_SYM_WARN="[!]"
    TUI_SYM_INFO="[i]"
    TUI_SYM_BULLET="*"
    TUI_SYM_HLINE="="
    TUI_SYM_BAR_FILL="#"
    TUI_SYM_BAR_EMPTY="-"
    TUI_SYM_NAV="Up/Down Navigate  Enter Select  Q Quit"
fi

# Check if any TUI tool is available
tui_available() {
    [[ -n "$HAS_DIALOG" || -n "$HAS_WHIPTAIL" ]]
}

# Get the best available TUI tool
tui_tool() {
    if [[ -n "$HAS_DIALOG" ]]; then
        echo "dialog"
    elif [[ -n "$HAS_WHIPTAIL" ]]; then
        echo "whiptail"
    else
        echo "none"
    fi
}

# ============================================================================
# Colors (for fallback mode)
# ============================================================================

TUI_RED='\033[0;31m'
TUI_GREEN='\033[0;32m'
TUI_YELLOW='\033[1;33m'
TUI_CYAN='\033[0;36m'
TUI_BLUE='\033[0;34m'
TUI_MAGENTA='\033[0;35m'
TUI_BOLD='\033[1m'
TUI_DIM='\033[2m'
TUI_NC='\033[0m'

# ============================================================================
# Menu Widget
# ============================================================================

# Display a menu and return the selected option
# Usage: tui_menu "Title" height width "tag1" "desc1" "tag2" "desc2" ...
# Returns: Selected tag via stdout, exit code 0 on selection, 1 on cancel
tui_menu() {
    local title="$1"
    local height="$2"
    local width="$3"
    shift 3
    local items=("$@")

    local menu_height=$((height - 7))
    [[ $menu_height -lt 1 ]] && menu_height=10

    if [[ -n "$HAS_DIALOG" ]]; then
        dialog --clear --title "$title" \
            --menu "Select an option:" "$height" "$width" "$menu_height" \
            "${items[@]}" 3>&1 1>&2 2>&3
        return $?
    elif [[ -n "$HAS_WHIPTAIL" ]]; then
        whiptail --title "$title" \
            --menu "Select an option:" "$height" "$width" "$menu_height" \
            "${items[@]}" 3>&1 1>&2 2>&3
        return $?
    else
        _fallback_menu "$title" "${items[@]}"
        return $?
    fi
}

# Fallback menu using select
_fallback_menu() {
    local title="$1"
    shift
    local items=("$@")

    echo
    echo -e "${TUI_BOLD}${TUI_CYAN}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE} $title ${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_NC}"
    echo

    # Build options array (tags only)
    local tags=()
    local descs=()
    local i=0
    while [[ $i -lt ${#items[@]} ]]; do
        tags+=("${items[$i]}")
        descs+=("${items[$((i+1))]}")
        ((i+=2))
    done

    # Display numbered menu
    for i in "${!tags[@]}"; do
        printf "  ${TUI_CYAN}%2d)${TUI_NC} %-15s %s\n" "$((i+1))" "${tags[$i]}" "${descs[$i]}"
    done
    echo
    printf "  ${TUI_DIM} 0) Cancel/Back${TUI_NC}\n"
    echo

    # Get selection
    local choice
    while true; do
        read -rp "Enter choice [0-${#tags[@]}]: " choice
        if [[ "$choice" == "0" || "$choice" == "q" || "$choice" == "Q" ]]; then
            return 1
        fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#tags[@]}" ]]; then
            echo "${tags[$((choice-1))]}"
            return 0
        fi
        echo "Invalid choice. Please enter a number between 0 and ${#tags[@]}."
    done
}

# ============================================================================
# Checklist Widget
# ============================================================================

# Display a checklist and return selected items
# Usage: tui_checklist "Title" height width "tag1" "desc1" "on/off" "tag2" "desc2" "on/off" ...
# Returns: Space-separated selected tags via stdout
tui_checklist() {
    local title="$1"
    local height="$2"
    local width="$3"
    shift 3
    local items=("$@")

    local list_height=$((height - 7))
    [[ $list_height -lt 1 ]] && list_height=10

    if [[ -n "$HAS_DIALOG" ]]; then
        dialog --clear --title "$title" \
            --checklist "Select items (space to toggle):" "$height" "$width" "$list_height" \
            "${items[@]}" 3>&1 1>&2 2>&3
        return $?
    elif [[ -n "$HAS_WHIPTAIL" ]]; then
        whiptail --title "$title" \
            --checklist "Select items (space to toggle):" "$height" "$width" "$list_height" \
            "${items[@]}" 3>&1 1>&2 2>&3
        return $?
    else
        _fallback_checklist "$title" "${items[@]}"
        return $?
    fi
}

_fallback_checklist() {
    local title="$1"
    shift
    local items=("$@")

    echo
    echo -e "${TUI_BOLD}${TUI_CYAN}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE} $title ${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_NC}"
    echo "Enter numbers separated by spaces (e.g., 1 3 5)"
    echo

    # Build options array
    local tags=()
    local descs=()
    local states=()
    local i=0
    while [[ $i -lt ${#items[@]} ]]; do
        tags+=("${items[$i]}")
        descs+=("${items[$((i+1))]}")
        states+=("${items[$((i+2))]}")
        ((i+=3))
    done

    # Display numbered list
    for i in "${!tags[@]}"; do
        local marker="[ ]"
        [[ "${states[$i]}" == "on" ]] && marker="[*]"
        printf "  ${TUI_CYAN}%2d)${TUI_NC} %s %-15s %s\n" "$((i+1))" "$marker" "${tags[$i]}" "${descs[$i]}"
    done
    echo

    # Get selection
    local choice
    read -rp "Enter choices (or Enter for defaults): " choice

    if [[ -z "$choice" ]]; then
        # Return defaults
        local selected=()
        for i in "${!tags[@]}"; do
            [[ "${states[$i]}" == "on" ]] && selected+=("${tags[$i]}")
        done
        echo "${selected[*]}"
    else
        # Parse user selection
        local selected=()
        for num in $choice; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [[ "$num" -ge 1 ]] && [[ "$num" -le "${#tags[@]}" ]]; then
                selected+=("${tags[$((num-1))]}")
            fi
        done
        echo "${selected[*]}"
    fi
    return 0
}

# ============================================================================
# Message Box Widget
# ============================================================================

# Display a message box
# Usage: tui_msgbox "Title" "Message" [height] [width]
tui_msgbox() {
    local title="$1"
    local message="$2"
    local height="${3:-10}"
    local width="${4:-50}"

    if [[ -n "$HAS_DIALOG" ]]; then
        dialog --clear --title "$title" --msgbox "$message" "$height" "$width"
    elif [[ -n "$HAS_WHIPTAIL" ]]; then
        whiptail --title "$title" --msgbox "$message" "$height" "$width"
    else
        echo
        echo -e "${TUI_BOLD}${TUI_CYAN}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE} $title ${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_NC}"
        echo
        echo -e "$message"
        echo
        read -rp "Press Enter to continue..."
    fi
}

# ============================================================================
# Yes/No Dialog Widget
# ============================================================================

# Display a yes/no dialog
# Usage: tui_yesno "Title" "Question" [height] [width]
# Returns: 0 for Yes, 1 for No
tui_yesno() {
    local title="$1"
    local question="$2"
    local height="${3:-8}"
    local width="${4:-50}"

    if [[ -n "$HAS_GUM" ]]; then
        gum confirm "$question" && return 0 || return 1
    elif [[ -n "$HAS_DIALOG" ]]; then
        dialog --clear --title "$title" --yesno "$question" "$height" "$width"
        return $?
    elif [[ -n "$HAS_WHIPTAIL" ]]; then
        whiptail --title "$title" --yesno "$question" "$height" "$width"
        return $?
    else
        echo
        echo -e "${TUI_BOLD}$title${TUI_NC}"
        local response
        read -rp "$question [y/N] " response
        [[ "$response" =~ ^[Yy] ]] && return 0 || return 1
    fi
}

# ============================================================================
# Input Box Widget
# ============================================================================

# Display an input box
# Usage: tui_input "Title" "Prompt" [default] [height] [width]
# Returns: User input via stdout
tui_input() {
    local title="$1"
    local prompt="$2"
    local default="${3:-}"
    local height="${4:-8}"
    local width="${5:-50}"

    if [[ -n "$HAS_GUM" ]]; then
        gum input --placeholder "$prompt" --value "$default"
        return $?
    elif [[ -n "$HAS_DIALOG" ]]; then
        dialog --clear --title "$title" --inputbox "$prompt" "$height" "$width" "$default" 3>&1 1>&2 2>&3
        return $?
    elif [[ -n "$HAS_WHIPTAIL" ]]; then
        whiptail --title "$title" --inputbox "$prompt" "$height" "$width" "$default" 3>&1 1>&2 2>&3
        return $?
    else
        echo
        echo -e "${TUI_BOLD}$title${TUI_NC}"
        local input
        if [[ -n "$default" ]]; then
            read -rp "$prompt [$default]: " input
            echo "${input:-$default}"
        else
            read -rp "$prompt: " input
            echo "$input"
        fi
        return 0
    fi
}

# ============================================================================
# Progress Gauge Widget
# ============================================================================

# Display a progress gauge
# Usage: tui_gauge "Title" percent "Text"
# Or pipe percentages: for i in {0..100}; do echo $i; sleep 0.1; done | tui_gauge "Title" 0 "Loading..."
tui_gauge() {
    local title="$1"
    local percent="${2:-0}"
    local text="${3:-}"

    if [[ -n "$HAS_DIALOG" ]]; then
        if [[ ! -t 0 ]]; then
            # Reading from pipe
            dialog --title "$title" --gauge "$text" 7 50 "$percent"
        else
            echo "$percent" | dialog --title "$title" --gauge "$text" 7 50 0
        fi
    elif [[ -n "$HAS_WHIPTAIL" ]]; then
        if [[ ! -t 0 ]]; then
            whiptail --title "$title" --gauge "$text" 7 50 "$percent"
        else
            echo "$percent" | whiptail --title "$title" --gauge "$text" 7 50 0
        fi
    else
        _fallback_progress_bar "$percent" "$text"
    fi
}

# Fallback progress bar
_fallback_progress_bar() {
    local percent="$1"
    local text="${2:-Progress}"
    local width=40
    local filled=$((width * percent / 100))
    local empty=$((width - filled))

    printf "\r%s: [" "$text"
    printf "%${filled}s" | tr ' ' "${TUI_SYM_BAR_FILL}"
    printf "%${empty}s" | tr ' ' "${TUI_SYM_BAR_EMPTY}"
    printf "] %3d%%" "$percent"
}

# ============================================================================
# Info Box Widget (non-blocking)
# ============================================================================

# Display an info box (auto-closes)
# Usage: tui_infobox "Title" "Message" [height] [width]
tui_infobox() {
    local title="$1"
    local message="$2"
    local height="${3:-5}"
    local width="${4:-40}"

    if [[ -n "$HAS_DIALOG" ]]; then
        dialog --title "$title" --infobox "$message" "$height" "$width"
    elif [[ -n "$HAS_WHIPTAIL" ]]; then
        # whiptail doesn't have infobox, use msgbox with short timeout
        timeout 2 whiptail --title "$title" --msgbox "$message" "$height" "$width" 2>/dev/null || true
    else
        echo -e "${TUI_DIM}$message${TUI_NC}"
    fi
}

# ============================================================================
# Spinner Widget (using gum if available)
# ============================================================================

# Run a command with a spinner
# Usage: tui_spin "Loading..." command args...
tui_spin() {
    local title="$1"
    shift

    if [[ -n "$HAS_GUM" ]]; then
        gum spin --spinner dot --title "$title" -- "$@"
    else
        echo -n "$title "
        "$@" &
        local pid=$!
        local spin='-\|/'
        local i=0
        while kill -0 $pid 2>/dev/null; do
            i=$(( (i+1) % 4 ))
            printf "\r%s %c" "$title" "${spin:$i:1}"
            sleep 0.1
        done
        wait $pid
        local status=$?
        printf "\r%s done\n" "$title"
        return $status
    fi
}

# ============================================================================
# Fuzzy Search Widget (using fzf if available)
# ============================================================================

# Fuzzy search through options
# Usage: echo -e "opt1\nopt2\nopt3" | tui_fzf "Select:" [preview_cmd]
tui_fzf() {
    local prompt="${1:-Select:}"
    local preview_cmd="${2:-}"

    if [[ -n "$HAS_FZF" ]]; then
        if [[ -n "$preview_cmd" ]]; then
            fzf --prompt="$prompt " --preview="$preview_cmd" --preview-window=right:50%
        else
            fzf --prompt="$prompt "
        fi
    else
        # Fallback: simple grep filter
        local input
        local lines=()
        while IFS= read -r line; do
            lines+=("$line")
        done

        echo -e "\n${TUI_BOLD}$prompt${TUI_NC}" >&2
        for i in "${!lines[@]}"; do
            printf "  %2d) %s\n" "$((i+1))" "${lines[$i]}" >&2
        done
        echo >&2

        read -rp "Enter number or search text: " input >&2

        if [[ "$input" =~ ^[0-9]+$ ]] && [[ "$input" -ge 1 ]] && [[ "$input" -le "${#lines[@]}" ]]; then
            echo "${lines[$((input-1))]}"
        else
            # Search for matching line
            for line in "${lines[@]}"; do
                if [[ "$line" == *"$input"* ]]; then
                    echo "$line"
                    return 0
                fi
            done
            return 1
        fi
    fi
}

# ============================================================================
# Text Display Widget
# ============================================================================

# Display scrollable text
# Usage: tui_textbox "Title" "file_or_text" [height] [width]
tui_textbox() {
    local title="$1"
    local content="$2"
    local height="${3:-20}"
    local width="${4:-70}"

    if [[ -n "$HAS_DIALOG" ]]; then
        if [[ -f "$content" ]]; then
            dialog --title "$title" --textbox "$content" "$height" "$width"
        else
            echo "$content" | dialog --title "$title" --programbox "$height" "$width"
        fi
    elif [[ -n "$HAS_WHIPTAIL" ]]; then
        if [[ -f "$content" ]]; then
            whiptail --title "$title" --textbox "$content" "$height" "$width"
        else
            echo "$content" | whiptail --title "$title" --scrolltext --msgbox "$(cat)" "$height" "$width"
        fi
    else
        echo
        echo -e "${TUI_BOLD}${TUI_CYAN}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE} $title ${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_NC}"
        echo
        if [[ -f "$content" ]]; then
            less "$content"
        else
            echo "$content" | less
        fi
    fi
}

# ============================================================================
# Screen Clear and Reset
# ============================================================================

# Clear the screen appropriately
tui_clear() {
    if [[ -n "$HAS_DIALOG" ]]; then
        dialog --clear
        clear
    else
        clear
    fi
}

# ============================================================================
# Progress Summary Box
# ============================================================================

# Display a formatted progress summary in a box
# Usage: tui_progress_box "Title" current total "label"
tui_progress_box() {
    local title="$1"
    local current="$2"
    local total="$3"
    local label="${4:-Progress}"

    local percent=$((current * 100 / total))
    local bar_width=30
    local filled=$((bar_width * current / total))
    local empty=$((bar_width - filled))

    local bar
    bar=$(printf "%${filled}s" | tr ' ' "${TUI_SYM_BAR_FILL}")
    bar+=$(printf "%${empty}s" | tr ' ' "${TUI_SYM_BAR_EMPTY}")

    local message
    message=$(printf "%s: %d/%d (%d%%)\n\n[%s]" "$label" "$current" "$total" "$percent" "$bar")

    tui_msgbox "$title" "$message" 10 50
}

# ============================================================================
# Status Line
# ============================================================================

# Print a status line with icon
# Usage: tui_status "pass|fail|warn|info" "message"
tui_status() {
    local type="$1"
    local message="$2"

    case "$type" in
        pass|ok|success)
            echo -e "${TUI_GREEN}${TUI_SYM_PASS}${TUI_NC} $message"
            ;;
        fail|error)
            echo -e "${TUI_RED}${TUI_SYM_FAIL}${TUI_NC} $message"
            ;;
        warn|warning)
            echo -e "${TUI_YELLOW}${TUI_SYM_WARN}${TUI_NC} $message"
            ;;
        info)
            echo -e "${TUI_CYAN}${TUI_SYM_INFO}${TUI_NC} $message"
            ;;
        *)
            echo "${TUI_SYM_BULLET} $message"
            ;;
    esac
}

# ============================================================================
# Header/Footer
# ============================================================================

# Print a styled header
tui_header() {
    local text="$1"
    local width="${2:-60}"

    echo
    echo -e "${TUI_BOLD}${TUI_BLUE}$(printf "${TUI_SYM_HLINE}%.0s" $(seq 1 "$width"))${TUI_NC}"
    echo -e "${TUI_BOLD}${TUI_BLUE}  $text${TUI_NC}"
    echo -e "${TUI_BOLD}${TUI_BLUE}$(printf "${TUI_SYM_HLINE}%.0s" $(seq 1 "$width"))${TUI_NC}"
    echo
}

# Print navigation hints
tui_nav_hint() {
    echo -e "${TUI_DIM}${TUI_SYM_NAV}${TUI_NC}"
}
