#!/bin/bash
# Objective 103.4: Use streams, pipes and redirects
# Weight: 4

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

echo "Checking Objective 103.4: Use streams, pipes and redirects"
echo "==========================================================="
echo

# Create test directory
TESTDIR=$(mktemp -d)
trap 'rm -rf "$TESTDIR"' EXIT

# Check essential commands
echo "Essential Commands:"
check "tee available" "command -v tee"
check "xargs available" "command -v xargs"
check "cat available" "command -v cat"
check "sort available" "command -v sort"
check "uniq available" "command -v uniq"
check "wc available" "command -v wc"
check "head available" "command -v head"
check "tail available" "command -v tail"
echo

# Test stdout redirection
echo "Standard Output Redirection:"
echo "test output" > "$TESTDIR/stdout.txt"
check "Redirect stdout (>)" "test -f $TESTDIR/stdout.txt && grep -q 'test output' $TESTDIR/stdout.txt"

echo "appended" >> "$TESTDIR/stdout.txt"
check "Append stdout (>>)" "grep -q 'appended' $TESTDIR/stdout.txt"

check "Redirect to /dev/null" "echo 'silent' > /dev/null"
echo

# Test stdin redirection
echo "Standard Input Redirection:"
echo -e "line1\nline2\nline3" > "$TESTDIR/input.txt"
check "Redirect stdin (<)" "wc -l < $TESTDIR/input.txt | grep -q '3'"

check "Here document (<<)" "cat <<EOF
heredoc test
EOF"

check "Here string (<<<)" "cat <<< 'here string test'"
echo

# Test stderr redirection
echo "Standard Error Redirection:"
check "Redirect stderr (2>)" "ls /nonexistent 2> $TESTDIR/stderr.txt; test -f $TESTDIR/stderr.txt"
check "Redirect stderr to stdout (2>&1)" "ls /nonexistent 2>&1 | grep -qi 'no such\|cannot'"
check "Discard stderr (2>/dev/null)" "ls /nonexistent 2>/dev/null; true"
check "Redirect both (&>)" "ls /nonexistent &> $TESTDIR/both.txt; true"
echo

# Test pipes
echo "Pipe Operations:"
check "Basic pipe (|)" "echo 'hello world' | grep -q 'hello'"
check "Multiple pipes" "echo -e 'b\na\nc' | sort | head -1 | grep -q 'a'"
check "Pipe to wc" "echo -e 'one\ntwo\nthree' | wc -l | grep -q '3'"
check "Pipe to sort | uniq" "echo -e 'a\nb\na\nc\nb' | sort | uniq | wc -l | grep -q '3'"
echo

# Test tee
echo "Tee Command:"
echo "tee test" | tee "$TESTDIR/tee1.txt" > /dev/null
check "tee writes to file" "grep -q 'tee test' $TESTDIR/tee1.txt"

echo "tee append" | tee -a "$TESTDIR/tee1.txt" > /dev/null
check "tee -a appends" "wc -l < $TESTDIR/tee1.txt | grep -q '2'"

echo "multi tee" | tee "$TESTDIR/tee2.txt" "$TESTDIR/tee3.txt" > /dev/null
check "tee writes to multiple files" "test -f $TESTDIR/tee2.txt && test -f $TESTDIR/tee3.txt"
echo

# Test xargs
echo "Xargs Command:"
echo -e "file1\nfile2\nfile3" > "$TESTDIR/filelist.txt"
check "xargs basic" "cat $TESTDIR/filelist.txt | xargs echo | grep -q 'file1 file2 file3'"

echo -e "a\nb\nc" | xargs -I {} touch "$TESTDIR/{}.txt"
check "xargs -I placeholder" "test -f $TESTDIR/a.txt && test -f $TESTDIR/b.txt"

check "xargs with find" "find $TESTDIR -name '*.txt' -print0 | xargs -0 ls > /dev/null"
echo

# Test command substitution
echo "Command Substitution:"
check "Backtick substitution" "test \"\`echo hello\`\" = 'hello'"
check "\$() substitution" "test \"\$(echo world)\" = 'world'"
check "Nested substitution" "test \"\$(echo \$(echo nested))\" = 'nested'"
echo

# Test file descriptors
echo "File Descriptors:"
check "Read from fd 0 (stdin)" "echo 'test' | cat /dev/stdin | grep -q 'test'"
check "Write to fd 1 (stdout)" "echo 'stdout' >&1 | grep -q 'stdout'"
check "File descriptor duplication" "exec 3>&1; echo 'fd3' >&3 | grep -q 'fd3'; exec 3>&-"
echo

# Test process substitution
echo "Process Substitution:"
check "Process substitution <()" "diff <(echo 'a') <(echo 'a')"
check "Process substitution >()" "echo 'test' | tee >(cat > $TESTDIR/procsub.txt) > /dev/null; grep -q 'test' $TESTDIR/procsub.txt"
echo

# Summary
total=$((passed + failed))
echo "==========================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 103.4 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
