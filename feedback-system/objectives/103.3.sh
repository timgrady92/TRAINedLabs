#!/bin/bash
# Objective 103.3: Perform basic file management
# Weight: 4

set -euo pipefail

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

# Print verbose output if enabled
verbose() {
    [[ "$VERBOSE" == "true" ]] && echo -e "  ${YELLOW}→${NC} $*"
}

check() {
    local desc="$1"
    local cmd="$2"
    local output

    if output=$(eval "$cmd" 2>&1); then
        echo -e "${GREEN}${PASS}${NC} $desc"
        ((passed++)) || true
        return 0
    else
        echo -e "${RED}${FAIL}${NC} $desc"
        [[ "$VERBOSE" == "true" && -n "$output" ]] && echo -e "  ${YELLOW}→${NC} $output"
        ((failed++)) || true
        return 1
    fi
}

echo "Checking Objective 103.3: Perform basic file management"
echo "========================================================"
echo

# Create test directory
TESTDIR=$(mktemp -d)
trap 'rm -rf "$TESTDIR"' EXIT

# Check essential commands
echo "Essential Commands:"
check "cp available" "command -v cp"
check "mv available" "command -v mv"
check "rm available" "command -v rm"
check "mkdir available" "command -v mkdir"
check "rmdir available" "command -v rmdir"
check "touch available" "command -v touch"
check "ls available" "command -v ls"
check "find available" "command -v find"
check "file available" "command -v file"
echo

# Check archive commands
echo "Archive Commands:"
check "tar available" "command -v tar"
check "cpio available" "command -v cpio"
check "dd available" "command -v dd"
echo

# Check compression commands
echo "Compression Commands:"
check "gzip available" "command -v gzip"
check "gunzip available" "command -v gunzip"
check "bzip2 available" "command -v bzip2"
check "bunzip2 available" "command -v bunzip2"
check "xz available" "command -v xz"
check "unxz available" "command -v unxz"
echo

# Test file operations
echo "File Operations:"
touch "$TESTDIR/testfile.txt"
check "touch creates files" "test -f $TESTDIR/testfile.txt"

cp "$TESTDIR/testfile.txt" "$TESTDIR/copied.txt"
check "cp copies files" "test -f $TESTDIR/copied.txt"

mv "$TESTDIR/copied.txt" "$TESTDIR/moved.txt"
check "mv moves files" "test -f $TESTDIR/moved.txt && test ! -f $TESTDIR/copied.txt"

rm "$TESTDIR/moved.txt"
check "rm removes files" "test ! -f $TESTDIR/moved.txt"
echo

# Test directory operations
echo "Directory Operations:"
mkdir "$TESTDIR/subdir"
check "mkdir creates directories" "test -d $TESTDIR/subdir"

mkdir -p "$TESTDIR/deep/nested/dir"
check "mkdir -p creates nested directories" "test -d $TESTDIR/deep/nested/dir"

rmdir "$TESTDIR/subdir"
check "rmdir removes empty directories" "test ! -d $TESTDIR/subdir"

rm -r "$TESTDIR/deep"
check "rm -r removes directories recursively" "test ! -d $TESTDIR/deep"
echo

# Test find functionality
echo "Find Functionality:"
touch "$TESTDIR/find1.txt" "$TESTDIR/find2.txt"
mkdir -p "$TESTDIR/finddir"
touch "$TESTDIR/finddir/find3.txt"

check "find by name" "find $TESTDIR -name 'find*.txt' | grep -q find"
check "find by type (file)" "find $TESTDIR -type f | grep -q txt"
check "find by type (directory)" "find $TESTDIR -type d | grep -q finddir"
echo

# Test tar functionality
echo "Tar Functionality:"
echo "test content" > "$TESTDIR/tartest.txt"
tar -cf "$TESTDIR/test.tar" -C "$TESTDIR" tartest.txt
check "tar creates archives" "test -f $TESTDIR/test.tar"

tar -tf "$TESTDIR/test.tar" | grep -q tartest
check "tar lists contents" "tar -tf $TESTDIR/test.tar | grep -q tartest"

mkdir "$TESTDIR/extract"
tar -xf "$TESTDIR/test.tar" -C "$TESTDIR/extract"
check "tar extracts files" "test -f $TESTDIR/extract/tartest.txt"
echo

# Test compression
echo "Compression Functionality:"
echo "compress me" > "$TESTDIR/compress.txt"
gzip -k "$TESTDIR/compress.txt"
check "gzip compresses files" "test -f $TESTDIR/compress.txt.gz"

gunzip "$TESTDIR/compress.txt.gz"
check "gunzip decompresses files" "test -f $TESTDIR/compress.txt && test ! -f $TESTDIR/compress.txt.gz"
echo

# Test file command
echo "File Type Detection:"
check "file detects text" "file $TESTDIR/compress.txt | grep -qi text"
check "file detects tar" "file $TESTDIR/test.tar | grep -qi 'tar\|archive'"
echo

# Test globbing
echo "File Globbing:"
touch "$TESTDIR/glob1.txt" "$TESTDIR/glob2.txt" "$TESTDIR/other.log"
check "* wildcard works" "ls $TESTDIR/*.txt 2>/dev/null | wc -l | grep -q '[2-9]'"
check "? wildcard works" "ls $TESTDIR/glob?.txt 2>/dev/null | wc -l | grep -q '2'"
check "[...] pattern works" "ls $TESTDIR/glob[12].txt 2>/dev/null | wc -l | grep -q '2'"
echo

# Summary
total=$((passed + failed))
echo "========================================================"
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 103.3 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
