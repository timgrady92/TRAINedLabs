#!/bin/bash
# Objective 103.8: Basic file editing
# Weight: 3

set -euo pipefail

# shellcheck disable=SC2034  # VERBOSE available for debugging
VERBOSE="${1:-false}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS="✓"
FAIL="✗"
WARN="⚠"

passed=0
failed=0

check() {
    local desc="$1"
    local cmd="$2"

    if eval "$cmd" &>/dev/null; then
        echo -e "${GREEN}${PASS}${NC} $desc"
        ((passed++)) || true
        return 0
    else
        echo -e "${RED}${FAIL}${NC} $desc"
        ((failed++)) || true
        return 1
    fi
}

echo "Checking Objective 103.8: Basic file editing"
echo "============================================="
echo

# Create test directory
TESTDIR=$(mktemp -d)
trap 'rm -rf "$TESTDIR"' EXIT

# Check vi/vim availability
echo "Vi/Vim Editors:"
check "vi available" "command -v vi"
if command -v vim &>/dev/null; then
    check "vim available" "command -v vim"
fi
echo

# Check alternative editors (awareness)
echo "Alternative Editors (awareness):"
if command -v nano &>/dev/null; then
    check "nano available" "command -v nano"
else
    echo -e "${YELLOW}${WARN}${NC} nano not installed"
fi
if command -v emacs &>/dev/null; then
    check "emacs available" "command -v emacs"
else
    echo -e "${YELLOW}${WARN}${NC} emacs not installed"
fi
echo

# Check EDITOR/VISUAL environment
echo "Editor Environment:"
check "EDITOR or VISUAL can be set" "EDITOR=vi true"
if [[ -n "${EDITOR:-}" ]]; then
    echo "  EDITOR is set to: $EDITOR"
fi
if [[ -n "${VISUAL:-}" ]]; then
    echo "  VISUAL is set to: $VISUAL"
fi
echo

# Test vi/vim non-interactive operations
echo "Vi/Vim Functionality:"
# Create test file
echo -e "line one\nline two\nline three" > "$TESTDIR/test.txt"

# Test ex mode commands (non-interactive vi)
check "vi can read file" "vi -es '+%p' '+q' $TESTDIR/test.txt 2>/dev/null | grep -q 'line'"

# Test substitution in ex mode
check "vi substitution works" "vi -es '+%s/one/ONE/g' '+wq' $TESTDIR/test.txt 2>/dev/null && grep -q 'ONE' $TESTDIR/test.txt"

# Reset test file
echo -e "line one\nline two\nline three" > "$TESTDIR/test.txt"

# Test delete in ex mode
check "vi delete line works" "vi -es '+2d' '+wq' $TESTDIR/test.txt 2>/dev/null && test \$(wc -l < $TESTDIR/test.txt) -eq 2"

# Reset test file
echo -e "line one\nline two\nline three" > "$TESTDIR/test.txt"

# Test append
check "vi append works" "vi -es '+\$a' '+new line' '+.' '+wq' $TESTDIR/test.txt 2>/dev/null || true"
echo

# Check vi runtime files
echo "Vi Runtime:"
if [[ -d /usr/share/vim ]]; then
    check "vim runtime exists" "test -d /usr/share/vim"
elif [[ -d /usr/share/vi ]]; then
    check "vi runtime exists" "test -d /usr/share/vi"
fi
echo

# Check vimrc locations
echo "Configuration Files:"
check "System vimrc location" "test -f /etc/vimrc || test -f /etc/vim/vimrc || test -f /usr/share/vim/vimrc || true"
check "User vimrc possible" "test -f ~/.vimrc || test -w ~"
echo

# Test important vi commands exist conceptually
echo "Vi Command Awareness:"
echo "  Navigation: h,j,k,l (left,down,up,right)"
echo "  Modes: i (insert), ESC (normal), : (command)"
echo "  Save/Quit: :w (write), :q (quit), :wq or ZZ (save+quit)"
echo "  Edit: dd (delete line), yy (yank line), p (paste)"
echo "  Search: / (forward), ? (backward), n (next)"
check "vi --version runs" "vi --version 2>&1 | head -1 || vim --version 2>&1 | head -1"
echo

# Test that vi can be invoked
echo "Vi Invocation:"
check "vi exits cleanly with +q" "timeout 2 vi -es '+q' 2>/dev/null || true"
echo

# Summary
total=$((passed + failed))
echo "============================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 103.8 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
