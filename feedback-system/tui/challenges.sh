#!/bin/bash
# LPIC-1 TUI - Challenges Browser
# Launch break/fix and build scenarios

set -euo pipefail

# Get script directory
TUI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEEDBACK_DIR="$(dirname "$TUI_DIR")"
LPIC1_DIR="$(dirname "$FEEDBACK_DIR")"
SCENARIOS_DIR="${LPIC1_DIR}/scenarios"

# Source dependencies (if not already sourced)
[[ -z "${TUI_NC:-}" ]] && source "${TUI_DIR}/widgets.sh"

# ============================================================================
# Scenario Definitions
# ============================================================================

# Break/Fix scenarios
declare -A BREAKFIX_SCENARIOS=(
    ["broken-boot"]="System won't boot - fix GRUB/init issues"
    ["broken-services"]="Critical services failing to start"
    ["broken-permissions"]="Permission issues blocking users"
    ["full-disk"]="Disk full - find and clean"
    ["orphaned-packages"]="Broken package dependencies"
)

# Build scenarios
declare -A BUILD_SCENARIOS=(
    ["create-users"]="Set up user accounts and groups"
    ["setup-web-server"]="Configure Apache/Nginx web server"
    ["setup-mail-server"]="Configure mail services"
    ["setup-print-server"]="Configure CUPS print server"
)

# Difficulty ratings
declare -A SCENARIO_DIFFICULTY=(
    ["broken-permissions"]="Easy"
    ["full-disk"]="Easy"
    ["broken-services"]="Medium"
    ["orphaned-packages"]="Medium"
    ["broken-boot"]="Hard"
    ["create-users"]="Easy"
    ["setup-print-server"]="Medium"
    ["setup-web-server"]="Medium"
    ["setup-mail-server"]="Hard"
)

# Estimated time
declare -A SCENARIO_TIME=(
    ["broken-permissions"]="15 min"
    ["full-disk"]="15 min"
    ["broken-services"]="20 min"
    ["orphaned-packages"]="20 min"
    ["broken-boot"]="30 min"
    ["create-users"]="15 min"
    ["setup-print-server"]="20 min"
    ["setup-web-server"]="25 min"
    ["setup-mail-server"]="30 min"
)

# ============================================================================
# Challenges Menu
# ============================================================================

show_challenges_menu() {
    while true; do
        local choice
        choice=$(tui_menu "Challenges - Real-World Scenarios" 15 55 \
            "breakfix"  "Break/Fix troubleshooting" \
            "build"     "Build from scratch" \
            "random"    "Random challenge" \
            "progress"  "View challenge progress" \
            "back"      "Return to main menu") || choice="back"

        case "$choice" in
            breakfix)
                show_breakfix_menu
                ;;
            build)
                show_build_menu
                ;;
            random)
                random_challenge
                ;;
            progress)
                show_challenge_progress
                ;;
            back|"")
                return
                ;;
        esac
    done
}

# ============================================================================
# Break/Fix Menu
# ============================================================================

show_breakfix_menu() {
    # Check if scenarios exist
    if [[ ! -d "${SCENARIOS_DIR}/break-fix" ]]; then
        tui_msgbox "Not Available" "Break/fix scenarios not found.\n\nExpected location:\n${SCENARIOS_DIR}/break-fix/"
        return
    fi

    # Build menu from available scenarios
    local items=()
    for scenario in broken-permissions full-disk broken-services orphaned-packages broken-boot; do
        local script="${SCENARIOS_DIR}/break-fix/${scenario}.sh"
        if [[ -f "$script" ]]; then
            local desc="${BREAKFIX_SCENARIOS[$scenario]:-Unknown scenario}"
            local diff="${SCENARIO_DIFFICULTY[$scenario]:-?}"
            local time="${SCENARIO_TIME[$scenario]:-?}"
            items+=("$scenario" "[$diff] $desc (~$time)")
        fi
    done

    if [[ ${#items[@]} -eq 0 ]]; then
        tui_msgbox "No Scenarios" "No break/fix scenarios available."
        return
    fi

    items+=("back" "Return to challenges menu")

    while true; do
        local choice
        choice=$(tui_menu "Break/Fix Scenarios" 16 65 "${items[@]}") || choice="back"

        if [[ "$choice" == "back" || -z "$choice" ]]; then
            return
        fi

        show_scenario_details "break-fix" "$choice"
    done
}

# ============================================================================
# Build Menu
# ============================================================================

show_build_menu() {
    # Check if scenarios exist
    if [[ ! -d "${SCENARIOS_DIR}/build" ]]; then
        tui_msgbox "Not Available" "Build scenarios not found.\n\nExpected location:\n${SCENARIOS_DIR}/build/"
        return
    fi

    # Build menu from available scenarios
    local items=()
    for scenario in create-users setup-print-server setup-web-server setup-mail-server; do
        local script="${SCENARIOS_DIR}/build/${scenario}.sh"
        if [[ -f "$script" ]]; then
            local desc="${BUILD_SCENARIOS[$scenario]:-Unknown scenario}"
            local diff="${SCENARIO_DIFFICULTY[$scenario]:-?}"
            local time="${SCENARIO_TIME[$scenario]:-?}"
            items+=("$scenario" "[$diff] $desc (~$time)")
        fi
    done

    if [[ ${#items[@]} -eq 0 ]]; then
        tui_msgbox "No Scenarios" "No build scenarios available."
        return
    fi

    items+=("back" "Return to challenges menu")

    while true; do
        local choice
        choice=$(tui_menu "Build Scenarios" 14 65 "${items[@]}") || choice="back"

        if [[ "$choice" == "back" || -z "$choice" ]]; then
            return
        fi

        show_scenario_details "build" "$choice"
    done
}

# ============================================================================
# Scenario Details and Launch
# ============================================================================

show_scenario_details() {
    local type="$1"
    local scenario="$2"
    local script="${SCENARIOS_DIR}/${type}/${scenario}.sh"

    if [[ ! -f "$script" ]]; then
        tui_msgbox "Error" "Scenario script not found:\n$script"
        return
    fi

    # Get scenario info
    local desc=""
    local diff="${SCENARIO_DIFFICULTY[$scenario]:-Unknown}"
    local time="${SCENARIO_TIME[$scenario]:-Unknown}"

    if [[ "$type" == "break-fix" ]]; then
        desc="${BREAKFIX_SCENARIOS[$scenario]:-No description}"
    else
        desc="${BUILD_SCENARIOS[$scenario]:-No description}"
    fi

    # Build details text
    local details="SCENARIO: $scenario\n"
    details+="==================\n\n"
    details+="Type: ${type^}\n"
    details+="Difficulty: $diff\n"
    details+="Est. Time: $time\n\n"
    details+="Description:\n$desc\n\n"

    if [[ "$type" == "break-fix" ]]; then
        details+="OBJECTIVE:\n"
        details+="Diagnose and fix the intentionally broken system.\n"
        details+="The scenario will create a problem for you to solve.\n\n"
        details+="WARNING: This may modify system state!\n"
        details+="Consider using a VM or container.\n"
    else
        details+="OBJECTIVE:\n"
        details+="Build and configure the system from scratch.\n"
        details+="Follow best practices for production deployment.\n\n"
        details+="NOTE: Some scenarios require root access.\n"
    fi

    tui_textbox "${scenario^} Details" "$details" 20 65

    if tui_yesno "Launch Scenario" "Ready to start '$scenario'?\n\nType: $type\nDifficulty: $diff"; then
        launch_scenario "$type" "$scenario"
    fi
}

launch_scenario() {
    local type="$1"
    local scenario="$2"
    local script="${SCENARIOS_DIR}/${type}/${scenario}.sh"

    tui_infobox "Starting" "Launching $scenario scenario..."
    sleep 1

    tui_clear

    echo -e "${TUI_BOLD}${TUI_CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              LPIC-1 Challenge: ${scenario^}"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${TUI_NC}"
    echo

    # Check if script needs root
    if grep -q "EUID.*-ne 0" "$script" 2>/dev/null; then
        echo -e "${TUI_YELLOW}Note: This scenario may require root access.${TUI_NC}"
        echo
    fi

    # Run the scenario
    if [[ -x "$script" ]]; then
        bash "$script" || true
    else
        chmod +x "$script"
        bash "$script" || true
    fi

    echo
    echo -e "${TUI_CYAN}════════════════════════════════════════════════════════════${TUI_NC}"
    read -rp "Press Enter to return to menu..."
}

# ============================================================================
# Random Challenge
# ============================================================================

random_challenge() {
    # Collect all available scenarios
    local all_scenarios=()

    for script in "${SCENARIOS_DIR}"/break-fix/*.sh; do
        if [[ -f "$script" ]]; then
            local name
            name=$(basename "$script" .sh)
            all_scenarios+=("break-fix:$name")
        fi
    done

    for script in "${SCENARIOS_DIR}"/build/*.sh; do
        if [[ -f "$script" ]]; then
            local name
            name=$(basename "$script" .sh)
            all_scenarios+=("build:$name")
        fi
    done

    if [[ ${#all_scenarios[@]} -eq 0 ]]; then
        tui_msgbox "No Scenarios" "No challenge scenarios available."
        return
    fi

    # Pick random
    local random_pick="${all_scenarios[$((RANDOM % ${#all_scenarios[@]}))]}"
    local type="${random_pick%%:*}"
    local scenario="${random_pick##*:}"

    local diff="${SCENARIO_DIFFICULTY[$scenario]:-Unknown}"

    if tui_yesno "Random Challenge" "You got: $scenario\n\nType: ${type^}\nDifficulty: $diff\n\nAccept this challenge?"; then
        show_scenario_details "$type" "$scenario"
    fi
}

# ============================================================================
# Challenge Progress
# ============================================================================

show_challenge_progress() {
    local db_file="/opt/LPIC-1/data/progress.db"

    # For now, show a simple summary (could be enhanced with completion tracking)
    local text="Challenge Progress\n"
    text+="==================\n\n"

    text+="BREAK/FIX SCENARIOS:\n"
    for scenario in broken-permissions full-disk broken-services orphaned-packages broken-boot; do
        local script="${SCENARIOS_DIR}/break-fix/${scenario}.sh"
        if [[ -f "$script" ]]; then
            local diff="${SCENARIO_DIFFICULTY[$scenario]:-?}"
            text+="  [ ] $scenario ($diff)\n"
        fi
    done

    text+="\nBUILD SCENARIOS:\n"
    for scenario in create-users setup-print-server setup-web-server setup-mail-server; do
        local script="${SCENARIOS_DIR}/build/${scenario}.sh"
        if [[ -f "$script" ]]; then
            local diff="${SCENARIO_DIFFICULTY[$scenario]:-?}"
            text+="  [ ] $scenario ($diff)\n"
        fi
    done

    text+="\n"
    text+="Note: Challenge completion tracking coming soon.\n"
    text+="For now, manually track your progress.\n"

    tui_textbox "Challenge Progress" "$text" 22 55
}

# ============================================================================
# Entry Point (when run directly)
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "${TUI_DIR}/widgets.sh"
    show_challenges_menu
fi
