#!/bin/bash
# LPIC-1 Training - tar Lesson
# Objective: 103.3 - Perform basic file management

lesson_tar() {
    print_header "tar - Archive Files"

    cat << 'INTRO'
tar (tape archive) creates, extracts, and manages archive files. Originally
designed for tape backup, it's now the standard tool for bundling files
on Linux. Often combined with compression (gzip, bzip2, xz).

INTRO

    echo -e "${BOLD}Real-World Uses:${NC}"
    echo "  ${BULLET} Creating backups of directories"
    echo "  ${BULLET} Distributing software packages"
    echo "  ${BULLET} Transferring multiple files as a single archive"
    echo "  ${BULLET} Preserving file permissions and ownership"
    echo "  ${BULLET} Incremental backups"

    wait_for_user

    # Basic Operations
    print_subheader "Three Essential Operations"

    echo -e "${BOLD}${CYAN}c${NC} - Create archive${NC}"
    echo "  tar -cvf archive.tar files..."
    echo
    echo -e "${BOLD}${CYAN}x${NC} - Extract archive${NC}"
    echo "  tar -xvf archive.tar"
    echo
    echo -e "${BOLD}${CYAN}t${NC} - List contents${NC}"
    echo "  tar -tvf archive.tar"
    echo
    echo -e "${YELLOW}Memory trick: c=Create, x=eXtract, t=lisT${NC}"

    wait_for_user

    # Common Options
    print_subheader "Common Options"

    echo -e "${CYAN}-c${NC}   Create new archive"
    echo -e "${CYAN}-x${NC}   Extract files"
    echo -e "${CYAN}-t${NC}   List contents"
    echo -e "${CYAN}-v${NC}   Verbose (show files being processed)"
    echo -e "${CYAN}-f${NC}   Specify archive filename (required!)"
    echo
    echo -e "${BOLD}Compression Options:${NC}"
    echo -e "${CYAN}-z${NC}   gzip compression (.tar.gz, .tgz)"
    echo -e "${CYAN}-j${NC}   bzip2 compression (.tar.bz2)"
    echo -e "${CYAN}-J${NC}   xz compression (.tar.xz)"
    echo -e "${CYAN}-a${NC}   Auto-detect compression from filename"
    echo
    echo -e "${BOLD}Other Options:${NC}"
    echo -e "${CYAN}-C dir${NC}    Change to directory before operation"
    echo -e "${CYAN}-p${NC}        Preserve permissions"
    echo -e "${CYAN}--exclude${NC} Exclude files matching pattern"

    wait_for_user

    # Creating Archives
    print_subheader "Creating Archives"

    local comp_dir
    comp_dir=$(get_practice_file "" "compression")

    echo -e "${CYAN}Example: Create uncompressed archive${NC}"
    echo "  tar -cvf backup.tar /home/user/documents/"
    echo
    echo -e "${CYAN}Example: Create gzip-compressed archive${NC}"
    echo "  tar -czvf backup.tar.gz /home/user/documents/"
    echo
    echo -e "${CYAN}Example: Create bzip2-compressed archive${NC}"
    echo "  tar -cjvf backup.tar.bz2 /home/user/documents/"
    echo
    echo -e "${CYAN}Example: Create xz-compressed archive (best compression)${NC}"
    echo "  tar -cJvf backup.tar.xz /home/user/documents/"

    if [[ -d "$comp_dir" ]]; then
        echo
        echo -e "${CYAN}Live Example:${NC}"
        echo -e "${BOLD}Command:${NC} tar -czvf /tmp/test-archive.tar.gz compression/"
        (cd "$PRACTICE_DIR" && tar -czvf /tmp/test-archive.tar.gz compression/ 2>/dev/null) | head -8 | sed 's/^/  /'
        rm -f /tmp/test-archive.tar.gz 2>/dev/null
    fi

    wait_for_user

    # Listing Contents
    print_subheader "Listing Archive Contents"

    echo -e "${CYAN}List contents of tar archive:${NC}"
    echo "  tar -tvf archive.tar"
    echo
    echo -e "${CYAN}List contents of compressed archive:${NC}"
    echo "  tar -tzvf archive.tar.gz"
    echo
    echo -e "${CYAN}List specific files:${NC}"
    echo "  tar -tvf archive.tar path/to/file"
    echo
    echo -e "${DIM}The -v option shows detailed listing (like ls -l)${NC}"
    echo -e "${DIM}Without -v, just shows filenames${NC}"

    wait_for_user

    # Extracting Archives
    print_subheader "Extracting Archives"

    echo -e "${CYAN}Extract to current directory:${NC}"
    echo "  tar -xvf archive.tar"
    echo
    echo -e "${CYAN}Extract compressed archive:${NC}"
    echo "  tar -xzvf archive.tar.gz"
    echo
    echo -e "${CYAN}Extract to specific directory:${NC}"
    echo "  tar -xzvf archive.tar.gz -C /destination/"
    echo
    echo -e "${CYAN}Extract specific files only:${NC}"
    echo "  tar -xzvf archive.tar.gz path/to/file.txt"
    echo
    echo -e "${YELLOW}${WARN} tar extracts with relative paths by default.${NC}"
    echo -e "${YELLOW}   Archives with absolute paths or .. can be dangerous!${NC}"

    wait_for_user

    # Compression Comparison
    print_subheader "Compression Comparison"

    echo -e "${BOLD}Compression methods (from fastest to smallest):${NC}"
    echo
    printf "  %-10s %-12s %-12s %s\n" "Format" "Speed" "Size" "Extension"
    printf "  %-10s %-12s %-12s %s\n" "──────" "─────" "────" "─────────"
    printf "  %-10s %-12s %-12s %s\n" "none" "fastest" "largest" ".tar"
    printf "  %-10s %-12s %-12s %s\n" "gzip" "fast" "medium" ".tar.gz, .tgz"
    printf "  %-10s %-12s %-12s %s\n" "bzip2" "medium" "smaller" ".tar.bz2"
    printf "  %-10s %-12s %-12s %s\n" "xz" "slowest" "smallest" ".tar.xz"
    echo
    echo -e "${DIM}gzip is usually the best balance for most cases${NC}"
    echo -e "${DIM}xz is great for distribution (download once, extract many)${NC}"

    wait_for_user

    # Excluding Files
    print_subheader "Excluding Files"

    echo -e "${CYAN}Exclude specific pattern:${NC}"
    echo "  tar -czvf backup.tar.gz --exclude='*.log' /var/www/"
    echo
    echo -e "${CYAN}Exclude multiple patterns:${NC}"
    echo "  tar -czvf backup.tar.gz \\"
    echo "      --exclude='*.log' \\"
    echo "      --exclude='*.tmp' \\"
    echo "      --exclude='.git' \\"
    echo "      /project/"
    echo
    echo -e "${CYAN}Exclude from file:${NC}"
    echo "  tar -czvf backup.tar.gz -X exclude.txt /home/"
    echo "  (exclude.txt contains patterns, one per line)"

    wait_for_user

    # Preserving Attributes
    print_subheader "Preserving File Attributes"

    echo -e "${BOLD}tar preserves by default:${NC}"
    echo "  ${BULLET} File permissions"
    echo "  ${BULLET} Ownership (when extracting as root)"
    echo "  ${BULLET} Modification times"
    echo "  ${BULLET} Symbolic links"
    echo
    echo -e "${CYAN}Ensure permissions preserved:${NC}"
    echo "  tar -cpvf backup.tar /etc/"
    echo
    echo -e "${CYAN}Extract preserving everything:${NC}"
    echo "  sudo tar -xpvf backup.tar -C /restore/"
    echo
    echo -e "${YELLOW}Note: Only root can restore original ownership${NC}"

    wait_for_user

    # Incremental Backups
    print_subheader "Incremental Backups"

    cat << 'INCR'
tar can create incremental backups using snapshot files,
backing up only files changed since the last backup.
INCR
    echo

    echo -e "${CYAN}Create full backup with snapshot:${NC}"
    echo "  tar -czvf full-backup.tar.gz \\"
    echo "      --listed-incremental=/var/backup/snapshot.snar \\"
    echo "      /home/"
    echo
    echo -e "${CYAN}Create incremental backup (changes only):${NC}"
    echo "  tar -czvf incr-backup.tar.gz \\"
    echo "      --listed-incremental=/var/backup/snapshot.snar \\"
    echo "      /home/"
    echo
    echo -e "${DIM}The snapshot file tracks what's been backed up${NC}"

    wait_for_user

    # Practical Examples
    print_subheader "Practical Examples"

    echo -e "${CYAN}1. Backup home directory:${NC}"
    echo "   tar -czvf ~/backup-\$(date +%Y%m%d).tar.gz ~/Documents/"
    echo

    echo -e "${CYAN}2. Extract and see contents simultaneously:${NC}"
    echo "   tar -xzvf archive.tar.gz"
    echo

    echo -e "${CYAN}3. Create archive excluding version control:${NC}"
    echo "   tar -czvf project.tar.gz --exclude='.git' project/"
    echo

    echo -e "${CYAN}4. Verify archive integrity:${NC}"
    echo "   tar -tvf archive.tar > /dev/null && echo 'OK'"
    echo

    echo -e "${CYAN}5. Append files to existing tar:${NC}"
    echo "   tar -rvf archive.tar newfile.txt"
    echo "   (Note: cannot append to compressed archives)"
    echo

    echo -e "${CYAN}6. Extract single file:${NC}"
    echo "   tar -xzvf backup.tar.gz home/user/important.txt"

    wait_for_user

    # Common Errors
    print_subheader "Common Mistakes"

    echo -e "${RED}${WARN}${NC} Forgetting -f (file) option"
    echo "    Wrong: tar -cz /home/"
    echo "    Right: tar -czf backup.tar.gz /home/"
    echo

    echo -e "${RED}${WARN}${NC} Wrong order: -f must be followed by filename"
    echo "    Wrong: tar -fvc backup.tar /home/"
    echo "    Right: tar -cvf backup.tar /home/"
    echo

    echo -e "${RED}${WARN}${NC} Extracting without checking contents first"
    echo "    Always: tar -tvf archive.tar  # List first"
    echo "    Then:   tar -xvf archive.tar  # Extract"
    echo

    echo -e "${RED}${WARN}${NC} Overwriting files during extraction"
    echo "    Use: tar -xvkf archive.tar  # -k keeps existing files"

    wait_for_user

    # Exam tips
    print_subheader "Exam Tips"

    echo -e "${MAGENTA}${BULLET}${NC} c=create, x=extract, t=list - always need one"
    echo -e "${MAGENTA}${BULLET}${NC} f=file MUST be followed by filename"
    echo -e "${MAGENTA}${BULLET}${NC} z=gzip, j=bzip2, J=xz compression"
    echo -e "${MAGENTA}${BULLET}${NC} -C changes directory before extracting"
    echo -e "${MAGENTA}${BULLET}${NC} v=verbose is optional but helpful"
    echo -e "${MAGENTA}${BULLET}${NC} Modern tar auto-detects compression on extract"

    wait_for_user

    # Key takeaways
    print_subheader "Key Takeaways"

    echo "1. tar bundles files; compression is optional (-z, -j, -J)"
    echo "2. Three main operations: create (-c), extract (-x), list (-t)"
    echo "3. -f specifies the archive file (required)"
    echo "4. -C extracts to a different directory"
    echo "5. Always list contents (-t) before extracting unfamiliar archives"
    echo "6. gzip (-z) is the most common compression choice"
    echo

    print_info "Ready to practice? Try: lpic-train practice tar"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    lesson_tar
fi
