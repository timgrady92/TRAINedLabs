#!/bin/bash
# LPIC-1 TUI - Exam Mode
# Timed LPIC-1 exam simulation

set -euo pipefail

# Get script directory
TUI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEEDBACK_DIR="$(dirname "$TUI_DIR")"

# Source dependencies (if not already sourced)
[[ -z "${TUI_NC:-}" ]] && source "${TUI_DIR}/widgets.sh"

# Configuration
LPIC_DIR="/opt/LPIC-1/data"
DB_FILE="${LPIC_DIR}/progress.db"

# ============================================================================
# Exam Information
# ============================================================================

# LPIC-1 exam structure
# Exam 101: Topics 101-104
# Exam 102: Topics 105-110
# Each exam: 60 questions, 90 minutes, ~65% to pass

declare -A EXAM_INFO=(
    ["101-topics"]="101 102 103 104"
    ["101-name"]="LPIC-1 Exam 101"
    ["101-desc"]="System Architecture, Linux Installation, GNU/Linux Commands, Devices/Filesystems"
    ["102-topics"]="105 106 107 108 109 110"
    ["102-name"]="LPIC-1 Exam 102"
    ["102-desc"]="Shells/Scripts, Interfaces/Desktops, Admin Tasks, Services, Networking, Security"
)

# ============================================================================
# Exam Menu
# ============================================================================

show_exam_menu() {
    while true; do
        local choice
        choice=$(tui_menu "Exam Mode - LPIC-1 Simulation" 16 55 \
            "101"       "LPIC-1 Exam 101 (Topics 101-104)" \
            "102"       "LPIC-1 Exam 102 (Topics 105-110)" \
            "mixed"     "Mixed (all topics)" \
            "custom"    "Custom exam settings" \
            "history"   "View exam history" \
            "tips"      "Exam tips" \
            "back"      "Return to main menu") || choice="back"

        case "$choice" in
            101)
                launch_preset_exam "101"
                ;;
            102)
                launch_preset_exam "102"
                ;;
            mixed)
                launch_preset_exam "mixed"
                ;;
            custom)
                custom_exam
                ;;
            history)
                show_exam_history
                ;;
            tips)
                show_exam_tips
                ;;
            back|"")
                return
                ;;
        esac
    done
}

# ============================================================================
# Preset Exams
# ============================================================================

launch_preset_exam() {
    local exam_type="$1"

    local title desc time_limit obj_count

    case "$exam_type" in
        101)
            title="LPIC-1 Exam 101"
            desc="Topics 101-104:\n• System Architecture\n• Linux Installation & Package Management\n• GNU and Unix Commands\n• Devices, Filesystems, FHS"
            time_limit=90
            obj_count=10
            ;;
        102)
            title="LPIC-1 Exam 102"
            desc="Topics 105-110:\n• Shells and Shell Scripting\n• User Interfaces and Desktops\n• Administrative Tasks\n• Essential System Services\n• Networking Fundamentals\n• Security"
            time_limit=90
            obj_count=10
            ;;
        mixed)
            title="LPIC-1 Full Exam"
            desc="All topics (101-110):\n• Complete LPIC-1 coverage\n• Random objective selection\n• Simulates real exam experience"
            time_limit=90
            obj_count=15
            ;;
    esac

    # Show exam info
    local info_text="$title\n"
    info_text+="══════════════════════════════\n\n"
    info_text+="$desc\n\n"
    info_text+="Format:\n"
    info_text+="• Time limit: $time_limit minutes\n"
    info_text+="• Objectives: $obj_count\n"
    info_text+="• Passing score: 65%\n"
    info_text+="• No hints allowed\n\n"
    info_text+="This simulates the real LPIC-1 exam format.\n"
    info_text+="Your score will be recorded."

    tui_textbox "$title" "$info_text" 22 55

    if tui_yesno "Start Exam" "Ready to begin $title?\n\nTime: $time_limit minutes\nObjectives: $obj_count\n\nThe timer starts immediately!"; then
        launch_exam "$exam_type" "$time_limit" "$obj_count"
    fi
}

# ============================================================================
# Custom Exam
# ============================================================================

custom_exam() {
    # Select exam type
    local exam_type
    exam_type=$(tui_menu "Exam Type" 12 50 \
        "101"   "Exam 101 objectives (101-104)" \
        "102"   "Exam 102 objectives (105-110)" \
        "mixed" "All objectives") || return

    # Select time limit
    local time_limit
    time_limit=$(tui_menu "Time Limit" 14 45 \
        "30"  "Quick practice (30 min)" \
        "45"  "Half exam (45 min)" \
        "60"  "One hour (60 min)" \
        "90"  "Full exam (90 min)" \
        "120" "Extended (120 min)") || time_limit="90"

    # Select number of objectives
    local obj_count
    obj_count=$(tui_menu "Number of Objectives" 14 45 \
        "5"  "Mini test (5 objectives)" \
        "10" "Standard (10 objectives)" \
        "15" "Extended (15 objectives)" \
        "20" "Comprehensive (20 objectives)") || obj_count="10"

    # Confirm
    local type_name="Mixed"
    [[ "$exam_type" == "101" ]] && type_name="Exam 101"
    [[ "$exam_type" == "102" ]] && type_name="Exam 102"

    if tui_yesno "Confirm Custom Exam" "Type: $type_name\nTime: $time_limit minutes\nObjectives: $obj_count\n\nStart exam?"; then
        launch_exam "$exam_type" "$time_limit" "$obj_count"
    fi
}

# ============================================================================
# Launch Exam
# ============================================================================

launch_exam() {
    local exam_type="$1"
    local time_limit="$2"
    local obj_count="$3"

    tui_infobox "Preparing Exam" "Loading objectives..."
    sleep 1

    tui_clear

    echo -e "${TUI_BOLD}${TUI_CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                  LPIC-1 EXAM SIMULATION                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${TUI_NC}"
    echo

    # Build exam command
    local args=("exam-mode" "--time" "$time_limit" "--count" "$obj_count" "--exam" "$exam_type")

    # Run exam through lpic-check
    "${FEEDBACK_DIR}/lpic-check" "${args[@]}" || true

    echo
    echo -en "Press Enter to return to menu..."
    read -r _
}

# ============================================================================
# Exam History
# ============================================================================

show_exam_history() {
    if [[ ! -f "$DB_FILE" ]]; then
        tui_msgbox "No History" "No exam history found.\n\nComplete an exam to see results here."
        return
    fi

    # Get exam results from labs table
    local results
    results=$(sqlite3 "$DB_FILE" << 'SQL'
SELECT
    lab_id,
    score,
    datetime(started_at, 'localtime') as started,
    CAST((julianday(completed_at) - julianday(started_at)) * 24 * 60 AS INTEGER) as duration_min
FROM labs
WHERE lab_id LIKE 'exam-%'
ORDER BY started_at DESC
LIMIT 10;
SQL
    ) 2>/dev/null || results=""

    if [[ -z "$results" ]]; then
        tui_msgbox "No History" "No exam history found.\n\nComplete an exam to track your progress."
        return
    fi

    local text="Exam History (Last 10)\n"
    text+="======================\n\n"
    text+=$(printf "%-20s %-8s %-8s %s\n" "Exam" "Score" "Time" "Date")
    text+="\n"

    local total_exams=0
    local total_score=0
    local passed=0

    while IFS='|' read -r exam_id score started duration; do
        [[ -z "$exam_id" ]] && continue

        local name="${exam_id#exam-}"
        name="${name%-*}"  # Remove timestamp portion

        local result="FAIL"
        if [[ $score -ge 65 ]]; then
            result="PASS"
            ((passed++))
        fi

        text+=$(printf "%-20s %-8s %-8s %s\n" "$name" "$score%" "${duration}m" "${started%% *}")
        text+="\n"

        ((total_exams++))
        ((total_score += score))
    done <<< "$results"

    if [[ $total_exams -gt 0 ]]; then
        local avg_score=$((total_score / total_exams))
        text+="\n"
        text+="Summary:\n"
        text+="  Exams taken: $total_exams\n"
        text+="  Average score: $avg_score%\n"
        text+="  Pass rate: $passed/$total_exams ($((passed * 100 / total_exams))%)\n"
    fi

    tui_textbox "Exam History" "$text" 22 60
}

# ============================================================================
# Exam Tips
# ============================================================================

show_exam_tips() {
    local tips="LPIC-1 Exam Tips\n"
    tips+="================\n\n"

    tips+="BEFORE THE EXAM:\n"
    tips+="• Review all objective domains\n"
    tips+="• Practice with hands-on labs\n"
    tips+="• Know command syntax by heart\n"
    tips+="• Understand file paths and config locations\n\n"

    tips+="DURING THE EXAM:\n"
    tips+="• Read questions carefully\n"
    tips+="• Flag uncertain answers for review\n"
    tips+="• Manage time - 90 min for 60 questions\n"
    tips+="• Don't spend too long on one question\n\n"

    tips+="KEY TOPICS:\n"
    tips+="• Exam 101: Hardware, boot, packages, commands, filesystems\n"
    tips+="• Exam 102: Scripting, X11, users, services, networking, security\n\n"

    tips+="COMMON PITFALLS:\n"
    tips+="• Confusing similar commands (systemctl vs service)\n"
    tips+="• Wrong file paths (/etc vs /var vs /usr)\n"
    tips+="• Permission calculations (chmod modes)\n"
    tips+="• Package manager differences (apt vs dnf vs rpm)\n\n"

    tips+="PRACTICE AREAS:\n"
    tips+="• Process management (ps, kill, nice)\n"
    tips+="• Text processing (grep, sed, awk)\n"
    tips+="• File permissions and ownership\n"
    tips+="• Network configuration and diagnostics\n"

    tui_textbox "Exam Tips" "$tips" 28 60
}

# ============================================================================
# Entry Point (when run directly)
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "${TUI_DIR}/widgets.sh"
    show_exam_menu
fi
