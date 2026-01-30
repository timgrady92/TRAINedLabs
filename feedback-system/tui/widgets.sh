#!/bin/bash
# LPIC-1 TUI - Reusable Widget Library
# Provides menu, progress bar, message box, and input widgets
# with graceful fallback from dialog → whiptail → basic terminal

# Get the directory where this script is located
_WIDGETS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the theme system for consistent styling
if [[ -f "${_WIDGETS_DIR}/theme.sh" ]]; then
    source "${_WIDGETS_DIR}/theme.sh"
fi

# ============================================================================
# Tool Detection
# ============================================================================

# Detect available TUI tools (set once at source time)
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
_detect_tui_tools

# Validate environment for TUI operations
_validate_environment() {
    # Check TERM variable
    if [[ -z "${TERM:-}" ]] || [[ "$TERM" == "dumb" ]]; then
        echo "Warning: TERM not set or is 'dumb', output may be degraded" >&2
    fi

    # Check for sqlite3 (commonly used by the training system)
    if ! command -v sqlite3 &>/dev/null; then
        echo "Warning: sqlite3 not found, progress tracking may be disabled" >&2
    fi
}
_validate_environment

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
    [[ -n "$HAS_GUM" || -n "$HAS_DIALOG" || -n "$HAS_WHIPTAIL" ]]
}

# Get the best available TUI tool
tui_tool() {
    if [[ -n "$HAS_GUM" ]]; then
        echo "gum"
    elif [[ -n "$HAS_DIALOG" ]]; then
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

    # Validate tag/desc pairs
    if (( ${#items[@]} % 2 != 0 )); then
        echo "Error: tui_menu requires tag/desc pairs" >&2
        return 1
    fi

    # Check for TTY availability
    if [[ ! -t 0 ]] && [[ ! -c /dev/tty ]]; then
        echo "Error: No TTY available for interactive input" >&2
        return 1
    fi

    local menu_height=$((height - 7))
    [[ $menu_height -lt 1 ]] && menu_height=10

    # Gum provides modern, styled menus
    if [[ -n "$HAS_GUM" ]]; then
        _gum_menu "$title" "${items[@]}"
        return $?
    elif [[ -n "$HAS_DIALOG" ]]; then
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

# Gum-based menu with modern styling
_gum_menu() {
    local title="$1"
    shift
    local items=("$@")

    # Build display options: "tag - description"
    local display_opts=()
    local tags=()
    local i=0
    while [[ $i -lt ${#items[@]} ]]; do
        local tag="${items[$i]}"
        local desc="${items[$((i+1))]}"
        tags+=("$tag")
        display_opts+=("$tag  │  $desc")
        ((i+=2))
    done

    # Show styled header (to stderr so it doesn't pollute the return value)
    echo >&2
    gum style \
        --foreground 33 --border-foreground 33 \
        --border rounded --padding "0 2" --margin "0 0 1 0" \
        "$title" >&2

    # Show the menu with gum choose
    local selection
    selection=$(printf '%s\n' "${display_opts[@]}" | gum choose \
        --cursor.foreground="214" \
        --selected.foreground="33" \
        --header="" \
        --cursor="▸ " \
        --height=15) || return 1

    # Extract the tag from selection (everything before the │)
    local selected_tag
    selected_tag=$(echo "$selection" | sed 's/  │.*//')
    echo "$selected_tag"
    return 0
}

# Fallback menu using select
_fallback_menu() {
    local title="$1"
    shift
    local items=("$@")

    echo >&2
    echo -e "${TUI_BOLD}${TUI_CYAN}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE} $title ${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_NC}" >&2
    echo >&2

    # Build options array (tags only)
    local tags=()
    local descs=()
    local i=0
    while [[ $i -lt ${#items[@]} ]]; do
        tags+=("${items[$i]}")
        descs+=("${items[$((i+1))]}")
        ((i+=2))
    done

    # Display numbered menu (to stderr)
    for i in "${!tags[@]}"; do
        printf "  ${TUI_CYAN}%2d)${TUI_NC} %-15s %s\n" "$((i+1))" "${tags[$i]}" "${descs[$i]}" >&2
    done
    echo >&2
    printf "  ${TUI_DIM} 0) Cancel/Back${TUI_NC}\n" >&2
    echo >&2

    # Get selection
    local choice
    while true; do
        echo -en "Enter choice [0-${#tags[@]}]: " >&2
        read -r choice || return 1
        if [[ "$choice" == "0" || "$choice" == "q" || "$choice" == "Q" ]]; then
            return 1
        fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#tags[@]}" ]]; then
            echo "${tags[$((choice-1))]}"
            return 0
        fi
        echo "Invalid choice. Please enter a number between 0 and ${#tags[@]}." >&2
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

    # Validate tag/desc/state triplets
    if (( ${#items[@]} % 3 != 0 )); then
        echo "Error: tui_checklist requires tag/desc/state triplets" >&2
        return 1
    fi

    # Check for TTY availability
    if [[ ! -t 0 ]] && [[ ! -c /dev/tty ]]; then
        echo "Error: No TTY available for interactive input" >&2
        return 1
    fi

    local list_height=$((height - 7))
    [[ $list_height -lt 1 ]] && list_height=10

    # Gum provides modern multi-select
    if [[ -n "$HAS_GUM" ]]; then
        _gum_checklist "$title" "${items[@]}"
        return $?
    elif [[ -n "$HAS_DIALOG" ]]; then
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

# Gum-based checklist with modern styling
_gum_checklist() {
    local title="$1"
    shift
    local items=("$@")

    # Build display options and track defaults
    local display_opts=()
    local tags=()
    local defaults=()
    local i=0
    while [[ $i -lt ${#items[@]} ]]; do
        local tag="${items[$i]}"
        local desc="${items[$((i+1))]}"
        local state="${items[$((i+2))]}"
        tags+=("$tag")
        display_opts+=("$tag  │  $desc")
        [[ "$state" == "on" ]] && defaults+=("$tag  │  $desc")
        ((i+=3))
    done

    # Show styled header (to stderr so it doesn't pollute the return value)
    echo >&2
    gum style \
        --foreground 33 --border-foreground 33 \
        --border rounded --padding "0 2" --margin "0 0 1 0" \
        "$title" >&2

    # Build selected args for defaults
    local selected_args=()
    for def in "${defaults[@]}"; do
        selected_args+=("--selected=$def")
    done

    # Show the checklist with gum choose --no-limit
    local selection
    selection=$(printf '%s\n' "${display_opts[@]}" | gum choose \
        --no-limit \
        --cursor.foreground="214" \
        --selected.foreground="34" \
        --cursor="▸ " \
        --header="Space to toggle, Enter to confirm" \
        "${selected_args[@]}" \
        --height=15) || return 1

    # Extract tags from selections
    local result=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && result+=("$(echo "$line" | sed 's/  │.*//')")
    done <<< "$selection"
    echo "${result[*]}"
    return 0
}

_fallback_checklist() {
    local title="$1"
    shift
    local items=("$@")

    echo >&2
    echo -e "${TUI_BOLD}${TUI_CYAN}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE} $title ${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_NC}" >&2
    echo "Enter numbers separated by spaces (e.g., 1 3 5)" >&2
    echo >&2

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

    # Display numbered list (to stderr)
    for i in "${!tags[@]}"; do
        local marker="[ ]"
        [[ "${states[$i]}" == "on" ]] && marker="[*]"
        printf "  ${TUI_CYAN}%2d)${TUI_NC} %s %-15s %s\n" "$((i+1))" "$marker" "${tags[$i]}" "${descs[$i]}" >&2
    done
    echo >&2

    # Get selection
    local choice
    echo -en "Enter choices (or Enter for defaults): " >&2
    read -r choice || return 1

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

    # Check for TTY availability
    if [[ ! -t 0 ]] && [[ ! -c /dev/tty ]]; then
        echo "Error: No TTY available for interactive input" >&2
        return 1
    fi

    if [[ -n "$HAS_GUM" ]]; then
        echo >&2
        gum style \
            --foreground 33 --border-foreground 33 \
            --border rounded --padding "1 2" --margin "0 0 1 0" \
            --bold "$title" >&2
        echo "$message" | gum format >&2
        echo >&2
        # Show a styled prompt and wait for Enter
        gum style --foreground 245 --italic "Press Enter to continue..." >&2
        read -r _ </dev/tty 2>/dev/null || read -r _
    elif [[ -n "$HAS_DIALOG" ]]; then
        dialog --clear --title "$title" --msgbox "$message" "$height" "$width"
    elif [[ -n "$HAS_WHIPTAIL" ]]; then
        whiptail --title "$title" --msgbox "$message" "$height" "$width"
    else
        echo >&2
        echo -e "${TUI_BOLD}${TUI_CYAN}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE} $title ${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_NC}" >&2
        echo >&2
        echo -e "$message" >&2
        echo >&2
        echo -en "Press Enter to continue..." >&2
        read -r _
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

    # Check for TTY availability
    if [[ ! -t 0 ]] && [[ ! -c /dev/tty ]]; then
        echo "Error: No TTY available for interactive input" >&2
        return 1
    fi

    if [[ -n "$HAS_GUM" ]]; then
        echo >&2
        gum style \
            --foreground 33 --border-foreground 33 \
            --border rounded --padding "0 2" --margin "0 0 1 0" \
            --bold "$title" >&2
        # Display multiline question text first, then simple confirm prompt
        echo -e "$question" | gum format >&2
        echo >&2
        gum confirm "Proceed?" \
            --affirmative="Yes" --negative="No" \
            --prompt.foreground="255" \
            --selected.background="33" \
            --unselected.foreground="245" && return 0 || return 1
    elif [[ -n "$HAS_DIALOG" ]]; then
        dialog --clear --title "$title" --yesno "$question" "$height" "$width"
        return $?
    elif [[ -n "$HAS_WHIPTAIL" ]]; then
        whiptail --title "$title" --yesno "$question" "$height" "$width"
        return $?
    else
        echo >&2
        echo -e "${TUI_BOLD}$title${TUI_NC}" >&2
        local response
        echo -en "$question [y/N] " >&2
        read -r response
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

    # Check for TTY availability
    if [[ ! -t 0 ]] && [[ ! -c /dev/tty ]]; then
        echo "Error: No TTY available for interactive input" >&2
        return 1
    fi

    if [[ -n "$HAS_GUM" ]]; then
        echo >&2
        gum style \
            --foreground 33 --border-foreground 33 \
            --border rounded --padding "0 2" --margin "0 0 1 0" \
            --bold "$title" >&2
        gum input \
            --placeholder "$prompt" \
            --value "$default" \
            --prompt "▸ " \
            --prompt.foreground="214" \
            --cursor.foreground="33" \
            --width 50
        return $?
    elif [[ -n "$HAS_DIALOG" ]]; then
        dialog --clear --title "$title" --inputbox "$prompt" "$height" "$width" "$default" 3>&1 1>&2 2>&3
        return $?
    elif [[ -n "$HAS_WHIPTAIL" ]]; then
        whiptail --title "$title" --inputbox "$prompt" "$height" "$width" "$default" 3>&1 1>&2 2>&3
        return $?
    else
        echo >&2
        echo -e "${TUI_BOLD}$title${TUI_NC}" >&2
        local input
        if [[ -n "$default" ]]; then
            echo -en "$prompt [$default]: " >&2
            read -r input
            echo "${input:-$default}"
        else
            echo -en "$prompt: " >&2
            read -r input
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

    if [[ -n "$HAS_GUM" ]]; then
        gum style \
            --foreground 245 --border-foreground 245 \
            --border rounded --padding "0 1" \
            --italic "$message"
    elif [[ -n "$HAS_DIALOG" ]]; then
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
        gum spin \
            --spinner dot \
            --spinner.foreground="214" \
            --title "$title" \
            --title.foreground="33" \
            -- "$@"
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
# Styled Output Helpers (Gum-enhanced)
# ============================================================================

# Display a styled banner/title
# Usage: tui_banner "Welcome to LPIC-1 Training"
tui_banner() {
    local text="$1"
    if [[ -n "$HAS_GUM" ]]; then
        gum style \
            --foreground 33 --border-foreground 33 \
            --border double --padding "1 4" --margin "1" \
            --bold --align center \
            "$text"
    else
        echo
        echo -e "${TUI_BOLD}${TUI_CYAN}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_NC}"
        echo -e "${TUI_BOLD}  $text${TUI_NC}"
        echo -e "${TUI_BOLD}${TUI_CYAN}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_SYM_HLINE}${TUI_NC}"
        echo
    fi
}

# Display styled key-value info
# Usage: tui_info "Status" "Active"
tui_info() {
    local key="$1"
    local value="$2"
    if [[ -n "$HAS_GUM" ]]; then
        echo "$(gum style --foreground 245 "$key:") $(gum style --foreground 255 --bold "$value")"
    else
        echo -e "${TUI_DIM}$key:${TUI_NC} ${TUI_BOLD}$value${TUI_NC}"
    fi
}

# Display a styled list with bullet points
# Usage: tui_list "Item 1" "Item 2" "Item 3"
tui_list() {
    for item in "$@"; do
        if [[ -n "$HAS_GUM" ]]; then
            echo "  $(gum style --foreground 214 "▸") $item"
        else
            echo -e "  ${TUI_CYAN}${TUI_SYM_BULLET}${TUI_NC} $item"
        fi
    done
}

# Display a warning/notice box
# Usage: tui_notice "warning" "This action cannot be undone"
tui_notice() {
    local type="$1"
    local message="$2"
    local color icon

    case "$type" in
        warning|warn)  color="220"; icon="⚠" ;;
        error)         color="196"; icon="✗" ;;
        success)       color="34";  icon="✓" ;;
        info|*)        color="33";  icon="ℹ" ;;
    esac

    if [[ -n "$HAS_GUM" ]]; then
        gum style \
            --foreground "$color" --border-foreground "$color" \
            --border rounded --padding "0 2" --margin "1 0" \
            "$icon $message"
    else
        case "$type" in
            warning|warn) echo -e "${TUI_YELLOW}${icon} $message${TUI_NC}" ;;
            error)        echo -e "${TUI_RED}${icon} $message${TUI_NC}" ;;
            success)      echo -e "${TUI_GREEN}${icon} $message${TUI_NC}" ;;
            *)            echo -e "${TUI_CYAN}${icon} $message${TUI_NC}" ;;
        esac
    fi
}

# ============================================================================
# Fuzzy Search Widget (using gum filter or fzf)
# ============================================================================

# Fuzzy search through options
# Usage: echo -e "opt1\nopt2\nopt3" | tui_fzf "Select:" [preview_cmd]
tui_fzf() {
    local prompt="${1:-Select:}"
    local preview_cmd="${2:-}"

    if [[ -n "$HAS_GUM" ]]; then
        gum filter \
            --placeholder "$prompt" \
            --prompt "▸ " \
            --prompt.foreground="214" \
            --indicator.foreground="33" \
            --match.foreground="214" \
            --height 15
    elif [[ -n "$HAS_FZF" ]]; then
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

        echo -en "Enter number or search text: " >&2
        read -r input

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

    if [[ -n "$HAS_GUM" ]]; then
        echo >&2
        gum style \
            --foreground 33 --border-foreground 33 \
            --border rounded --padding "0 2" --margin "0 0 1 0" \
            --bold "$title" >&2
        if [[ -f "$content" ]]; then
            gum pager --soft-wrap < "$content"
        else
            echo "$content" | gum pager --soft-wrap
        fi
    elif [[ -n "$HAS_DIALOG" ]]; then
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
            if command -v less &>/dev/null; then
                less "$content"
            elif command -v more &>/dev/null; then
                more "$content"
            else
                cat "$content"
            fi
        else
            if command -v less &>/dev/null; then
                echo "$content" | less
            elif command -v more &>/dev/null; then
                echo "$content" | more
            else
                echo "$content"
            fi
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

    if [[ -n "$HAS_GUM" ]]; then
        echo
        gum style \
            --foreground 33 --border-foreground 33 \
            --border rounded --padding "1 2" --margin "0 0 1 0" \
            --bold "$title"
        echo
        gum style --foreground 245 "$label: $current/$total"
        echo
        echo "$(gum style --foreground 34 "$bar") $(gum style --bold "${percent}%")"
        echo
        gum input --placeholder "Press Enter to continue..." --width 0 >/dev/null 2>&1 || read -r _
    else
        local message
        message=$(printf "%s: %d/%d (%d%%)\n\n[%s]" "$label" "$current" "$total" "$percent" "$bar")
        tui_msgbox "$title" "$message" 10 50
    fi
}

# ============================================================================
# Status Line
# ============================================================================

# Print a status line with icon
# Usage: tui_status "pass|fail|warn|info" "message"
tui_status() {
    local type="$1"
    local message="$2"

    if [[ -n "$HAS_GUM" ]]; then
        case "$type" in
            pass|ok|success)
                echo "$(gum style --foreground 34 "✓") $message"
                ;;
            fail|error)
                echo "$(gum style --foreground 196 "✗") $message"
                ;;
            warn|warning)
                echo "$(gum style --foreground 220 "⚠") $message"
                ;;
            info)
                echo "$(gum style --foreground 33 "ℹ") $message"
                ;;
            *)
                echo "$(gum style --foreground 214 "▸") $message"
                ;;
        esac
    else
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
    fi
}

# ============================================================================
# Header/Footer
# ============================================================================

# Print a styled header
tui_header() {
    local text="$1"
    local width="${2:-60}"

    if [[ -n "$HAS_GUM" ]]; then
        echo
        gum style \
            --foreground 33 --border-foreground 33 \
            --border normal --padding "0 2" \
            --bold "$text"
        echo
    else
        echo
        echo -e "${TUI_BOLD}${TUI_BLUE}$(printf "${TUI_SYM_HLINE}%.0s" $(seq 1 "$width"))${TUI_NC}"
        echo -e "${TUI_BOLD}${TUI_BLUE}  $text${TUI_NC}"
        echo -e "${TUI_BOLD}${TUI_BLUE}$(printf "${TUI_SYM_HLINE}%.0s" $(seq 1 "$width"))${TUI_NC}"
        echo
    fi
}

# Print navigation hints
tui_nav_hint() {
    if [[ -n "$HAS_GUM" ]]; then
        gum style --foreground 245 --italic "↑↓ Navigate  Enter Select  Esc Cancel"
    else
        echo -e "${TUI_DIM}${TUI_SYM_NAV}${TUI_NC}"
    fi
}

# ============================================================================
# Additional Gum-Enhanced Widgets
# ============================================================================

# Multi-line text input (for notes, descriptions, etc.)
# Usage: tui_write "Enter your notes" [placeholder]
tui_write() {
    local prompt="${1:-Enter text}"
    local placeholder="${2:-Type here...}"

    if [[ -n "$HAS_GUM" ]]; then
        echo >&2
        gum style --foreground 33 --bold "$prompt" >&2
        gum write \
            --placeholder "$placeholder" \
            --char-limit 500 \
            --width 60
    else
        echo >&2
        echo -e "${TUI_BOLD}$prompt${TUI_NC}" >&2
        echo "(Enter text, then press Ctrl+D when done)" >&2
        cat
    fi
}

# File picker
# Usage: tui_file "Select a file" [directory] [extension]
tui_file() {
    local prompt="${1:-Select a file}"
    local directory="${2:-.}"
    local extension="${3:-}"

    if [[ -n "$HAS_GUM" ]]; then
        echo >&2
        gum style --foreground 33 --bold "$prompt" >&2
        if [[ -n "$extension" ]]; then
            gum file "$directory" --file --height 15 | grep -E "\.${extension}$" || \
                gum file "$directory" --file --height 15
        else
            gum file "$directory" --file --height 15
        fi
    else
        # Fallback: list files and let user choose
        local files=()
        while IFS= read -r -d '' file; do
            files+=("$file")
        done < <(find "$directory" -maxdepth 3 -type f ${extension:+-name "*.$extension"} -print0 2>/dev/null | head -z -n 20)

        if [[ ${#files[@]} -eq 0 ]]; then
            echo "No files found" >&2
            return 1
        fi

        echo -e "\n${TUI_BOLD}$prompt${TUI_NC}" >&2
        for i in "${!files[@]}"; do
            printf "  %2d) %s\n" "$((i+1))" "${files[$i]}" >&2
        done
        echo >&2

        local choice
        echo -en "Enter number: " >&2
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#files[@]}" ]]; then
            echo "${files[$((choice-1))]}"
        else
            return 1
        fi
    fi
}

# Tabbed output display
# Usage: tui_table "Header1,Header2,Header3" "row1col1,row1col2,row1col3" "row2col1,row2col2,row2col3"
tui_table() {
    if [[ -n "$HAS_GUM" ]]; then
        # Convert comma-separated values to tab-separated for gum table
        local formatted=""
        for row in "$@"; do
            formatted+="${row//,/$'\t'}"$'\n'
        done
        echo "$formatted" | gum table \
            --border.foreground="33" \
            --header.foreground="214" \
            --cell.foreground="255"
    else
        # Simple fallback table
        local first=1
        for row in "$@"; do
            if [[ $first -eq 1 ]]; then
                echo -e "${TUI_BOLD}${row//,/  │  }${TUI_NC}"
                echo -e "${TUI_DIM}$(printf '─%.0s' {1..60})${TUI_NC}"
                first=0
            else
                echo "${row//,/  │  }"
            fi
        done
    fi
}

# Join multiple strings with a styled separator
# Usage: tui_join " │ " "item1" "item2" "item3"
tui_join() {
    local sep="$1"
    shift
    if [[ -n "$HAS_GUM" ]]; then
        local result=""
        local first=1
        for item in "$@"; do
            if [[ $first -eq 1 ]]; then
                result="$item"
                first=0
            else
                result+="$(gum style --foreground 245 "$sep")$item"
            fi
        done
        echo "$result"
    else
        local IFS="$sep"
        echo "$*"
    fi
}

# Loading animation with custom message
# Usage: tui_loading "Initializing..." 2
tui_loading() {
    local message="${1:-Loading...}"
    local seconds="${2:-2}"

    if [[ -n "$HAS_GUM" ]]; then
        gum spin \
            --spinner pulse \
            --spinner.foreground="214" \
            --title "$message" \
            --title.foreground="33" \
            -- sleep "$seconds"
    else
        echo -n "$message "
        for ((i=0; i<seconds*4; i++)); do
            echo -n "."
            sleep 0.25
        done
        echo " done"
    fi
}
