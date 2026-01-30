#!/bin/bash
# Objective 103.1: Work on the command line
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

echo "Checking Objective 103.1: Work on the command line"
echo "==================================================="
echo

# Check shells
echo "Shell Environment:"
check "bash available" "command -v bash"
check "sh available" "command -v sh"
check "SHELL variable set" "test -n \"\$SHELL\""
check "PATH variable set" "test -n \"\$PATH\""
check "HOME variable set" "test -n \"\$HOME\""
check "USER variable set" "test -n \"\$USER\""
echo

# Check essential commands
echo "Essential Commands:"
check "echo available" "command -v echo"
check "env available" "command -v env"
check "export available" "type export"
check "pwd available" "command -v pwd"
check "set available" "type set"
check "unset available" "type unset"
check "type available" "type type"
check "which available" "command -v which"
check "man available" "command -v man"
check "uname available" "command -v uname"
check "history available" "type history"
echo

# Check history functionality
echo "History Functionality:"
check "HISTFILE variable set" "test -n \"\${HISTFILE:-}\""
check "History file exists" "test -f \"\${HISTFILE:-\$HOME/.bash_history}\""
check "HISTSIZE variable set" "test -n \"\${HISTSIZE:-}\""
echo

# Check command execution
echo "Command Execution:"
check "Command substitution works" "test \"\$(echo test)\" = 'test'"
check "Quoting works correctly" "test \"\$'single'\" = 'single'"
check "Piping works" "echo test | cat | grep test"
check "Exit status captured" "true && test \$? -eq 0"
echo

# Check profile files
echo "Profile Configuration:"
check "/etc/profile exists" "test -f /etc/profile"
check "~/.bashrc exists" "test -f \$HOME/.bashrc"
check "~/.profile or ~/.bash_profile exists" "test -f \$HOME/.profile || test -f \$HOME/.bash_profile"
echo

# Check path functionality
echo "PATH Functionality:"
check "Commands found via PATH" "which ls"
check "/usr/bin in PATH" "echo \$PATH | grep -q '/usr/bin'"
check "/bin in PATH or is symlink" "echo \$PATH | grep -q '/bin' || test -L /bin"
echo

# Summary
total=$((passed + failed))
echo "==================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 103.1 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
