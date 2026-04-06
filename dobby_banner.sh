#!/usr/bin/env bash
#
# dobby_banner.sh - ASCII Art and UI Functions for Dobby
# The Autonomous MuleSoft Development Elf
#
# This file contains all the visual elements:
# - ASCII art banners
# - Color definitions
# - Status indicators
# - Dobby character states
#

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly."
    exit 1
fi

# =============================================================================
# COLOR DEFINITIONS
# =============================================================================

# Check if terminal supports colors
if [[ -t 1 ]] && [[ -n "$(tput colors 2>/dev/null)" ]] && [[ "$(tput colors)" -ge 8 ]]; then
    export NC='\033[0m'           # No Color / Reset
    export RED='\033[0;31m'       # Red - Errors
    export GREEN='\033[0;32m'     # Green - Success
    export YELLOW='\033[0;33m'    # Yellow - Warnings
    export BLUE='\033[0;34m'      # Blue - Info
    export PURPLE='\033[0;35m'    # Purple - Snaps/Actions
    export CYAN='\033[0;36m'      # Cyan - Headers
    export WHITE='\033[0;37m'     # White - Default text
    export BOLD='\033[1m'         # Bold text
    export DIM='\033[2m'          # Dim text
    export BLINK='\033[5m'        # Blinking text (use sparingly)

    # Bright variants
    export BRIGHT_RED='\033[1;31m'
    export BRIGHT_GREEN='\033[1;32m'
    export BRIGHT_YELLOW='\033[1;33m'
    export BRIGHT_BLUE='\033[1;34m'
    export BRIGHT_PURPLE='\033[1;35m'
    export BRIGHT_CYAN='\033[1;36m'
else
    export NC=''
    export RED=''
    export GREEN=''
    export YELLOW=''
    export BLUE=''
    export PURPLE=''
    export CYAN=''
    export WHITE=''
    export BOLD=''
    export DIM=''
    export BLINK=''
    export BRIGHT_RED=''
    export BRIGHT_GREEN=''
    export BRIGHT_YELLOW=''
    export BRIGHT_BLUE=''
    export BRIGHT_PURPLE=''
    export BRIGHT_CYAN=''
fi

# =============================================================================
# MAIN BANNER
# =============================================================================

show_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
+============================================================+
|     ____   ___  ____  ______   __                          |
|    |  _ \ / _ \| __ )|  _ \ \ / /                          |
|    | | | | | | |  _ \| |_) \ V /                           |
|    | |_| | |_| | |_) |  _ < | |                            |
|    |____/ \___/|____/|_| \_\|_|                            |
|                                                            |
|         .---.                                              |
|        | o o |   "Dobby is FREE to build integrations!"    |
|        |  >  |                                             |
|         \___/    Autonomous MuleSoft Development Elf       |
|          |||                                               |
|         /|||\                                              |
+============================================================+
EOF
    echo -e "${NC}"
}

# =============================================================================
# DOBBY CHARACTER STATES
# =============================================================================

# Working Dobby - eyes up, focused
show_dobby_working() {
    echo -e "${PURPLE}"
    cat << 'EOF'
    .---.
   | ^ ^ |   Dobby is working very hard!
   |  >  |
    \___/
     |||
    /|||\
EOF
    echo -e "${NC}"
}

# Happy Dobby - big eyes, smile
show_dobby_happy() {
    echo -e "${GREEN}"
    cat << 'EOF'
    .---.
   | O O |   Dobby has pleased Master!
   | \_/ |
    \___/
     |||
    /|||\
EOF
    echo -e "${NC}"
}

# Sad Dobby - crying, error state
show_dobby_sad() {
    echo -e "${RED}"
    cat << 'EOF'
    .---.
   | ; ; |   Bad Dobby! Dobby made a mistake!
   |  o  |
    \___/
     |||
    /|||\
EOF
    echo -e "${NC}"
}

# Thinking Dobby - concerned look
show_dobby_thinking() {
    echo -e "${YELLOW}"
    cat << 'EOF'
    .---.
   | ? ? |   Dobby is thinking...
   |  ~  |
    \___/
     |||
    /|||\
EOF
    echo -e "${NC}"
}

# Snapping Dobby - taking action
show_dobby_snap() {
    echo -e "${BRIGHT_PURPLE}"
    cat << 'EOF'
    .---.
   | * * |   *SNAP!* Dobby is creating magic!
   |  >  |
    \___/
     |/\
    /|  \
EOF
    echo -e "${NC}"
}

# Waiting Dobby - rate limited
show_dobby_waiting() {
    echo -e "${YELLOW}"
    cat << 'EOF'
    .---.
   | - - |   Dobby must wait for Master's API...
   |  o  |
    \___/
     |||
    /|||\
EOF
    echo -e "${NC}"
}

# Celebrating Dobby - task complete
show_dobby_celebrating() {
    echo -e "${BRIGHT_GREEN}"
    cat << 'EOF'
    \   .---.   /
     \ | O O | /
      \| \-/ |/   Dobby is FREE! Integration complete!
       \___/
        |||
       /|||\
EOF
    echo -e "${NC}"
}

# =============================================================================
# STATUS DISPLAYS
# =============================================================================

# Show progress bar
# Usage: show_progress_bar 50 100 "Building APIs"
show_progress_bar() {
    local current=$1
    local total=$2
    local label=${3:-"Progress"}
    local width=40

    if [[ $total -eq 0 ]]; then
        total=1
    fi

    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    echo -e "${CYAN}${label}: ${NC}[${GREEN}${bar}${NC}] ${BRIGHT_CYAN}${percentage}%${NC}"
}

# Show status line
# Usage: show_status "working" 12 100 45
show_status_line() {
    local status=$1
    local loop=$2
    local max_loops=$3
    local api_calls=$4

    local status_color="${YELLOW}"
    local status_icon="..."

    case $status in
        "working")
            status_color="${PURPLE}"
            status_icon="🫰"
            ;;
        "success")
            status_color="${GREEN}"
            status_icon="✨"
            ;;
        "error")
            status_color="${RED}"
            status_icon="😢"
            ;;
        "waiting")
            status_color="${YELLOW}"
            status_icon="⏳"
            ;;
        "complete")
            status_color="${BRIGHT_GREEN}"
            status_icon="🎉"
            ;;
    esac

    echo -e "${status_color}${status_icon} Status: ${status}${NC} | Loop: ${CYAN}${loop}/${max_loops}${NC} | APIs: ${BLUE}${api_calls}${NC}"
}

# Show divider line
show_divider() {
    local char=${1:-"═"}
    local width=${2:-60}
    local color=${3:-$CYAN}

    echo -e "${color}"
    printf '%*s\n' "$width" '' | tr ' ' "$char"
    echo -e "${NC}"
}

# Show section header
# Usage: show_section "Configuration"
show_section() {
    local title=$1
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    printf "${CYAN}║${NC} ${BOLD}%-58s ${CYAN}║${NC}\n" "$title"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
}

# Show info box
# Usage: show_info_box "Important message here"
show_info_box() {
    local message=$1
    echo ""
    echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC} ${message}"
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
}

# =============================================================================
# LOG MESSAGE FORMATTING
# =============================================================================

# Format log message with timestamp
# Usage: format_log "INFO" "Message here"
format_log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    local color="${WHITE}"
    local icon=""

    case $level in
        "INFO")
            color="${BLUE}"
            icon="🧙"
            ;;
        "SUCCESS")
            color="${GREEN}"
            icon="✨"
            ;;
        "ERROR")
            color="${RED}"
            icon="😢"
            ;;
        "WARN"|"WARNING")
            color="${YELLOW}"
            icon="⚠️"
            ;;
        "SNAP")
            color="${PURPLE}"
            icon="🫰"
            ;;
        "DEBUG")
            color="${DIM}"
            icon="🔍"
            ;;
        "MAGIC")
            color="${BRIGHT_PURPLE}"
            icon="✨"
            ;;
    esac

    echo -e "${DIM}[${timestamp}]${NC} ${color}[${level}]${NC} ${icon}  ${message}"
}

# =============================================================================
# SPECIAL MESSAGES
# =============================================================================

# Welcome message when starting
show_welcome() {
    show_banner
    echo ""
    echo -e "${GREEN}  Master has given Dobby a specification!${NC}"
    echo -e "${BRIGHT_GREEN}  Dobby is FREE to build integrations!${NC}"
    echo ""
    show_divider "─" 60 "$CYAN"
}

# Completion message
show_completion() {
    echo ""
    show_divider "═" 60 "$GREEN"
    show_dobby_celebrating
    echo -e "${BRIGHT_GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_GREEN}║    🎉  DOBBY HAS COMPLETED MASTER'S INTEGRATION!  🎉      ║${NC}"
    echo -e "${BRIGHT_GREEN}║                                                            ║${NC}"
    echo -e "${BRIGHT_GREEN}║         Master's MuleSoft project is ready!              ║${NC}"
    echo -e "${BRIGHT_GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Error message
show_error_banner() {
    local message=$1
    echo ""
    show_dobby_sad
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  😢  Dobby encountered an error!                          ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${RED}   Error: ${message}${NC}"
    echo ""
}

# Rate limit warning
show_rate_limit_warning() {
    local wait_time=$1
    echo ""
    show_dobby_waiting
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  ⏳  Dobby must wait - API rate limit reached             ║${NC}"
    echo -e "${YELLOW}║      Waiting ${wait_time} seconds for Master's API...           ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Circuit breaker warning
show_circuit_breaker() {
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ⚡  Circuit Breaker OPEN                                  ║${NC}"
    echo -e "${RED}║      Dobby detected a stuck loop!                         ║${NC}"
    echo -e "${RED}║      Please check the logs and MASTER_ORDERS.md           ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# =============================================================================
# HELP DISPLAY
# =============================================================================

show_help() {
    show_banner
    echo ""
    echo -e "${CYAN}USAGE:${NC}"
    echo "  dobby [OPTIONS]"
    echo ""
    echo -e "${CYAN}OPTIONS:${NC}"
    echo -e "  ${GREEN}--snap${NC}              Start autonomous development loop"
    echo -e "  ${GREEN}--status${NC}            Show current project status"
    echo -e "  ${GREEN}--reset${NC}             Reset Dobby's state (clear progress)"
    echo -e "  ${GREEN}--help${NC}              Show this help message"
    echo -e "  ${GREEN}--version${NC}           Show version information"
    echo ""
    echo -e "${CYAN}COMMANDS:${NC}"
    echo -e "  ${GREEN}dobby-setup${NC} <name>  Create a new MuleSoft project"
    echo -e "  ${GREEN}dobby-monitor${NC}       Start live monitoring dashboard"
    echo ""
    echo -e "${CYAN}EXAMPLES:${NC}"
    echo "  dobby-setup customer-sync   # Create new project"
    echo "  cd customer-sync"
    echo "  # Edit .dobby/MASTER_ORDERS.md with your requirements"
    echo "  dobby --snap                # Start autonomous development"
    echo ""
    echo -e "${CYAN}FILES:${NC}"
    echo "  .dobby/MASTER_ORDERS.md     Integration requirements (the 'sock')"
    echo "  .dobby/@magic_plan.md       Task tracking"
    echo "  .dobby/@AGENT.md            Build instructions"
    echo "  .dobby/house-elf-magic/     Logs directory"
    echo ""
    echo -e "${YELLOW}\"Master gives Dobby a sock, and Dobby is FREE!\"${NC}"
    echo ""
}

# Show version
show_version() {
    echo -e "${CYAN}Dobby${NC} - The Autonomous MuleSoft Development Elf"
    echo "Version: 1.0.0"
    echo "License: MIT"
    echo ""
    echo "Powered by Claude Code"
}

# =============================================================================
# MONITOR DISPLAY
# =============================================================================

# Show monitor header
show_monitor_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               🧦 DOBBY'S MAGIC MONITOR 🧦                  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Show monitor dashboard
# Usage: show_monitor_dashboard "working" 12 100 45 50
show_monitor_dashboard() {
    local status=$1
    local loop=$2
    local max_loops=$3
    local api_calls=$4
    local progress=$5

    # Choose Dobby state based on status
    case $status in
        "working")
            show_dobby_working
            ;;
        "success"|"complete")
            show_dobby_happy
            ;;
        "error")
            show_dobby_sad
            ;;
        "waiting")
            show_dobby_waiting
            ;;
        *)
            show_dobby_thinking
            ;;
    esac

    echo ""
    echo -e "   ${CYAN}Loop:${NC}     ${loop}/${max_loops}"
    echo -e "   ${CYAN}APIs:${NC}     ${api_calls} calls"
    echo ""
    show_progress_bar "$progress" 100 "   Progress"
    echo ""
}

# =============================================================================
# SPINNER ANIMATION
# =============================================================================

# Spinner characters
SPINNER_CHARS=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
SPINNER_PID=""

# Start spinner
# Usage: start_spinner "Loading..."
start_spinner() {
    local message=${1:-"Working..."}

    (
        local i=0
        while true; do
            printf "\r${PURPLE}${SPINNER_CHARS[$i]} ${message}${NC}"
            i=$(( (i + 1) % ${#SPINNER_CHARS[@]} ))
            sleep 0.1
        done
    ) &

    SPINNER_PID=$!
    disown
}

# Stop spinner
stop_spinner() {
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null || true
        wait "$SPINNER_PID" 2>/dev/null || true
        SPINNER_PID=""
        printf "\r                                                    \r"
    fi
}

# =============================================================================
# COUNTDOWN DISPLAY
# =============================================================================

# Show countdown timer
# Usage: show_countdown 60 "Waiting for API rate limit"
show_countdown() {
    local seconds=$1
    local message=${2:-"Waiting"}

    while [[ $seconds -gt 0 ]]; do
        printf "\r${YELLOW}⏳ ${message}: %02d:%02d${NC}" $((seconds/60)) $((seconds%60))
        sleep 1
        ((seconds--))
    done
    printf "\r                                                    \r"
}

# =============================================================================
# TABLE FORMATTING
# =============================================================================

# Print a simple table row
# Usage: print_table_row "Label" "Value"
print_table_row() {
    local label=$1
    local value=$2
    printf "  ${CYAN}%-20s${NC} %s\n" "${label}:" "$value"
}

# Print a table header
print_table_header() {
    local title=$1
    echo ""
    echo -e "  ${BOLD}${title}${NC}"
    echo "  ────────────────────────────────────────"
}
