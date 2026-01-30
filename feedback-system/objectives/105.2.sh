#!/bin/bash
# Objective 105.2: Customize or write simple scripts
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

echo "Checking Objective 105.2: Customize or write simple scripts"
echo "============================================================"
echo

# Create test directory
TESTDIR=$(mktemp -d)
trap 'rm -rf "$TESTDIR"' EXIT

# Check essential commands
echo "Essential Commands:"
check "test available" "command -v test"
check "[ available" "command -v ["
check "read available" "type read"
check "seq available" "command -v seq"
check "exec available" "type exec"
check "sh available" "command -v sh"
check "bash available" "command -v bash"
echo

# Test conditional constructs
echo "Conditional Constructs:"
check "if/then/fi works" "if true; then true; fi"
check "if/else works" "if false; then false; else true; fi"
check "test command works" "test 1 -eq 1"
check "[ ] brackets work" "[ 1 -eq 1 ]"
check "[[ ]] brackets work" "[[ 1 -eq 1 ]]"
echo

# Test comparison operators
echo "Comparison Operators:"
check "Numeric equality (-eq)" "test 5 -eq 5"
check "Numeric inequality (-ne)" "test 5 -ne 6"
check "Greater than (-gt)" "test 6 -gt 5"
check "Less than (-lt)" "test 5 -lt 6"
check "String equality (=)" "test 'a' = 'a'"
check "String inequality (!=)" "test 'a' != 'b'"
check "String not empty (-n)" "test -n 'string'"
check "String empty (-z)" "test -z ''"
echo

# Test file test operators
echo "File Test Operators:"
touch "$TESTDIR/testfile"
mkdir "$TESTDIR/testdir"
check "File exists (-f)" "test -f $TESTDIR/testfile"
check "Directory exists (-d)" "test -d $TESTDIR/testdir"
check "File readable (-r)" "test -r $TESTDIR/testfile"
check "File writable (-w)" "test -w $TESTDIR/testfile"
check "File exists (-e)" "test -e $TESTDIR/testfile"
echo

# Test loops
echo "Loop Constructs:"
check "for loop works" "for i in 1 2 3; do echo \$i; done | wc -l | grep -q '3'"
check "while loop works" "i=0; while [ \$i -lt 3 ]; do ((i++)); done; test \$i -eq 3"
check "until loop works" "i=0; until [ \$i -ge 3 ]; do ((i++)); done; test \$i -eq 3"
check "seq generates sequence" "seq 1 5 | wc -l | grep -q '5'"
check "for with seq" "for i in \$(seq 1 3); do echo \$i; done | wc -l | grep -q '3'"
echo

# Test logical operators
echo "Logical Operators:"
check "&& (AND) works" "true && true"
check "|| (OR) works" "false || true"
check "! (NOT) works" "! false"
check "Combined && ||" "false && echo no || echo yes | grep -q 'yes'"
echo

# Test exit status
echo "Exit Status:"
check "\$? captures exit status" "true; test \$? -eq 0"
check "false returns non-zero" "false; test \$? -ne 0 || true"
check "exit status propagates" "(exit 5); test \$? -eq 5"
echo

# Test script creation and execution
echo "Script Execution:"
cat > "$TESTDIR/test_script.sh" << 'SCRIPT'
#!/bin/bash
echo "Script executed"
exit 0
SCRIPT
chmod +x "$TESTDIR/test_script.sh"
check "Shebang script works" "$TESTDIR/test_script.sh | grep -q 'Script executed'"
check "bash script.sh works" "bash $TESTDIR/test_script.sh | grep -q 'Script executed'"
check "sh script.sh works" "sh $TESTDIR/test_script.sh | grep -q 'Script executed'"
echo

# Test read command
echo "Read Command:"
check "read from pipe" "echo 'test' | { read var; test \"\$var\" = 'test'; }"
check "read with -r" "echo 'test\\nmore' | { read -r var; test -n \"\$var\"; }"
echo

# Test case statement
echo "Case Statement:"
cat > "$TESTDIR/case_test.sh" << 'SCRIPT'
#!/bin/bash
case "$1" in
    start) echo "starting";;
    stop) echo "stopping";;
    *) echo "unknown";;
esac
SCRIPT
chmod +x "$TESTDIR/case_test.sh"
check "case matches exactly" "$TESTDIR/case_test.sh start | grep -q 'starting'"
check "case default (*)" "$TESTDIR/case_test.sh other | grep -q 'unknown'"
echo

# Test command substitution
echo "Command Substitution:"
check "\$() substitution" "test \"\$(echo hello)\" = 'hello'"
check "Backtick substitution" "test \"\`echo world\`\" = 'world'"
check "Nested substitution" "test \"\$(echo \$(date +%Y))\" -ge 2020"
echo

# Test positional parameters
echo "Positional Parameters:"
cat > "$TESTDIR/params.sh" << 'SCRIPT'
#!/bin/bash
echo "First: $1, Second: $2, All: $@, Count: $#"
SCRIPT
chmod +x "$TESTDIR/params.sh"
check "\$1 \$2 work" "$TESTDIR/params.sh a b | grep -q 'First: a, Second: b'"
check "\$@ works" "$TESTDIR/params.sh a b c | grep -q 'All: a b c'"
check "\$# works" "$TESTDIR/params.sh a b c | grep -q 'Count: 3'"
echo

# Summary
total=$((passed + failed))
echo "============================================================"
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 105.2 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
