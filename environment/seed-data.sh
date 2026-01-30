#!/bin/bash
# LPIC-1 Training Environment - Practice Data Seeder
# Populates practice files for text processing, grep, awk exercises
# Run as regular user (not root)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
USER_PRACTICE="${HOME}/lpic1-practice"

# Parse arguments
RESET=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --reset)
            RESET=true
            shift
            ;;
        --help)
            echo "Usage: $0 [--reset]"
            echo "  --reset  Remove existing practice data and recreate"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Setup directories
setup_directories() {
    log_info "Setting up directories..."

    mkdir -p "${USER_PRACTICE}"/{text,logs,scripts,configs,compression}
    mkdir -p "${USER_PRACTICE}"/text/{grep-practice,sed-practice,awk-practice}
    mkdir -p "${USER_PRACTICE}"/permissions-lab
    mkdir -p "${USER_PRACTICE}"/find-practice/{level1/{level2/{level3,other},backup},temp}

    log_success "Directories created"
}

# Create text processing practice files
create_text_files() {
    log_info "Creating text processing practice files..."

    # Sample /etc/passwd style file
    cat > "${USER_PRACTICE}/text/users.txt" << 'EOF'
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/run/ircd:/usr/sbin/nologin
gnats:x:41:41:Gnats Bug-Reporting:/var/lib/gnats:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
systemd-network:x:100:102:systemd Network Management:/run/systemd:/usr/sbin/nologin
systemd-resolve:x:101:103:systemd Resolver:/run/systemd:/usr/sbin/nologin
messagebus:x:102:105::/nonexistent:/usr/sbin/nologin
sshd:x:103:65534::/run/sshd:/usr/sbin/nologin
student:x:1000:1000:LPIC Student:/home/student:/bin/bash
developer:x:1001:1001:Developer Account:/home/developer:/bin/bash
testuser:x:1002:1002:Test User:/home/testuser:/bin/bash
admin:x:1003:1003:Administrator:/home/admin:/bin/bash
EOF

    # Sample /etc/group style file
    cat > "${USER_PRACTICE}/text/groups.txt" << 'EOF'
root:x:0:
daemon:x:1:
bin:x:2:
sys:x:3:
adm:x:4:student,admin
tty:x:5:
disk:x:6:
lp:x:7:
mail:x:8:
news:x:9:
uucp:x:10:
man:x:12:
proxy:x:13:
kmem:x:15:
dialout:x:20:student
fax:x:21:
voice:x:22:
cdrom:x:24:student
floppy:x:25:student
tape:x:26:
sudo:x:27:student,admin
audio:x:29:student
dip:x:30:student
www-data:x:33:
backup:x:34:
operator:x:37:
list:x:38:
irc:x:39:
src:x:40:developer
gnats:x:41:
shadow:x:42:
utmp:x:43:
video:x:44:student
sasl:x:45:
plugdev:x:46:student
staff:x:50:developer,admin
games:x:60:
users:x:100:student,developer,testuser
nogroup:x:65534:
systemd-journal:x:101:
systemd-network:x:102:
systemd-resolve:x:103:
messagebus:x:105:
ssh:x:106:
student:x:1000:
developer:x:1001:
testuser:x:1002:
admin:x:1003:
docker:x:999:developer
wheel:x:10:admin
EOF

    # Sample log file with various patterns
    cat > "${USER_PRACTICE}/logs/system.log" << 'EOF'
Jan 15 08:00:01 server01 CRON[1234]: (root) CMD (/usr/lib/php/sessionclean)
Jan 15 08:05:22 server01 sshd[5678]: Accepted publickey for student from 192.168.1.100 port 52345 ssh2
Jan 15 08:05:23 server01 sshd[5678]: pam_unix(sshd:session): session opened for user student by (uid=0)
Jan 15 08:10:15 server01 systemd[1]: Starting Daily apt download activities...
Jan 15 08:10:16 server01 systemd[1]: Started Daily apt download activities.
Jan 15 08:15:33 server01 kernel: [123456.789] ata1.00: exception Emask 0x0 SAct 0x0 SErr 0x0 action 0x0
Jan 15 08:15:33 server01 kernel: [123456.790] ata1.00: BMDMA stat 0x4
Jan 15 08:20:01 server01 CRON[2345]: (root) CMD (/usr/local/bin/backup.sh)
Jan 15 08:25:44 server01 sshd[6789]: Failed password for invalid user admin from 10.0.0.50 port 54321 ssh2
Jan 15 08:25:45 server01 sshd[6789]: Failed password for invalid user admin from 10.0.0.50 port 54321 ssh2
Jan 15 08:25:46 server01 sshd[6789]: Failed password for invalid user admin from 10.0.0.50 port 54321 ssh2
Jan 15 08:30:01 server01 CRON[3456]: (developer) CMD (/home/developer/scripts/check_disk.sh)
Jan 15 08:35:12 server01 postfix/smtpd[7890]: connect from mail.example.com[203.0.113.25]
Jan 15 08:35:13 server01 postfix/smtpd[7890]: disconnect from mail.example.com[203.0.113.25]
Jan 15 08:40:00 server01 systemd[1]: Starting Cleanup of Temporary Directories...
Jan 15 08:40:00 server01 systemd-tmpfiles[4567]: Removing stale temporary files
Jan 15 08:40:01 server01 systemd[1]: Finished Cleanup of Temporary Directories.
Jan 15 08:45:22 server01 sshd[8901]: Accepted password for developer from 192.168.1.101 port 43210 ssh2
Jan 15 08:50:01 server01 CRON[5678]: (root) CMD (test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily ))
Jan 15 08:55:33 server01 kernel: [123789.012] EXT4-fs (sda1): mounted filesystem with ordered data mode
Jan 15 09:00:01 server01 CRON[6789]: (root) CMD (/usr/lib/php/sessionclean)
Jan 15 09:05:15 server01 sshd[9012]: error: maximum authentication attempts exceeded for root from 10.0.0.100 port 55555 ssh2
Jan 15 09:05:16 server01 sshd[9012]: Disconnecting: Too many authentication failures
Jan 15 09:10:44 server01 su[1111]: (to root) student on pts/0
Jan 15 09:10:44 server01 su[1111]: pam_unix(su:session): session opened for user root by student(uid=1000)
Jan 15 09:15:01 server01 CRON[2222]: (backup) CMD (/opt/scripts/rotate_logs.sh)
Jan 15 09:20:33 server01 nginx[3333]: 192.168.1.200 - - [15/Jan/2024:09:20:33 +0000] "GET /api/status HTTP/1.1" 200 45
Jan 15 09:20:34 server01 nginx[3333]: 192.168.1.200 - - [15/Jan/2024:09:20:34 +0000] "GET /api/users HTTP/1.1" 401 23
Jan 15 09:20:35 server01 nginx[3333]: 192.168.1.200 - - [15/Jan/2024:09:20:35 +0000] "POST /api/login HTTP/1.1" 200 156
Jan 15 09:25:01 server01 CRON[4444]: (root) CMD (/usr/bin/certbot renew)
Jan 15 09:30:00 server01 systemd[1]: Starting Docker Application Container Engine...
Jan 15 09:30:02 server01 dockerd[5555]: time="2024-01-15T09:30:02Z" level=info msg="Starting up"
Jan 15 09:30:05 server01 systemd[1]: Started Docker Application Container Engine.
EOF

    # Apache-style access log
    cat > "${USER_PRACTICE}/logs/access.log" << 'EOF'
192.168.1.100 - - [15/Jan/2024:10:00:01 +0000] "GET / HTTP/1.1" 200 2345 "-" "Mozilla/5.0"
192.168.1.101 - - [15/Jan/2024:10:00:02 +0000] "GET /style.css HTTP/1.1" 200 1234 "http://example.com/" "Mozilla/5.0"
192.168.1.100 - - [15/Jan/2024:10:00:03 +0000] "GET /app.js HTTP/1.1" 200 5678 "http://example.com/" "Mozilla/5.0"
10.0.0.50 - - [15/Jan/2024:10:00:04 +0000] "GET /admin HTTP/1.1" 403 123 "-" "curl/7.68.0"
192.168.1.102 - admin [15/Jan/2024:10:00:05 +0000] "GET /admin HTTP/1.1" 200 4567 "-" "Mozilla/5.0"
192.168.1.100 - - [15/Jan/2024:10:00:06 +0000] "POST /api/data HTTP/1.1" 201 89 "http://example.com/form" "Mozilla/5.0"
10.0.0.51 - - [15/Jan/2024:10:00:07 +0000] "GET /../../../etc/passwd HTTP/1.1" 400 45 "-" "BadBot/1.0"
192.168.1.103 - - [15/Jan/2024:10:00:08 +0000] "GET /images/logo.png HTTP/1.1" 200 12345 "http://example.com/" "Mozilla/5.0"
192.168.1.100 - - [15/Jan/2024:10:00:09 +0000] "GET /api/status HTTP/1.1" 200 67 "-" "HealthChecker/1.0"
192.168.1.104 - - [15/Jan/2024:10:00:10 +0000] "GET /page-not-found HTTP/1.1" 404 234 "-" "Mozilla/5.0"
EOF

    # CSV data file for awk practice
    cat > "${USER_PRACTICE}/text/sales.csv" << 'EOF'
date,product,quantity,price,salesperson
2024-01-01,Widget A,10,25.99,Alice
2024-01-01,Widget B,5,45.50,Bob
2024-01-02,Widget A,15,25.99,Charlie
2024-01-02,Widget C,3,99.99,Alice
2024-01-03,Widget B,8,45.50,Bob
2024-01-03,Widget A,20,25.99,Alice
2024-01-04,Widget D,2,149.99,Charlie
2024-01-04,Widget B,12,45.50,Alice
2024-01-05,Widget A,7,25.99,Bob
2024-01-05,Widget C,5,99.99,Charlie
2024-01-06,Widget B,10,45.50,Alice
2024-01-06,Widget D,1,149.99,Bob
2024-01-07,Widget A,25,25.99,Charlie
2024-01-07,Widget C,4,99.99,Alice
EOF

    # Server inventory for processing
    cat > "${USER_PRACTICE}/text/servers.txt" << 'EOF'
hostname        ip_address      os              memory  disk    status
web-01          192.168.1.10    Ubuntu 22.04    16GB    100GB   active
web-02          192.168.1.11    Ubuntu 22.04    16GB    100GB   active
db-01           192.168.1.20    RHEL 8          64GB    500GB   active
db-02           192.168.1.21    RHEL 8          64GB    500GB   standby
app-01          192.168.1.30    Debian 12       32GB    200GB   active
app-02          192.168.1.31    Debian 12       32GB    200GB   active
cache-01        192.168.1.40    Ubuntu 22.04    128GB   50GB    active
backup-01       192.168.1.50    Rocky 9         16GB    2TB     active
monitor-01      192.168.1.60    Fedora 39       8GB     100GB   active
dev-01          192.168.1.70    Ubuntu 22.04    16GB    200GB   maintenance
EOF

    log_success "Text processing files created"
}

# Create grep practice files
create_grep_practice() {
    log_info "Creating grep practice files..."

    local grep_dir="${USER_PRACTICE}/text/grep-practice"

    # File with email addresses
    cat > "${grep_dir}/emails.txt" << 'EOF'
Contact: john.doe@example.com
Sales: sales@company.org
Support: support@example.com
Invalid: not-an-email
Marketing: marketing@company.org
CEO: ceo@bigcorp.com
Test: test.user+tag@example.com
Bad: @missing-local.com
Also bad: noat.sign
Good: user_name@sub.domain.co.uk
EOF

    # File with IP addresses
    cat > "${grep_dir}/ips.txt" << 'EOF'
Server 1: 192.168.1.1
Server 2: 10.0.0.50
Gateway: 192.168.1.254
Invalid: 999.999.999.999
DNS: 8.8.8.8
Also DNS: 8.8.4.4
Localhost: 127.0.0.1
Private: 172.16.0.1
Public: 203.0.113.50
Broadcast: 255.255.255.255
EOF

    # File with phone numbers
    cat > "${grep_dir}/phones.txt" << 'EOF'
Main: (555) 123-4567
Fax: 555-987-6543
Mobile: +1-555-246-8101
International: +44 20 7123 4567
Invalid: 12345
Short: 555-1234
Extensions: (555) 111-2222 x123
Toll-free: 1-800-555-0199
EOF

    # File with mixed content for pattern matching
    cat > "${grep_dir}/patterns.txt" << 'EOF'
Error: Connection timeout at 2024-01-15 08:30:00
Warning: Disk usage at 85%
Info: User login successful
ERROR: Database connection failed
error: file not found
Debug: Processing record 12345
Warning: Memory usage high
Info: Backup completed successfully
Error: Authentication failed for user admin
DEBUG: Variable value = 42
EOF

    log_success "Grep practice files created"
}

# Create sed practice files
create_sed_practice() {
    log_info "Creating sed practice files..."

    local sed_dir="${USER_PRACTICE}/text/sed-practice"

    # Config file for sed editing practice
    cat > "${sed_dir}/config.ini" << 'EOF'
[database]
host = localhost
port = 3306
name = production_db
user = app_user
password = old_password

[cache]
host = localhost
port = 6379
ttl = 3600

[logging]
level = INFO
file = /var/log/app.log
max_size = 100M

[api]
base_url = http://localhost:8080
timeout = 30
retries = 3
EOF

    # HTML file for sed practice
    cat > "${sed_dir}/page.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Old Title</title>
    <meta charset="utf-8">
</head>
<body>
    <h1>Welcome to Our Site</h1>
    <p>This is paragraph one.</p>
    <p>This is paragraph two.</p>
    <a href="http://old-domain.com/page1">Link 1</a>
    <a href="http://old-domain.com/page2">Link 2</a>
    <img src="http://old-domain.com/images/logo.png" alt="Logo">
    <footer>Copyright 2023</footer>
</body>
</html>
EOF

    # Text file with formatting issues
    cat > "${sed_dir}/messy-text.txt" << 'EOF'
This    has    multiple     spaces
And trailing spaces here
   Leading spaces here
Mixed    spacing     throughout
UPPERCASE WORDS NEED FIXING
tabs	between	words	here
Empty lines below


And above
The end.
EOF

    log_success "Sed practice files created"
}

# Create awk practice files
create_awk_practice() {
    log_info "Creating awk practice files..."

    local awk_dir="${USER_PRACTICE}/text/awk-practice"

    # Space-delimited data
    cat > "${awk_dir}/employees.dat" << 'EOF'
EMP001 John Smith Engineering 75000 2020-03-15
EMP002 Jane Doe Marketing 65000 2019-07-22
EMP003 Bob Johnson Sales 70000 2021-01-10
EMP004 Alice Brown Engineering 85000 2018-11-05
EMP005 Charlie Wilson HR 55000 2022-04-01
EMP006 Diana Ross Marketing 72000 2020-08-15
EMP007 Edward King Sales 68000 2019-12-01
EMP008 Fiona Green Engineering 90000 2017-06-20
EMP009 George Hall IT 78000 2021-09-01
EMP010 Helen Clark HR 52000 2023-02-14
EOF

    # Process list simulation
    cat > "${awk_dir}/processes.txt" << 'EOF'
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.1 169532 13284 ?        Ss   Jan14   0:05 /sbin/init
root         2  0.0  0.0      0     0 ?        S    Jan14   0:00 [kthreadd]
root         3  0.0  0.0      0     0 ?        I<   Jan14   0:00 [rcu_gp]
student   1234  2.5  1.2 345678 98765 pts/0    S+   09:00   0:30 /usr/bin/vim
developer 2345  5.0  3.4 567890 276543 pts/1    R    09:15   1:00 python script.py
root      3456  0.2  0.5 234567 43210 ?        Ssl  Jan14   2:30 /usr/sbin/sshd
www-data  4567  1.0  2.1 456789 171234 ?        S    08:00   0:45 nginx: worker
mysql     5678  3.5  8.2 1234567 671234 ?      Sl   Jan14   5:00 /usr/sbin/mysqld
student   6789  0.5  0.8 123456 65432 pts/2    S+   10:00   0:10 bash
EOF

    # Disk usage simulation
    cat > "${awk_dir}/disk-usage.txt" << 'EOF'
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        50G   35G   13G  74% /
/dev/sda2       100G   45G   50G  48% /home
/dev/sdb1       500G  200G  275G  43% /data
tmpfs            16G  1.2G   15G   8% /dev/shm
/dev/sdc1        1T  800G  150G  85% /backup
/dev/nvme0n1p1  250G  100G  138G  43% /opt
EOF

    log_success "Awk practice files created"
}

# Create find practice structure
create_find_practice() {
    log_info "Creating find practice structure..."

    local find_dir="${USER_PRACTICE}/find-practice"

    # Create files with different extensions
    touch "${find_dir}/level1/file1.txt"
    touch "${find_dir}/level1/file2.log"
    touch "${find_dir}/level1/script1.sh"
    touch "${find_dir}/level1/level2/file3.txt"
    touch "${find_dir}/level1/level2/file4.conf"
    touch "${find_dir}/level1/level2/level3/deep-file.txt"
    touch "${find_dir}/level1/level2/other/other-file.dat"
    touch "${find_dir}/level1/backup/backup-2024-01-15.tar.gz"
    touch "${find_dir}/temp/temp-file.tmp"

    # Create files with different sizes
    dd if=/dev/zero of="${find_dir}/level1/small.bin" bs=1K count=10 2>/dev/null
    dd if=/dev/zero of="${find_dir}/level1/medium.bin" bs=1K count=100 2>/dev/null
    dd if=/dev/zero of="${find_dir}/level1/large.bin" bs=1M count=5 2>/dev/null

    # Create files with different permissions
    chmod 755 "${find_dir}/level1/script1.sh"
    chmod 644 "${find_dir}/level1/file1.txt"
    chmod 600 "${find_dir}/level1/level2/file4.conf"

    # Set SUID/SGID for practice (on a dummy file)
    chmod 4755 "${find_dir}/level1/script1.sh"  # SUID

    # Create files with different timestamps
    touch -d "2024-01-01" "${find_dir}/level1/backup/backup-2024-01-15.tar.gz"
    touch -d "7 days ago" "${find_dir}/temp/temp-file.tmp"

    # Create some hidden files
    touch "${find_dir}/level1/.hidden-file"
    touch "${find_dir}/level1/level2/.another-hidden"

    log_success "Find practice structure created"
}

# Create permission practice files
create_permission_practice() {
    log_info "Creating permission practice files..."

    local perm_dir="${USER_PRACTICE}/permissions-lab"

    # Create files with various permissions for practice
    touch "${perm_dir}/public-read.txt"
    touch "${perm_dir}/private.txt"
    touch "${perm_dir}/shared.txt"
    touch "${perm_dir}/executable.sh"

    echo "This is public content" > "${perm_dir}/public-read.txt"
    echo "This is private content" > "${perm_dir}/private.txt"
    echo "This is shared content" > "${perm_dir}/shared.txt"
    cat > "${perm_dir}/executable.sh" << 'EOF'
#!/bin/bash
echo "Hello from executable script!"
EOF

    chmod 644 "${perm_dir}/public-read.txt"
    chmod 600 "${perm_dir}/private.txt"
    chmod 664 "${perm_dir}/shared.txt"
    chmod 755 "${perm_dir}/executable.sh"

    # Create directory structure for permission testing
    mkdir -p "${perm_dir}/team-project"
    touch "${perm_dir}/team-project/README.md"
    chmod 775 "${perm_dir}/team-project"
    chmod 664 "${perm_dir}/team-project/README.md"

    log_success "Permission practice files created"
}

# Create compression practice files
create_compression_practice() {
    log_info "Creating compression practice files..."

    local comp_dir="${USER_PRACTICE}/compression"

    # Create sample data for compression
    for i in {1..5}; do
        cat > "${comp_dir}/data-file-${i}.txt" << EOF
This is data file number ${i}.
It contains some sample text for compression testing.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Line number: $(seq 1 100 | tr '\n' ' ')
EOF
    done

    # Create a directory to archive
    mkdir -p "${comp_dir}/archive-me"
    cp "${comp_dir}"/data-file-*.txt "${comp_dir}/archive-me/"

    log_success "Compression practice files created"
}

# Create sample config files
create_config_examples() {
    log_info "Creating sample config files..."

    local config_dir="${USER_PRACTICE}/configs"

    # Sample crontab
    cat > "${config_dir}/sample-crontab" << 'EOF'
# Sample crontab for practice
# minute hour day month weekday command

# Run backup every day at 2:30 AM
30 2 * * * /opt/scripts/backup.sh

# Check disk space every hour
0 * * * * /opt/scripts/check_disk.sh

# Monthly report on first day at midnight
0 0 1 * * /opt/scripts/monthly_report.sh

# Weekday log rotation at 4 AM
0 4 * * 1-5 /usr/sbin/logrotate /etc/logrotate.conf

# Every 15 minutes during business hours
*/15 9-17 * * 1-5 /opt/scripts/health_check.sh
EOF

    # Sample rsyslog config
    cat > "${config_dir}/sample-rsyslog.conf" << 'EOF'
# Sample rsyslog configuration

# Log all kernel messages
kern.*                          /var/log/kern.log

# Log all auth messages
auth,authpriv.*                 /var/log/auth.log

# Log all mail messages
mail.*                          /var/log/mail.log

# Emergency messages to all users
*.emerg                         :omusrmsg:*

# Save boot messages
local7.*                        /var/log/boot.log
EOF

    # Sample sudoers snippet
    cat > "${config_dir}/sample-sudoers" << 'EOF'
# Sample sudoers configuration (DO NOT use directly)

# User alias definitions
User_Alias ADMINS = alice, bob, charlie
User_Alias DEVELOPERS = dev1, dev2, dev3

# Command alias definitions
Cmnd_Alias SERVICES = /bin/systemctl start *, /bin/systemctl stop *, /bin/systemctl restart *
Cmnd_Alias NETWORK = /sbin/ifconfig, /sbin/route, /sbin/ip

# User privilege specification
root    ALL=(ALL:ALL) ALL
%admin  ALL=(ALL) ALL
%sudo   ALL=(ALL:ALL) ALL

# Allow admins to manage services without password
ADMINS  ALL = NOPASSWD: SERVICES

# Allow developers to run specific commands
DEVELOPERS ALL = NETWORK
EOF

    log_success "Sample config files created"
}

# Main execution
main() {
    log_info "LPIC-1 Practice Data Seeder"
    log_info "==========================="
    echo

    if [[ "$RESET" == true ]]; then
        log_info "Resetting practice data..."
        rm -rf "${USER_PRACTICE:?}"/*
    fi

    setup_directories
    create_text_files
    create_grep_practice
    create_sed_practice
    create_awk_practice
    create_find_practice
    create_permission_practice
    create_compression_practice
    create_config_examples

    echo
    log_success "==========================="
    log_success "Practice Data Setup Complete"
    log_success "==========================="
    echo
    log_info "Practice files location: ${USER_PRACTICE}"
    echo
    log_info "Contents:"
    tree -L 2 "${USER_PRACTICE}" 2>/dev/null || find "${USER_PRACTICE}" -maxdepth 2 -type d
    echo
    log_info "Ready for grep, sed, awk, find, and other exercises!"
}

main
