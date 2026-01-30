#!/bin/bash
# LPIC-1 Training Platform - Fedora/RHEL Setup
#
# Usage: sudo ./setup-fedora.sh [username]
#
# Installs the LPIC-1 training environment for the specified user.

set -euo pipefail

# Installation directory
INSTALL_DIR="/opt/LPIC-1"
SOURCE_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "\n${BOLD}${BLUE}═══ $1 ═══${NC}\n"; }

# Verify running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Verify Fedora/RHEL
if [[ ! -f /etc/fedora-release ]] && [[ ! -f /etc/redhat-release ]]; then
    log_error "This script is for Fedora/RHEL systems"
    log_info "For Ubuntu/Debian, use: sudo ./setup-ubuntu.sh"
    exit 1
fi

# Determine target user
TARGET_USER="${1:-${SUDO_USER:-}}"
if [[ -z "$TARGET_USER" ]]; then
    log_error "Could not determine target user"
    echo "Usage: sudo $0 <username>"
    exit 1
fi

if ! id "$TARGET_USER" &>/dev/null; then
    log_error "User '$TARGET_USER' does not exist"
    exit 1
fi

TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

# Banner
echo -e "${BOLD}${CYAN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           LPIC-1 Training Platform Setup (Fedora)             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
log_info "Installing for user: $TARGET_USER"
log_info "Install directory: $INSTALL_DIR"
echo

# ============================================================================
# Phase 1: Install System Packages
# ============================================================================
log_step "Installing Required Packages"

dnf makecache -q

# Core packages for LPIC-1 training
PACKAGES=(
    # Dialog for TUI
    dialog
    # Database for progress tracking
    sqlite
    # Text processing (103.2)
    grep sed gawk
    # File operations (103.3)
    findutils tar gzip bzip2 xz
    # Process management (103.5)
    procps-ng psmisc
    # User management (107.1)
    shadow-utils
    # Storage (104.x)
    util-linux e2fsprogs xfsprogs btrfs-progs lvm2 dosfstools
    # Networking (109.x)
    iproute iputils bind-utils traceroute nmap-ncat
    # Services (101.3, 108.x)
    systemd chrony cups
    # Security (110.x)
    openssh sudo gnupg2 iptables
    # Editors
    vim-enhanced nano
    # Additional tools
    man-db man-pages bash-completion tree
)

log_info "Installing packages..."
dnf install -y -q "${PACKAGES[@]}" 2>/dev/null || {
    log_warn "Some packages may not be available, continuing..."
}
log_success "Package installation complete"

# ============================================================================
# Phase 2: Install Training Platform
# ============================================================================
log_step "Installing Training Platform"

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Copy training files
log_info "Copying training files to $INSTALL_DIR..."
cp -r "$SOURCE_DIR/feedback-system" "$INSTALL_DIR/"
cp -r "$SOURCE_DIR/scenarios" "$INSTALL_DIR/"
cp -r "$SOURCE_DIR/environment" "$INSTALL_DIR/"
cp -r "$SOURCE_DIR/motd-integration" "$INSTALL_DIR/"
cp "$SOURCE_DIR/lpic1" "$INSTALL_DIR/"

# Make scripts executable
find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \;
chmod +x "$INSTALL_DIR/lpic1"
chmod +x "$INSTALL_DIR/feedback-system/lpic-train"
chmod +x "$INSTALL_DIR/feedback-system/lpic-check"

# Update the lpic1 launcher to use installed paths
sed -i "s|SCRIPT_DIR=.*|SCRIPT_DIR=\"$INSTALL_DIR\"|" "$INSTALL_DIR/lpic1"

log_success "Training platform installed to $INSTALL_DIR"

# ============================================================================
# Phase 3: Create Command Symlinks
# ============================================================================
log_step "Creating Commands"

ln -sf "$INSTALL_DIR/lpic1" /usr/local/bin/lpic1
log_success "Created: lpic1"

# ============================================================================
# Phase 4: Initialize User Environment
# ============================================================================
log_step "Setting Up User Environment"

# Create user's progress directory
USER_LPIC_DIR="${TARGET_HOME}/.lpic1"
mkdir -p "$USER_LPIC_DIR"
chown "$TARGET_USER:$TARGET_USER" "$USER_LPIC_DIR"

# Initialize progress database
log_info "Initializing progress tracking..."
sudo -u "$TARGET_USER" bash "$INSTALL_DIR/feedback-system/init-progress.sh" </dev/null 2>/dev/null || true
log_success "Progress database initialized"

# Create practice files
log_info "Creating practice files..."
sudo -u "$TARGET_USER" bash "$INSTALL_DIR/environment/seed-data.sh" 2>/dev/null || true
log_success "Practice files created at ${TARGET_HOME}/lpic1-practice/"

# ============================================================================
# Phase 5: Install Login Banner
# ============================================================================
log_step "Installing Login Banner"

cat > /etc/profile.d/lpic1-training.sh << 'PROFILE'
#!/bin/bash
# LPIC-1 Training - Login Banner
[[ $- == *i* ]] || return
[[ -z "${LPIC1_BANNER_SHOWN:-}" ]] || return
export LPIC1_BANNER_SHOWN=1
PROFILE

echo "bash \"$INSTALL_DIR/motd-integration/training-motd.sh\" 2>/dev/null || true" >> /etc/profile.d/lpic1-training.sh
chmod +x /etc/profile.d/lpic1-training.sh

log_success "Login banner installed"

# ============================================================================
# Phase 6: Create Practice Filesystems (Optional)
# ============================================================================
log_step "Practice Filesystems"

if [[ -f "$INSTALL_DIR/environment/create-practice-filesystems.sh" ]]; then
    log_info "Creating practice filesystems..."
    bash "$INSTALL_DIR/environment/create-practice-filesystems.sh" 2>/dev/null || {
        log_warn "Practice filesystems skipped (may require additional setup)"
    }
fi

# ============================================================================
# Complete
# ============================================================================
echo
echo -e "${BOLD}${GREEN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    Setup Complete!                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BOLD}Installed:${NC}"
echo "  • Training platform at $INSTALL_DIR"
echo "  • Command: lpic1"
echo "  • Progress tracking at ${USER_LPIC_DIR}"
echo "  • Practice files at ${TARGET_HOME}/lpic1-practice/"
echo "  • Login banner"
echo

echo -e "${BOLD}${YELLOW}>>> Reboot now, then log in as ${TARGET_USER} <<<${NC}"
echo

echo -e "${BOLD}After reboot:${NC}"
echo "  You'll see a progress banner when you log in."
echo "  Type ${GREEN}lpic1${NC} to start training."
echo
