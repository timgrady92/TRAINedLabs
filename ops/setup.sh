#!/bin/bash
# LPIC-1 Training Platform - Hospital Deployment Installer
#
# Single-script deployment for Ubuntu/Debian and Fedora/RHEL
# Creates training user, installs platform, and sets up practice filesystems
#
# Usage: sudo ./setup.sh [options]
#   --user USERNAME     Training user (default: student)
#   --password PASS     Initial password (default: training123)
#   --skip-filesystems  Skip practice filesystem setup
#   --verify            Run verification only (no install)
#   --uninstall         Remove LPIC-1 environment
#   --help              Show this help

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
VERSION="2.0.0"
INSTALL_DIR="/opt/LPIC-1"
PRACTICE_DIR="/opt/lpic1-practice"
MOUNT_BASE="/mnt/lpic1"
LOG_FILE="/var/log/lpic1-install.log"
SOURCE_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"

# Defaults
DEFAULT_USER="student"
DEFAULT_PASSWORD="training123"
TARGET_USER="$DEFAULT_USER"
TARGET_PASSWORD="$DEFAULT_PASSWORD"
TARGET_HOME=""  # Set in setup_user()
SKIP_FILESYSTEMS=false
VERIFY_ONLY=false
UNINSTALL=false
PKG_MGR=""
OS_FAMILY=""
OS_NAME=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ============================================================================
# Logging Functions
# ============================================================================
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$LOG_FILE" 2>/dev/null || true
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] OK: $1" >> "$LOG_FILE" 2>/dev/null || true
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $1" >> "$LOG_FILE" 2>/dev/null || true
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE" 2>/dev/null || true
}

log_step() {
    echo -e "\n${BOLD}${BLUE}═══ $1 ═══${NC}\n"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP: $1" >> "$LOG_FILE" 2>/dev/null || true
}

# ============================================================================
# Help Function
# ============================================================================
show_help() {
    cat << EOF
LPIC-1 Training Platform - Hospital Deployment Installer v${VERSION}

Usage: sudo $0 [options]

Options:
  --user USERNAME     Training user account (default: ${DEFAULT_USER})
  --password PASS     Initial password (default: ${DEFAULT_PASSWORD})
  --skip-filesystems  Skip practice filesystem setup
  --verify            Run verification only (no install)
  --uninstall         Remove LPIC-1 environment
  --help              Show this help

Examples:
  # Standard installation (creates 'student' user with default password)
  sudo ./setup.sh

  # Custom user and password
  sudo ./setup.sh --user trainee --password SecurePass123

  # Install without practice filesystems
  sudo ./setup.sh --skip-filesystems

  # Verify existing installation
  sudo ./setup.sh --verify

  # Remove installation
  sudo ./setup.sh --uninstall

After installation:
  1. Reboot the system
  2. Log in as the training user
  3. Type 'lpic1' to start training

Log file: ${LOG_FILE}
EOF
    exit 0
}

# ============================================================================
# Argument Parsing
# ============================================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --user)
                TARGET_USER="${2:-}"
                if [[ -z "$TARGET_USER" ]]; then
                    log_error "--user requires a username"
                    exit 1
                fi
                shift 2
                ;;
            --password)
                TARGET_PASSWORD="${2:-}"
                if [[ -z "$TARGET_PASSWORD" ]]; then
                    log_error "--password requires a password"
                    exit 1
                fi
                shift 2
                ;;
            --skip-filesystems)
                SKIP_FILESYSTEMS=true
                shift
                ;;
            --verify)
                VERIFY_ONLY=true
                shift
                ;;
            --uninstall)
                UNINSTALL=true
                shift
                ;;
            --help|-h)
                show_help
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# Pre-flight Checks
# ============================================================================
preflight_checks() {
    log_step "Pre-flight Checks"
    local failed=0

    # Check root/sudo
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
    log_success "Running as root"

    # Detect OS and package manager
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_NAME="${PRETTY_NAME:-unknown}"
        if command -v apt-get &>/dev/null; then
            PKG_MGR="apt"
            OS_FAMILY="debian"
        elif command -v dnf &>/dev/null; then
            PKG_MGR="dnf"
            OS_FAMILY="fedora"
        fi
    fi

    if [[ -n "$OS_NAME" ]]; then
        log_success "OS: $OS_NAME"
    else
        log_warn "OS: unknown"
    fi

    if [[ -z "$PKG_MGR" ]]; then
        log_error "No supported package manager found (apt or dnf required)"
        exit 1
    fi

    # Check disk space (need at least 5GB free)
    local free_space
    free_space=$(df -BG / | awk 'NR==2 {gsub("G","",$4); print $4}')
    if [[ "$free_space" -lt 5 ]]; then
        log_error "Insufficient disk space: ${free_space}GB free, need at least 5GB"
        failed=1
    else
        log_success "Disk space: ${free_space}GB free"
    fi

    # Check network connectivity (for package downloads)
    if ping -c 1 -W 5 archive.ubuntu.com &>/dev/null || ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
        log_success "Network connectivity: OK"
    else
        log_warn "Network connectivity: Cannot reach package servers (offline install may work)"
    fi

    # Check kernel loop device support
    if [[ -e /dev/loop-control ]] || modprobe loop 2>/dev/null; then
        log_success "Kernel loop device support: OK"
    else
        log_warn "Loop device support may be limited"
    fi

    # Check if source files exist
    if [[ ! -f "$SOURCE_DIR/bin/lpic1" ]]; then
        log_error "Source files not found. Run this script from the LPIC-1 repository directory."
        failed=1
    else
        log_success "Source files found in $SOURCE_DIR"
    fi

    if [[ $failed -eq 1 ]]; then
        log_error "Pre-flight checks failed. Please resolve issues and try again."
        exit 1
    fi

    log_success "All pre-flight checks passed"
}

# ============================================================================
# User Setup
# ============================================================================
setup_user() {
    log_step "User Setup"

    local user_created=false

    # Check if user exists
    if id "$TARGET_USER" &>/dev/null; then
        log_info "User '$TARGET_USER' already exists"
        TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    else
        log_info "Creating user '$TARGET_USER'..."

        # Create user with home directory
        if ! useradd -m -s /bin/bash -c "LPIC-1 Training User" "$TARGET_USER"; then
            log_error "Failed to create user '$TARGET_USER'"
            exit 1
        fi

        TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
        user_created=true
        log_success "User '$TARGET_USER' created with home directory $TARGET_HOME"
    fi

    # Set password only if we created the user, or if password was explicitly provided
    if [[ "$user_created" == true ]] || [[ "$TARGET_PASSWORD" != "$DEFAULT_PASSWORD" ]]; then
        log_info "Setting password for '$TARGET_USER'..."
        if echo "${TARGET_USER}:${TARGET_PASSWORD}" | chpasswd; then
            log_success "Password set for '$TARGET_USER'"
        else
            log_error "Failed to set password for '$TARGET_USER'"
            exit 1
        fi
    else
        log_info "User already exists, keeping existing password (use --password to change)"
    fi

    # Add to admin group
    local admin_group="sudo"
    if [[ "$PKG_MGR" == "dnf" ]]; then
        admin_group="wheel"
    fi
    if ! groups "$TARGET_USER" | grep -qw "$admin_group"; then
        log_info "Adding '$TARGET_USER' to ${admin_group} group..."
        if usermod -aG "$admin_group" "$TARGET_USER"; then
            log_success "User '$TARGET_USER' added to ${admin_group} group"
        else
            log_warn "Failed to add user to ${admin_group} group (may need manual setup)"
        fi
    else
        log_success "User '$TARGET_USER' already in ${admin_group} group"
    fi

    # Ensure home directory has correct permissions
    if [[ -d "$TARGET_HOME" ]]; then
        chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME"
        chmod 755 "$TARGET_HOME"
        log_success "Home directory permissions set"
    fi
}

# ============================================================================
# Package Installation
# ============================================================================
install_packages() {
    log_step "Installing Required Packages"

    log_info "Updating package lists..."
    if [[ "$PKG_MGR" == "apt" ]]; then
        if ! apt-get update -qq 2>&1 | tee -a "$LOG_FILE"; then
            log_warn "Package list update had issues, continuing..."
        fi
    else
        if ! dnf makecache -q 2>&1 | tee -a "$LOG_FILE"; then
            log_warn "Package cache update had issues, continuing..."
        fi
    fi

    local PACKAGES=()
    if [[ "$PKG_MGR" == "apt" ]]; then
        PACKAGES=(\
            sqlite3 \
            grep sed gawk \
            findutils tar gzip bzip2 xz-utils \
            procps psmisc \
            passwd \
            util-linux e2fsprogs xfsprogs btrfs-progs lvm2 dosfstools quota \
            iproute2 iputils-ping dnsutils traceroute netcat-openbsd \
            systemd chrony cups \
            openssh-client sudo gnupg iptables \
            vim nano \
            man-db manpages bash-completion tree \
            python3 python3-pip \
        )
    else
        PACKAGES=(\
            sqlite \
            grep sed gawk \
            findutils tar gzip bzip2 xz \
            procps-ng psmisc \
            shadow-utils \
            util-linux e2fsprogs xfsprogs btrfs-progs lvm2 dosfstools quota \
            iproute iputils bind-utils traceroute nmap-ncat \
            systemd chrony cups \
            openssh sudo gnupg2 iptables \
            vim-enhanced nano \
            man-db man-pages bash-completion tree \
            python3 python3-pip \
        )
    fi

    local failed_packages=()
    local installed_packages=()

    log_info "Installing ${#PACKAGES[@]} packages..."

    for pkg in "${PACKAGES[@]}"; do
        if [[ "$PKG_MGR" == "apt" ]]; then
            if dpkg -s "$pkg" &>/dev/null; then
                installed_packages+=("$pkg")
                continue
            fi
            if apt-get install -y -qq "$pkg" >> "$LOG_FILE" 2>&1; then
                installed_packages+=("$pkg")
            else
                failed_packages+=("$pkg")
                log_warn "Failed to install: $pkg"
            fi
        else
            if rpm -q "$pkg" &>/dev/null; then
                installed_packages+=("$pkg")
                continue
            fi
            if dnf install -y -q "$pkg" >> "$LOG_FILE" 2>&1; then
                installed_packages+=("$pkg")
            else
                failed_packages+=("$pkg")
                log_warn "Failed to install: $pkg"
            fi
        fi
    done

    log_success "Installed ${#installed_packages[@]} packages"

    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_warn "Failed packages (${#failed_packages[@]}): ${failed_packages[*]}"
        echo "Failed packages: ${failed_packages[*]}" >> "$LOG_FILE"
    fi

    log_info "Verifying critical commands..."
    local critical_commands=("sqlite3" "grep" "sed" "awk" "tar" "vim" "systemctl" "mount" "python3")
    local missing_commands=()

    for cmd in "${critical_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_commands+=("$cmd")
        fi
    done

    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing critical commands: ${missing_commands[*]}"
        log_error "Installation cannot continue. Please install these manually."
        exit 1
    fi

    log_success "All critical commands available"

    log_info "Installing Textual UI (pip)..."
    if python3 -c "import textual" &>/dev/null; then
        log_success "Textual already installed"
    else
        if python3 -m pip install --quiet textual >> "$LOG_FILE" 2>&1; then
            log_success "Textual installed"
        else
            log_warn "Textual install failed (pip). UI will require manual install."
        fi
    fi
}

# ============================================================================
# Training Platform Installation
# ============================================================================
install_platform() {
    log_step "Installing Training Platform"

    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    log_info "Installing to $INSTALL_DIR..."

    # Copy training files (check existence first to provide clear errors)
    local required_dirs=("core" "content" "apps" "bin")
    local optional_dirs=("docs" "ops" "skills")

    for dir in "${required_dirs[@]}"; do
        if [[ -d "$SOURCE_DIR/$dir" ]]; then
            cp -r "$SOURCE_DIR/$dir" "$INSTALL_DIR/"
        else
            log_error "Required directory not found: $SOURCE_DIR/$dir"
            exit 1
        fi
    done

    for dir in "${optional_dirs[@]}"; do
        if [[ -d "$SOURCE_DIR/$dir" ]]; then
            cp -r "$SOURCE_DIR/$dir" "$INSTALL_DIR/"
        else
            log_warn "Optional directory not found: $SOURCE_DIR/$dir (skipping)"
        fi
    done

    # Copy uninstall script if it exists
    [[ -f "$SOURCE_DIR/ops/uninstall.sh" ]] && cp "$SOURCE_DIR/ops/uninstall.sh" "$INSTALL_DIR/ops/uninstall.sh"

    log_success "Training files copied"

    # Make scripts executable
    find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \;
    chmod +x "$INSTALL_DIR/bin/lpic1"
    chmod +x "$INSTALL_DIR/core/lpic-train" 2>/dev/null || true
    chmod +x "$INSTALL_DIR/core/lpic-check" 2>/dev/null || true
    log_success "Scripts made executable"

    # Create command symlink
    ln -sf "$INSTALL_DIR/bin/lpic1" /usr/local/bin/lpic1
    log_success "Created /usr/local/bin/lpic1 symlink"

    # Create data and practice directories
    mkdir -p "$INSTALL_DIR/data"
    mkdir -p "$INSTALL_DIR/data/snapshots"
    mkdir -p "$INSTALL_DIR/practice"
    chmod 755 "$INSTALL_DIR/data" "$INSTALL_DIR/practice"
    log_success "Created data and practice directories"
}

# ============================================================================
# User Environment Initialization
# ============================================================================
init_user_environment() {
    log_step "Setting Up User Environment"

    # Migrate existing user data if present (from old ~/.lpic1 location)
    if [[ -f "${TARGET_HOME}/.lpic1/progress.db" ]] && [[ ! -f "$INSTALL_DIR/data/progress.db" ]]; then
        log_info "Migrating existing progress data from ${TARGET_HOME}/.lpic1..."
        cp "${TARGET_HOME}/.lpic1/progress.db" "$INSTALL_DIR/data/"
        if [[ -d "${TARGET_HOME}/.lpic1/snapshots" ]]; then
            cp -r "${TARGET_HOME}/.lpic1/snapshots"/* "$INSTALL_DIR/data/snapshots/" 2>/dev/null || true
        fi
        log_success "Progress data migrated"
        log_info "Old data directory ${TARGET_HOME}/.lpic1 can be removed manually"
    fi

    # Initialize progress database (data goes to /opt/LPIC-1/data)
    log_info "Initializing progress tracking..."
    if [[ -f "$INSTALL_DIR/core/init-progress.sh" ]]; then
        bash "$INSTALL_DIR/core/init-progress.sh" </dev/null 2>&1 | tee -a "$LOG_FILE" || {
            log_warn "Progress initialization had issues, will initialize on first run"
        }
    fi
    log_success "Progress database initialized at $INSTALL_DIR/data/"

    # Create practice files (data goes to /opt/LPIC-1/practice)
    log_info "Creating practice files..."
    if [[ -f "$INSTALL_DIR/content/environment/seed-data.sh" ]]; then
        bash "$INSTALL_DIR/content/environment/seed-data.sh" 2>&1 | tee -a "$LOG_FILE" || {
            log_warn "Practice file creation had issues"
        }
    fi
    log_success "Practice files created at $INSTALL_DIR/practice/"

    # Set appropriate permissions for data directory (allow all users to write)
    chmod 777 "$INSTALL_DIR/data"
    chmod 666 "$INSTALL_DIR/data/progress.db" 2>/dev/null || true
    chmod 777 "$INSTALL_DIR/data/snapshots"
    chmod 755 "$INSTALL_DIR/practice"
    log_success "Permissions set for shared access"
}

# ============================================================================
# Practice Filesystems with systemd Persistence
# ============================================================================
setup_practice_filesystems() {
    log_step "Setting Up Practice Filesystems"

    if [[ "$SKIP_FILESYSTEMS" == true ]]; then
        log_info "Skipping practice filesystems (--skip-filesystems specified)"
        return 0
    fi

    # Create the practice filesystems
    if [[ -f "$INSTALL_DIR/content/environment/create-practice-filesystems.sh" ]]; then
        log_info "Creating practice filesystems (this may take a moment)..."
        # The script has its own output formatting, so let it display directly
        # We capture the exit code separately
        set +e  # Temporarily allow failures
        bash "$INSTALL_DIR/content/environment/create-practice-filesystems.sh"
        local fs_result=$?
        set -e
        if [[ $fs_result -eq 0 ]]; then
            log_success "Practice filesystems created"
        else
            log_warn "Practice filesystem creation had issues (may require manual setup)"
            return 0
        fi
    fi

    # Install systemd service for persistence
    if [[ -f "$INSTALL_DIR/content/environment/systemd/lpic1-filesystems.service" ]]; then
        log_info "Installing systemd service for filesystem persistence..."
        cp "$INSTALL_DIR/content/environment/systemd/lpic1-filesystems.service" /etc/systemd/system/
        systemctl daemon-reload
        systemctl enable lpic1-filesystems.service 2>&1 | tee -a "$LOG_FILE"
        log_success "Filesystem persistence service enabled"
        log_info "Practice filesystems will automatically mount on boot"
    else
        log_warn "Systemd service file not found - filesystems won't persist across reboots"
        log_info "Manual remount: sudo $PRACTICE_DIR/mount-practice-fs.sh"
    fi
}

# ============================================================================
# MOTD Installation
# ============================================================================
install_motd() {
    log_step "Installing Login Banner"

    # Ubuntu/Debian uses /etc/update-motd.d/
    if [[ -d /etc/update-motd.d ]]; then
        # Disable verbose default MOTD components
        for f in /etc/update-motd.d/10-help-text /etc/update-motd.d/50-motd-news \
                 /etc/update-motd.d/80-livepatch /etc/update-motd.d/91-release-upgrade \
                 /etc/update-motd.d/95-hwe-eol; do
            [[ -f "$f" ]] && chmod -x "$f" 2>/dev/null || true
        done

        # Install LPIC-1 training MOTD
        cat > /etc/update-motd.d/99-lpic1-training << MOTD_SCRIPT
#!/bin/bash
# LPIC-1 Training MOTD
[[ -z "\${LPIC1_BANNER_SHOWN:-}" ]] || exit 0
export LPIC1_BANNER_SHOWN=1

# Get the actual user
if [[ -n "\${SUDO_USER:-}" ]]; then
    ACTUAL_USER="\$SUDO_USER"
else
    ACTUAL_USER="\$(logname 2>/dev/null || echo "\$USER")"
fi
ACTUAL_HOME=\$(getent passwd "\$ACTUAL_USER" | cut -d: -f6)

HOME="\$ACTUAL_HOME" bash "$INSTALL_DIR/content/motd/training-motd.sh" 2>/dev/null || true
MOTD_SCRIPT
        chmod +x /etc/update-motd.d/99-lpic1-training
        log_success "Login banner installed to /etc/update-motd.d/"
    else
        # Fallback: use /etc/profile.d/
        cat > /etc/profile.d/lpic1-training.sh << 'PROFILE'
#!/bin/bash
# LPIC-1 Training - Login Banner
[[ $- == *i* ]] || return
[[ -z "${LPIC1_BANNER_SHOWN:-}" ]] || return
export LPIC1_BANNER_SHOWN=1
PROFILE
        echo "bash \"$INSTALL_DIR/content/motd/training-motd.sh\" 2>/dev/null || true" >> /etc/profile.d/lpic1-training.sh
        chmod +x /etc/profile.d/lpic1-training.sh
        log_success "Login banner installed to /etc/profile.d/"
    fi
}

# ============================================================================
# Verification
# ============================================================================
run_verification() {
    log_step "Verifying Installation"

    if [[ -f "$INSTALL_DIR/content/environment/verify-installation.sh" ]]; then
        bash "$INSTALL_DIR/content/environment/verify-installation.sh"
        return $?
    fi

    # Fallback inline verification if script not found
    local failed=0

    echo -e "\n${BOLD}Core Installation${NC}"
    if [[ -d "$INSTALL_DIR" ]]; then
        echo -e "  ${GREEN}✓${NC} $INSTALL_DIR exists"
    else
        echo -e "  ${RED}✗${NC} $INSTALL_DIR missing"
        failed=1
    fi

    if [[ -x "$INSTALL_DIR/bin/lpic1" ]]; then
        echo -e "  ${GREEN}✓${NC} lpic1 launcher executable"
    else
        echo -e "  ${RED}✗${NC} lpic1 launcher not executable"
        failed=1
    fi

    if [[ -L /usr/local/bin/lpic1 ]] && [[ -x /usr/local/bin/lpic1 ]]; then
        echo -e "  ${GREEN}✓${NC} /usr/local/bin/lpic1 symlink works"
    else
        echo -e "  ${RED}✗${NC} /usr/local/bin/lpic1 symlink broken"
        failed=1
    fi

    echo -e "\n${BOLD}Critical Commands${NC}"
    for cmd in dialog sqlite3 grep sed awk tar vim systemctl mount; do
        if command -v "$cmd" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $cmd"
        else
            echo -e "  ${RED}✗${NC} $cmd missing"
            failed=1
        fi
    done

    if [[ $failed -eq 0 ]]; then
        echo -e "\n${GREEN}${BOLD}All checks passed!${NC}\n"
        return 0
    else
        echo -e "\n${RED}${BOLD}Some checks failed${NC}\n"
        return 1
    fi
}

# ============================================================================
# Uninstall
# ============================================================================
run_uninstall() {
    if [[ -f "$INSTALL_DIR/ops/uninstall.sh" ]]; then
        bash "$INSTALL_DIR/ops/uninstall.sh"
        return $?
    elif [[ -f "$SOURCE_DIR/ops/uninstall.sh" ]]; then
        bash "$SOURCE_DIR/ops/uninstall.sh"
        return $?
    else
        log_error "Uninstall script not found"
        exit 1
    fi
}

# ============================================================================
# Main Installation
# ============================================================================
main() {
    # Initialize log file
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "=== LPIC-1 Installation Log ===" > "$LOG_FILE"
    echo "Started: $(date)" >> "$LOG_FILE"
    echo "Options: $*" >> "$LOG_FILE"

    # Parse command line arguments
    parse_args "$@"

    # Handle special modes
    if [[ "$VERIFY_ONLY" == true ]]; then
        run_verification
        exit $?
    fi

    if [[ "$UNINSTALL" == true ]]; then
        run_uninstall
        exit $?
    fi

    # Show banner
    echo -e "${BOLD}${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║       LPIC-1 Training Platform - Hospital Deployment          ║"
    echo "║                        v${VERSION}                                  ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    log_info "Installing for user: $TARGET_USER"
    log_info "Log file: $LOG_FILE"
    echo

    # Run installation phases
    preflight_checks
    setup_user
    install_packages
    install_platform
    init_user_environment
    setup_practice_filesystems
    install_motd

    # Run verification
    run_verification

    # Complete
    echo
    echo -e "${BOLD}${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    Installation Complete!                      ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo -e "${BOLD}Installed:${NC}"
    echo "  • Training platform at $INSTALL_DIR"
    echo "  • Command: lpic1"
    echo "  • User: $TARGET_USER (password: $TARGET_PASSWORD)"
    echo "  • Progress tracking at $INSTALL_DIR/data/"
    echo "  • Practice files at $INSTALL_DIR/practice/"
    if [[ "$SKIP_FILESYSTEMS" != true ]]; then
        echo "  • Practice filesystems at $MOUNT_BASE/"
    fi
    echo "  • Login banner"
    echo
    echo -e "${BOLD}Log file:${NC} $LOG_FILE"
    echo

    echo -e "${BOLD}${YELLOW}>>> Reboot now, then log in as ${TARGET_USER} <<<${NC}"
    echo
    echo -e "${BOLD}After reboot:${NC}"
    echo "  You'll see a progress banner when you log in."
    echo "  Type ${GREEN}lpic1${NC} to start training."
    echo

    echo "Completed: $(date)" >> "$LOG_FILE"
}

main "$@"
