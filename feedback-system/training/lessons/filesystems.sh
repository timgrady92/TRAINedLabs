#!/bin/bash
# LPIC-1 Training - Filesystems Lesson
# Objectives: 104.1-104.3 - Create partitions, maintain filesystem integrity, mount/unmount

lesson_filesystems() {
    print_header "Filesystem Management"

    cat << 'INTRO'
Understanding filesystems is crucial for Linux administration. You need
to know how to create partitions, format them with filesystems, mount
them, and monitor disk usage.

INTRO

    echo -e "${BOLD}Real-World Uses:${NC}"
    echo "  ${BULLET} Adding new storage to servers"
    echo "  ${BULLET} Monitoring and managing disk space"
    echo "  ${BULLET} Creating and mounting backup drives"
    echo "  ${BULLET} Troubleshooting disk problems"
    echo "  ${BULLET} Setting up persistent mounts"

    wait_for_user

    # Viewing Storage
    print_subheader "Viewing Storage Devices"

    echo -e "${BOLD}lsblk - List block devices${NC}"
    echo "  lsblk                  # Tree view of devices"
    echo "  lsblk -f               # Include filesystem info"
    echo "  lsblk -p               # Show full device paths"
    echo

    echo -e "${CYAN}Live Example:${NC}"
    echo -e "${BOLD}Command:${NC} lsblk"
    lsblk 2>/dev/null | head -10 | sed 's/^/  /' || echo "  (lsblk not available)"
    echo

    echo -e "${BOLD}blkid - Block device attributes${NC}"
    echo "  blkid                  # All devices"
    echo "  blkid /dev/sda1        # Specific device"
    echo "  ${DIM}Shows UUID, filesystem type, labels${NC}"

    wait_for_user

    # Disk Usage
    print_subheader "Disk Space Usage"

    echo -e "${BOLD}df - Disk free space${NC}"
    echo "  df                     # All filesystems"
    echo "  df -h                  # Human readable"
    echo "  df -T                  # Include filesystem type"
    echo "  df -i                  # Inode usage"
    echo "  df /home               # Specific mount point"
    echo

    echo -e "${CYAN}Live Example:${NC}"
    echo -e "${BOLD}Command:${NC} df -hT"
    df -hT 2>/dev/null | head -8 | sed 's/^/  /'
    echo

    echo -e "${BOLD}du - Directory space usage${NC}"
    echo "  du -sh /home           # Summary of directory"
    echo "  du -h --max-depth=1 /  # First-level subdirs"
    echo "  du -ah /var | sort -rh | head  # Largest files"

    wait_for_user

    # Partitioning
    print_subheader "Partitioning Tools"

    echo -e "${BOLD}fdisk - MBR partitioning (interactive)${NC}"
    echo "  fdisk -l               # List all partitions"
    echo "  fdisk /dev/sdb         # Interactive mode"
    echo "  ${DIM}Commands: n=new, d=delete, p=print, w=write, q=quit${NC}"
    echo

    echo -e "${BOLD}gdisk - GPT partitioning${NC}"
    echo "  gdisk -l /dev/sdb      # List partitions"
    echo "  gdisk /dev/sdb         # Interactive mode"
    echo "  ${DIM}Similar commands to fdisk${NC}"
    echo

    echo -e "${BOLD}parted - Both MBR and GPT${NC}"
    echo "  parted -l              # List all"
    echo "  parted /dev/sdb        # Interactive"
    echo "  parted /dev/sdb mkpart primary ext4 0% 100%"
    echo

    echo -e "${YELLOW}${WARN} Partitioning destroys data! Always backup first.${NC}"

    wait_for_user

    # Creating Filesystems
    print_subheader "Creating Filesystems"

    echo -e "${BOLD}mkfs - Make filesystem${NC}"
    echo "  mkfs.ext4 /dev/sdb1        # ext4 filesystem"
    echo "  mkfs.xfs /dev/sdb1         # XFS filesystem"
    echo "  mkfs.btrfs /dev/sdb1       # Btrfs filesystem"
    echo "  mkfs.vfat /dev/sdb1        # FAT32 (USB drives)"
    echo

    echo -e "${BOLD}Common options:${NC}"
    echo "  mkfs.ext4 -L 'DATA' /dev/sdb1      # Set label"
    echo "  mkfs.xfs -L 'BACKUP' /dev/sdb1"
    echo "  mkfs.ext4 -m 1 /dev/sdb1           # 1% reserved"
    echo

    echo -e "${BOLD}Filesystem comparison:${NC}"
    printf "  %-10s %-15s %-15s\n" "Type" "Max Size" "Use Case"
    printf "  %-10s %-15s %-15s\n" "────" "────────" "────────"
    printf "  %-10s %-15s %-15s\n" "ext4" "1 EB" "General purpose"
    printf "  %-10s %-15s %-15s\n" "xfs" "8 EB" "Large files, databases"
    printf "  %-10s %-15s %-15s\n" "btrfs" "16 EB" "Snapshots, RAID"
    printf "  %-10s %-15s %-15s\n" "vfat" "2 TB" "USB, compatibility"

    wait_for_user

    # Mounting
    print_subheader "Mounting Filesystems"

    echo -e "${BOLD}mount - Attach filesystem${NC}"
    echo "  mount /dev/sdb1 /mnt/data     # Mount device"
    echo "  mount -t ext4 /dev/sdb1 /mnt  # Specify type"
    echo "  mount -o ro /dev/sdb1 /mnt    # Read-only"
    echo "  mount                          # Show mounted"
    echo

    echo -e "${BOLD}umount - Detach filesystem${NC}"
    echo "  umount /mnt/data              # By mount point"
    echo "  umount /dev/sdb1              # By device"
    echo "  umount -l /mnt/data           # Lazy unmount"
    echo "  ${DIM}(detaches when no longer busy)${NC}"
    echo

    echo -e "${YELLOW}${WARN} 'Device is busy' means something is using it${NC}"
    echo "  lsof /mnt/data                # Find what's using it"
    echo "  fuser -m /mnt/data            # PIDs using mount"

    wait_for_user

    # Mount Options
    print_subheader "Mount Options"

    echo -e "${BOLD}Common mount options (-o):${NC}"
    echo "  ${CYAN}ro${NC}        Read-only"
    echo "  ${CYAN}rw${NC}        Read-write"
    echo "  ${CYAN}noexec${NC}    Don't allow execution"
    echo "  ${CYAN}nosuid${NC}    Ignore SUID bits"
    echo "  ${CYAN}nodev${NC}     Ignore device files"
    echo "  ${CYAN}noatime${NC}   Don't update access times"
    echo "  ${CYAN}sync${NC}      Synchronous I/O"
    echo "  ${CYAN}async${NC}     Asynchronous I/O (default)"
    echo "  ${CYAN}user${NC}      Allow non-root to mount"
    echo "  ${CYAN}defaults${NC}  rw,suid,dev,exec,auto,nouser,async"
    echo

    echo -e "${CYAN}Example:${NC}"
    echo "  mount -o ro,noexec /dev/sdb1 /mnt/usb"

    wait_for_user

    # /etc/fstab
    print_subheader "/etc/fstab - Persistent Mounts"

    cat << 'FSTAB'
/etc/fstab defines filesystems to mount at boot.

Format:
  device    mount-point    fs-type    options    dump    pass

FSTAB

    echo -e "${BOLD}Fields:${NC}"
    echo "  1. Device (UUID preferred, or /dev/xxx)"
    echo "  2. Mount point"
    echo "  3. Filesystem type (ext4, xfs, etc.)"
    echo "  4. Mount options"
    echo "  5. Dump (0=no backup, 1=backup)"
    echo "  6. Pass (0=no check, 1=root, 2=others)"
    echo

    echo -e "${CYAN}Example entries:${NC}"
    echo "  UUID=abc123 /data ext4 defaults 0 2"
    echo "  /dev/sdb1 /backup xfs defaults,noatime 0 2"
    echo "  //server/share /mnt/share cifs credentials=/etc/creds 0 0"
    echo

    echo -e "${CYAN}Get UUID:${NC}"
    echo "  blkid /dev/sdb1"
    echo "  lsblk -f"

    wait_for_user

    # Testing fstab
    print_subheader "Testing /etc/fstab"

    echo -e "${RED}${WARN} Bad fstab can prevent system boot!${NC}"
    echo

    echo -e "${CYAN}Test mount from fstab:${NC}"
    echo "  mount -a                   # Mount all in fstab"
    echo "  mount /data                # Mount specific entry"
    echo

    echo -e "${CYAN}Before reboot, verify:${NC}"
    echo "  1. Edit /etc/fstab"
    echo "  2. Run: mount -a"
    echo "  3. Check for errors"
    echo "  4. Verify: df -h"
    echo

    echo -e "${CYAN}Recovery tip:${NC}"
    echo "  If boot fails, boot to recovery/rescue mode"
    echo "  Fix /etc/fstab, then reboot"

    wait_for_user

    # Filesystem Maintenance
    print_subheader "Filesystem Maintenance"

    echo -e "${BOLD}fsck - Filesystem check${NC}"
    echo "  fsck /dev/sdb1             # Check filesystem"
    echo "  fsck -y /dev/sdb1          # Auto-yes to repairs"
    echo "  fsck -n /dev/sdb1          # No changes (check only)"
    echo "  ${RED}Never run on mounted filesystem!${NC}"
    echo

    echo -e "${BOLD}tune2fs - Tune ext2/3/4${NC}"
    echo "  tune2fs -l /dev/sdb1       # List parameters"
    echo "  tune2fs -L 'DATA' /dev/sdb1  # Set label"
    echo "  tune2fs -c 30 /dev/sdb1    # Check every 30 mounts"
    echo "  tune2fs -m 1 /dev/sdb1     # 1% reserved blocks"
    echo

    echo -e "${BOLD}xfs_repair - XFS filesystem check${NC}"
    echo "  xfs_repair /dev/sdb1       # Check and repair"
    echo "  xfs_info /mnt/data         # Show XFS info"

    wait_for_user

    # Swap Space
    print_subheader "Swap Space"

    echo -e "${BOLD}Create swap partition:${NC}"
    echo "  mkswap /dev/sdb2           # Initialize swap"
    echo "  swapon /dev/sdb2           # Enable"
    echo "  swapoff /dev/sdb2          # Disable"
    echo

    echo -e "${BOLD}Create swap file:${NC}"
    echo "  dd if=/dev/zero of=/swapfile bs=1M count=1024"
    echo "  chmod 600 /swapfile"
    echo "  mkswap /swapfile"
    echo "  swapon /swapfile"
    echo

    echo -e "${CYAN}View swap usage:${NC}"
    echo "  swapon --show"
    echo "  free -h"
    echo

    echo -e "${CYAN}fstab entry for swap:${NC}"
    echo "  UUID=xxx swap swap defaults 0 0"

    wait_for_user

    # Practical Examples
    print_subheader "Practical Examples"

    echo -e "${CYAN}1. Add new disk:${NC}"
    echo "   lsblk                        # Identify disk"
    echo "   fdisk /dev/sdb               # Create partition"
    echo "   mkfs.ext4 -L 'DATA' /dev/sdb1"
    echo "   mkdir /data"
    echo "   mount /dev/sdb1 /data"
    echo "   # Add to /etc/fstab using UUID"
    echo

    echo -e "${CYAN}2. Find disk space usage:${NC}"
    echo "   df -h                        # Filesystem usage"
    echo "   du -sh /*                    # Directory sizes"
    echo "   du -ah / | sort -rh | head -20  # Largest files"
    echo

    echo -e "${CYAN}3. Check filesystem before mount:${NC}"
    echo "   umount /dev/sdb1"
    echo "   fsck -y /dev/sdb1"
    echo "   mount /dev/sdb1 /data"

    wait_for_user

    # Exam tips
    print_subheader "Exam Tips"

    echo -e "${MAGENTA}${BULLET}${NC} lsblk shows devices; df shows space; du shows usage"
    echo -e "${MAGENTA}${BULLET}${NC} fdisk for MBR, gdisk for GPT partitioning"
    echo -e "${MAGENTA}${BULLET}${NC} mkfs.ext4, mkfs.xfs create filesystems"
    echo -e "${MAGENTA}${BULLET}${NC} mount attaches, umount detaches filesystems"
    echo -e "${MAGENTA}${BULLET}${NC} /etc/fstab: device mountpoint type options dump pass"
    echo -e "${MAGENTA}${BULLET}${NC} Use UUID in fstab (more reliable than /dev names)"
    echo -e "${MAGENTA}${BULLET}${NC} fsck only on unmounted filesystems!"

    wait_for_user

    # Key takeaways
    print_subheader "Key Takeaways"

    echo "1. lsblk, blkid to view storage devices"
    echo "2. df for filesystem space, du for directory usage"
    echo "3. fdisk/gdisk for partitioning, mkfs for formatting"
    echo "4. mount/umount to attach/detach filesystems"
    echo "5. /etc/fstab for persistent mounts (use UUID)"
    echo "6. fsck to check/repair (must be unmounted)"
    echo

    print_info "Ready to practice? Try: lpic-train practice filesystems"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    lesson_filesystems
fi
