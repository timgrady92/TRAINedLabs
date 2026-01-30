#!/bin/bash
# LPIC-1 Training - Progress Database Initialization
# Creates SQLite database for tracking training progress
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
LPIC_DIR="${HOME}/.lpic1"
DB_FILE="${LPIC_DIR}/progress.db"
SNAPSHOT_DIR="${LPIC_DIR}/snapshots"

# Check for sqlite3
if ! command -v sqlite3 &>/dev/null; then
    log_error "sqlite3 is required but not installed"
    log_info "Install with: sudo dnf install sqlite  OR  sudo apt install sqlite3"
    exit 1
fi

# Create directory structure
log_info "Creating LPIC-1 training directory structure..."
mkdir -p "$LPIC_DIR"
mkdir -p "$SNAPSHOT_DIR"

# Check if database already exists
if [[ -f "$DB_FILE" ]]; then
    log_warn "Database already exists at $DB_FILE"
    if [[ -t 0 ]]; then
        read -p "Reset database? This will erase all progress! [y/N] " -n 1 -r
        echo
    else
        # Non-interactive mode (e.g., piped or SSH without TTY) - keep existing
        log_info "Non-interactive mode: keeping existing database"
        REPLY="n"
    fi
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Keeping existing database"
        exit 0
    fi
    rm -f "$DB_FILE"
fi

# Create database schema
log_info "Creating database schema..."

sqlite3 "$DB_FILE" << 'SQL'
-- LPIC-1 Training Progress Database Schema

-- Objectives table (all 34 objectives)
CREATE TABLE objectives (
    id TEXT PRIMARY KEY,
    topic TEXT NOT NULL,
    number TEXT NOT NULL,
    title TEXT NOT NULL,
    weight INTEGER NOT NULL,
    completed INTEGER DEFAULT 0,
    completed_at TEXT,
    notes TEXT
);

-- Skills within objectives
CREATE TABLE skills (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    objective_id TEXT NOT NULL,
    skill_name TEXT NOT NULL,
    verified INTEGER DEFAULT 0,
    verified_at TEXT,
    FOREIGN KEY (objective_id) REFERENCES objectives(id)
);

-- Commands proficiency tracking
CREATE TABLE commands (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    command TEXT UNIQUE NOT NULL,
    objective_id TEXT,
    attempts INTEGER DEFAULT 0,
    successes INTEGER DEFAULT 0,
    last_practiced TEXT,
    proficiency_level TEXT DEFAULT 'novice',
    FOREIGN KEY (objective_id) REFERENCES objectives(id)
);

-- Lab completion tracking
CREATE TABLE labs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lab_id TEXT UNIQUE NOT NULL,
    objective_id TEXT,
    started_at TEXT,
    completed_at TEXT,
    hints_used INTEGER DEFAULT 0,
    time_taken_seconds INTEGER,
    score INTEGER,
    FOREIGN KEY (objective_id) REFERENCES objectives(id)
);

-- Scenario attempts
CREATE TABLE scenarios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scenario_id TEXT NOT NULL,
    scenario_type TEXT NOT NULL,
    started_at TEXT,
    completed_at TEXT,
    success INTEGER DEFAULT 0,
    hints_used INTEGER DEFAULT 0,
    time_taken_seconds INTEGER,
    difficulty TEXT
);

-- Daily practice sessions
CREATE TABLE sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    started_at TEXT NOT NULL,
    ended_at TEXT,
    objectives_practiced TEXT,
    commands_practiced TEXT,
    total_time_seconds INTEGER
);

-- Exam simulation results
CREATE TABLE exam_attempts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    exam_type TEXT NOT NULL,
    started_at TEXT NOT NULL,
    completed_at TEXT,
    score INTEGER,
    total_questions INTEGER,
    correct_answers INTEGER,
    time_taken_seconds INTEGER
);

-- Insert all LPIC-1 objectives (101 exam)
INSERT INTO objectives (id, topic, number, title, weight) VALUES
-- Topic 101: System Architecture
('101.1', '101', '101.1', 'Determine and configure hardware settings', 2),
('101.2', '101', '101.2', 'Boot the system', 3),
('101.3', '101', '101.3', 'Change runlevels / boot targets and shutdown or reboot system', 3),

-- Topic 102: Linux Installation and Package Management
('102.1', '102', '102.1', 'Design hard disk layout', 2),
('102.2', '102', '102.2', 'Install a boot manager', 2),
('102.3', '102', '102.3', 'Manage shared libraries', 1),
('102.4', '102', '102.4', 'Use Debian package management', 3),
('102.5', '102', '102.5', 'Use RPM and YUM package management', 3),
('102.6', '102', '102.6', 'Linux as a virtualization guest', 1),

-- Topic 103: GNU and Unix Commands
('103.1', '103', '103.1', 'Work on the command line', 4),
('103.2', '103', '103.2', 'Process text streams using filters', 2),
('103.3', '103', '103.3', 'Perform basic file management', 4),
('103.4', '103', '103.4', 'Use streams, pipes and redirects', 4),
('103.5', '103', '103.5', 'Create, monitor and kill processes', 4),
('103.6', '103', '103.6', 'Modify process execution priorities', 2),
('103.7', '103', '103.7', 'Search text files using regular expressions', 3),
('103.8', '103', '103.8', 'Basic file editing', 3),

-- Topic 104: Devices, Linux Filesystems, FHS
('104.1', '104', '104.1', 'Create partitions and filesystems', 2),
('104.2', '104', '104.2', 'Maintain the integrity of filesystems', 2),
('104.3', '104', '104.3', 'Control mounting and unmounting of filesystems', 3),
('104.5', '104', '104.5', 'Manage file permissions and ownership', 3),
('104.6', '104', '104.6', 'Create and change hard and symbolic links', 2),
('104.7', '104', '104.7', 'Find system files and place files in the correct location', 2);

-- Insert LPIC-1 objectives (102 exam)
INSERT INTO objectives (id, topic, number, title, weight) VALUES
-- Topic 105: Shells and Shell Scripting
('105.1', '105', '105.1', 'Customize and use the shell environment', 4),
('105.2', '105', '105.2', 'Customize or write simple scripts', 4),

-- Topic 106: User Interfaces and Desktops
('106.1', '106', '106.1', 'Install and configure X11', 2),
('106.2', '106', '106.2', 'Graphical desktops', 1),
('106.3', '106', '106.3', 'Accessibility', 1),

-- Topic 107: Administrative Tasks
('107.1', '107', '107.1', 'Manage user and group accounts and related system files', 5),
('107.2', '107', '107.2', 'Automate system administration tasks by scheduling jobs', 4),
('107.3', '107', '107.3', 'Localisation and internationalisation', 3),

-- Topic 108: Essential System Services
('108.1', '108', '108.1', 'Maintain system time', 3),
('108.2', '108', '108.2', 'System logging', 4),
('108.3', '108', '108.3', 'Mail Transfer Agent (MTA) basics', 3),
('108.4', '108', '108.4', 'Manage printers and printing', 2),

-- Topic 109: Networking Fundamentals
('109.1', '109', '109.1', 'Fundamentals of internet protocols', 4),
('109.2', '109', '109.2', 'Persistent network configuration', 4),
('109.3', '109', '109.3', 'Basic network troubleshooting', 4),
('109.4', '109', '109.4', 'Configure client side DNS', 2),

-- Topic 110: Security
('110.1', '110', '110.1', 'Perform security administration tasks', 3),
('110.2', '110', '110.2', 'Setup host security', 3),
('110.3', '110', '110.3', 'Securing data with encryption', 4);

-- Insert key commands for each objective
INSERT INTO commands (command, objective_id) VALUES
-- 101.1 Hardware
('lspci', '101.1'), ('lsusb', '101.1'), ('lsmod', '101.1'),
('modprobe', '101.1'), ('modinfo', '101.1'), ('rmmod', '101.1'),
('lsblk', '101.1'), ('dmesg', '101.1'),

-- 101.2 Boot
('dmesg', '101.2'), ('journalctl', '101.2'),

-- 101.3 Runlevels
('systemctl', '101.3'), ('init', '101.3'), ('shutdown', '101.3'),
('reboot', '101.3'), ('poweroff', '101.3'), ('halt', '101.3'),
('telinit', '101.3'),

-- 102.4 Debian packages
('dpkg', '102.4'), ('apt', '102.4'), ('apt-get', '102.4'),
('apt-cache', '102.4'), ('aptitude', '102.4'),

-- 102.5 RPM packages
('rpm', '102.5'), ('yum', '102.5'), ('dnf', '102.5'),
('zypper', '102.5'),

-- 103.1 Command line
('bash', '103.1'), ('echo', '103.1'), ('env', '103.1'),
('export', '103.1'), ('pwd', '103.1'), ('set', '103.1'),
('unset', '103.1'), ('type', '103.1'), ('which', '103.1'),
('man', '103.1'), ('uname', '103.1'), ('history', '103.1'),

-- 103.2 Text processing
('cat', '103.2'), ('cut', '103.2'), ('expand', '103.2'),
('fmt', '103.2'), ('head', '103.2'), ('join', '103.2'),
('less', '103.2'), ('nl', '103.2'), ('od', '103.2'),
('paste', '103.2'), ('pr', '103.2'), ('sed', '103.2'),
('sort', '103.2'), ('split', '103.2'), ('tail', '103.2'),
('tr', '103.2'), ('unexpand', '103.2'), ('uniq', '103.2'),
('wc', '103.2'),

-- 103.3 File management
('cp', '103.3'), ('find', '103.3'), ('mkdir', '103.3'),
('mv', '103.3'), ('ls', '103.3'), ('rm', '103.3'),
('rmdir', '103.3'), ('touch', '103.3'), ('tar', '103.3'),
('cpio', '103.3'), ('dd', '103.3'), ('file', '103.3'),
('gzip', '103.3'), ('gunzip', '103.3'), ('bzip2', '103.3'),
('bunzip2', '103.3'), ('xz', '103.3'), ('unxz', '103.3'),

-- 103.4 Streams and pipes
('tee', '103.4'), ('xargs', '103.4'),

-- 103.5 Process management
('ps', '103.5'), ('top', '103.5'), ('free', '103.5'),
('uptime', '103.5'), ('pgrep', '103.5'), ('pkill', '103.5'),
('kill', '103.5'), ('killall', '103.5'), ('watch', '103.5'),
('screen', '103.5'), ('tmux', '103.5'), ('nohup', '103.5'),
('bg', '103.5'), ('fg', '103.5'), ('jobs', '103.5'),

-- 103.6 Process priorities
('nice', '103.6'), ('renice', '103.6'),

-- 103.7 Regular expressions
('grep', '103.7'), ('egrep', '103.7'), ('fgrep', '103.7'),

-- 103.8 File editing
('vi', '103.8'), ('vim', '103.8'),

-- 104.1 Partitions and filesystems
('fdisk', '104.1'), ('gdisk', '104.1'), ('parted', '104.1'),
('mkfs', '104.1'), ('mkswap', '104.1'),

-- 104.2 Filesystem integrity
('fsck', '104.2'), ('e2fsck', '104.2'), ('mke2fs', '104.2'),
('tune2fs', '104.2'), ('xfs_repair', '104.2'), ('xfs_db', '104.2'),
('dumpe2fs', '104.2'),

-- 104.3 Mounting
('mount', '104.3'), ('umount', '104.3'), ('blkid', '104.3'),
('lsblk', '104.3'), ('findmnt', '104.3'),

-- 104.5 Permissions
('chmod', '104.5'), ('chown', '104.5'), ('chgrp', '104.5'),
('umask', '104.5'),

-- 104.6 Links
('ln', '104.6'),

-- 104.7 Find files
('find', '104.7'), ('locate', '104.7'), ('updatedb', '104.7'),
('whereis', '104.7'), ('which', '104.7'), ('type', '104.7'),

-- 105.1 Shell environment
('source', '105.1'), ('alias', '105.1'), ('unalias', '105.1'),
('function', '105.1'),

-- 105.2 Scripting
('test', '105.2'), ('exec', '105.2'), ('read', '105.2'),

-- 106.1 X11
('xhost', '106.1'), ('xauth', '106.1'), ('xdpyinfo', '106.1'),
('Xorg', '106.1'), ('xinit', '106.1'), ('startx', '106.1'),

-- 107.1 User management
('useradd', '107.1'), ('usermod', '107.1'), ('userdel', '107.1'),
('groupadd', '107.1'), ('groupmod', '107.1'), ('groupdel', '107.1'),
('passwd', '107.1'), ('chage', '107.1'), ('getent', '107.1'),

-- 107.2 Scheduling
('crontab', '107.2'), ('at', '107.2'), ('atq', '107.2'),
('atrm', '107.2'), ('anacron', '107.2'),

-- 107.3 Localization
('locale', '107.3'), ('localectl', '107.3'), ('timedatectl', '107.3'),
('iconv', '107.3'),

-- 108.1 System time
('date', '108.1'), ('hwclock', '108.1'), ('timedatectl', '108.1'),
('ntpq', '108.1'), ('chronyc', '108.1'),

-- 108.2 Logging
('logger', '108.2'), ('logrotate', '108.2'),

-- 108.3 MTA
('mail', '108.3'), ('mailq', '108.3'), ('sendmail', '108.3'),

-- 108.4 Printing
('lp', '108.4'), ('lpr', '108.4'), ('lpq', '108.4'),
('lprm', '108.4'), ('lpstat', '108.4'), ('lpadmin', '108.4'),
('cupsctl', '108.4'),

-- 109.1 IP fundamentals
('ip', '109.1'),

-- 109.2 Network config
('ip', '109.2'), ('nmcli', '109.2'), ('hostnamectl', '109.2'),

-- 109.3 Network troubleshooting
('ping', '109.3'), ('traceroute', '109.3'), ('tracepath', '109.3'),
('mtr', '109.3'), ('ss', '109.3'), ('netstat', '109.3'),
('nc', '109.3'),

-- 109.4 DNS
('dig', '109.4'), ('nslookup', '109.4'), ('host', '109.4'),
('getent', '109.4'),

-- 110.1 Security admin
('find', '110.1'), ('passwd', '110.1'), ('fuser', '110.1'),
('lsof', '110.1'), ('nmap', '110.1'), ('chage', '110.1'),
('sudo', '110.1'), ('su', '110.1'), ('usermod', '110.1'),
('ulimit', '110.1'),

-- 110.2 Host security
('chattr', '110.2'), ('lsattr', '110.2'), ('netstat', '110.2'),
('nmap', '110.2'),

-- 110.3 Encryption
('ssh', '110.3'), ('ssh-keygen', '110.3'), ('ssh-agent', '110.3'),
('ssh-add', '110.3'), ('scp', '110.3'), ('gpg', '110.3');

-- Create indexes for performance
CREATE INDEX idx_skills_objective ON skills(objective_id);
CREATE INDEX idx_commands_objective ON commands(objective_id);
CREATE INDEX idx_labs_objective ON labs(objective_id);
CREATE INDEX idx_scenarios_type ON scenarios(scenario_type);

-- Create views for easy querying
CREATE VIEW objective_progress AS
SELECT
    o.topic,
    o.number,
    o.title,
    o.weight,
    CASE WHEN o.completed = 1 THEN 'Completed' ELSE 'In Progress' END as status,
    (SELECT COUNT(*) FROM skills s WHERE s.objective_id = o.id AND s.verified = 1) as skills_verified,
    (SELECT COUNT(*) FROM skills s WHERE s.objective_id = o.id) as total_skills,
    (SELECT COUNT(*) FROM commands c WHERE c.objective_id = o.id AND c.proficiency_level != 'novice') as commands_practiced
FROM objectives o
ORDER BY o.topic, o.number;

CREATE VIEW topic_summary AS
SELECT
    topic,
    COUNT(*) as total_objectives,
    SUM(completed) as completed_objectives,
    SUM(weight) as total_weight,
    ROUND(100.0 * SUM(completed) / COUNT(*), 1) as completion_percent
FROM objectives
GROUP BY topic
ORDER BY topic;

SQL

log_success "Database created at $DB_FILE"

# Display summary
echo
log_info "Database Summary:"
sqlite3 "$DB_FILE" << 'SQL'
.mode column
.headers on
SELECT 'Objectives' as table_name, COUNT(*) as count FROM objectives
UNION ALL
SELECT 'Commands', COUNT(*) FROM commands
UNION ALL
SELECT 'Topics', COUNT(DISTINCT topic) FROM objectives;
SQL

echo
log_success "Progress tracking initialized!"
log_info "View progress with: ./lpic-check progress"
log_info "Data directory: $LPIC_DIR"
