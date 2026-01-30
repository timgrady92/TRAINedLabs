#!/bin/bash
# LPIC-1 Training - User Administration Lesson
# Objective: 107.1 - Manage user and group accounts

lesson_users() {
    print_header "User and Group Administration"

    cat << 'INTRO'
Linux is a multi-user system. User and group management is fundamental
to system administration - controlling who can access the system, what
resources they can use, and how they collaborate.

INTRO

    echo -e "${BOLD}Real-World Uses:${NC}"
    echo "  ${BULLET} Creating accounts for new employees"
    echo "  ${BULLET} Setting up service accounts for applications"
    echo "  ${BULLET} Managing team access through groups"
    echo "  ${BULLET} Enforcing password policies"
    echo "  ${BULLET} Removing access for departing users"

    wait_for_user

    # User Database Files
    print_subheader "User Database Files"

    echo -e "${BOLD}/etc/passwd - User account information${NC}"
    echo "  Format: username:x:UID:GID:comment:home:shell"
    echo
    echo -e "${CYAN}Example line:${NC}"
    echo "  john:x:1001:1001:John Smith:/home/john:/bin/bash"
    echo
    echo "  john    = username"
    echo "  x       = password placeholder (actual hash in /etc/shadow)"
    echo "  1001    = UID (user ID)"
    echo "  1001    = GID (primary group ID)"
    echo "  John Smith = GECOS/comment field"
    echo "  /home/john = home directory"
    echo "  /bin/bash  = login shell"

    wait_for_user

    echo -e "${BOLD}/etc/shadow - Encrypted passwords${NC}"
    echo "  Format: username:hash:lastchg:min:max:warn:inactive:expire:"
    echo
    echo -e "${CYAN}Example:${NC}"
    echo '  john:$6$rounds=...:19500:0:99999:7:::'
    echo
    echo "  Only root can read /etc/shadow"
    echo "  Password hashes: \$6\$ = SHA-512, \$5\$ = SHA-256, \$1\$ = MD5"
    echo

    echo -e "${BOLD}/etc/group - Group definitions${NC}"
    echo "  Format: groupname:x:GID:members"
    echo
    echo -e "${CYAN}Example:${NC}"
    echo "  developers:x:1002:john,jane,bob"

    wait_for_user

    # useradd
    print_subheader "useradd - Create Users"

    echo -e "${BOLD}Basic syntax:${NC}"
    echo "  useradd [options] username"
    echo

    echo -e "${BOLD}Common options:${NC}"
    echo "  ${CYAN}-m${NC}          Create home directory"
    echo "  ${CYAN}-d path${NC}     Specify home directory"
    echo "  ${CYAN}-s shell${NC}    Login shell"
    echo "  ${CYAN}-g group${NC}    Primary group"
    echo "  ${CYAN}-G groups${NC}   Supplementary groups (comma-separated)"
    echo "  ${CYAN}-c comment${NC}  GECOS/full name field"
    echo "  ${CYAN}-u uid${NC}      Specific UID"
    echo "  ${CYAN}-e date${NC}     Account expiration (YYYY-MM-DD)"
    echo "  ${CYAN}-r${NC}          System account (no home, UID < 1000)"
    echo

    echo -e "${CYAN}Example: Create regular user${NC}"
    echo "  useradd -m -s /bin/bash -c 'John Smith' john"
    echo

    echo -e "${CYAN}Example: Create system user for service${NC}"
    echo "  useradd -r -s /usr/sbin/nologin nginx"

    wait_for_user

    # usermod
    print_subheader "usermod - Modify Users"

    echo -e "${BOLD}Common options:${NC}"
    echo "  ${CYAN}-l newname${NC}  Change username"
    echo "  ${CYAN}-d path${NC}     Change home directory"
    echo "  ${CYAN}-m${NC}          Move home directory contents"
    echo "  ${CYAN}-s shell${NC}    Change login shell"
    echo "  ${CYAN}-g group${NC}    Change primary group"
    echo "  ${CYAN}-G groups${NC}   Set supplementary groups (replaces!)"
    echo "  ${CYAN}-aG groups${NC}  Append to supplementary groups"
    echo "  ${CYAN}-L${NC}          Lock account"
    echo "  ${CYAN}-U${NC}          Unlock account"
    echo "  ${CYAN}-e date${NC}     Set expiration date"
    echo

    echo -e "${RED}${WARN} -G without -a REPLACES all groups!${NC}"
    echo

    echo -e "${CYAN}Example: Add user to docker group (preserving others)${NC}"
    echo "  usermod -aG docker john"
    echo

    echo -e "${CYAN}Example: Lock a user account${NC}"
    echo "  usermod -L john"

    wait_for_user

    # userdel
    print_subheader "userdel - Delete Users"

    echo -e "${BOLD}Syntax:${NC}"
    echo "  userdel [options] username"
    echo

    echo -e "${BOLD}Options:${NC}"
    echo "  ${CYAN}-r${NC}          Remove home directory and mail spool"
    echo "  ${CYAN}-f${NC}          Force removal (even if user logged in)"
    echo

    echo -e "${CYAN}Example: Delete user and their files${NC}"
    echo "  userdel -r john"
    echo

    echo -e "${YELLOW}${WARN} Without -r, home directory and files remain${NC}"
    echo

    echo -e "${CYAN}Before deleting, check for:${NC}"
    echo "  • Running processes: ps -u john"
    echo "  • Cron jobs: crontab -l -u john"
    echo "  • Files elsewhere: find / -user john"

    wait_for_user

    # passwd
    print_subheader "passwd - Manage Passwords"

    echo -e "${BOLD}Basic usage:${NC}"
    echo "  passwd              # Change your own password"
    echo "  passwd username     # Change another user's (root only)"
    echo

    echo -e "${BOLD}Administrative options (root only):${NC}"
    echo "  ${CYAN}-l${NC}          Lock account"
    echo "  ${CYAN}-u${NC}          Unlock account"
    echo "  ${CYAN}-d${NC}          Delete password (allow passwordless login)"
    echo "  ${CYAN}-e${NC}          Force password change at next login"
    echo "  ${CYAN}-n days${NC}     Minimum days between changes"
    echo "  ${CYAN}-x days${NC}     Maximum days before expiry"
    echo "  ${CYAN}-w days${NC}     Warning days before expiry"
    echo "  ${CYAN}-S${NC}          Show password status"
    echo

    echo -e "${CYAN}Example: Force password change at next login${NC}"
    echo "  passwd -e john"
    echo

    echo -e "${CYAN}Example: Check password status${NC}"
    echo "  passwd -S john"

    wait_for_user

    # Group Management
    print_subheader "Group Management"

    echo -e "${BOLD}groupadd - Create groups${NC}"
    echo "  groupadd developers"
    echo "  groupadd -g 2000 mygroup    # Specific GID"
    echo "  groupadd -r sysgroup        # System group"
    echo

    echo -e "${BOLD}groupmod - Modify groups${NC}"
    echo "  groupmod -n newname oldname # Rename"
    echo "  groupmod -g 2001 mygroup    # Change GID"
    echo

    echo -e "${BOLD}groupdel - Delete groups${NC}"
    echo "  groupdel developers"
    echo "  ${DIM}(Can't delete a user's primary group)${NC}"
    echo

    echo -e "${BOLD}gpasswd - Group membership${NC}"
    echo "  gpasswd -a john developers  # Add user to group"
    echo "  gpasswd -d john developers  # Remove user from group"
    echo "  gpasswd -A john developers  # Make john group admin"

    wait_for_user

    # Viewing Information
    print_subheader "Viewing User/Group Information"

    echo -e "${CYAN}Who am I?${NC}"
    echo "  whoami           # Current username"
    echo "  id               # UID, GID, groups"
    echo "  id john          # Info for specific user"
    echo

    echo -e "${CYAN}Live example:${NC}"
    echo -e "${BOLD}Command:${NC} id"
    id | sed 's/^/  /'
    echo

    echo -e "${CYAN}Group membership:${NC}"
    echo "  groups           # Your groups"
    echo "  groups john      # User's groups"
    echo "  getent group developers  # Group members"
    echo

    echo -e "${CYAN}Who's logged in:${NC}"
    echo "  who              # Current logins"
    echo "  w                # Logins with activity"
    echo "  last             # Login history"

    wait_for_user

    # chage
    print_subheader "chage - Password Aging"

    echo -e "${BOLD}chage manages password expiration policy${NC}"
    echo

    echo -e "${CYAN}View current settings:${NC}"
    echo "  chage -l john"
    echo

    echo -e "${BOLD}Options:${NC}"
    echo "  ${CYAN}-d DATE${NC}     Last password change (YYYY-MM-DD)"
    echo "  ${CYAN}-E DATE${NC}     Account expiration date"
    echo "  ${CYAN}-I days${NC}     Inactive days before account lock"
    echo "  ${CYAN}-m days${NC}     Minimum days between changes"
    echo "  ${CYAN}-M days${NC}     Maximum days before password expires"
    echo "  ${CYAN}-W days${NC}     Warning days before expiry"
    echo

    echo -e "${CYAN}Example: Set password to expire in 90 days${NC}"
    echo "  chage -M 90 john"
    echo

    echo -e "${CYAN}Example: Force password change on next login${NC}"
    echo "  chage -d 0 john"

    wait_for_user

    # Default Settings
    print_subheader "Default Settings"

    echo -e "${BOLD}/etc/login.defs - System-wide defaults${NC}"
    echo "  PASS_MAX_DAYS   Maximum password age"
    echo "  PASS_MIN_DAYS   Minimum password age"
    echo "  PASS_WARN_AGE   Warning before expiry"
    echo "  UID_MIN/UID_MAX User ID range"
    echo "  CREATE_HOME     Create home by default"
    echo

    echo -e "${BOLD}/etc/default/useradd - useradd defaults${NC}"
    echo "  useradd -D      # View defaults"
    echo "  Changes stored in /etc/default/useradd"
    echo

    echo -e "${BOLD}/etc/skel - Skeleton directory${NC}"
    echo "  Contents copied to new home directories"
    echo "  Put default .bashrc, .profile here"

    wait_for_user

    # Practical Scenarios
    print_subheader "Practical Scenarios"

    echo -e "${CYAN}1. New employee setup:${NC}"
    echo "   useradd -m -s /bin/bash -c 'John Smith' -G developers john"
    echo "   passwd john"
    echo "   chage -d 0 john  # Force password change"
    echo

    echo -e "${CYAN}2. Service account (no login):${NC}"
    echo "   useradd -r -s /usr/sbin/nologin -d /var/lib/myapp myapp"
    echo

    echo -e "${CYAN}3. Add existing user to group:${NC}"
    echo "   usermod -aG docker john  # Note: -a is crucial!"
    echo

    echo -e "${CYAN}4. Disable account (keep files):${NC}"
    echo "   usermod -L john          # Lock"
    echo "   usermod -s /sbin/nologin john  # Or change shell"
    echo

    echo -e "${CYAN}5. Employee departure:${NC}"
    echo "   tar -czvf /backup/john.tar.gz /home/john"
    echo "   userdel -r john"

    wait_for_user

    # Exam tips
    print_subheader "Exam Tips"

    echo -e "${MAGENTA}${BULLET}${NC} useradd -m creates home directory"
    echo -e "${MAGENTA}${BULLET}${NC} usermod -aG appends groups; -G alone replaces"
    echo -e "${MAGENTA}${BULLET}${NC} userdel -r removes home directory"
    echo -e "${MAGENTA}${BULLET}${NC} passwd -e forces password change at next login"
    echo -e "${MAGENTA}${BULLET}${NC} chage -l shows password aging info"
    echo -e "${MAGENTA}${BULLET}${NC} System accounts: UID < 1000, usually no home"
    echo -e "${MAGENTA}${BULLET}${NC} /etc/skel contents copied to new home dirs"

    wait_for_user

    # Key takeaways
    print_subheader "Key Takeaways"

    echo "1. useradd creates, usermod modifies, userdel removes"
    echo "2. Always use -m with useradd for home directory"
    echo "3. Use -aG (not just -G) to append to groups"
    echo "4. passwd manages passwords; chage manages aging"
    echo "5. /etc/passwd, /etc/shadow, /etc/group are key files"
    echo "6. /etc/skel provides template for new home directories"
    echo

    print_info "Ready to practice? Try: lpic-train practice users"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    lesson_users
fi
