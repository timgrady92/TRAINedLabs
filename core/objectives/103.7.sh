#!/bin/bash
# Objective 103.7: Search text files using regular expressions
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

echo "Checking Objective 103.7: Search text files using regular expressions"
echo "======================================================================"
echo

# Create test directory
TESTDIR=$(mktemp -d)
trap 'rm -rf "$TESTDIR"' EXIT

# Create test files
cat > "$TESTDIR/test.txt" << 'EOF'
Hello World
hello world
HELLO WORLD
test123
123test
test 123 test
line with special chars: $100 & *stars*
email@example.com
192.168.1.1
2024-01-15
EOF

# Check essential commands
echo "Essential Commands:"
check "grep available" "command -v grep"
check "egrep available" "command -v egrep || grep -E --version"
check "fgrep available" "command -v fgrep || grep -F --version"
check "sed available" "command -v sed"
echo

# Test basic grep
echo "Basic Grep:"
check "grep finds pattern" "grep 'hello' $TESTDIR/test.txt"
check "grep -i case insensitive" "grep -i 'hello' $TESTDIR/test.txt | wc -l | grep -q '3'"
check "grep -v inverts match" "grep -v 'hello' $TESTDIR/test.txt | head -1"
check "grep -n shows line numbers" "grep -n 'hello' $TESTDIR/test.txt | grep -q ':'"
check "grep -c counts matches" "grep -c 'test' $TESTDIR/test.txt"
check "grep -l lists files" "grep -l 'hello' $TESTDIR/test.txt"
echo

# Test BRE (Basic Regular Expressions)
echo "Basic Regular Expressions (BRE):"
check "^ anchors start" "grep '^Hello' $TESTDIR/test.txt"
check "\$ anchors end" "grep 'World\$' $TESTDIR/test.txt"
check ". matches any char" "grep 'h.llo' $TESTDIR/test.txt"
check "* matches zero or more" "grep 'hel*o' $TESTDIR/test.txt"
check "[...] character class" "grep '[Hh]ello' $TESTDIR/test.txt"
check "[^...] negated class" "grep '[^0-9]test' $TESTDIR/test.txt"
echo

# Test ERE (Extended Regular Expressions)
echo "Extended Regular Expressions (ERE):"
check "+ matches one or more" "grep -E 'l+' $TESTDIR/test.txt | head -1"
check "? matches zero or one" "grep -E 'tests?' $TESTDIR/test.txt | head -1"
check "| alternation" "grep -E 'hello|HELLO' $TESTDIR/test.txt"
check "{n} exact count" "grep -E 'l{2}' $TESTDIR/test.txt"
check "{n,m} range count" "grep -E '[0-9]{3}' $TESTDIR/test.txt"
check "(...) grouping" "grep -E '(test)+' $TESTDIR/test.txt"
echo

# Test character classes
echo "Character Classes:"
check "[0-9] digit range" "grep '[0-9]' $TESTDIR/test.txt | head -1"
check "[a-z] lowercase range" "grep '[a-z]' $TESTDIR/test.txt | head -1"
check "[A-Z] uppercase range" "grep '[A-Z]' $TESTDIR/test.txt | head -1"
check "[[:digit:]] POSIX digit" "grep '[[:digit:]]' $TESTDIR/test.txt | head -1"
check "[[:alpha:]] POSIX alpha" "grep '[[:alpha:]]' $TESTDIR/test.txt | head -1"
check "[[:space:]] POSIX space" "grep '[[:space:]]' $TESTDIR/test.txt | head -1"
echo

# Test word boundaries
echo "Word Boundaries:"
check "\\b word boundary" "grep -E '\\btest\\b' $TESTDIR/test.txt | head -1"
check "\\< word start" "grep '\\<test' $TESTDIR/test.txt | head -1"
check "\\> word end" "grep 'test\\>' $TESTDIR/test.txt | head -1"
check "grep -w whole word" "grep -w 'test' $TESTDIR/test.txt | head -1"
echo

# Test sed with regex
echo "Sed with Regular Expressions:"
check "sed s/pattern/replace/" "echo 'hello' | sed 's/hello/world/' | grep -q 'world'"
check "sed with BRE groups" "echo 'hello' | sed 's/\\(hel\\)lo/\\1p/' | grep -q 'help'"
check "sed with ERE -E" "echo 'hello' | sed -E 's/(hel)lo/\\1p/' | grep -q 'help'"
check "sed delete matching lines" "sed '/test/d' $TESTDIR/test.txt | grep -v 'test' | head -1"
echo

# Test practical patterns
echo "Practical Patterns:"
check "Match email-like" "grep -E '[a-zA-Z0-9]+@[a-zA-Z0-9]+\\.[a-zA-Z]+' $TESTDIR/test.txt"
check "Match IP-like" "grep -E '[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+' $TESTDIR/test.txt"
check "Match date-like" "grep -E '[0-9]{4}-[0-9]{2}-[0-9]{2}' $TESTDIR/test.txt"
echo

# Test grep -E vs egrep
echo "Egrep Compatibility:"
check "grep -E equals egrep" "grep -E 'hello|world' $TESTDIR/test.txt"
check "grep -F equals fgrep" "grep -F 'hello' $TESTDIR/test.txt"
echo

# Summary
total=$((passed + failed))
echo "======================================================================"
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 103.7 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
