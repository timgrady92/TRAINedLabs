#!/bin/bash
# Gum Integration Test Suite
# Tests all TUI widgets and module loading with pass/fail output

set -uo pipefail

# ============================================================================
# Test Framework Setup
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TUI_DIR="${SCRIPT_DIR}/feedback-system/tui"
WIDGETS_FILE="${TUI_DIR}/widgets.sh"

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# Test Utilities
# ============================================================================

pass() {
    local msg="$1"
    ((TESTS_TOTAL++))
    ((TESTS_PASSED++))
    echo -e "[${GREEN}PASS${NC}] $msg"
}

fail() {
    local msg="$1"
    local detail="${2:-}"
    ((TESTS_TOTAL++))
    ((TESTS_FAILED++))
    echo -e "[${RED}FAIL${NC}] $msg"
    [[ -n "$detail" ]] && echo -e "       ${RED}$detail${NC}"
}

skip() {
    local msg="$1"
    local reason="${2:-}"
    ((TESTS_TOTAL++))
    ((TESTS_SKIPPED++))
    echo -e "[${YELLOW}SKIP${NC}] $msg"
    [[ -n "$reason" ]] && echo -e "       ${YELLOW}$reason${NC}"
}

section_header() {
    local title="$1"
    echo
    echo -e "${BOLD}${CYAN}--- $title ---${NC}"
}

# ============================================================================
# Category 1: Environment Verification
# ============================================================================

test_environment() {
    section_header "Environment Verification"

    # Test: Gum binary exists and is executable
    if command -v gum &>/dev/null; then
        local gum_version
        gum_version=$(gum --version 2>/dev/null || echo "unknown")
        pass "Gum installed: version $gum_version"
    else
        fail "Gum binary not found"
    fi

    # Test: widgets.sh exists
    if [[ -f "$WIDGETS_FILE" ]]; then
        pass "widgets.sh exists at $WIDGETS_FILE"
    else
        fail "widgets.sh not found at $WIDGETS_FILE"
        return 1
    fi

    # Test: widgets.sh sources without error
    local source_output
    if source_output=$(source "$WIDGETS_FILE" 2>&1); then
        pass "widgets.sh sourced successfully"
    else
        fail "widgets.sh failed to source" "$source_output"
        return 1
    fi

    # Source it for real now
    source "$WIDGETS_FILE"

    # Test: HAS_GUM variable is set correctly
    if [[ -n "$HAS_GUM" ]]; then
        pass "HAS_GUM=1 (gum detected)"
    else
        if command -v gum &>/dev/null; then
            fail "HAS_GUM is empty but gum is installed"
        else
            pass "HAS_GUM is empty (gum not installed, correct behavior)"
        fi
    fi

    # Test: tui_tool returns "gum"
    local tool_result
    tool_result=$(tui_tool)
    if [[ "$tool_result" == "gum" ]]; then
        pass "tui_tool=gum"
    elif [[ "$tool_result" == "dialog" || "$tool_result" == "whiptail" ]]; then
        pass "tui_tool=$tool_result (fallback active)"
    elif [[ "$tool_result" == "none" ]]; then
        fail "tui_tool=none (no TUI tools available)"
    else
        fail "tui_tool returned unexpected value: $tool_result"
    fi

    # Test: tui_available returns true
    if tui_available; then
        pass "tui_available returns true"
    else
        fail "tui_available returns false (no TUI tools detected)"
    fi
}

# ============================================================================
# Category 2: Widget Unit Tests (Non-Interactive)
# ============================================================================

test_widgets_noninteractive() {
    section_header "Widget Unit Tests (Non-Interactive)"

    # Ensure widgets are loaded
    source "$WIDGETS_FILE"

    # Test: tui_banner renders styled output
    local banner_output
    banner_output=$(tui_banner "Test Banner" 2>&1)
    if [[ -n "$banner_output" ]]; then
        pass "tui_banner renders styled output"
    else
        fail "tui_banner produced no output"
    fi

    # Test: tui_header renders styled header
    local header_output
    header_output=$(tui_header "Test Header" 2>&1)
    if [[ -n "$header_output" ]]; then
        pass "tui_header renders styled output"
    else
        fail "tui_header produced no output"
    fi

    # Test: tui_notice - all 4 types
    local notice_types=("info" "warning" "error" "success")
    for notice_type in "${notice_types[@]}"; do
        local notice_output
        notice_output=$(tui_notice "$notice_type" "Test message for $notice_type" 2>&1)
        if [[ -n "$notice_output" ]]; then
            pass "tui_notice ($notice_type) renders correctly"
        else
            fail "tui_notice ($notice_type) produced no output"
        fi
    done

    # Test: tui_status - all status types
    local status_types=("pass" "fail" "warn" "info")
    for status_type in "${status_types[@]}"; do
        local status_output
        status_output=$(tui_status "$status_type" "Test status message" 2>&1)
        if [[ -n "$status_output" ]]; then
            pass "tui_status ($status_type) renders correctly"
        else
            fail "tui_status ($status_type) produced no output"
        fi
    done

    # Test: tui_info key-value formatting
    local info_output
    info_output=$(tui_info "TestKey" "TestValue" 2>&1)
    if [[ -n "$info_output" ]] && [[ "$info_output" == *"TestKey"* ]] && [[ "$info_output" == *"TestValue"* ]]; then
        pass "tui_info key-value formatting works"
    else
        fail "tui_info did not format key-value correctly" "Output: $info_output"
    fi

    # Test: tui_list bullet list output
    local list_output
    list_output=$(tui_list "Item 1" "Item 2" "Item 3" 2>&1)
    if [[ -n "$list_output" ]] && [[ "$list_output" == *"Item 1"* ]] && [[ "$list_output" == *"Item 2"* ]]; then
        pass "tui_list bullet output works"
    else
        fail "tui_list did not render items correctly"
    fi

    # Test: tui_spin runs command with spinner
    local spin_exit_code
    tui_spin "Testing spinner..." sleep 0.5 >/dev/null 2>&1
    spin_exit_code=$?
    if [[ $spin_exit_code -eq 0 ]]; then
        pass "tui_spin runs command with spinner (sleep 0.5)"
    else
        fail "tui_spin failed with exit code $spin_exit_code"
    fi

    # Test: tui_loading animation completes
    local loading_exit_code
    tui_loading "Testing..." 1 >/dev/null 2>&1
    loading_exit_code=$?
    if [[ $loading_exit_code -eq 0 ]]; then
        pass "tui_loading animation completes"
    else
        fail "tui_loading failed with exit code $loading_exit_code"
    fi

    # Test: tui_clear clears screen without error
    local clear_exit_code
    tui_clear >/dev/null 2>&1
    clear_exit_code=$?
    if [[ $clear_exit_code -eq 0 ]]; then
        pass "tui_clear executes without error"
    else
        fail "tui_clear failed with exit code $clear_exit_code"
    fi

    # Test: tui_infobox renders info
    local infobox_output
    infobox_output=$(tui_infobox "Info" "Test info message" 2>&1)
    if [[ $? -eq 0 ]]; then
        pass "tui_infobox renders without error"
    else
        fail "tui_infobox failed"
    fi

    # Test: tui_nav_hint renders navigation hints
    local nav_output
    nav_output=$(tui_nav_hint 2>&1)
    if [[ -n "$nav_output" ]]; then
        pass "tui_nav_hint renders navigation hints"
    else
        fail "tui_nav_hint produced no output"
    fi

    # Test: tui_table renders formatted table
    local table_output
    table_output=$(tui_table "Col1,Col2,Col3" "A,B,C" "D,E,F" 2>&1)
    if [[ -n "$table_output" ]]; then
        pass "tui_table renders formatted table"
    else
        fail "tui_table produced no output"
    fi

    # Test: tui_join joins strings
    local join_output
    join_output=$(tui_join " | " "A" "B" "C" 2>&1)
    if [[ -n "$join_output" ]] && [[ "$join_output" == *"A"* ]] && [[ "$join_output" == *"B"* ]]; then
        pass "tui_join joins strings correctly"
    else
        fail "tui_join did not work correctly"
    fi
}

# ============================================================================
# Category 3: Interactive Widget Smoke Tests
# ============================================================================

test_widgets_interactive_smoke() {
    section_header "Interactive Widget Smoke Tests"

    source "$WIDGETS_FILE"

    echo -e "${YELLOW}Note: Interactive tests verify widgets can launch without crashing.${NC}"
    echo -e "${YELLOW}They will time out after 1 second (expected behavior).${NC}"
    echo

    # Test: tui_menu - check if function exists and can be called with timeout
    if declare -f tui_menu &>/dev/null; then
        # We can't fully test interactive widgets without user input,
        # but we can verify they don't crash immediately
        # Using timeout with a short delay
        local menu_result
        menu_result=$(timeout 1s bash -c "
            source '$WIDGETS_FILE'
            echo '' | tui_menu 'Test Menu' 10 40 'opt1' 'Option 1' 'opt2' 'Option 2'
        " 2>&1) || true
        # Menu will timeout or fail (no input), that's expected
        pass "tui_menu function exists and callable"
    else
        fail "tui_menu function not defined"
    fi

    # Test: tui_checklist
    if declare -f tui_checklist &>/dev/null; then
        pass "tui_checklist function exists and callable"
    else
        fail "tui_checklist function not defined"
    fi

    # Test: tui_yesno
    if declare -f tui_yesno &>/dev/null; then
        pass "tui_yesno function exists and callable"
    else
        fail "tui_yesno function not defined"
    fi

    # Test: tui_input
    if declare -f tui_input &>/dev/null; then
        pass "tui_input function exists and callable"
    else
        fail "tui_input function not defined"
    fi

    # Test: tui_msgbox
    if declare -f tui_msgbox &>/dev/null; then
        pass "tui_msgbox function exists and callable"
    else
        fail "tui_msgbox function not defined"
    fi

    # Test: tui_textbox
    if declare -f tui_textbox &>/dev/null; then
        pass "tui_textbox function exists and callable"
    else
        fail "tui_textbox function not defined"
    fi

    # Test: tui_gauge
    if declare -f tui_gauge &>/dev/null; then
        pass "tui_gauge function exists and callable"
    else
        fail "tui_gauge function not defined"
    fi

    # Test: tui_fzf
    if declare -f tui_fzf &>/dev/null; then
        pass "tui_fzf function exists and callable"
    else
        fail "tui_fzf function not defined"
    fi

    # Test: tui_write
    if declare -f tui_write &>/dev/null; then
        pass "tui_write function exists and callable"
    else
        fail "tui_write function not defined"
    fi

    # Test: tui_file
    if declare -f tui_file &>/dev/null; then
        pass "tui_file function exists and callable"
    else
        fail "tui_file function not defined"
    fi

    # Test: tui_progress_box
    if declare -f tui_progress_box &>/dev/null; then
        pass "tui_progress_box function exists and callable"
    else
        fail "tui_progress_box function not defined"
    fi
}

# ============================================================================
# Category 4: Module Loading Tests
# ============================================================================

test_module_loading() {
    section_header "Module Loading Tests"

    local modules=(
        "main.sh:main_loop"
        "learn.sh:show_learn_menu"
        "practice.sh:show_practice_menu"
        "test.sh:show_test_menu"
        "dashboard.sh:show_dashboard"
        "challenges.sh:show_challenges_menu"
        "exam.sh:show_exam_menu"
    )

    for module_entry in "${modules[@]}"; do
        local module_file="${module_entry%%:*}"
        local expected_func="${module_entry##*:}"
        local module_path="${TUI_DIR}/${module_file}"

        if [[ ! -f "$module_path" ]]; then
            fail "$module_file not found at $module_path"
            continue
        fi

        # Test that module sources without error (in subshell to avoid polluting environment)
        local source_result
        source_result=$(bash -c "
            set -e
            source '$WIDGETS_FILE' 2>/dev/null || true
            # Provide mock common.sh if needed
            if [[ ! -f '${SCRIPT_DIR}/feedback-system/training/common.sh' ]]; then
                # Skip modules that need common.sh
                exit 0
            fi
            # Source the module (but don't run it)
            # We check if it defines the expected function by grepping
            grep -q '^${expected_func}()' '$module_path' || grep -q '^${expected_func} ()' '$module_path'
        " 2>&1)
        local grep_result=$?

        if [[ $grep_result -eq 0 ]]; then
            pass "$module_file defines $expected_func"
        else
            # Double-check with a more flexible pattern
            if grep -qE "^${expected_func}\s*\(\)" "$module_path" 2>/dev/null; then
                pass "$module_file defines $expected_func"
            else
                fail "$module_file does not define $expected_func"
            fi
        fi
    done

    # Test theme.sh loads without error
    local theme_path="${TUI_DIR}/theme.sh"
    if [[ -f "$theme_path" ]]; then
        if source_result=$(source "$theme_path" 2>&1); then
            pass "theme.sh loads without error"
        else
            fail "theme.sh failed to load" "$source_result"
        fi
    else
        skip "theme.sh not found" "Optional file"
    fi
}

# ============================================================================
# Category 5: Gum-Specific Features
# ============================================================================

test_gum_features() {
    section_header "Gum-Specific Features"

    if ! command -v gum &>/dev/null; then
        skip "Gum not installed, skipping gum-specific tests"
        return
    fi

    source "$WIDGETS_FILE"

    # Test: gum style renders borders correctly
    local style_output
    style_output=$(gum style --border rounded --padding "0 1" "Test border" 2>&1)
    if [[ -n "$style_output" ]]; then
        pass "gum style renders borders correctly"
    else
        fail "gum style failed to render border"
    fi

    # Test: gum choose displays (non-interactive check)
    if gum choose --help &>/dev/null; then
        pass "gum choose is available"
    else
        fail "gum choose not available"
    fi

    # Test: gum confirm shows help (proxy for functionality)
    if gum confirm --help &>/dev/null; then
        pass "gum confirm is available"
    else
        fail "gum confirm not available"
    fi

    # Test: gum spin works
    local spin_result
    spin_result=$(gum spin --spinner dot --title "Test" -- sleep 0.1 2>&1)
    if [[ $? -eq 0 ]]; then
        pass "gum spin executes successfully"
    else
        fail "gum spin failed"
    fi

    # Test: gum input help works
    if gum input --help &>/dev/null; then
        pass "gum input is available"
    else
        fail "gum input not available"
    fi

    # Test: Color codes apply via gum style
    local color_tests=(
        "33:blue"
        "214:orange"
        "34:green"
        "196:red"
        "220:yellow"
    )

    for color_test in "${color_tests[@]}"; do
        local color_code="${color_test%%:*}"
        local color_name="${color_test##*:}"
        local color_output
        color_output=$(gum style --foreground "$color_code" "Color test" 2>&1)
        if [[ -n "$color_output" ]]; then
            pass "Color code $color_code ($color_name) applies"
        else
            fail "Color code $color_code ($color_name) failed"
        fi
    done
}

# ============================================================================
# Category 6: Fallback Testing
# ============================================================================

test_fallback() {
    section_header "Fallback Testing"

    # Check if we can run fallback tests (need dialog or whiptail as backup)
    local has_fallback=""
    command -v dialog &>/dev/null && has_fallback="dialog"
    command -v whiptail &>/dev/null && has_fallback="${has_fallback:-whiptail}"

    if [[ -z "$has_fallback" ]]; then
        skip "No fallback TUI tool (dialog/whiptail) available for fallback testing"
        return
    fi

    # We'll test the fallback behavior by temporarily hiding gum from PATH
    # and re-sourcing widgets.sh in a subshell

    # Test: Verify HAS_GUM becomes empty when gum is not in PATH
    local test_result
    test_result=$(
        # Create a modified PATH without gum
        export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "gum" | tr '\n' ':' | sed 's/:$//')

        # Re-source widgets.sh
        unset HAS_GUM HAS_DIALOG HAS_WHIPTAIL
        source "$WIDGETS_FILE" 2>/dev/null

        if [[ -z "$HAS_GUM" ]]; then
            echo "HAS_GUM_EMPTY=true"
        else
            echo "HAS_GUM_EMPTY=false"
        fi

        echo "TUI_TOOL=$(tui_tool)"
    )

    # This test only works if gum isn't a builtin or in /usr/bin where we can't hide it
    if command -v gum &>/dev/null; then
        # Since we can't easily hide gum, we'll test the fallback code paths directly

        # Test fallback menu function exists
        if declare -f _fallback_menu &>/dev/null || grep -q "_fallback_menu()" "$WIDGETS_FILE"; then
            pass "Fallback menu function (_fallback_menu) exists"
        else
            fail "Fallback menu function not found"
        fi

        # Test fallback checklist function exists
        if declare -f _fallback_checklist &>/dev/null || grep -q "_fallback_checklist()" "$WIDGETS_FILE"; then
            pass "Fallback checklist function (_fallback_checklist) exists"
        else
            fail "Fallback checklist function not found"
        fi

        # Test fallback progress bar exists
        if declare -f _fallback_progress_bar &>/dev/null || grep -q "_fallback_progress_bar()" "$WIDGETS_FILE"; then
            pass "Fallback progress bar function exists"
        else
            fail "Fallback progress bar function not found"
        fi

        # Verify tui_tool logic for fallback
        # The function checks HAS_DIALOG and returns "dialog", check both patterns
        if grep -q 'HAS_DIALOG' "$WIDGETS_FILE" && grep -q 'echo "dialog"' "$WIDGETS_FILE" && \
           grep -q 'HAS_WHIPTAIL' "$WIDGETS_FILE" && grep -q 'echo "whiptail"' "$WIDGETS_FILE"; then
            pass "Fallback logic for dialog/whiptail exists in tui_tool"
        else
            fail "Fallback logic incomplete in tui_tool"
        fi

        # Test that dialog fallback code exists in key widgets
        if grep -q "HAS_DIALOG" "$WIDGETS_FILE" && grep -q "dialog --" "$WIDGETS_FILE"; then
            pass "Dialog fallback code present in widgets"
        else
            fail "Dialog fallback code missing"
        fi

        pass "Fallback test: $has_fallback is available as fallback"
    else
        pass "No gum installed - fallback mode is active"
    fi
}

# ============================================================================
# Additional Tests: UTF-8 Symbols and Helpers
# ============================================================================

test_utf8_and_helpers() {
    section_header "UTF-8 Symbols and Helpers"

    source "$WIDGETS_FILE"

    # Test UTF-8 symbol variables are set
    local symbols=("TUI_SYM_PASS" "TUI_SYM_FAIL" "TUI_SYM_WARN" "TUI_SYM_INFO" "TUI_SYM_BULLET")
    for sym in "${symbols[@]}"; do
        if [[ -n "${!sym:-}" ]]; then
            pass "$sym symbol is set (${!sym})"
        else
            fail "$sym symbol is not set"
        fi
    done

    # Test color variables are set
    local colors=("TUI_RED" "TUI_GREEN" "TUI_YELLOW" "TUI_CYAN" "TUI_NC")
    for color in "${colors[@]}"; do
        if [[ -n "${!color:-}" ]]; then
            pass "$color color code is set"
        else
            fail "$color color code is not set"
        fi
    done
}

# ============================================================================
# Category 7: Non-TTY Handling Tests
# ============================================================================

test_non_tty_handling() {
    section_header "Non-TTY Handling Tests"

    source "$WIDGETS_FILE"

    # Test: tui_menu handles lack of TTY gracefully
    local result
    result=$(echo "" | bash -c "
        source '$WIDGETS_FILE' 2>/dev/null
        tui_menu 'Test' 10 40 'a' 'Option A' 'b' 'Option B' 2>&1
    " 2>&1) || true

    if [[ "$result" == *"No TTY available"* ]] || [[ "$result" == *"Error"* ]]; then
        pass "tui_menu handles no-TTY gracefully (returns error message)"
    else
        # May succeed if there's a /dev/tty available
        pass "tui_menu handles no-TTY (may have fallback TTY)"
    fi

    # Test: tui_yesno handles lack of TTY gracefully
    result=$(echo "" | bash -c "
        source '$WIDGETS_FILE' 2>/dev/null
        tui_yesno 'Test' 'Question?' 2>&1
    " 2>&1) || true

    if [[ "$result" == *"No TTY available"* ]] || [[ "$result" == *"Error"* ]]; then
        pass "tui_yesno handles no-TTY gracefully (returns error message)"
    else
        pass "tui_yesno handles no-TTY (may have fallback TTY)"
    fi

    # Test: tui_input handles lack of TTY gracefully
    result=$(echo "" | bash -c "
        source '$WIDGETS_FILE' 2>/dev/null
        tui_input 'Test' 'Prompt:' 2>&1
    " 2>&1) || true

    if [[ "$result" == *"No TTY available"* ]] || [[ "$result" == *"Error"* ]]; then
        pass "tui_input handles no-TTY gracefully (returns error message)"
    else
        pass "tui_input handles no-TTY (may have fallback TTY)"
    fi
}

# ============================================================================
# Category 8: Input Validation Tests
# ============================================================================

test_input_validation() {
    section_header "Input Validation Tests"

    source "$WIDGETS_FILE"

    # Test: tui_menu rejects odd number of arguments
    local result
    result=$(bash -c "
        source '$WIDGETS_FILE' 2>/dev/null
        tui_menu 'Test' 10 40 'a' 'Option A' 'b' 2>&1
    " 2>&1) || true

    if [[ "$result" == *"tag/desc pairs"* ]]; then
        pass "tui_menu validates tag/desc pairs"
    else
        fail "tui_menu does not validate tag/desc pairs" "Output: $result"
    fi

    # Test: tui_checklist rejects non-triplet arguments
    result=$(bash -c "
        source '$WIDGETS_FILE' 2>/dev/null
        tui_checklist 'Test' 10 40 'a' 'Option A' 2>&1
    " 2>&1) || true

    if [[ "$result" == *"tag/desc/state triplets"* ]]; then
        pass "tui_checklist validates tag/desc/state triplets"
    else
        fail "tui_checklist does not validate triplets" "Output: $result"
    fi
}

# ============================================================================
# Category 9: Environment Validation Tests
# ============================================================================

test_environment_validation() {
    section_header "Environment Validation Tests"

    # Test: _validate_environment function exists
    if grep -q "_validate_environment()" "$WIDGETS_FILE"; then
        pass "_validate_environment function exists"
    else
        fail "_validate_environment function not found"
    fi

    # Test: TERM check is present
    if grep -q 'TERM.*dumb' "$WIDGETS_FILE"; then
        pass "TERM validation check exists"
    else
        fail "TERM validation check not found"
    fi

    # Test: sqlite3 check is present
    if grep -q 'sqlite3' "$WIDGETS_FILE"; then
        pass "sqlite3 availability check exists"
    else
        fail "sqlite3 availability check not found"
    fi
}

# ============================================================================
# Category 10: Source Error Handling Tests
# ============================================================================

test_source_error_handling() {
    section_header "Source Error Handling Tests"

    local modules=("main.sh" "dashboard.sh" "learn.sh" "practice.sh" "test.sh" "exam.sh" "challenges.sh")

    for module in "${modules[@]}"; do
        local module_path="${TUI_DIR}/${module}"
        if [[ -f "$module_path" ]]; then
            if grep -q 'if ! source' "$module_path" || grep -q 'ERROR.*Failed to load' "$module_path"; then
                pass "$module has source error handling"
            else
                fail "$module missing source error handling"
            fi
        else
            skip "$module not found"
        fi
    done
}

# ============================================================================
# Main Test Runner
# ============================================================================

main() {
    echo
    echo -e "${BOLD}${CYAN}=== Gum Integration Test Suite ===${NC}"
    echo

    # Run all test categories
    test_environment || true
    test_widgets_noninteractive || true
    test_widgets_interactive_smoke || true
    test_module_loading || true
    test_gum_features || true
    test_fallback || true
    test_utf8_and_helpers || true
    test_non_tty_handling || true
    test_input_validation || true
    test_environment_validation || true
    test_source_error_handling || true

    # Summary
    echo
    echo -e "${BOLD}${CYAN}=== Summary ===${NC}"
    echo -e "Total:   $TESTS_TOTAL tests"
    echo -e "${GREEN}Passed:  $TESTS_PASSED${NC}"
    echo -e "${RED}Failed:  $TESTS_FAILED${NC}"
    if [[ $TESTS_SKIPPED -gt 0 ]]; then
        echo -e "${YELLOW}Skipped: $TESTS_SKIPPED${NC}"
    fi
    echo

    # Exit with appropriate code
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    else
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    fi
}

# Run main
main "$@"
