#!/bin/bash
# LPIC-1 Training - Networking Lesson
# Objectives: 109.1-109.4 - Fundamentals of internet protocols, network configuration

lesson_networking() {
    print_header "Network Configuration and Diagnostics"

    cat << 'INTRO'
Network administration is essential for any Linux system. Understanding
IP addressing, routing, DNS, and diagnostic tools allows you to configure
connectivity and troubleshoot problems effectively.

INTRO

    echo -e "${BOLD}Real-World Uses:${NC}"
    echo "  ${BULLET} Configuring server network interfaces"
    echo "  ${BULLET} Diagnosing connectivity problems"
    echo "  ${BULLET} Setting up routing tables"
    echo "  ${BULLET} DNS troubleshooting"
    echo "  ${BULLET} Monitoring network connections"

    wait_for_user

    # ip command
    print_subheader "ip - Network Configuration (Modern)"

    echo "The 'ip' command is the modern replacement for ifconfig, route, etc."
    echo

    echo -e "${BOLD}ip addr - View/configure addresses${NC}"
    echo "  ip addr                    # Show all addresses"
    echo "  ip addr show eth0          # Show specific interface"
    echo "  ip -br addr                # Brief format"
    echo "  ip addr add 192.168.1.100/24 dev eth0  # Add address"
    echo "  ip addr del 192.168.1.100/24 dev eth0  # Remove address"
    echo

    echo -e "${CYAN}Live Example:${NC}"
    echo -e "${BOLD}Command:${NC} ip -br addr"
    ip -br addr 2>/dev/null | head -5 | sed 's/^/  /' || echo "  (ip command not available)"

    wait_for_user

    echo -e "${BOLD}ip link - Interface management${NC}"
    echo "  ip link                    # List interfaces"
    echo "  ip link show eth0          # Specific interface"
    echo "  ip link set eth0 up        # Enable interface"
    echo "  ip link set eth0 down      # Disable interface"
    echo "  ip link set eth0 mtu 9000  # Set MTU"
    echo

    echo -e "${BOLD}ip route - Routing table${NC}"
    echo "  ip route                   # Show routing table"
    echo "  ip route show              # Same"
    echo "  ip route get 8.8.8.8       # Show route to destination"
    echo "  ip route add 10.0.0.0/8 via 192.168.1.1  # Add route"
    echo "  ip route del 10.0.0.0/8    # Delete route"
    echo "  ip route add default via 192.168.1.1     # Default gateway"
    echo

    echo -e "${CYAN}Live Example:${NC}"
    echo -e "${BOLD}Command:${NC} ip route"
    ip route 2>/dev/null | head -5 | sed 's/^/  /' || echo "  (routing table not available)"

    wait_for_user

    # ss - Socket Statistics
    print_subheader "ss - Socket Statistics (Modern)"

    echo "ss is the modern replacement for netstat."
    echo

    echo -e "${BOLD}Common options:${NC}"
    echo "  ${CYAN}-t${NC}   TCP sockets"
    echo "  ${CYAN}-u${NC}   UDP sockets"
    echo "  ${CYAN}-l${NC}   Listening sockets only"
    echo "  ${CYAN}-n${NC}   Numeric (don't resolve names)"
    echo "  ${CYAN}-p${NC}   Show process using socket"
    echo "  ${CYAN}-a${NC}   All sockets"
    echo

    echo -e "${BOLD}Common combinations:${NC}"
    echo "  ss -tlnp    # Listening TCP ports with process"
    echo "  ss -ulnp    # Listening UDP ports with process"
    echo "  ss -tunap   # All TCP/UDP connections"
    echo "  ss -s       # Summary statistics"
    echo

    echo -e "${CYAN}Live Example: Listening TCP ports${NC}"
    echo -e "${BOLD}Command:${NC} ss -tlnp"
    ss -tlnp 2>/dev/null | head -8 | sed 's/^/  /' || echo "  (requires root for -p)"

    wait_for_user

    # DNS Tools
    print_subheader "DNS Tools"

    echo -e "${BOLD}dig - DNS queries${NC}"
    echo "  dig example.com            # Query A record"
    echo "  dig example.com MX         # Mail server records"
    echo "  dig example.com NS         # Name server records"
    echo "  dig @8.8.8.8 example.com   # Query specific DNS server"
    echo "  dig +short example.com     # Brief output"
    echo "  dig -x 8.8.8.8            # Reverse lookup"
    echo

    echo -e "${BOLD}host - Simple DNS lookup${NC}"
    echo "  host example.com"
    echo "  host -t MX example.com"
    echo

    echo -e "${BOLD}nslookup - Interactive DNS${NC}"
    echo "  nslookup example.com"
    echo "  nslookup -type=mx example.com"

    wait_for_user

    # Connectivity Testing
    print_subheader "Connectivity Testing"

    echo -e "${BOLD}ping - ICMP echo${NC}"
    echo "  ping host              # Continuous ping"
    echo "  ping -c 4 host         # Send 4 packets"
    echo "  ping -i 0.5 host       # 0.5 second interval"
    echo "  ping -s 1000 host      # Packet size"
    echo "  ping -W 2 host         # 2 second timeout"
    echo

    echo -e "${BOLD}traceroute / tracepath - Route tracing${NC}"
    echo "  traceroute example.com     # Show network path"
    echo "  tracepath example.com      # No root needed"
    echo "  traceroute -n example.com  # Numeric (faster)"
    echo

    echo -e "${BOLD}mtr - Combined ping + traceroute${NC}"
    echo "  mtr example.com            # Interactive"
    echo "  mtr -n example.com         # Numeric"
    echo "  mtr -r -c 10 example.com   # Report mode"

    wait_for_user

    # Legacy Commands
    print_subheader "Legacy Commands (Still Common)"

    echo -e "${BOLD}ifconfig - Interface config (deprecated)${NC}"
    echo "  ifconfig                   # Show all interfaces"
    echo "  ifconfig eth0              # Specific interface"
    echo "  ifconfig eth0 up/down      # Enable/disable"
    echo "  ${DIM}Modern: ip addr, ip link${NC}"
    echo

    echo -e "${BOLD}route - Routing table (deprecated)${NC}"
    echo "  route -n                   # Show routing table"
    echo "  route add default gw IP    # Add default gateway"
    echo "  ${DIM}Modern: ip route${NC}"
    echo

    echo -e "${BOLD}netstat - Network statistics (deprecated)${NC}"
    echo "  netstat -tlnp              # Listening TCP ports"
    echo "  netstat -an                # All connections"
    echo "  netstat -r                 # Routing table"
    echo "  netstat -i                 # Interface stats"
    echo "  ${DIM}Modern: ss${NC}"

    wait_for_user

    # Configuration Files
    print_subheader "Network Configuration Files"

    echo -e "${BOLD}/etc/hosts - Local hostname resolution${NC}"
    echo "  127.0.0.1   localhost"
    echo "  192.168.1.10 server1.local server1"
    echo

    echo -e "${BOLD}/etc/resolv.conf - DNS configuration${NC}"
    echo "  nameserver 8.8.8.8"
    echo "  nameserver 8.8.4.4"
    echo "  search example.com"
    echo

    echo -e "${BOLD}/etc/nsswitch.conf - Name service order${NC}"
    echo "  hosts: files dns"
    echo "  (Check files (/etc/hosts) before DNS)"
    echo

    echo -e "${BOLD}/etc/hostname - System hostname${NC}"
    echo "  hostnamectl set-hostname server1.example.com"

    wait_for_user

    # Network Services
    print_subheader "Common Ports"

    printf "  %-8s %-8s %s\n" "Port" "Proto" "Service"
    printf "  %-8s %-8s %s\n" "────" "─────" "───────"
    printf "  %-8s %-8s %s\n" "20,21" "TCP" "FTP"
    printf "  %-8s %-8s %s\n" "22" "TCP" "SSH"
    printf "  %-8s %-8s %s\n" "23" "TCP" "Telnet"
    printf "  %-8s %-8s %s\n" "25" "TCP" "SMTP"
    printf "  %-8s %-8s %s\n" "53" "TCP/UDP" "DNS"
    printf "  %-8s %-8s %s\n" "67,68" "UDP" "DHCP"
    printf "  %-8s %-8s %s\n" "80" "TCP" "HTTP"
    printf "  %-8s %-8s %s\n" "110" "TCP" "POP3"
    printf "  %-8s %-8s %s\n" "143" "TCP" "IMAP"
    printf "  %-8s %-8s %s\n" "443" "TCP" "HTTPS"
    printf "  %-8s %-8s %s\n" "3306" "TCP" "MySQL"
    printf "  %-8s %-8s %s\n" "5432" "TCP" "PostgreSQL"

    wait_for_user

    # Troubleshooting Workflow
    print_subheader "Network Troubleshooting Workflow"

    echo -e "${CYAN}1. Check local interface${NC}"
    echo "   ip addr show"
    echo "   ip link show"
    echo

    echo -e "${CYAN}2. Check local connectivity${NC}"
    echo "   ping -c 3 127.0.0.1       # Loopback"
    echo "   ping -c 3 192.168.1.1     # Gateway"
    echo

    echo -e "${CYAN}3. Check routing${NC}"
    echo "   ip route"
    echo "   ip route get 8.8.8.8"
    echo

    echo -e "${CYAN}4. Check DNS${NC}"
    echo "   dig +short example.com"
    echo "   cat /etc/resolv.conf"
    echo

    echo -e "${CYAN}5. Check remote connectivity${NC}"
    echo "   ping -c 3 8.8.8.8         # By IP"
    echo "   ping -c 3 google.com      # By name (tests DNS)"
    echo

    echo -e "${CYAN}6. Trace the path${NC}"
    echo "   traceroute destination"

    wait_for_user

    # Practical Examples
    print_subheader "Practical Examples"

    echo -e "${CYAN}1. Find what's listening on port 80:${NC}"
    echo "   ss -tlnp | grep :80"
    echo "   # or: lsof -i :80"
    echo

    echo -e "${CYAN}2. Add temporary IP address:${NC}"
    echo "   sudo ip addr add 192.168.1.100/24 dev eth0"
    echo

    echo -e "${CYAN}3. Test if port is open:${NC}"
    echo "   nc -zv host 22"
    echo "   # or: telnet host 22"
    echo

    echo -e "${CYAN}4. Check DNS resolution:${NC}"
    echo "   dig +short google.com"
    echo "   host google.com"
    echo

    echo -e "${CYAN}5. Monitor network connections:${NC}"
    echo "   watch -n 1 'ss -tuna'"

    wait_for_user

    # Exam tips
    print_subheader "Exam Tips"

    echo -e "${MAGENTA}${BULLET}${NC} ip replaces ifconfig, route: ip addr, ip route, ip link"
    echo -e "${MAGENTA}${BULLET}${NC} ss replaces netstat: ss -tlnp for listening ports"
    echo -e "${MAGENTA}${BULLET}${NC} dig is preferred over nslookup for DNS"
    echo -e "${MAGENTA}${BULLET}${NC} /etc/resolv.conf contains DNS server addresses"
    echo -e "${MAGENTA}${BULLET}${NC} /etc/hosts overrides DNS (per nsswitch.conf)"
    echo -e "${MAGENTA}${BULLET}${NC} ping -c N sends exactly N packets"
    echo -e "${MAGENTA}${BULLET}${NC} Know common ports: 22=SSH, 80=HTTP, 443=HTTPS"

    wait_for_user

    # Key takeaways
    print_subheader "Key Takeaways"

    echo "1. ip command: ip addr, ip route, ip link"
    echo "2. ss -tlnp shows listening TCP ports with processes"
    echo "3. dig for DNS queries; host for simple lookups"
    echo "4. ping tests connectivity; traceroute shows path"
    echo "5. /etc/resolv.conf and /etc/hosts for name resolution"
    echo "6. Know both modern (ip, ss) and legacy (ifconfig, netstat)"
    echo

    print_info "Ready to practice? Try: lpic-train practice networking"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    lesson_networking
fi
