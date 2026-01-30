#!/bin/bash
# LPIC-1 TUI - Practice Mode
# Guided exercises with hints

set -euo pipefail

# Get script directory
TUI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEEDBACK_DIR="$(dirname "$TUI_DIR")"
TRAINING_DIR="${FEEDBACK_DIR}/training"
EXERCISES_DIR="${TRAINING_DIR}/exercises"

# Source dependencies (if not already sourced)
[[ -z "${TUI_NC:-}" ]] && source "${TUI_DIR}/widgets.sh"

# ============================================================================
# Available Exercises
# ============================================================================

# Topics with exercises (discovered dynamically)
get_available_exercises() {
    local exercises=()
    for file in "${EXERCISES_DIR}"/*-exercises.sh; do
        if [[ -f "$file" ]]; then
            local topic
            topic=$(basename "$file" -exercises.sh)
            exercises+=("$topic")
        fi
    done
    echo "${exercises[@]}"
}

declare -A TOPIC_DESCRIPTIONS=(
    ["grep"]="Text searching with regular expressions"
    ["sed"]="Stream editing and substitution"
    ["awk"]="Data extraction and formatting"
    ["find"]="File searching by attributes"
    ["tar"]="Archive operations"
    ["permissions"]="chmod, chown, and umask"
    ["processes"]="Process management (ps, kill)"
    ["users"]="User administration"
    ["networking"]="Network diagnostics"
    ["filesystems"]="Mount, df, disk operations"
)

# ============================================================================
# Practice Menu
# ============================================================================

show_practice_menu() {
    while true; do
        local choice
        choice=$(tui_menu "Practice - Build Your Skills" 20 60 \
            "select"    "Choose a topic to practice" \
            "weak"      "Practice your weak areas" \
            "drill"     "Quick-fire drills (muscle memory)" \
            "mix"       "Interleaved practice (mixed topics)" \
            "smart"     "Smart review (personalized)" \
            "quick"     "Quick session (5 questions)" \
            "full"      "Full session (10 questions)" \
            "back"      "Return to main menu") || choice="back"

        case "$choice" in
            select)
                select_topic_practice
                ;;
            weak)
                practice_weak_areas
                ;;
            drill)
                show_drill_menu
                ;;
            mix)
                launch_interleaved_practice
                ;;
            smart)
                launch_smart_review
                ;;
            quick)
                quick_session 5
                ;;
            full)
                quick_session 10
                ;;
            back|"")
                return
                ;;
        esac
    done
}

# ============================================================================
# Topic Selection
# ============================================================================

select_topic_practice() {
    # Build menu from available exercises
    local items=()
    for file in "${EXERCISES_DIR}"/*-exercises.sh; do
        if [[ -f "$file" ]]; then
            local topic
            topic=$(basename "$file" -exercises.sh)
            local desc="${TOPIC_DESCRIPTIONS[$topic]:-$topic exercises}"
            items+=("$topic" "$desc")
        fi
    done
    items+=("back" "Return to practice menu")

    if [[ ${#items[@]} -eq 2 ]]; then
        tui_msgbox "No Exercises" "No exercise files found.\n\nRun setup first."
        return
    fi

    while true; do
        local choice
        choice=$(tui_menu "Select Topic" 18 55 "${items[@]}") || choice="back"

        if [[ "$choice" == "back" || -z "$choice" ]]; then
            return
        fi

        configure_and_launch_practice "$choice"
    done
}

# ============================================================================
# Practice Configuration
# ============================================================================

configure_and_launch_practice() {
    local topic="$1"

    # Get session preferences
    local count
    count=$(tui_menu "Number of Exercises" 12 45 \
        "3"  "Quick practice (3 exercises)" \
        "5"  "Standard (5 exercises)" \
        "10" "Extended (10 exercises)") || count="5"

    local hints_choice
    hints_choice=$(tui_menu "Hints" 10 45 \
        "yes" "Enable hints (recommended)" \
        "no"  "Disable hints (harder)") || hints_choice="yes"

    # Confirm and launch
    local hints_text="enabled"
    [[ "$hints_choice" == "no" ]] && hints_text="disabled"

    if tui_yesno "Start Practice" "Topic: $topic\nExercises: $count\nHints: $hints_text\n\nReady to begin?"; then
        launch_practice "$topic" "$count" "$hints_choice"
    fi
}

launch_practice() {
    local topic="$1"
    local count="$2"
    local hints="$3"

    tui_infobox "Starting" "Loading $topic exercises..."
    sleep 1

    tui_clear

    # Build command
    local args=("practice" "$topic" "-n" "$count")
    [[ "$hints" == "no" ]] && args+=("--no-hints")

    # Run practice session
    "${FEEDBACK_DIR}/lpic-train" "${args[@]}" || true

    echo
    read -rp "Press Enter to return to menu..."
}

# ============================================================================
# Weak Areas Practice
# ============================================================================

practice_weak_areas() {
    local db_file="${HOME}/.lpic1/progress.db"

    if [[ ! -f "$db_file" ]]; then
        tui_msgbox "No Data" "No practice history found.\n\nComplete some exercises first to identify weak areas."
        return
    fi

    # Find topics with low success rate
    local weak_topics
    weak_topics=$(sqlite3 "$db_file" << 'SQL'
SELECT DISTINCT
    CASE
        WHEN command IN ('grep', 'egrep', 'fgrep') THEN 'grep'
        WHEN command IN ('sed') THEN 'sed'
        WHEN command IN ('awk', 'gawk') THEN 'awk'
        WHEN command IN ('find', 'locate', 'which') THEN 'find'
        WHEN command IN ('tar', 'gzip', 'bzip2', 'xz') THEN 'tar'
        WHEN command IN ('chmod', 'chown', 'chgrp', 'umask') THEN 'permissions'
        WHEN command IN ('ps', 'kill', 'jobs', 'bg', 'fg', 'nice') THEN 'processes'
        WHEN command IN ('useradd', 'usermod', 'userdel', 'groupadd', 'passwd') THEN 'users'
        WHEN command IN ('ip', 'ss', 'ping', 'dig', 'netstat') THEN 'networking'
        ELSE command
    END as topic
FROM commands
WHERE attempts >= 3 AND (successes * 100 / attempts) < 70
LIMIT 3;
SQL
    ) 2>/dev/null || echo ""

    if [[ -z "$weak_topics" ]]; then
        tui_msgbox "Great Progress!" "No significant weak areas found.\n\nYou're doing well! Consider:\n• Taking a full test\n• Trying exam mode\n• Learning new topics"
        return
    fi

    # Build menu from weak topics
    local items=()
    while IFS= read -r topic; do
        [[ -z "$topic" ]] && continue
        if [[ -f "${EXERCISES_DIR}/${topic}-exercises.sh" ]]; then
            local desc="${TOPIC_DESCRIPTIONS[$topic]:-Needs practice}"
            items+=("$topic" "$desc")
        fi
    done <<< "$weak_topics"

    if [[ ${#items[@]} -eq 0 ]]; then
        tui_msgbox "No Exercises" "No exercises available for weak areas."
        return
    fi

    items+=("back" "Return to practice menu")

    local choice
    choice=$(tui_menu "Weak Areas (Need Practice)" 14 55 "${items[@]}") || choice="back"

    if [[ "$choice" != "back" && -n "$choice" ]]; then
        launch_practice "$choice" 5 "yes"
    fi
}

# ============================================================================
# Quick Session
# ============================================================================

quick_session() {
    local count="$1"

    # Get available topics
    local topics=()
    for file in "${EXERCISES_DIR}"/*-exercises.sh; do
        if [[ -f "$file" ]]; then
            local topic
            topic=$(basename "$file" -exercises.sh)
            topics+=("$topic")
        fi
    done

    if [[ ${#topics[@]} -eq 0 ]]; then
        tui_msgbox "No Exercises" "No exercises available."
        return
    fi

    # Let user select multiple topics or random
    local items=()
    items+=("random" "Random mix of topics")
    for topic in "${topics[@]}"; do
        local desc="${TOPIC_DESCRIPTIONS[$topic]:-$topic}"
        items+=("$topic" "$desc")
    done

    local choice
    choice=$(tui_menu "Quick Session ($count exercises)" 18 55 "${items[@]}") || return

    if [[ "$choice" == "random" ]]; then
        # Pick random topic
        local random_topic="${topics[$((RANDOM % ${#topics[@]}))]}"
        launch_practice "$random_topic" "$count" "yes"
    elif [[ -n "$choice" ]]; then
        launch_practice "$choice" "$count" "yes"
    fi
}

# ============================================================================
# Drill Menu (Muscle Memory)
# ============================================================================

show_drill_menu() {
    tui_msgbox "Quick-Fire Drills" "Build muscle memory with rapid recall exercises!

How it works:
• Answer short questions as fast as you can
• Speed builds automatic recall
• Focus on one topic to master it

This is like flashcards but for commands."

    # Select topic for drilling
    local items=()
    items+=("chmod" "Permission calculations (755, 644, etc.)")
    items+=("grep" "Grep flags (-i, -v, -r, etc.)")
    items+=("find" "Find options (-name, -type, -exec)")
    items+=("ps" "Process commands and signals")
    items+=("all" "Mix of all topics")
    items+=("back" "Return to practice menu")

    local choice
    choice=$(tui_menu "Select Topic for Drill" 16 55 "${items[@]}") || choice="back"

    if [[ "$choice" == "back" || -z "$choice" ]]; then
        return
    fi

    # Select number of rounds
    local rounds
    rounds=$(tui_menu "Number of Rounds" 12 40 \
        "5"  "Quick drill (5 questions)" \
        "10" "Standard (10 questions)" \
        "20" "Intensive (20 questions)") || rounds="10"

    tui_clear

    echo -e "${TUI_BOLD}${TUI_CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              QUICK DRILL: ${choice^^}"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${TUI_NC}"
    echo

    "${FEEDBACK_DIR}/lpic-train" drill "$choice" -n "$rounds" || true

    echo
    read -rp "Press Enter to return to menu..."
}

# ============================================================================
# Interleaved Practice
# ============================================================================

launch_interleaved_practice() {
    tui_msgbox "Interleaved Practice" "Why mix topics?

Research shows interleaved practice leads to:
• Better long-term retention
• Improved transfer to new problems
• Stronger connections between concepts

You'll get questions from different topics
randomly mixed together."

    local count
    count=$(tui_menu "Number of Questions" 12 45 \
        "5"  "Quick mix (5 questions)" \
        "10" "Standard mix (10 questions)" \
        "15" "Extended mix (15 questions)") || count="10"

    tui_clear

    echo -e "${TUI_BOLD}${TUI_CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              INTERLEAVED PRACTICE                          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${TUI_NC}"
    echo

    "${FEEDBACK_DIR}/lpic-train" mix -n "$count" || true

    echo
    read -rp "Press Enter to return to menu..."
}

# ============================================================================
# Smart Review
# ============================================================================

launch_smart_review() {
    tui_clear

    echo -e "${TUI_BOLD}${TUI_CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              SMART REVIEW                                   ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${TUI_NC}"
    echo

    "${FEEDBACK_DIR}/lpic-train" smart || true

    echo
    read -rp "Press Enter to return to menu..."
}

# ============================================================================
# Entry Point (when run directly)
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "${TUI_DIR}/widgets.sh"
    show_practice_menu
fi
