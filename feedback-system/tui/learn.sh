#!/bin/bash
# LPIC-1 TUI - Learn Mode Browser
# Browse and launch lessons by topic or command

set -euo pipefail

# Get script directory
TUI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEEDBACK_DIR="$(dirname "$TUI_DIR")"
TRAINING_DIR="${FEEDBACK_DIR}/training"
LESSONS_DIR="${TRAINING_DIR}/lessons"

# Source dependencies (if not already sourced)
[[ -z "${TUI_NC:-}" ]] && source "${TUI_DIR}/widgets.sh"

# ============================================================================
# Topic Definitions
# ============================================================================

# Topics organized by category
declare -A TOPIC_CATEGORIES=(
    ["text"]="Text Processing"
    ["files"]="File Operations"
    ["system"]="System Management"
    ["admin"]="Administration"
    ["storage"]="Storage"
    ["services"]="Services"
)

declare -A TOPICS_BY_CATEGORY=(
    ["text"]="grep sed awk"
    ["files"]="find tar permissions"
    ["system"]="processes"
    ["admin"]="users networking"
    ["storage"]="filesystems"
    ["services"]="systemd"
)

declare -A TOPIC_DESCRIPTIONS=(
    ["grep"]="Text searching and pattern matching"
    ["sed"]="Stream editing and text transformation"
    ["awk"]="Text processing and data extraction"
    ["find"]="Finding files by various criteria"
    ["tar"]="Archive creation and extraction"
    ["permissions"]="File permissions (chmod, chown, umask)"
    ["processes"]="Process management (ps, kill, jobs, bg, fg)"
    ["users"]="User and group management"
    ["networking"]="Network configuration and diagnostics"
    ["filesystems"]="Filesystem management (mount, df, fdisk)"
    ["systemd"]="Service management with systemctl"
)

declare -A TOPIC_OBJECTIVES=(
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

# Command aliases that map to topics
declare -A COMMAND_ALIASES=(
    ["chmod"]="permissions"
    ["chown"]="permissions"
    ["umask"]="permissions"
    ["ps"]="processes"
    ["kill"]="processes"
    ["jobs"]="processes"
    ["bg"]="processes"
    ["fg"]="processes"
    ["nice"]="processes"
    ["useradd"]="users"
    ["usermod"]="users"
    ["groupadd"]="users"
    ["passwd"]="users"
    ["ip"]="networking"
    ["ss"]="networking"
    ["ping"]="networking"
    ["dig"]="networking"
    ["mount"]="filesystems"
    ["umount"]="filesystems"
    ["df"]="filesystems"
    ["du"]="filesystems"
    ["fdisk"]="filesystems"
    ["lsblk"]="filesystems"
    ["systemctl"]="systemd"
    ["journalctl"]="systemd"
    ["gzip"]="tar"
    ["bzip2"]="tar"
    ["xz"]="tar"
)

# ============================================================================
# Learn Menu
# ============================================================================

show_learn_menu() {
    while true; do
        local choice
        choice=$(tui_menu "Learn - Choose Your Path" 16 55 \
            "category"  "Browse by topic category" \
            "all"       "View all available topics" \
            "command"   "Search by command name" \
            "recent"    "Continue recent lesson" \
            "back"      "Return to main menu") || choice="back"

        case "$choice" in
            category)
                show_category_browser
                ;;
            all)
                show_all_topics
                ;;
            command)
                search_by_command
                ;;
            recent)
                continue_recent
                ;;
            back|"")
                return
                ;;
        esac
    done
}

# ============================================================================
# Category Browser
# ============================================================================

show_category_browser() {
    while true; do
        local choice
        choice=$(tui_menu "Topic Categories" 16 55 \
            "text"     "Text Processing (grep, sed, awk)" \
            "files"    "File Operations (find, tar, chmod)" \
            "system"   "System (processes)" \
            "admin"    "Administration (users, networking)" \
            "storage"  "Storage (filesystems, mount)" \
            "services" "Services (systemd)" \
            "back"     "Return to learn menu") || choice="back"

        case "$choice" in
            text|files|system|admin|storage|services)
                show_category_topics "$choice"
                ;;
            back|"")
                return
                ;;
        esac
    done
}

show_category_topics() {
    local category="$1"
    local category_name="${TOPIC_CATEGORIES[$category]}"
    local topics="${TOPICS_BY_CATEGORY[$category]}"

    # Build menu items
    local items=()
    for topic in $topics; do
        local desc="${TOPIC_DESCRIPTIONS[$topic]:-$topic lesson}"
        local obj="${TOPIC_OBJECTIVES[$topic]:-}"
        [[ -n "$obj" ]] && desc+=" ($obj)"
        items+=("$topic" "$desc")
    done
    items+=("back" "Return to categories")

    while true; do
        local choice
        choice=$(tui_menu "$category_name" 14 60 "${items[@]}") || choice="back"

        if [[ "$choice" == "back" || -z "$choice" ]]; then
            return
        fi

        launch_lesson "$choice"
    done
}

# ============================================================================
# All Topics
# ============================================================================

show_all_topics() {
    # Build menu of all available topics
    local items=()

    for topic in grep sed awk find tar permissions processes users networking filesystems systemd; do
        local lesson_file="${LESSONS_DIR}/${topic}.sh"
        if [[ -f "$lesson_file" ]]; then
            local desc="${TOPIC_DESCRIPTIONS[$topic]:-$topic lesson}"
            items+=("$topic" "$desc")
        fi
    done
    items+=("back" "Return to learn menu")

    while true; do
        local choice
        choice=$(tui_menu "All Topics" 18 60 "${items[@]}") || choice="back"

        if [[ "$choice" == "back" || -z "$choice" ]]; then
            return
        fi

        launch_lesson "$choice"
    done
}

# ============================================================================
# Command Search
# ============================================================================

search_by_command() {
    # Get command name from user
    local cmd
    cmd=$(tui_input "Search by Command" "Enter command name (e.g., chmod, ps, grep):" "" 8 50)

    if [[ -z "$cmd" ]]; then
        return
    fi

    # Resolve to topic
    local topic=""

    # Check if it's a direct topic
    if [[ -f "${LESSONS_DIR}/${cmd}.sh" ]]; then
        topic="$cmd"
    # Check aliases
    elif [[ -n "${COMMAND_ALIASES[$cmd]:-}" ]]; then
        topic="${COMMAND_ALIASES[$cmd]}"
    fi

    if [[ -n "$topic" ]]; then
        local desc="${TOPIC_DESCRIPTIONS[$topic]:-$topic lesson}"
        if tui_yesno "Found Lesson" "$cmd is covered in: $topic\n\n$desc\n\nStart lesson?"; then
            launch_lesson "$topic"
        fi
    else
        tui_msgbox "Not Found" "No lesson found for '$cmd'\n\nAvailable topics:\n• grep, sed, awk (text processing)\n• find, tar, permissions (files)\n• processes, users, networking\n• filesystems, systemd\n\nTip: Try the command's category instead."
    fi
}

# ============================================================================
# Recent Lesson
# ============================================================================

continue_recent() {
    local db_file="/opt/LPIC-1/data/progress.db"

    if [[ ! -f "$db_file" ]]; then
        tui_msgbox "No History" "No lesson history found.\n\nStart a new lesson to build history."
        return
    fi

    # Get most recent lesson from sessions
    local recent
    recent=$(sqlite3 "$db_file" "SELECT objectives_practiced FROM sessions WHERE objectives_practiced LIKE 'lesson-%' ORDER BY ended_at DESC LIMIT 1;" 2>/dev/null || echo "")

    if [[ -z "$recent" ]]; then
        tui_msgbox "No History" "No recent lessons found.\n\nChoose a topic to get started."
        return
    fi

    # Extract topic from "lesson-<topic>"
    local topic="${recent#lesson-}"

    if [[ -f "${LESSONS_DIR}/${topic}.sh" ]]; then
        local desc="${TOPIC_DESCRIPTIONS[$topic]:-$topic lesson}"
        if tui_yesno "Continue Lesson" "Your most recent lesson was:\n\n$topic - $desc\n\nContinue?"; then
            launch_lesson "$topic"
        fi
    else
        tui_msgbox "Not Available" "Recent lesson '$topic' is no longer available."
    fi
}

# ============================================================================
# Lesson Launcher
# ============================================================================

launch_lesson() {
    local topic="$1"
    local lesson_file="${LESSONS_DIR}/${topic}.sh"

    if [[ ! -f "$lesson_file" ]]; then
        tui_msgbox "Error" "Lesson file not found:\n$lesson_file"
        return 1
    fi

    # Show loading message
    tui_infobox "Loading" "Starting $topic lesson..."
    sleep 1

    # Clear screen and launch lesson
    tui_clear

    # Run the lesson through lpic-train
    "${FEEDBACK_DIR}/lpic-train" learn "$topic" || true

    # Wait for user after lesson
    echo
    echo -en "Press Enter to return to menu..."
    read -r _
}

# ============================================================================
# Fuzzy Search (if fzf available)
# ============================================================================

fuzzy_topic_search() {
    if [[ -z "$HAS_FZF" ]]; then
        # Fallback to regular search
        search_by_command
        return
    fi

    # Build searchable list
    local search_list=""
    for topic in "${!TOPIC_DESCRIPTIONS[@]}"; do
        search_list+="$topic: ${TOPIC_DESCRIPTIONS[$topic]}\n"
    done
    for cmd in "${!COMMAND_ALIASES[@]}"; do
        local topic="${COMMAND_ALIASES[$cmd]}"
        search_list+="$cmd → $topic: ${TOPIC_DESCRIPTIONS[$topic]:-}\n"
    done

    local selected
    selected=$(echo -e "$search_list" | fzf --prompt="Search topics/commands: " --height=15)

    if [[ -n "$selected" ]]; then
        # Extract topic (handle both direct and alias cases)
        local topic
        if [[ "$selected" == *" → "* ]]; then
            # Alias case: "cmd → topic: desc"
            topic=$(echo "$selected" | sed 's/.*→ \([^:]*\):.*/\1/' | tr -d ' ')
        else
            # Direct case: "topic: desc"
            topic=$(echo "$selected" | cut -d: -f1 | tr -d ' ')
        fi

        if [[ -f "${LESSONS_DIR}/${topic}.sh" ]]; then
            launch_lesson "$topic"
        fi
    fi
}

# ============================================================================
# Entry Point (when run directly)
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "${TUI_DIR}/widgets.sh"
    show_learn_menu
fi
