#!/bin/bash
# LPIC-1 Training Platform - Uninstall Script
#
# Cleanly removes the LPIC-1 training environment while preserving user data.
#
# What is REMOVED:
#   - /opt/LPIC-1 (training platform)
#   - /opt/lpic1-practice (practice filesystems)
#   - /mnt/lpic1 (mount points)
#   - /usr/local/bin/lpic1 (command symlink)
#   - /etc/systemd/system/lpic1-filesystems.service
#   - /etc/update-motd.d/99-lpic1-training or /etc/profile.d/lpic1-training.sh
#
# What is PRESERVED:
#   - User accounts (student, etc.)
#   - ~/.lpic1 progress data
#   - ~/lpic1-practice files
#   - Installed packages (dialog, sqlite3, etc.)
#
# Usage: sudo /opt/LPIC-1/uninstall.sh [--purge]
#   --purge: Also remove user progress data (~/.lpic1)

set -euo pipefail

# Configuration
INSTALL_DIR="/opt/LPIC-1"
PRACTICE_DIR="/opt/lpic1-practice"
MOUNT_BASE="/mnt/lpic1"
LVM_VG="lpic1_vg"
LOG_FILE="/var/log/lpic1-install.log"

# Parse arguments
PURGE=false
FORCE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --purge)
            PURGE=true
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --help|-h)
            cat << EOF
LPIC-1 Training Platform - Uninstall Script

Usage: sudo $0 [options]

Options:
  --purge    Also remove user progress data (~/.lpic1)
  --force    Skip confirmation prompt
  --help     Show this help

What is REMOVED:
  - /opt/LPIC-1 (training platform)
  - /opt/lpic1-practice (practice filesystems and loop images)
  - /mnt/lpic1 (mount points)
  - /usr/local/bin/lpic1 (command symlink)
  - systemd service for filesystem persistence
  - Login banner (MOTD)

What is PRESERVED:
  - User accounts
  - ~/lpic1-practice (user's practice files)
  - ~/.lpic1 (progress data) - unless --purge is specified
  - Installed system packages
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Confirmation
echo -e "${BOLD}${YELLOW}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           LPIC-1 Training Platform - Uninstall                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BOLD}This will remove:${NC}"
echo "  • $INSTALL_DIR"
echo "  • $PRACTICE_DIR (loop images and filesystems)"
echo "  • $MOUNT_BASE (mount points)"
echo "  • /usr/local/bin/lpic1"
echo "  • systemd filesystem service"
echo "  • Login banner"
if [[ "$PURGE" == true ]]; then
    echo -e "  ${YELLOW}• All user ~/.lpic1 directories (progress data)${NC}"
fi
echo
echo -e "${BOLD}This will preserve:${NC}"
echo "  • User accounts"
echo "  • Installed packages"
if [[ "$PURGE" != true ]]; then
    echo "  • User progress data (~/.lpic1)"
fi
echo

if [[ "$FORCE" != true ]]; then
    read -rp "Continue with uninstall? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy] ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi
fi

echo
log_info "Starting uninstall..."

# ============================================================================
# Stop and disable systemd service
# ============================================================================
log_info "Stopping filesystem service..."
if systemctl is-active lpic1-filesystems.service &>/dev/null; then
    systemctl stop lpic1-filesystems.service 2>/dev/null || true
    log_success "Service stopped"
fi

if systemctl is-enabled lpic1-filesystems.service &>/dev/null; then
    systemctl disable lpic1-filesystems.service 2>/dev/null || true
    log_success "Service disabled"
fi

rm -f /etc/systemd/system/lpic1-filesystems.service
systemctl daemon-reload 2>/dev/null || true
log_success "Systemd service removed"

# ============================================================================
# Unmount filesystems
# ============================================================================
log_info "Unmounting practice filesystems..."

# Run unmount script if available
if [[ -x "$INSTALL_DIR/environment/unmount-practice-filesystems.sh" ]]; then
    "$INSTALL_DIR/environment/unmount-practice-filesystems.sh" || true
else
    # Manual unmount
    for mount in "${MOUNT_BASE}"/*; do
        if mountpoint -q "$mount" 2>/dev/null; then
            # Disable quotas first
            quotaoff "$mount" 2>/dev/null || true
            umount "$mount" 2>/dev/null || umount -l "$mount" 2>/dev/null || true
        fi
    done

    # Deactivate LVM
    if vgdisplay "$LVM_VG" &>/dev/null; then
        vgchange -an "$LVM_VG" 2>/dev/null || true
    fi

    # Detach loop devices
    for loop in /dev/loop{10..19}; do
        if losetup "$loop" &>/dev/null; then
            losetup -d "$loop" 2>/dev/null || true
        fi
    done
fi

log_success "Filesystems unmounted"

# ============================================================================
# Remove directories
# ============================================================================
log_info "Removing installation directories..."

# Remove practice directory (contains loop images)
if [[ -d "$PRACTICE_DIR" ]]; then
    rm -rf "$PRACTICE_DIR"
    log_success "Removed $PRACTICE_DIR"
fi

# Remove mount points
if [[ -d "$MOUNT_BASE" ]]; then
    rm -rf "$MOUNT_BASE"
    log_success "Removed $MOUNT_BASE"
fi

# Remove installation directory
if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
    log_success "Removed $INSTALL_DIR"
fi

# ============================================================================
# Remove symlink
# ============================================================================
log_info "Removing command symlink..."
rm -f /usr/local/bin/lpic1
log_success "Removed /usr/local/bin/lpic1"

# ============================================================================
# Remove MOTD
# ============================================================================
log_info "Removing login banner..."
rm -f /etc/update-motd.d/99-lpic1-training
rm -f /etc/profile.d/lpic1-training.sh
log_success "Login banner removed"

# ============================================================================
# Remove quotauser if created by us
# ============================================================================
if id quotauser &>/dev/null; then
    log_info "Removing quotauser account..."
    userdel -r quotauser 2>/dev/null || userdel quotauser 2>/dev/null || true
    log_success "quotauser removed"
fi

# ============================================================================
# Purge user data (optional)
# ============================================================================
if [[ "$PURGE" == true ]]; then
    log_info "Purging user progress data..."

    # Find all home directories and remove .lpic1
    for home in /home/*; do
        if [[ -d "$home/.lpic1" ]]; then
            rm -rf "$home/.lpic1"
            log_success "Removed $home/.lpic1"
        fi
    done

    # Also check root
    if [[ -d /root/.lpic1 ]]; then
        rm -rf /root/.lpic1
        log_success "Removed /root/.lpic1"
    fi
fi

# ============================================================================
# Clean up log file (optional, keep for debugging)
# ============================================================================
# We keep the log file for troubleshooting: $LOG_FILE

# ============================================================================
# Complete
# ============================================================================
echo
echo -e "${BOLD}${GREEN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    Uninstall Complete                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BOLD}Removed:${NC}"
echo "  • Training platform ($INSTALL_DIR)"
echo "  • Practice filesystems ($PRACTICE_DIR)"
echo "  • Mount points ($MOUNT_BASE)"
echo "  • Command: lpic1"
echo "  • Systemd service"
echo "  • Login banner"
echo

echo -e "${BOLD}Preserved:${NC}"
echo "  • User accounts"
echo "  • Installed packages"
if [[ "$PURGE" != true ]]; then
    echo "  • User progress data (~/.lpic1)"
    echo
    echo -e "${CYAN}To completely remove all traces, run:${NC}"
    echo "  sudo $0 --purge"
fi
echo

log_success "LPIC-1 training environment has been removed."
