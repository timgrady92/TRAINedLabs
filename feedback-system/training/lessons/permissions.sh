#!/bin/bash
# LPIC-1 Training - Permissions Lesson
# Objective: 104.5 - Manage file permissions and ownership

lesson_permissions() {
    print_header "File Permissions and Ownership"

    cat << 'INTRO'
Linux file security is based on three types of permissions (read, write,
execute) for three categories of users (owner, group, others). Understanding
permissions is essential for system administration and security.

INTRO

    echo -e "${BOLD}Why Permissions Matter:${NC}"
    echo "  ${BULLET} Protect sensitive files from unauthorized access"
    echo "  ${BULLET} Control who can run scripts and programs"
    echo "  ${BULLET} Enable collaboration through group permissions"
    echo "  ${BULLET} Prevent accidental deletion or modification"
    echo "  ${BULLET} Security compliance and auditing"

    wait_for_user

    # Understanding Permissions
    print_subheader "Understanding Permission Bits"

    echo -e "${BOLD}The three permission types:${NC}"
    echo -e "  ${CYAN}r${NC} (read)    - View file contents or list directory"
    echo -e "  ${CYAN}w${NC} (write)   - Modify file or add/remove files in directory"
    echo -e "  ${CYAN}x${NC} (execute) - Run file as program or enter directory"
    echo
    echo -e "${BOLD}The three user categories:${NC}"
    echo -e "  ${CYAN}u${NC} (user)    - The file owner"
    echo -e "  ${CYAN}g${NC} (group)   - Members of the file's group"
    echo -e "  ${CYAN}o${NC} (others)  - Everyone else"
    echo -e "  ${CYAN}a${NC} (all)     - All three categories"

    wait_for_user

    # Reading Permissions
    print_subheader "Reading Permission Display"

    echo -e "${BOLD}ls -l output format:${NC}"
    echo
    echo "  -rw-r--r-- 1 user group 1234 Jan 15 10:00 file.txt"
    echo "  │└┬┘└┬┘└┬┘"
    echo "  │ │  │  └── Others: read only"
    echo "  │ │  └───── Group: read only"
    echo "  │ └──────── Owner: read, write"
    echo "  └────────── File type (- = regular file)"
    echo
    echo -e "${BOLD}File type indicators:${NC}"
    echo "  ${CYAN}-${NC}  Regular file"
    echo "  ${CYAN}d${NC}  Directory"
    echo "  ${CYAN}l${NC}  Symbolic link"
    echo "  ${CYAN}b${NC}  Block device"
    echo "  ${CYAN}c${NC}  Character device"

    local perm_dir
    perm_dir=$(get_practice_file "perm" "")

    if [[ -d "$perm_dir" ]]; then
        echo
        echo -e "${CYAN}Example from practice files:${NC}"
        ls -la "$perm_dir" 2>/dev/null | head -8 | sed 's/^/  /'
    fi

    wait_for_user

    # Numeric Mode
    print_subheader "Numeric (Octal) Mode"

    echo -e "${BOLD}Each permission has a numeric value:${NC}"
    echo "  r = 4"
    echo "  w = 2"
    echo "  x = 1"
    echo
    echo -e "${BOLD}Add values for each category:${NC}"
    echo
    printf "  %-10s %-10s %-10s %-10s %s\n" "Perm" "Owner" "Group" "Others" "Numeric"
    printf "  %-10s %-10s %-10s %-10s %s\n" "────" "─────" "─────" "──────" "───────"
    printf "  %-10s %-10s %-10s %-10s %s\n" "rwxr-xr-x" "rwx=7" "r-x=5" "r-x=5" "755"
    printf "  %-10s %-10s %-10s %-10s %s\n" "rw-r--r--" "rw-=6" "r--=4" "r--=4" "644"
    printf "  %-10s %-10s %-10s %-10s %s\n" "rw-------" "rw-=6" "---=0" "---=0" "600"
    printf "  %-10s %-10s %-10s %-10s %s\n" "rwxrwxrwx" "rwx=7" "rwx=7" "rwx=7" "777"

    wait_for_user

    # chmod - Changing Permissions
    print_subheader "chmod - Change Permissions"

    echo -e "${BOLD}Numeric mode:${NC}"
    echo "  chmod 755 script.sh    # rwxr-xr-x"
    echo "  chmod 644 file.txt     # rw-r--r--"
    echo "  chmod 600 private.key  # rw-------"
    echo
    echo -e "${BOLD}Symbolic mode:${NC}"
    echo "  chmod u+x file        # Add execute for owner"
    echo "  chmod g-w file        # Remove write for group"
    echo "  chmod o=r file        # Set others to read only"
    echo "  chmod a+r file        # Add read for everyone"
    echo "  chmod ug+x file       # Add execute for user and group"
    echo
    echo -e "${BOLD}Symbolic operators:${NC}"
    echo "  ${CYAN}+${NC}  Add permission"
    echo "  ${CYAN}-${NC}  Remove permission"
    echo "  ${CYAN}=${NC}  Set exact permission"

    wait_for_user

    # Practical chmod Examples
    print_subheader "Practical chmod Examples"

    echo -e "${CYAN}Make script executable:${NC}"
    echo "  chmod +x script.sh"
    echo "  chmod 755 script.sh"
    echo

    echo -e "${CYAN}Secure private key:${NC}"
    echo "  chmod 600 ~/.ssh/id_rsa"
    echo

    echo -e "${CYAN}Web server files:${NC}"
    echo "  chmod 644 index.html   # Files"
    echo "  chmod 755 /var/www/    # Directories"
    echo

    echo -e "${CYAN}Shared directory:${NC}"
    echo "  chmod 775 /project/    # Owner and group full, others read/execute"
    echo

    echo -e "${CYAN}Remove all permissions for others:${NC}"
    echo "  chmod o= sensitive.txt"
    echo "  chmod o-rwx sensitive.txt"

    wait_for_user

    # Recursive chmod
    print_subheader "Recursive Permission Changes"

    echo -e "${CYAN}chmod -R applies to directory and all contents:${NC}"
    echo "  chmod -R 755 /var/www/"
    echo
    echo -e "${RED}${WARN} Be careful! This changes EVERYTHING underneath${NC}"
    echo
    echo -e "${CYAN}Better approach - different perms for files vs directories:${NC}"
    echo "  find /var/www -type d -exec chmod 755 {} \\;"
    echo "  find /var/www -type f -exec chmod 644 {} \\;"

    wait_for_user

    # Special Permissions
    print_subheader "Special Permission Bits"

    echo -e "${BOLD}SUID (4xxx) - Set User ID${NC}"
    echo "  When set on executable, runs as file owner (not caller)"
    echo "  chmod u+s file  or  chmod 4755 file"
    echo "  Example: /usr/bin/passwd runs as root"
    echo
    echo -e "${BOLD}SGID (2xxx) - Set Group ID${NC}"
    echo "  On file: runs as file's group"
    echo "  On directory: new files inherit directory's group"
    echo "  chmod g+s dir  or  chmod 2755 dir"
    echo
    echo -e "${BOLD}Sticky Bit (1xxx)${NC}"
    echo "  On directory: only owner can delete their files"
    echo "  chmod +t dir  or  chmod 1777 dir"
    echo "  Example: /tmp has sticky bit"
    echo
    echo -e "${DIM}Display: SUID='s' in owner execute, SGID='s' in group execute,"
    echo "         Sticky='t' in others execute${NC}"

    wait_for_user

    # chown - Changing Ownership
    print_subheader "chown - Change Ownership"

    echo -e "${BOLD}Change owner:${NC}"
    echo "  chown newowner file.txt"
    echo
    echo -e "${BOLD}Change owner and group:${NC}"
    echo "  chown newowner:newgroup file.txt"
    echo "  chown newowner.newgroup file.txt  # Alternative syntax"
    echo
    echo -e "${BOLD}Change group only:${NC}"
    echo "  chown :newgroup file.txt"
    echo "  chgrp newgroup file.txt"
    echo
    echo -e "${BOLD}Recursive:${NC}"
    echo "  chown -R www-data:www-data /var/www/"
    echo
    echo -e "${YELLOW}Note: Only root can change file ownership${NC}"

    wait_for_user

    # chgrp
    print_subheader "chgrp - Change Group"

    echo -e "${CYAN}Change group ownership:${NC}"
    echo "  chgrp developers project/"
    echo "  chgrp -R developers project/  # Recursive"
    echo
    echo -e "${DIM}Users can only change to groups they belong to${NC}"
    echo -e "${DIM}Check your groups: groups or id${NC}"

    wait_for_user

    # umask
    print_subheader "umask - Default Permissions"

    cat << 'UMASK'
umask sets the default permissions for NEW files and directories.
It specifies which permissions to REMOVE from the default.

Default without umask:
  Files: 666 (rw-rw-rw-)
  Directories: 777 (rwxrwxrwx)

umask subtracts from these defaults.
UMASK
    echo

    echo -e "${BOLD}Common umask values:${NC}"
    printf "  %-8s %-20s %-20s\n" "umask" "Files" "Directories"
    printf "  %-8s %-20s %-20s\n" "─────" "─────" "───────────"
    printf "  %-8s %-20s %-20s\n" "022" "644 (rw-r--r--)" "755 (rwxr-xr-x)"
    printf "  %-8s %-20s %-20s\n" "027" "640 (rw-r-----)" "750 (rwxr-x---)"
    printf "  %-8s %-20s %-20s\n" "077" "600 (rw-------)" "700 (rwx------)"
    echo

    echo -e "${CYAN}View current umask:${NC}"
    echo "  umask"
    echo -n "  Current: "
    umask
    echo

    echo -e "${CYAN}Set umask:${NC}"
    echo "  umask 022   # Common default"
    echo "  umask 077   # More restrictive"

    wait_for_user

    # Directory Permissions
    print_subheader "Directory Permission Meanings"

    echo "Directory permissions behave differently than file permissions:"
    echo
    echo -e "  ${CYAN}r${NC} (read)    - List directory contents (ls)"
    echo -e "  ${CYAN}w${NC} (write)   - Create/delete files in directory"
    echo -e "  ${CYAN}x${NC} (execute) - Enter directory (cd), access files"
    echo
    echo -e "${BOLD}Common combinations:${NC}"
    echo "  ${CYAN}r-x${NC}  Can list and enter, but not create/delete"
    echo "  ${CYAN}rwx${NC}  Full access"
    echo "  ${CYAN}--x${NC}  Can enter and access files if you know names"
    echo "  ${CYAN}r--${NC}  Can list names only, cannot enter or read files"
    echo
    echo -e "${YELLOW}Note: To read a file, you need x on ALL parent directories${NC}"

    wait_for_user

    # Practical Scenarios
    print_subheader "Practical Scenarios"

    echo -e "${CYAN}1. Secure SSH key:${NC}"
    echo "   chmod 600 ~/.ssh/id_rsa"
    echo "   chmod 644 ~/.ssh/id_rsa.pub"
    echo "   chmod 700 ~/.ssh"
    echo

    echo -e "${CYAN}2. Web server setup:${NC}"
    echo "   chown -R www-data:www-data /var/www/"
    echo "   find /var/www -type d -exec chmod 755 {} \\;"
    echo "   find /var/www -type f -exec chmod 644 {} \\;"
    echo

    echo -e "${CYAN}3. Shared project directory:${NC}"
    echo "   groupadd developers"
    echo "   chown :developers /project"
    echo "   chmod 2775 /project  # SGID + group write"
    echo

    echo -e "${CYAN}4. Executable script:${NC}"
    echo "   chmod 755 script.sh  # Everyone can run"
    echo "   chmod 750 script.sh  # Owner and group only"

    wait_for_user

    # Exam tips
    print_subheader "Exam Tips"

    echo -e "${MAGENTA}${BULLET}${NC} Know numeric values: r=4, w=2, x=1"
    echo -e "${MAGENTA}${BULLET}${NC} 755 and 644 are the most common permissions"
    echo -e "${MAGENTA}${BULLET}${NC} SUID=4, SGID=2, Sticky=1 (prepend to permissions)"
    echo -e "${MAGENTA}${BULLET}${NC} umask 022 means files get 644, directories get 755"
    echo -e "${MAGENTA}${BULLET}${NC} Only root can chown; users can chgrp to their groups"
    echo -e "${MAGENTA}${BULLET}${NC} x on directory = can enter; r = can list"

    wait_for_user

    # Key takeaways
    print_subheader "Key Takeaways"

    echo "1. Permissions: r(4) w(2) x(1) for user/group/others"
    echo "2. chmod changes permissions (numeric or symbolic)"
    echo "3. chown changes owner, chgrp changes group"
    echo "4. umask sets default permissions for new files"
    echo "5. Special bits: SUID(4), SGID(2), Sticky(1)"
    echo "6. Directory x means enter; w means create/delete files"
    echo

    print_info "Ready to practice? Try: lpic-train practice permissions"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    lesson_permissions
fi
