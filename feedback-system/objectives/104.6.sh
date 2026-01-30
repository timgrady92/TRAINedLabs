#!/bin/bash
# Objective 104.6: Create and change hard and symbolic links
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

echo "Checking Objective 104.6: Create and change hard and symbolic links"
echo "===================================================================="
echo

# Create test directory
TESTDIR=$(mktemp -d)
trap 'rm -rf "$TESTDIR"' EXIT

# Check essential commands
echo "Essential Commands:"
check "ln available" "command -v ln"
check "ls available" "command -v ls"
check "stat available" "command -v stat"
check "readlink available" "command -v readlink"
echo

# Create test file
echo "test content" > "$TESTDIR/original.txt"

# Test symbolic link creation
echo "Symbolic Links:"
ln -s "$TESTDIR/original.txt" "$TESTDIR/symlink.txt"
check "ln -s creates symlink" "test -L $TESTDIR/symlink.txt"
check "symlink points to target" "readlink $TESTDIR/symlink.txt | grep -q 'original.txt'"
check "symlink content matches" "cat $TESTDIR/symlink.txt | grep -q 'test content'"
check "ls -l shows symlink" "ls -l $TESTDIR/symlink.txt | grep -q '^l'"
echo

# Test hard link creation
echo "Hard Links:"
ln "$TESTDIR/original.txt" "$TESTDIR/hardlink.txt"
check "ln creates hard link" "test -f $TESTDIR/hardlink.txt"
check "hard link has same inode" "test \$(stat -c %i $TESTDIR/original.txt) -eq \$(stat -c %i $TESTDIR/hardlink.txt)"
check "hard link count is 2" "test \$(stat -c %h $TESTDIR/original.txt) -eq 2"
check "hard link content matches" "cat $TESTDIR/hardlink.txt | grep -q 'test content'"
echo

# Test link behavior with deletion
echo "Link Behavior:"
rm "$TESTDIR/original.txt"
check "hard link survives deletion" "cat $TESTDIR/hardlink.txt | grep -q 'test content'"
check "symlink is broken" "! cat $TESTDIR/symlink.txt 2>/dev/null"
check "ls shows broken symlink" "ls -l $TESTDIR/symlink.txt 2>/dev/null | head -1"
echo

# Recreate for more tests
echo "new content" > "$TESTDIR/original.txt"

# Test relative vs absolute symlinks
echo "Relative vs Absolute Symlinks:"
ln -s original.txt "$TESTDIR/relative_symlink.txt"
check "relative symlink works" "cat $TESTDIR/relative_symlink.txt | grep -q 'new content'"

ln -s "$TESTDIR/original.txt" "$TESTDIR/absolute_symlink.txt"
check "absolute symlink works" "cat $TESTDIR/absolute_symlink.txt | grep -q 'new content'"
echo

# Test directory symlinks
echo "Directory Symlinks:"
mkdir "$TESTDIR/subdir"
echo "subdir file" > "$TESTDIR/subdir/file.txt"
ln -s "$TESTDIR/subdir" "$TESTDIR/dirlink"
check "symlink to directory" "test -L $TESTDIR/dirlink"
check "can access through dirlink" "cat $TESTDIR/dirlink/file.txt | grep -q 'subdir file'"
echo

# Test stat output
echo "Link Information:"
check "stat shows link count" "stat $TESTDIR/hardlink.txt | grep -qi 'links'"
check "stat -c %h shows link count" "stat -c %h $TESTDIR/hardlink.txt"
check "readlink -f resolves symlink" "readlink -f $TESTDIR/relative_symlink.txt | grep -q 'original.txt'"
echo

# Test ls -l output
echo "Ls Link Display:"
check "ls -l shows -> for symlink" "ls -l $TESTDIR/relative_symlink.txt | grep -q '->'"
check "ls -li shows inodes" "ls -li $TESTDIR | head -3"
echo

# Test hard link restrictions (awareness)
echo "Hard Link Restrictions:"
check "Cannot hard link directory" "! ln $TESTDIR/subdir $TESTDIR/dir_hardlink 2>/dev/null"
echo

# Summary
total=$((passed + failed))
echo "===================================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 104.6 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
