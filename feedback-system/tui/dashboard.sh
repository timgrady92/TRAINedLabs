#!/bin/bash
# LPIC-1 TUI - Dashboard View
# Shows progress summary, topic breakdown, weak areas, and recommendations

set -euo pipefail

# Get script directory
TUI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEEDBACK_DIR="$(dirname "$TUI_DIR")"
TRAINING_DIR="${FEEDBACK_DIR}/training"

# Source dependencies (if not already sourced)
[[ -z "${TUI_NC:-}" ]] && source "${TUI_DIR}/widgets.sh"
[[ -z "${LPIC_DIR:-}" ]] && source "${TRAINING_DIR}/common.sh"

# Configuration
LPIC_DIR="${HOME}/.lpic1"
DB_FILE="${LPIC_DIR}/progress.db"

# ============================================================================
# Data Gathering
# ============================================================================

get_topic_progress() {
    if [[ ! -f "$DB_FILE" ]]; then
        return
    fi

    sqlite3 "$DB_FILE" << 'SQL'
SELECT
    topic,
    COUNT(*) as total,
    SUM(completed) as done
FROM objectives
GROUP BY topic
ORDER BY topic;
SQL
}

get_incomplete_objectives() {
    if [[ ! -f "$DB_FILE" ]]; then
        return
    fi

    sqlite3 "$DB_FILE" << 'SQL'
SELECT number, title, weight
FROM objectives
WHERE completed = 0
ORDER BY weight DESC, number
LIMIT 5;
SQL
}

get_recent_commands() {
    if [[ ! -f "$DB_FILE" ]]; then
        return
    fi

    sqlite3 "$DB_FILE" << 'SQL'
SELECT command, attempts, successes
FROM commands
WHERE attempts > 0
ORDER BY last_practiced DESC
LIMIT 5;
SQL
}

get_weak_areas() {
    if [[ ! -f "$DB_FILE" ]]; then
        return
    fi

    # Commands with low success rate
    sqlite3 "$DB_FILE" << 'SQL'
SELECT command, successes, attempts
FROM commands
WHERE attempts >= 3 AND (successes * 100 / attempts) < 60
ORDER BY (successes * 100 / attempts) ASC
LIMIT 5;
SQL
}

get_next_suggestion() {
    if [[ ! -f "$DB_FILE" ]]; then
        echo "Initialize progress tracking first"
        return
    fi

    # First check for weak commands that need practice
    local weak_cmd
    weak_cmd=$(sqlite3 "$DB_FILE" "SELECT command FROM commands WHERE attempts >= 3 AND (successes * 100 / attempts) < 60 ORDER BY (successes * 100 / attempts) ASC LIMIT 1;" 2>/dev/null)

    if [[ -n "$weak_cmd" ]]; then
        echo "PRACTICE: '$weak_cmd' (low success rate)"
        return
    fi

    # Check for stale commands (not practiced in 7+ days)
    local stale_cmd
    stale_cmd=$(sqlite3 "$DB_FILE" "SELECT command FROM commands WHERE attempts > 0 AND julianday('now') - julianday(last_practiced) > 7 ORDER BY last_practiced ASC LIMIT 1;" 2>/dev/null)

    if [[ -n "$stale_cmd" ]]; then
        echo "REVIEW: '$stale_cmd' (not practiced recently)"
        return
    fi

    # Find highest-weight incomplete objective
    local next
    next=$(sqlite3 "$DB_FILE" "SELECT number || ': ' || title FROM objectives WHERE completed=0 ORDER BY weight DESC, number LIMIT 1;")

    if [[ -n "$next" ]]; then
        echo "LEARN: $next"
    else
        echo "All objectives complete! Ready for exam."
    fi
}

# ============================================================================
# Dashboard Display
# ============================================================================

build_dashboard_text() {
    local output=""

    # Overall Progress
    local total completed percent
    total=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM objectives;" 2>/dev/null || echo "42")
    completed=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM objectives WHERE completed=1;" 2>/dev/null || echo "0")
    [[ $total -gt 0 ]] && percent=$((completed * 100 / total)) || percent=0

    local bar_width=30
    local filled=$((bar_width * percent / 100))
    local empty=$((bar_width - filled))
    local progress_bar
    progress_bar=$(printf "%${filled}s" | tr ' ' '#')
    progress_bar+=$(printf "%${empty}s" | tr ' ' '-')

    output+="OVERALL PROGRESS\n"
    output+="================\n"
    output+="Objectives: $completed/$total ($percent%)\n"
    output+="[$progress_bar]\n\n"

    # Topic Breakdown
    output+="TOPIC BREAKDOWN\n"
    output+="===============\n"
    output+=$(printf "%-8s %-6s %s\n" "Topic" "Done" "Progress")
    output+="\n"

    while IFS='|' read -r topic total_obj done_obj; do
        [[ -z "$topic" ]] && continue
        local topic_pct=$((done_obj * 100 / total_obj))
        local mini_bar=""
        local mini_filled=$((10 * done_obj / total_obj))
        mini_bar=$(printf "%${mini_filled}s" | tr ' ' '#')
        mini_bar+=$(printf "%$((10 - mini_filled))s" | tr ' ' '-')
        output+=$(printf "%-8s %d/%-3d [%s] %d%%\n" "$topic" "$done_obj" "$total_obj" "$mini_bar" "$topic_pct")
        output+="\n"
    done < <(get_topic_progress)

    # Weak Areas
    local weak_areas
    weak_areas=$(get_weak_areas)
    if [[ -n "$weak_areas" ]]; then
        output+="\nNEEDS PRACTICE\n"
        output+="==============\n"
        while IFS='|' read -r cmd successes attempts; do
            [[ -z "$cmd" ]] && continue
            local rate=$((successes * 100 / attempts))
            output+="$cmd: $successes/$attempts ($rate%)\n"
        done <<< "$weak_areas"
    fi

    # Next Suggestion
    output+="\nRECOMMENDED NEXT\n"
    output+="================\n"
    output+="$(get_next_suggestion)\n"

    echo -e "$output"
}

show_dashboard() {
    while true; do
        if [[ ! -f "$DB_FILE" ]]; then
            tui_msgbox "Dashboard" "Progress database not found.\n\nRun the setup script first:\n  sudo ./setup-fedora.sh\n  or\n  sudo ./setup-ubuntu.sh"
            return
        fi

        # Get progress summary for menu title
        local total completed percent
        total=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM objectives;" 2>/dev/null || echo "42")
        completed=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM objectives WHERE completed=1;" 2>/dev/null || echo "0")
        [[ $total -gt 0 ]] && percent=$((completed * 100 / total)) || percent=0

        local choice
        choice=$(tui_menu "Dashboard - $completed/$total objectives ($percent%)" 18 55 \
            "summary"     "View detailed progress summary" \
            "topics"      "Topic-by-topic breakdown" \
            "weak"        "Commands needing practice" \
            "recent"      "Recently practiced commands" \
            "suggest"     "Get study recommendation" \
            "back"        "Return to main menu") || choice="back"

        case "$choice" in
            summary)
                local summary
                summary=$(build_dashboard_text)
                tui_textbox "Progress Summary" "$summary" 24 70
                ;;
            topics)
                show_topic_details
                ;;
            weak)
                show_weak_areas
                ;;
            recent)
                show_recent_activity
                ;;
            suggest)
                show_smart_suggestion
                ;;
            back|"")
                return
                ;;
        esac
    done
}

# ============================================================================
# Topic Details
# ============================================================================

show_topic_details() {
    local topic_data
    topic_data=$(get_topic_progress)

    if [[ -z "$topic_data" ]]; then
        tui_msgbox "Topic Progress" "No progress data available."
        return
    fi

    # Build menu items from topic data
    local items=()
    while IFS='|' read -r topic total_obj done_obj; do
        [[ -z "$topic" ]] && continue
        local pct=$((done_obj * 100 / total_obj))
        items+=("$topic" "$done_obj/$total_obj complete ($pct%)")
    done <<< "$topic_data"
    items+=("back" "Return to dashboard")

    local choice
    choice=$(tui_menu "Topic Progress" 18 55 "${items[@]}") || choice="back"

    if [[ "$choice" != "back" && -n "$choice" ]]; then
        show_topic_objectives "$choice"
    fi
}

show_topic_objectives() {
    local topic="$1"

    local objectives
    objectives=$(sqlite3 "$DB_FILE" "SELECT number, title, completed, weight FROM objectives WHERE topic='$topic' ORDER BY number;")

    local text="Objectives for Topic $topic\n"
    text+="================================\n\n"

    while IFS='|' read -r number title completed weight; do
        [[ -z "$number" ]] && continue
        local status="[ ]"
        [[ "$completed" == "1" ]] && status="[X]"
        text+="$status $number: $title (weight: $weight)\n"
    done <<< "$objectives"

    tui_textbox "Topic $topic Objectives" "$text" 20 70
}

# ============================================================================
# Weak Areas
# ============================================================================

show_weak_areas() {
    local weak
    weak=$(get_weak_areas)

    if [[ -z "$weak" ]]; then
        tui_msgbox "Practice Areas" "No weak areas identified yet.\n\nComplete more exercises to get personalized recommendations."
        return
    fi

    local text="Commands Needing Practice\n"
    text+="=========================\n"
    text+="(Less than 60% success rate)\n\n"
    text+=$(printf "%-15s %-12s %s\n" "Command" "Success" "Rate")
    text+="\n"

    while IFS='|' read -r cmd successes attempts; do
        [[ -z "$cmd" ]] && continue
        local rate=$((successes * 100 / attempts))
        text+=$(printf "%-15s %d/%-3d      %d%%\n" "$cmd" "$successes" "$attempts" "$rate")
        text+="\n"
    done <<< "$weak"

    text+="\nTip: Use 'lpic1 practice <topic>' to improve.\n"

    tui_textbox "Needs Practice" "$text" 18 60
}

# ============================================================================
# Recent Activity
# ============================================================================

show_recent_activity() {
    local recent
    recent=$(get_recent_commands)

    if [[ -z "$recent" ]]; then
        tui_msgbox "Recent Activity" "No practice history yet.\n\nStart with:\n  lpic1 learn grep\n  lpic1 practice grep"
        return
    fi

    local text="Recently Practiced Commands\n"
    text+="===========================\n\n"
    text+=$(printf "%-15s %-10s %s\n" "Command" "Attempts" "Successes")
    text+="\n"

    while IFS='|' read -r cmd attempts successes; do
        [[ -z "$cmd" ]] && continue
        text+=$(printf "%-15s %-10s %s\n" "$cmd" "$attempts" "$successes")
        text+="\n"
    done <<< "$recent"

    tui_textbox "Recent Activity" "$text" 16 55
}

# ============================================================================
# Smart Suggestion
# ============================================================================

show_smart_suggestion() {
    local suggestion
    suggestion=$(get_next_suggestion)

    local text="PERSONALIZED RECOMMENDATION\n"
    text+="============================\n\n"
    text+="Based on your learning data:\n\n"
    text+="$suggestion\n\n"

    # Add context based on suggestion type
    if [[ "$suggestion" == PRACTICE:* ]]; then
        text+="WHY THIS MATTERS:\n"
        text+="Your success rate is below 60% for this command.\n"
        text+="Focused practice will build confidence.\n\n"
        text+="RECOMMENDED ACTION:\n"
        text+="  lpic1 drill [topic]\n"
        text+="  (Quick-fire drills for muscle memory)\n"
    elif [[ "$suggestion" == REVIEW:* ]]; then
        text+="WHY THIS MATTERS:\n"
        text+="Skills fade without practice (use it or lose it).\n"
        text+="A quick review reinforces long-term memory.\n\n"
        text+="RECOMMENDED ACTION:\n"
        text+="  lpic1 practice [topic]\n"
        text+="  (Even 5 minutes helps!)\n"
    elif [[ "$suggestion" == LEARN:* ]]; then
        text+="WHY THIS MATTERS:\n"
        text+="Higher-weight objectives = more exam questions.\n"
        text+="Focus on high-impact topics first.\n\n"
        text+="RECOMMENDED ACTION:\n"
        text+="  lpic1 learn [topic]\n"
        text+="  (Study the concepts, then practice)\n"
    fi

    text+="\n"
    text+="LEARNING SCIENCE TIPS:\n"
    text+="• Spaced repetition beats cramming\n"
    text+="• Mix topics for better retention\n"
    text+="• Speed drills build automaticity\n"
    text+="• Explaining WHY deepens understanding\n"

    tui_textbox "Study Recommendation" "$text" 26 60
}

# ============================================================================
# Entry Point (when run directly)
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "${TUI_DIR}/widgets.sh"
    source "${TRAINING_DIR}/common.sh"
    show_dashboard
fi
