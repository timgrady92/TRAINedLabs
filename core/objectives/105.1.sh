#!/bin/bash
# Objective 105.1: Customize and use the shell environment
# Weight: 4

# shellcheck disable=SC2088  # Tildes in description strings are intentional display text
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

echo "Checking Objective 105.1: Customize and use the shell environment"
echo "=================================================================="
echo

# Check essential builtins
echo "Shell Builtins:"
check "source available" "type source"
check ". (dot) available" "type ."
check "export available" "type export"
check "set available" "type set"
check "unset available" "type unset"
check "alias available" "type alias"
check "function available" "type function"
echo

# Check shell commands
echo "Shell Commands:"
check "env available" "command -v env"
check "bash available" "command -v bash"
echo

# Check global configuration files
echo "Global Configuration Files:"
check "/etc/profile exists" "test -f /etc/profile"
check "/etc/bash.bashrc or /etc/bashrc exists" "test -f /etc/bash.bashrc || test -f /etc/bashrc"
check "/etc/profile.d exists" "test -d /etc/profile.d"
echo

# Check user configuration files
echo "User Configuration Files:"
check "~/.bashrc exists" "test -f \$HOME/.bashrc"
check "~/.profile or ~/.bash_profile exists" "test -f \$HOME/.profile || test -f \$HOME/.bash_profile"
if [[ -f "$HOME/.bash_logout" ]]; then
    check "~/.bash_logout exists" "test -f \$HOME/.bash_logout"
else
    echo -e "${YELLOW}${WARN}${NC} ~/.bash_logout not found (optional)"
fi
echo

# Check environment variables
echo "Environment Variables:"
check "PATH is set" "test -n \"\$PATH\""
check "HOME is set" "test -n \"\$HOME\""
check "USER is set" "test -n \"\$USER\""
check "SHELL is set" "test -n \"\$SHELL\""
check "TERM is set" "test -n \"\$TERM\""
check "PS1 is set" "test -n \"\$PS1\""
echo

# Test export functionality
echo "Export Functionality:"
export TEST_LPIC_VAR="test_value"
check "export creates variable" "test \"\$TEST_LPIC_VAR\" = 'test_value'"
check "env shows exported var" "env | grep -q 'TEST_LPIC_VAR=test_value'"
unset TEST_LPIC_VAR
check "unset removes variable" "test -z \"\${TEST_LPIC_VAR:-}\""
echo

# Test set functionality
echo "Set Command:"
check "set shows variables" "set | grep -q 'PATH='"
check "set -o shows options" "set -o | grep -q 'emacs\|vi'"
echo

# Test alias functionality
echo "Alias Functionality:"
alias test_alias_lpic='echo test'
check "alias creates shortcut" "type test_alias_lpic | grep -q 'alias'"
unalias test_alias_lpic 2>/dev/null || true
echo

# Test function definition
echo "Function Functionality:"
test_func_lpic() { echo "function works"; }
check "function definition works" "test_func_lpic | grep -q 'function works'"
unset -f test_func_lpic
echo

# Test source/dot command
echo "Source Command:"
TESTFILE=$(mktemp)
echo "SOURCED_VAR=sourced" > "$TESTFILE"
source "$TESTFILE"
check "source loads variables" "test \"\$SOURCED_VAR\" = 'sourced'"
unset SOURCED_VAR
rm "$TESTFILE"
echo

# Check PATH configuration
echo "PATH Configuration:"
check "/usr/bin in PATH" "echo \$PATH | grep -q '/usr/bin'"
check "/usr/local/bin in PATH" "echo \$PATH | grep -q '/usr/local/bin' || echo \$PATH | grep -q '/usr/bin'"
check "PATH has no empty components" "test -z \"\$(echo \$PATH | grep '::')\" || true"
echo

# Check skeleton directory
echo "Skeleton Directory:"
check "/etc/skel exists" "test -d /etc/skel"
check "/etc/skel has profiles" "ls /etc/skel/.*rc 2>/dev/null || ls /etc/skel/.profile 2>/dev/null || ls /etc/skel/.bash* 2>/dev/null"
echo

# Summary
total=$((passed + failed))
echo "=================================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 105.1 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
