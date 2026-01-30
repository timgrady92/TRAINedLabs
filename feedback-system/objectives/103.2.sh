#!/bin/bash
# Objective 103.2: Process text streams using filters
# Weight: 2

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

echo "Checking Objective 103.2: Process text streams using filters"
echo "============================================================="
echo

# Create test directory
TESTDIR=$(mktemp -d)
trap 'rm -rf "$TESTDIR"' EXIT

# Check essential commands
echo "Essential Commands:"
check "cat available" "command -v cat"
check "cut available" "command -v cut"
check "head available" "command -v head"
check "tail available" "command -v tail"
check "less available" "command -v less"
check "sort available" "command -v sort"
check "uniq available" "command -v uniq"
check "wc available" "command -v wc"
check "nl available" "command -v nl"
check "tr available" "command -v tr"
check "sed available" "command -v sed"
echo

# Check additional text utilities
echo "Additional Utilities:"
check "paste available" "command -v paste"
check "split available" "command -v split"
check "od available" "command -v od"
echo

# Check checksum utilities
echo "Checksum Utilities:"
check "md5sum available" "command -v md5sum"
check "sha256sum available" "command -v sha256sum"
check "sha512sum available" "command -v sha512sum"
echo

# Check compression utilities
echo "Compression Utilities:"
check "zcat available" "command -v zcat"
check "bzcat available" "command -v bzcat"
check "xzcat available" "command -v xzcat"
echo

# Create test data
echo -e "banana\napple\ncherry\napple\ndate\nbanana" > "$TESTDIR/fruits.txt"
echo -e "one:two:three\nfour:five:six" > "$TESTDIR/fields.txt"

# Test cat
echo "Cat Functionality:"
check "cat displays file" "cat $TESTDIR/fruits.txt | grep -q 'apple'"
check "cat -n numbers lines" "cat -n $TESTDIR/fruits.txt | grep -qE '^ *1'"
echo

# Test head/tail
echo "Head/Tail Functionality:"
check "head shows first lines" "head -n 2 $TESTDIR/fruits.txt | wc -l | grep -q '2'"
check "tail shows last lines" "tail -n 2 $TESTDIR/fruits.txt | wc -l | grep -q '2'"
check "head with default (10)" "head $TESTDIR/fruits.txt"
echo

# Test cut
echo "Cut Functionality:"
check "cut -d: -f1 works" "echo 'a:b:c' | cut -d: -f1 | grep -q 'a'"
check "cut -d: -f2 works" "echo 'a:b:c' | cut -d: -f2 | grep -q 'b'"
check "cut -c works" "echo 'hello' | cut -c1-3 | grep -q 'hel'"
echo

# Test sort
echo "Sort Functionality:"
check "sort works" "sort $TESTDIR/fruits.txt | head -1 | grep -q 'apple'"
check "sort -r reverses" "sort -r $TESTDIR/fruits.txt | head -1 | grep -q 'date'"
check "sort -n numeric" "echo -e '10\n2\n1' | sort -n | head -1 | grep -q '1'"
check "sort -u unique" "sort -u $TESTDIR/fruits.txt | wc -l | grep -q '4'"
echo

# Test uniq
echo "Uniq Functionality:"
check "uniq removes adjacent dups" "sort $TESTDIR/fruits.txt | uniq | wc -l | grep -q '4'"
check "uniq -c counts" "sort $TESTDIR/fruits.txt | uniq -c | grep -q '2'"
check "uniq -d shows duplicates" "sort $TESTDIR/fruits.txt | uniq -d | head -1"
echo

# Test wc
echo "Wc Functionality:"
check "wc -l counts lines" "wc -l $TESTDIR/fruits.txt | grep -q '6'"
check "wc -w counts words" "echo 'one two three' | wc -w | grep -q '3'"
check "wc -c counts bytes" "echo -n 'hello' | wc -c | grep -q '5'"
echo

# Test tr
echo "Tr Functionality:"
check "tr translates chars" "echo 'hello' | tr 'a-z' 'A-Z' | grep -q 'HELLO'"
check "tr -d deletes chars" "echo 'hello' | tr -d 'l' | grep -q 'heo'"
check "tr -s squeezes" "echo 'helllo' | tr -s 'l' | grep -q 'helo'"
echo

# Test sed
echo "Sed Functionality:"
check "sed substitution" "echo 'hello' | sed 's/hello/world/' | grep -q 'world'"
check "sed global sub" "echo 'aaa' | sed 's/a/b/g' | grep -q 'bbb'"
check "sed delete line" "echo -e 'a\nb\nc' | sed '2d' | wc -l | grep -q '2'"
echo

# Test paste
echo "Paste Functionality:"
echo -e "1\n2\n3" > "$TESTDIR/col1.txt"
echo -e "a\nb\nc" > "$TESTDIR/col2.txt"
check "paste joins files" "paste $TESTDIR/col1.txt $TESTDIR/col2.txt | head -1 | grep -q '1.*a'"
echo

# Test nl
echo "Nl Functionality:"
check "nl numbers lines" "nl $TESTDIR/fruits.txt | head -1 | grep -qE '^ *1'"
echo

# Test checksums
echo "Checksum Functionality:"
echo "test" > "$TESTDIR/checksum.txt"
check "md5sum generates hash" "md5sum $TESTDIR/checksum.txt | grep -qE '^[a-f0-9]{32}'"
check "sha256sum generates hash" "sha256sum $TESTDIR/checksum.txt | grep -qE '^[a-f0-9]{64}'"
echo

# Summary
total=$((passed + failed))
echo "============================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 103.2 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
