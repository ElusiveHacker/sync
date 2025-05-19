#!/bin/bash

# ========================================================================================
# sync.sh - Active Directory clock sync Script
# GNU Bash 5.2.37(1)-release compatible
# ========================================================================================

# ------------------------------------
# Setup Script Directory
# ------------------------------------
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# ------------------------------------
# Global Variables and Defaults
# ------------------------------------
LOG_FILE="$SCRIPT_DIR/sync.log"
DATE_TIME="$(date +%Y%m%d_%H%M)"
REPORT_FILE="$SCRIPT_DIR/${DATE_TIME}_sync.txt"

IP=""
QUIET_MODE=false
trueRoot=false

# ------------------------------------
# Logging Function
# ------------------------------------
log() {
    local type="$1"
    local msg="$2"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] [$type] $msg" | tee -a "$LOG_FILE" >> "$REPORT_FILE"
}

# ------------------------------------
# Help Menu
# ------------------------------------
show_help() {
    echo "Usage: $0 -i <IP> [--quiet] [--help|-h]"
    echo ""
    echo "Options:"
    echo "  -i <IP>       IP address of the domain controller (e.g., 192.168.1.10)"
    echo "  --quiet       Suppress standard output (silent mode)"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "Example:"
    echo "  sudo $0 -i 192.168.1.10"
    exit 0
}

# ------------------------------------
# Root Privilege Check
# ------------------------------------
check_root() {
    if [[ $(id -u) -ne 0 ]]; then
        log "ERROR" "Script must run as root. Use sudo."
        exit 1
    else
        trueRoot=true
        [[ "$QUIET_MODE" = false ]] && echo "[+] SCRIPT IS RUNNING AS ROOT"
        log "INFO" "Script is running as root."
    fi
}

# ------------------------------------
# Argument Parsing
# ------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i)
                IP="$2"; shift 2;;
            --quiet)
                QUIET_MODE=true; shift;;
            -h|--help)
                show_help;;
            *)
                log "ERROR" "Unknown argument: $1"
                show_help;;
        esac
    done

    if ! [[ "$IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        log "ERROR" "Invalid IPv4 format. Use xxx.xxx.xxx.xxx"
        exit 1
    fi

    log "INFO" "Inputs: IP=$IP"
}

# ------------------------------------
# Connectivity Check
# ------------------------------------
test_connectivity() {
    local host="$1"
    if ping -c 1 -W 2 "$host" > /dev/null 2>&1; then
        [[ "$QUIET_MODE" = false ]] && echo "[+] Host $host is reachable"
        log "Connectivity Check" "Host $host is reachable"
    else
        [[ "$QUIET_MODE" = false ]] && echo "[-] Host $host is not reachable"
        log "ERROR" "Ping to $host failed"
        exit 1
    fi
}

# ------------------------------------
# Clock Synchronization
# ------------------------------------
sync_clock() {
    local ntp_tool="ntpdate"
    local ntp_port=123
    local max_attempts=3
    local attempt=1
    local output=""

    if ! command -v "$ntp_tool" >/dev/null 2>&1; then
        output="Error: $ntp_tool is not installed. Install it with 'sudo apt install ntpdate'."
        echo "[-] $output"
        log "Clock Sync" "$output"
        return 1
    fi

    if ! command -v nc >/dev/null 2>&1; then
        output="Error: netcat (nc) is not installed. Install it with 'sudo apt install netcat'."
        echo "[-] $output"
        log "Clock Sync" "$output"
        return 1
    fi

    if ! nc -z -u -w 2 "$IP" "$ntp_port" >/dev/null 2>&1; then
        output="Error: NTP port $ntp_port/UDP is not open on $IP. Time synchronization skipped."
        echo "[-] $output"
        log "Clock Sync" "$output"
        return 1
    fi

    local sudo_cmd=""
    if [[ $(id -u) -ne 0 ]]; then
        if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
            sudo_cmd="sudo"
        else
            output="Error: sudo is required but not available or not configured for non-interactive use."
            echo "[-] $output"
            log "Clock Sync" "$output"
            return 1
        fi
    fi

    echo "[+] Synchronizing clock with $IP using $ntp_tool..."
    while [[ $attempt -le $max_attempts ]]; do
        output=$($sudo_cmd $ntp_tool "$IP" 2>&1)
        if [[ $? -eq 0 ]]; then
            echo "[+] Successfully synchronized clock with $IP"
            log "Clock Sync" "$output"
            log "INFO" "System time after sync: $(date)"
            return 0
        fi
        echo "[-] Attempt $attempt/$max_attempts failed: $output"
        log "Clock Sync" "Attempt $attempt failed: $output"
        sleep 2
        ((attempt++))
    done

    output="Error: Failed to synchronize clock with $IP after $max_attempts attempts. Last error: $output"
    echo "[-] $output"
    log "Clock Sync" "$output"
    return 1
}

# ------------------------------------
# Main
# ------------------------------------
main() {
    parse_args "$@"
    check_root
    test_connectivity "$IP"
    sync_clock
}

main "$@"
