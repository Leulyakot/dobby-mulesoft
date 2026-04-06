#!/usr/bin/env bash
#
# dobby_monitor.sh - Live Monitoring Dashboard
# The Autonomous MuleSoft Development Elf
#
# Provides a real-time view of Dobby's progress:
# - Current status and loop count
# - API call tracking
# - Progress percentage
# - Recent log entries
# - Task completion status
#

set -euo pipefail

# =============================================================================
# SCRIPT LOCATION
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the banner/UI library
if [[ -f "${SCRIPT_DIR}/dobby_banner.sh" ]]; then
    source "${SCRIPT_DIR}/dobby_banner.sh"
elif [[ -f "${HOME}/.dobby/dobby_banner.sh" ]]; then
    source "${HOME}/.dobby/dobby_banner.sh"
else
    echo "Error: Cannot find dobby_banner.sh"
    exit 1
fi

# =============================================================================
# CONFIGURATION
# =============================================================================

REFRESH_INTERVAL=${DOBBY_MONITOR_REFRESH:-2}  # Seconds between updates
LOG_LINES=${DOBBY_MONITOR_LOGS:-10}           # Number of log lines to show

# Project paths
PROJECT_DIR=""
DOBBY_DIR=""
STATUS_FILE=""
LOG_DIR=""
MAGIC_PLAN=""

# =============================================================================
# INITIALIZATION
# =============================================================================

init_monitor() {
    PROJECT_DIR="${1:-$(pwd)}"
    DOBBY_DIR="${PROJECT_DIR}/.dobby"
    STATUS_FILE="${DOBBY_DIR}/dobby_status.json"
    LOG_DIR="${DOBBY_DIR}/house-elf-magic"
    MAGIC_PLAN="${DOBBY_DIR}/@magic_plan.md"

    # Validate project
    if [[ ! -d "$DOBBY_DIR" ]]; then
        echo -e "${RED}Error: Not a Dobby project directory${NC}"
        echo "Run 'dobby-setup <project-name>' first."
        exit 1
    fi
}

# =============================================================================
# DATA RETRIEVAL
# =============================================================================

# Get status from JSON file
get_status() {
    local field=$1
    local default=${2:-"unknown"}

    if [[ -f "$STATUS_FILE" ]]; then
        local value=$(grep -o "\"${field}\": *\"[^\"]*\"" "$STATUS_FILE" 2>/dev/null | cut -d'"' -f4)
        if [[ -z "$value" ]]; then
            # Try numeric value
            value=$(grep -o "\"${field}\": *[0-9]*" "$STATUS_FILE" 2>/dev/null | grep -o '[0-9]*$')
        fi
        echo "${value:-$default}"
    else
        echo "$default"
    fi
}

# Get task counts from magic plan
get_task_counts() {
    if [[ -f "$MAGIC_PLAN" ]]; then
        local complete
        local incomplete
        complete=$(grep -c '\- \[x\]' "$MAGIC_PLAN" 2>/dev/null) || complete=0
        incomplete=$(grep -c '\- \[ \]' "$MAGIC_PLAN" 2>/dev/null) || incomplete=0
        printf "%d:%d" "$complete" "$incomplete"
    else
        printf "0:0"
    fi
}

# Get recent log entries
get_recent_logs() {
    local count=${1:-10}
    local log_file="${LOG_DIR}/dobby.log"

    if [[ -f "$log_file" ]]; then
        tail -n "$count" "$log_file" 2>/dev/null
    else
        echo "No log entries yet..."
    fi
}

# Get the current snap log
get_current_snap_log() {
    local loop=$(get_status "loop_count" "0")
    local snap_file="${LOG_DIR}/snap_${loop}.log"

    if [[ -f "$snap_file" ]]; then
        tail -n 5 "$snap_file" 2>/dev/null
    fi
}

# =============================================================================
# DISPLAY FUNCTIONS
# =============================================================================

# Clear screen and show header
show_header() {
    clear
    echo -e "${CYAN}+============================================================+${NC}"
    echo -e "${CYAN}|               DOBBY'S MAGIC MONITOR                        |${NC}"
    echo -e "${CYAN}+============================================================+${NC}"
    echo ""
}

# Show Dobby based on status
show_dobby_status() {
    local status=$1

    case $status in
        "working")
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
            ;;
        "complete"|"success")
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
            ;;
        "error")
            echo -e "${RED}"
            cat << 'EOF'
        .---.
       | ; ; |   Bad Dobby! Something went wrong!
       |  o  |
        \___/
         |||
        /|||\
EOF
            echo -e "${NC}"
            ;;
        "waiting")
            echo -e "${YELLOW}"
            cat << 'EOF'
        .---.
       | - - |   Dobby is waiting...
       |  o  |
        \___/
         |||
        /|||\
EOF
            echo -e "${NC}"
            ;;
        "stopped")
            echo -e "${YELLOW}"
            cat << 'EOF'
        .---.
       | . . |   Dobby has stopped
       |  -  |
        \___/
         |||
        /|||\
EOF
            echo -e "${NC}"
            ;;
        *)
            echo -e "${BLUE}"
            cat << 'EOF'
        .---.
       | ? ? |   Dobby is ready for orders!
       |  ~  |
        \___/
         |||
        /|||\
EOF
            echo -e "${NC}"
            ;;
    esac
}

# Show status metrics
show_metrics() {
    local status=$(get_status "dobby_status" "idle")
    local loop=$(get_status "loop_count" "0")
    local max_loops=$(get_status "max_loops" "100")
    local api_calls=$(get_status "api_calls" "0")
    local completion=$(get_status "completion_percentage" "0")
    local current_task=$(get_status "current_task" "Waiting for orders")
    local circuit=$(get_status "circuit_breaker" "closed")

    # Task counts
    local task_counts=$(get_task_counts)
    local tasks_complete=$(echo "$task_counts" | cut -d':' -f1 | tr -d '[:space:]')
    local tasks_remaining=$(echo "$task_counts" | cut -d':' -f2 | tr -d '[:space:]')
    tasks_complete=${tasks_complete:-0}
    tasks_remaining=${tasks_remaining:-0}
    local total_tasks=$((tasks_complete + tasks_remaining))

    # Status color
    local status_color="${YELLOW}"
    case $status in
        "working") status_color="${PURPLE}" ;;
        "complete"|"success") status_color="${GREEN}" ;;
        "error") status_color="${RED}" ;;
        "waiting") status_color="${YELLOW}" ;;
    esac

    # Circuit breaker color
    local circuit_color="${GREEN}"
    case $circuit in
        "open") circuit_color="${RED}" ;;
        "half-open") circuit_color="${YELLOW}" ;;
    esac

    echo -e "${CYAN}+------------------------------------------------------------+${NC}"
    echo -e "${CYAN}|                        STATUS                              |${NC}"
    echo -e "${CYAN}+------------------------------------------------------------+${NC}"
    echo ""

    printf "  ${CYAN}%-18s${NC} ${status_color}%-20s${NC}   ${CYAN}%-10s${NC} %s\n" \
        "Status:" "$status" "Loop:" "${loop}/${max_loops}"

    printf "  ${CYAN}%-18s${NC} %-20s   ${CYAN}%-10s${NC} %s\n" \
        "API Calls:" "$api_calls" "Circuit:" "${circuit_color}${circuit}${NC}"

    printf "  ${CYAN}%-18s${NC} %-20s   ${CYAN}%-10s${NC} %s/%s\n" \
        "Current Task:" "${current_task:0:20}" "Tasks:" "$tasks_complete" "$total_tasks"

    echo ""

    # Progress bar
    echo -e "  ${CYAN}Progress:${NC}"
    local bar_width=50
    local filled=$((completion * bar_width / 100))
    local empty=$((bar_width - filled))

    printf "  ["
    printf "${GREEN}"
    for ((i=0; i<filled; i++)); do printf "█"; done
    printf "${NC}"
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "] ${BRIGHT_CYAN}%d%%${NC}\n" "$completion"

    echo ""
}

# Show recent activity
show_activity() {
    echo -e "${CYAN}+------------------------------------------------------------+${NC}"
    echo -e "${CYAN}|                    RECENT ACTIVITY                         |${NC}"
    echo -e "${CYAN}+------------------------------------------------------------+${NC}"
    echo ""

    local logs=$(get_recent_logs "$LOG_LINES")

    while IFS= read -r line; do
        # Colorize based on log level
        if [[ "$line" == *"[SUCCESS]"* ]]; then
            echo -e "  ${GREEN}${line}${NC}"
        elif [[ "$line" == *"[ERROR]"* ]]; then
            echo -e "  ${RED}${line}${NC}"
        elif [[ "$line" == *"[WARN]"* ]] || [[ "$line" == *"[WARNING]"* ]]; then
            echo -e "  ${YELLOW}${line}${NC}"
        elif [[ "$line" == *"[SNAP]"* ]]; then
            echo -e "  ${PURPLE}${line}${NC}"
        else
            echo -e "  ${DIM}${line}${NC}"
        fi
    done <<< "$logs"

    echo ""
}

# Show task list summary
show_tasks() {
    if [[ ! -f "$MAGIC_PLAN" ]]; then
        return
    fi

    echo -e "${CYAN}+------------------------------------------------------------+${NC}"
    echo -e "${CYAN}|                      TASK STATUS                           |${NC}"
    echo -e "${CYAN}+------------------------------------------------------------+${NC}"
    echo ""

    # Show last 5 completed and next 5 pending tasks
    echo -e "  ${GREEN}Recently Completed:${NC}"
    grep "^\s*- \[x\]" "$MAGIC_PLAN" 2>/dev/null | tail -3 | while read -r line; do
        echo -e "    ${GREEN}✓${NC} ${line#*] }"
    done

    echo ""
    echo -e "  ${YELLOW}Up Next:${NC}"
    grep "^\s*- \[ \]" "$MAGIC_PLAN" 2>/dev/null | head -3 | while read -r line; do
        echo -e "    ${YELLOW}○${NC} ${line#*] }"
    done

    echo ""
}

# Show footer with controls
show_footer() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo -e "${DIM}+------------------------------------------------------------+${NC}"
    echo -e "${DIM}|  Last updated: ${timestamp}                       |${NC}"
    echo -e "${DIM}|  Press Ctrl+C to exit  |  Refresh: ${REFRESH_INTERVAL}s                       |${NC}"
    echo -e "${DIM}+------------------------------------------------------------+${NC}"
}

# Full dashboard refresh
refresh_dashboard() {
    local status=$(get_status "dobby_status" "idle")

    show_header
    show_dobby_status "$status"
    show_metrics
    show_activity
    show_tasks
    show_footer
}

# =============================================================================
# TMUX INTEGRATION
# =============================================================================

# Check if tmux is available
has_tmux() {
    command -v tmux &> /dev/null
}

# Start monitor in a tmux pane
start_tmux_monitor() {
    if ! has_tmux; then
        echo -e "${YELLOW}tmux not found. Running in current terminal.${NC}"
        return 1
    fi

    # Check if we're already in tmux
    if [[ -n "${TMUX:-}" ]]; then
        echo -e "${YELLOW}Already in tmux. Running in current pane.${NC}"
        return 1
    fi

    # Create new tmux session with monitor
    tmux new-session -d -s dobby-monitor "$0 --loop"
    tmux attach-session -t dobby-monitor
}

# =============================================================================
# MAIN LOOP
# =============================================================================

run_monitor_loop() {
    # Handle Ctrl+C gracefully
    trap 'echo ""; echo -e "${CYAN}Dobby monitor stopped.${NC}"; exit 0' INT

    while true; do
        refresh_dashboard
        sleep "$REFRESH_INTERVAL"
    done
}

# Single refresh (for scripting)
run_single_refresh() {
    refresh_dashboard
}

# =============================================================================
# COMMAND LINE INTERFACE
# =============================================================================

show_monitor_help() {
    show_banner
    echo ""
    echo -e "${CYAN}USAGE:${NC}"
    echo "  dobby-monitor [OPTIONS] [project-directory]"
    echo ""
    echo -e "${CYAN}OPTIONS:${NC}"
    echo -e "  ${GREEN}--loop${NC}        Run continuous monitoring (default)"
    echo -e "  ${GREEN}--once${NC}        Show status once and exit"
    echo -e "  ${GREEN}--tmux${NC}        Start monitor in tmux session"
    echo -e "  ${GREEN}--help${NC}        Show this help message"
    echo ""
    echo -e "${CYAN}ENVIRONMENT VARIABLES:${NC}"
    echo "  DOBBY_MONITOR_REFRESH   Refresh interval in seconds (default: 2)"
    echo "  DOBBY_MONITOR_LOGS      Number of log lines to show (default: 10)"
    echo ""
    echo -e "${CYAN}EXAMPLES:${NC}"
    echo "  dobby-monitor                    # Monitor current directory"
    echo "  dobby-monitor /path/to/project   # Monitor specific project"
    echo "  dobby-monitor --once             # Show status once"
    echo "  dobby-monitor --tmux             # Start in tmux session"
    echo ""
}

main() {
    local mode="loop"
    local project_dir="."

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            "--help"|"-h")
                show_monitor_help
                exit 0
                ;;
            "--loop"|"-l")
                mode="loop"
                shift
                ;;
            "--once"|"-o")
                mode="once"
                shift
                ;;
            "--tmux"|"-t")
                mode="tmux"
                shift
                ;;
            -*)
                echo -e "${RED}Unknown option: $1${NC}"
                show_monitor_help
                exit 1
                ;;
            *)
                project_dir="$1"
                shift
                ;;
        esac
    done

    # Initialize
    init_monitor "$project_dir"

    # Run based on mode
    case $mode in
        "loop")
            run_monitor_loop
            ;;
        "once")
            run_single_refresh
            ;;
        "tmux")
            start_tmux_monitor || run_monitor_loop
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
