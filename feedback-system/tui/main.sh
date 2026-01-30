#!/bin/bash
# LPIC-1 TUI - Main Menu
# Central hub for all training features

set -euo pipefail

# ERROR TRAP - Show useful info on failure
trap 'echo "ERROR: Script failed at line $LINENO" >&2; exit 1' ERR

# Get script directory
TUI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEEDBACK_DIR="$(dirname "$TUI_DIR")"
TRAINING_DIR="${FEEDBACK_DIR}/training"

# VERIFY paths before sourcing
if [[ ! -f "${TUI_DIR}/widgets.sh" ]]; then
    echo "ERROR: widgets.sh not found at ${TUI_DIR}/widgets.sh" >&2
    echo "TUI_DIR resolved to: ${TUI_DIR}" >&2
    exit 1
fi
if [[ ! -f "${TRAINING_DIR}/common.sh" ]]; then
    echo "ERROR: common.sh not found at ${TRAINING_DIR}/common.sh" >&2
    echo "TRAINING_DIR resolved to: ${TRAINING_DIR}" >&2
    exit 1
fi

# Source dependencies (widgets.sh sources theme.sh)
if ! source "${TUI_DIR}/widgets.sh"; then
    echo "ERROR: Failed to load widgets.sh" >&2
    exit 1
fi
if ! source "${TRAINING_DIR}/common.sh"; then
    echo "ERROR: Failed to load common.sh" >&2
    exit 1
fi

# Configuration
LPIC_DIR="${LPIC_DIR:-/opt/LPIC-1/data}"
DB_FILE="${LPIC_DIR}/progress.db"

# Check for sqlite3 availability
DB_AVAILABLE=true
if ! command -v sqlite3 &>/dev/null; then
    echo "Warning: sqlite3 not found, progress tracking disabled" >&2
    DB_AVAILABLE=false
fi

# ============================================================================
# Progress Summary
# ============================================================================

get_progress_summary() {
    if [[ "$DB_AVAILABLE" != "true" ]] || [[ ! -f "$DB_FILE" ]]; then
        echo "0|0|0"
        return
    fi

    local total completed percent
    total=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM objectives;" 2>/dev/null || echo "0")
    completed=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM objectives WHERE completed=1;" 2>/dev/null || echo "0")

    if [[ $total -gt 0 ]]; then
        percent=$((completed * 100 / total))
    else
        percent=0
    fi

    echo "${completed}|${total}|${percent}"
}

# Build progress bar string
build_progress_bar() {
    local percent="$1"
    local width="${2:-20}"
    local filled=$((width * percent / 100))
    local empty=$((width - filled))

    local bar=""
    bar+=$(printf "%${filled}s" | tr ' ' '█')
    bar+=$(printf "%${empty}s" | tr ' ' '░')
    echo "$bar"
}

# ============================================================================
# Main Menu
# ============================================================================

show_main_menu() {
    local progress_data
    progress_data=$(get_progress_summary)
    IFS='|' read -r completed total percent <<< "$progress_data"

    local progress_bar
    progress_bar=$(build_progress_bar "$percent")

    # Build menu title with progress
    local title="LPIC-1 Training Platform"

    # For beginners (0% progress), show a "Start Here" option prominently
    local choice
    if [[ $percent -eq 0 ]]; then
        choice=$(tui_menu "$title - Getting Started" 22 60 \
            "start"      ">>> NEW? START HERE <<<" \
            "learn"      "Lessons by topic" \
            "practice"   "Guided exercises with hints" \
            "dashboard"  "View progress & recommendations" \
            "test"       "Skill assessment (no hints)" \
            "sandbox"    "Free experimentation" \
            "challenges" "Break/fix scenarios" \
            "exam"       "Timed LPIC-1 simulation" \
            "settings"   "Configure preferences" \
            "quit"       "Exit training platform") || choice="quit"
    else
        choice=$(tui_menu "$title ($percent% complete)" 20 60 \
            "dashboard"  "View progress & recommendations" \
            "learn"      "Lessons by topic" \
            "practice"   "Guided exercises with hints" \
            "test"       "Skill assessment (no hints)" \
            "sandbox"    "Free experimentation" \
            "challenges" "Break/fix scenarios" \
            "exam"       "Timed LPIC-1 simulation" \
            "settings"   "Configure preferences" \
            "quit"       "Exit training platform") || choice="quit"
    fi

    [[ -z "$choice" ]] && choice="quit"
    echo "$choice"
}

# ============================================================================
# Settings Menu
# ============================================================================

show_settings_menu() {
    local choice
    choice=$(tui_menu "Settings" 15 50 \
        "reset"   "Reset all progress" \
        "export"  "Export progress to JSON" \
        "verify"  "Verify package installation" \
        "test"    "Run system self-test" \
        "about"   "About LPIC-1 Training" \
        "back"    "Return to main menu")

    case "$choice" in
        reset)
            if tui_yesno "Confirm Reset" "This will erase ALL progress. Continue?"; then
                rm -f "$DB_FILE"
                bash "${FEEDBACK_DIR}/init-progress.sh"
                tui_msgbox "Progress Reset" "Progress has been reset to zero."
            fi
            ;;
        export)
            local export_file="${HOME}/lpic1-progress-$(date +%Y%m%d).json"
            "${FEEDBACK_DIR}/lpic-check" export "$export_file" 2>/dev/null || true
            tui_msgbox "Export Complete" "Progress exported to:\n$export_file"
            ;;
        verify)
            tui_clear
            "${FEEDBACK_DIR}/lpic-check" verify-packages
            echo
            echo -en "Press Enter to continue..."
            read -r _
            ;;
        test)
            tui_clear
            "${FEEDBACK_DIR}/lpic-check" self-test
            echo
            echo -en "Press Enter to continue..."
            read -r _
            ;;
        about)
            tui_msgbox "About" "LPIC-1 Training Platform v1.0

A hands-on training environment for
LPIC-1 Linux Professional certification.

Features:
• Interactive lessons with live examples
• Guided practice exercises
• Break/fix troubleshooting scenarios
• Timed exam simulations
• Progress tracking

Training wheels for Linux mastery!"
            ;;
        back|"")
            return
            ;;
    esac
}

# ============================================================================
# Getting Started (for new users)
# ============================================================================

show_getting_started() {
    # Step 1: Welcome and orientation
    tui_textbox "Welcome to LPIC-1 Training" "
WHAT IS THIS?
=============
This is a hands-on training environment for the LPIC-1 Linux
certification exam. It combines:

  * Interactive lessons with live examples
  * Guided practice exercises (with hints!)
  * Real troubleshooting scenarios
  * Timed exam simulations

The platform tracks your progress and recommends what to study next.


HOW LPIC-1 CERTIFICATION WORKS
==============================
LPIC-1 has TWO exams, each 90 minutes:

  Exam 101: System basics, commands, storage
  Exam 102: Scripting, services, networking, security

You need to pass BOTH to earn LPIC-1 certification.


RECOMMENDED LEARNING PATH
=========================
  1. LEARN   - Read lessons to understand concepts
  2. PRACTICE - Do exercises with hints available
  3. TEST    - Try exercises without hints
  4. EXAM    - Simulate the real exam

Press OK to choose your first topic..." 28 65

    # Step 2: Pick first topic
    local first_topic
    first_topic=$(tui_menu "Choose Your First Topic" 18 60 \
        "grep"        "Text searching (essential skill)" \
        "permissions" "File permissions (chmod, chown)" \
        "processes"   "Process management (ps, kill)" \
        "filesystems" "Disk and storage basics" \
        "systemd"     "Service management" \
        "skip"        "Go to main menu instead") || first_topic="skip"

    if [[ "$first_topic" == "skip" || -z "$first_topic" ]]; then
        return
    fi

    # Step 3: Explain what will happen
    tui_msgbox "Starting: $first_topic" "You're about to start the $first_topic lesson.

WHAT TO EXPECT:
  * Explanation of key concepts
  * Live command examples
  * Tips for the certification exam

CONTROLS:
  * Press ENTER to continue through sections
  * The lesson is self-paced

After the lesson, you'll be offered practice exercises.

Ready? Press OK to begin!"

    # Launch the lesson
    tui_clear
    "${FEEDBACK_DIR}/lpic-train" learn "$first_topic" || true

    echo
    echo -e "${TUI_GREEN}Lesson complete!${TUI_NC}"
    echo
    echo -en "Press Enter to continue to practice exercises..."
    read -r _

    # Offer practice
    if tui_yesno "Practice Now?" "Would you like to practice what you just learned?\n\nPractice mode gives you exercises with hints available.\nThis is the best way to reinforce your learning."; then
        tui_clear
        "${FEEDBACK_DIR}/lpic-train" practice "$first_topic" || true
        echo
        echo -en "Press Enter to return to main menu..."
        read -r _
    fi

    # Mark that user has been onboarded
    touch "${LPIC_DIR}/.onboarded" 2>/dev/null || true
}

# ============================================================================
# Welcome Screen
# ============================================================================

show_welcome() {
    local progress_data
    progress_data=$(get_progress_summary)
    IFS='|' read -r completed total percent <<< "$progress_data"

    local bar
    bar=$(build_progress_bar "$percent" 30)

    if [[ $percent -eq 0 ]]; then
        # First-time user welcome
        tui_msgbox "Welcome to LPIC-1 Training!" "This training platform will help you prepare for
the LPIC-1 Linux Professional certification.

WHAT YOU'LL FIND:
  * 11 topic lessons with live examples
  * 60+ practice exercises with hints
  * Break/fix troubleshooting scenarios
  * Timed exam simulations

HOW TO START:
  Select '>>> NEW? START HERE <<<' from the menu
  for a guided introduction to your first topic.

Or jump directly to:
  * Learn - for lessons
  * Practice - for hands-on exercises

Your progress is automatically saved.
Good luck on your certification journey!"
    else
        # Returning user welcome
        tui_msgbox "Welcome Back!" "Your Progress: $completed/$total objectives ($percent%)

[$bar]

RECOMMENDED NEXT STEPS:
  * Dashboard - See personalized recommendations
  * Practice - Continue building skills
  * Exam - Test yourself when ready

Tip: Consistent practice beats cramming.
Even 15 minutes a day builds lasting knowledge."
    fi
}

# ============================================================================
# Main Loop
# ============================================================================

main_loop() {
    # Show welcome on first run
    local first_run="${LPIC_DIR}/.tui-welcomed"
    if [[ ! -f "$first_run" ]]; then
        show_welcome
        touch "$first_run" 2>/dev/null || true
    fi

    while true; do
        local choice
        choice=$(show_main_menu) || choice="quit"

        case "$choice" in
            start)
                show_getting_started
                ;;
            dashboard)
                source "${TUI_DIR}/dashboard.sh"
                show_dashboard
                ;;
            learn)
                source "${TUI_DIR}/learn.sh"
                show_learn_menu
                ;;
            practice)
                source "${TUI_DIR}/practice.sh"
                show_practice_menu
                ;;
            test)
                source "${TUI_DIR}/test.sh"
                show_test_menu
                ;;
            sandbox)
                tui_clear
                "${FEEDBACK_DIR}/lpic-train" sandbox
                ;;
            challenges)
                source "${TUI_DIR}/challenges.sh"
                show_challenges_menu
                ;;
            exam)
                source "${TUI_DIR}/exam.sh"
                show_exam_menu
                ;;
            settings)
                show_settings_menu
                ;;
            quit|"")
                tui_clear
                echo -e "${TUI_CYAN}Happy studying! Good luck on your LPIC-1 exam.${TUI_NC}"
                echo
                exit 0
                ;;
        esac
    done
}

# ============================================================================
# Entry Point
# ============================================================================

# Initialize progress database if needed
if [[ ! -f "$DB_FILE" ]]; then
    mkdir -p "$LPIC_DIR"
    if [[ -f "${FEEDBACK_DIR}/init-progress.sh" ]]; then
        if ! bash "${FEEDBACK_DIR}/init-progress.sh" </dev/null 2>&1; then
            echo "Warning: Progress DB initialization had issues (non-fatal)" >&2
        fi
    fi
fi

# Run main loop
main_loop
