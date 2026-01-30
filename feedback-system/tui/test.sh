#!/bin/bash
# LPIC-1 TUI - Test Mode
# Skill assessment without hints

set -euo pipefail

# Get script directory
TUI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEEDBACK_DIR="$(dirname "$TUI_DIR")"
TRAINING_DIR="${FEEDBACK_DIR}/training"
EXERCISES_DIR="${TRAINING_DIR}/exercises"

# Source dependencies (if not already sourced)
[[ -z "${TUI_NC:-}" ]] && source "${TUI_DIR}/widgets.sh"

# ============================================================================
# Topic Descriptions
# ============================================================================

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
# Test Menu
# ============================================================================

show_test_menu() {
    while true; do
        local choice
        choice=$(tui_menu "Test - Skill Assessment" 16 55 \
            "select"    "Test a specific topic" \
            "mixed"     "Mixed topic test" \
            "timed"     "Timed challenge" \
            "scores"    "View past scores" \
            "back"      "Return to main menu") || choice="back"

        case "$choice" in
            select)
                select_topic_test
                ;;
            mixed)
                mixed_topic_test
                ;;
            timed)
                timed_challenge
                ;;
            scores)
                view_scores
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

select_topic_test() {
    # Build menu from available exercises
    local items=()
    for file in "${EXERCISES_DIR}"/*-exercises.sh; do
        if [[ -f "$file" ]]; then
            local topic
            topic=$(basename "$file" -exercises.sh)
            local desc="${TOPIC_DESCRIPTIONS[$topic]:-$topic test}"
            items+=("$topic" "$desc")
        fi
    done
    items+=("back" "Return to test menu")

    if [[ ${#items[@]} -eq 2 ]]; then
        tui_msgbox "No Tests" "No test files found.\n\nRun setup first."
        return
    fi

    while true; do
        local choice
        choice=$(tui_menu "Select Topic for Test" 18 55 "${items[@]}") || choice="back"

        if [[ "$choice" == "back" || -z "$choice" ]]; then
            return
        fi

        configure_and_launch_test "$choice"
    done
}

# ============================================================================
# Test Configuration
# ============================================================================

configure_and_launch_test() {
    local topic="$1"

    # Get number of questions
    local count
    count=$(tui_menu "Number of Questions" 12 45 \
        "5"  "Quick test (5 questions)" \
        "10" "Standard test (10 questions)" \
        "15" "Comprehensive (15 questions)") || count="5"

    # Warning about no hints
    tui_msgbox "Test Mode" "IMPORTANT: Test mode has NO HINTS!\n\nThis is a real assessment of your skills.\nYour results will be recorded.\n\nTopic: $topic\nQuestions: $count"

    if tui_yesno "Ready?" "Start the test now?"; then
        launch_test "$topic" "$count" "no"
    fi
}

launch_test() {
    local topic="$1"
    local count="$2"
    local timed="$3"

    tui_infobox "Starting" "Loading $topic test..."
    sleep 1

    tui_clear

    # Run test through lpic-train (or skill-checker for timed)
    if [[ "$timed" == "yes" ]]; then
        "${FEEDBACK_DIR}/skill-checker.sh" session "$topic" -n "$count" -t || true
    else
        "${FEEDBACK_DIR}/lpic-train" test "$topic" -n "$count" || true
    fi

    echo
    echo -en "Press Enter to return to menu..."
    read -r _
}

# ============================================================================
# Mixed Topic Test
# ============================================================================

mixed_topic_test() {
    # Get available topics
    local topics=()
    for file in "${EXERCISES_DIR}"/*-exercises.sh; do
        if [[ -f "$file" ]]; then
            local topic
            topic=$(basename "$file" -exercises.sh)
            topics+=("$topic")
        fi
    done

    if [[ ${#topics[@]} -lt 2 ]]; then
        tui_msgbox "Not Enough Topics" "Need at least 2 topics for mixed test."
        return
    fi

    # Let user select topics to include
    local checklist_items=()
    for topic in "${topics[@]}"; do
        local desc="${TOPIC_DESCRIPTIONS[$topic]:-$topic}"
        checklist_items+=("$topic" "$desc" "on")
    done

    local selected
    selected=$(tui_checklist "Select Topics for Mixed Test" 18 55 "${checklist_items[@]}") || return

    if [[ -z "$selected" ]]; then
        tui_msgbox "No Topics" "No topics selected."
        return
    fi

    # Pick random topic from selected
    local selected_array
    read -ra selected_array <<< "$selected"
    local random_topic="${selected_array[$((RANDOM % ${#selected_array[@]}))]}"
    # Remove quotes if present
    random_topic="${random_topic//\"/}"

    tui_msgbox "Mixed Test" "Testing: ${selected_array[*]}\n\nStarting with: $random_topic\n\n5 questions per topic (randomly selected)"

    if tui_yesno "Ready?" "Start mixed topic test?"; then
        launch_test "$random_topic" 5 "no"
    fi
}

# ============================================================================
# Timed Challenge
# ============================================================================

timed_challenge() {
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
        tui_msgbox "No Tests" "No test files available."
        return
    fi

    # Build menu
    local items=()
    for topic in "${topics[@]}"; do
        local desc="${TOPIC_DESCRIPTIONS[$topic]:-$topic}"
        items+=("$topic" "$desc")
    done
    items+=("back" "Return to test menu")

    local choice
    choice=$(tui_menu "Timed Challenge - Select Topic" 16 55 "${items[@]}") || choice="back"

    if [[ "$choice" == "back" || -z "$choice" ]]; then
        return
    fi

    # Get time limit
    local time_limit
    time_limit=$(tui_menu "Time Limit" 12 40 \
        "5"  "Sprint (5 minutes)" \
        "10" "Standard (10 minutes)" \
        "15" "Extended (15 minutes)") || time_limit="10"

    tui_msgbox "Timed Challenge" "TIMED CHALLENGE\n\nTopic: $choice\nTime: $time_limit minutes\nQuestions: 10\n\nNo hints. Clock starts immediately!"

    if tui_yesno "Ready?" "Start timed challenge?"; then
        launch_test "$choice" 10 "yes"
    fi
}

# ============================================================================
# View Scores
# ============================================================================

view_scores() {
    local db_file="/opt/LPIC-1/data/progress.db"

    if [[ ! -f "$db_file" ]]; then
        tui_msgbox "No History" "No test history found.\n\nComplete some tests to see scores."
        return
    fi

    # Get recent test results (from labs table which stores exam results)
    local results
    results=$(sqlite3 "$db_file" << 'SQL'
SELECT
    lab_id,
    score,
    datetime(started_at, 'localtime') as started
FROM labs
WHERE lab_id LIKE 'exam-%'
ORDER BY started_at DESC
LIMIT 10;
SQL
    ) 2>/dev/null || results=""

    if [[ -z "$results" ]]; then
        # Try getting command success rates instead
        results=$(sqlite3 "$db_file" << 'SQL'
SELECT
    command,
    successes,
    attempts,
    CASE WHEN attempts > 0 THEN (successes * 100 / attempts) ELSE 0 END as rate
FROM commands
WHERE attempts > 0
ORDER BY last_practiced DESC
LIMIT 10;
SQL
        ) 2>/dev/null || results=""
    fi

    if [[ -z "$results" ]]; then
        tui_msgbox "No Scores" "No test scores recorded yet.\n\nComplete some tests to see your progress."
        return
    fi

    local text="Recent Performance\n"
    text+="==================\n\n"

    if [[ "$results" == *"exam-"* ]]; then
        text+=$(printf "%-25s %-8s %s\n" "Test" "Score" "Date")
        text+="\n"
        while IFS='|' read -r test_id score date; do
            [[ -z "$test_id" ]] && continue
            local name="${test_id#exam-}"
            text+=$(printf "%-25s %-8s %s\n" "$name" "$score%" "$date")
            text+="\n"
        done <<< "$results"
    else
        text+=$(printf "%-15s %-10s %-10s %s\n" "Command" "Success" "Attempts" "Rate")
        text+="\n"
        while IFS='|' read -r cmd successes attempts rate; do
            [[ -z "$cmd" ]] && continue
            text+=$(printf "%-15s %-10s %-10s %s%%\n" "$cmd" "$successes" "$attempts" "$rate")
            text+="\n"
        done <<< "$results"
    fi

    tui_textbox "Test Scores" "$text" 18 60
}

# ============================================================================
# Entry Point (when run directly)
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "${TUI_DIR}/widgets.sh"
    show_test_menu
fi
