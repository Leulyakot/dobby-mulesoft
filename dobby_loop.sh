#!/usr/bin/env bash
#
# dobby_loop.sh - Main Autonomous Development Loop
# The Autonomous MuleSoft Development Elf
#
# This is the core of Dobby - the autonomous loop that:
# 1. Reads specifications from MASTER_ORDERS.md
# 2. Executes Claude Code to generate MuleSoft components
# 3. Tracks progress in @magic_plan.md
# 4. Intelligently exits when integration is complete
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

# Loop settings
MAX_LOOPS=${DOBBY_MAX_LOOPS:-100}
LOOP_DELAY=${DOBBY_LOOP_DELAY:-5}           # Seconds between loops
VERBOSE=${DOBBY_VERBOSE:-true}

# Rate limiting
MAX_API_CALLS_PER_HOUR=${DOBBY_MAX_API_CALLS:-100}
RATE_LIMIT_COOLDOWN=${DOBBY_RATE_COOLDOWN:-3600}  # 1 hour in seconds

# Circuit breaker settings
MAX_NO_CHANGE_LOOPS=${DOBBY_MAX_NO_CHANGE:-3}
MAX_SAME_ERROR_LOOPS=${DOBBY_MAX_SAME_ERROR:-5}

# Completion detection
MIN_COMPLETION_SIGNALS=${DOBBY_MIN_COMPLETION:-4}

# Project paths (set when running)
PROJECT_DIR=""
DOBBY_DIR=""
MASTER_ORDERS=""
MAGIC_PLAN=""
AGENT_FILE=""
LOG_DIR=""
STATUS_FILE=""

# State variables
loop_count=0
api_calls=0
api_call_timestamps=()
no_change_count=0
same_error_count=0
last_error=""
last_file_hash=""
completion_signals=0
circuit_breaker_state="closed"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Initialize project paths
init_project_paths() {
    PROJECT_DIR="${1:-$(pwd)}"
    DOBBY_DIR="${PROJECT_DIR}/.dobby"
    MASTER_ORDERS="${DOBBY_DIR}/MASTER_ORDERS.md"
    MAGIC_PLAN="${DOBBY_DIR}/@magic_plan.md"
    AGENT_FILE="${DOBBY_DIR}/@AGENT.md"
    LOG_DIR="${DOBBY_DIR}/house-elf-magic"
    STATUS_FILE="${DOBBY_DIR}/dobby_status.json"
}

# Logging function
log_dobby() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Create log directory if it doesn't exist
    mkdir -p "$LOG_DIR"

    # Log to file
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_DIR}/dobby.log"

    # Display to console if verbose
    if [[ "$VERBOSE" == "true" ]]; then
        format_log "$level" "$message"
    fi
}

# Update status file
update_status() {
    local status=$1
    local current_task=${2:-""}
    local completion_pct=${3:-0}

    cat > "$STATUS_FILE" << EOF
{
  "dobby_status": "${status}",
  "loop_count": ${loop_count},
  "max_loops": ${MAX_LOOPS},
  "api_calls": ${api_calls},
  "completion_percentage": ${completion_pct},
  "current_task": "${current_task}",
  "last_snap": "$(date '+%Y-%m-%dT%H:%M:%S%z')",
  "is_free": true,
  "master_pleased": false,
  "circuit_breaker": "${circuit_breaker_state}",
  "completion_signals": ${completion_signals}
}
EOF
}

# =============================================================================
# VALIDATION
# =============================================================================

# Check if we're in a Dobby project
validate_project() {
    if [[ ! -d "$DOBBY_DIR" ]]; then
        show_error_banner "Not a Dobby project! Run 'dobby-setup' first."
        log_dobby "ERROR" "Not a Dobby project directory"
        return 1
    fi

    if [[ ! -f "$MASTER_ORDERS" ]]; then
        show_error_banner "MASTER_ORDERS.md not found!"
        log_dobby "ERROR" "MASTER_ORDERS.md missing"
        return 1
    fi

    # Check if Claude Code is available
    if ! command -v claude &> /dev/null; then
        show_error_banner "Claude Code CLI not found! Install with: npm install -g @anthropic-ai/claude-code"
        log_dobby "ERROR" "Claude Code CLI not installed"
        return 1
    fi

    return 0
}

# =============================================================================
# RATE LIMITING
# =============================================================================

# Check if we're within rate limits
check_rate_limit() {
    local current_time=$(date +%s)
    local one_hour_ago=$((current_time - 3600))

    # Filter timestamps to only those within the last hour
    local new_timestamps=()
    for ts in "${api_call_timestamps[@]:-}"; do
        if [[ $ts -ge $one_hour_ago ]]; then
            new_timestamps+=("$ts")
        fi
    done
    api_call_timestamps=("${new_timestamps[@]:-}")

    local calls_this_hour=${#api_call_timestamps[@]}

    if [[ $calls_this_hour -ge $MAX_API_CALLS_PER_HOUR ]]; then
        log_dobby "WARN" "Rate limit reached: ${calls_this_hour}/${MAX_API_CALLS_PER_HOUR} calls this hour"
        return 1
    fi

    return 0
}

# Record an API call
record_api_call() {
    api_call_timestamps+=("$(date +%s)")
    api_calls=$((api_calls + 1))
}

# Wait for rate limit to clear
wait_for_rate_limit() {
    local current_time=$(date +%s)
    local oldest_call=${api_call_timestamps[0]:-$current_time}
    local wait_time=$((oldest_call + 3600 - current_time))

    if [[ $wait_time -gt 0 ]]; then
        show_rate_limit_warning "$wait_time"
        update_status "waiting" "Rate limit cooldown" 0
        show_countdown "$wait_time" "Rate limit cooldown"
    fi
}

# =============================================================================
# CIRCUIT BREAKER
# =============================================================================

# Get hash of project files
get_files_hash() {
    local hash_cmd="md5sum"
    if ! command -v md5sum &>/dev/null; then
        hash_cmd="md5 -r"
    fi
    find "$PROJECT_DIR" -type f \( -name "*.xml" -o -name "*.dwl" -o -name "*.raml" -o -name "*.yaml" \) \
        -not -path "*/.dobby/*" -exec $hash_cmd {} \; 2>/dev/null | sort | $hash_cmd 2>/dev/null | cut -d' ' -f1 || echo "none"
}

# Check circuit breaker state
check_circuit_breaker() {
    case $circuit_breaker_state in
        "open")
            log_dobby "ERROR" "Circuit breaker is OPEN - Dobby is stuck!"
            show_circuit_breaker
            return 1
            ;;
        "half-open")
            log_dobby "INFO" "Circuit breaker HALF-OPEN - testing recovery..."
            return 0
            ;;
        "closed")
            return 0
            ;;
    esac
}

# Update circuit breaker based on loop results
update_circuit_breaker() {
    local success=$1
    local current_hash=$(get_files_hash)

    if [[ "$success" == "true" ]]; then
        # Success - close circuit breaker
        circuit_breaker_state="closed"
        no_change_count=0
        same_error_count=0
        last_file_hash="$current_hash"
        return 0
    fi

    # Check for no file changes
    if [[ "$current_hash" == "$last_file_hash" ]]; then
        no_change_count=$((no_change_count + 1))
        log_dobby "WARN" "No file changes detected (${no_change_count}/${MAX_NO_CHANGE_LOOPS})"

        if [[ $no_change_count -ge $MAX_NO_CHANGE_LOOPS ]]; then
            circuit_breaker_state="open"
            log_dobby "ERROR" "Circuit breaker OPENED - no progress detected"
            return 1
        fi
    else
        no_change_count=0
        last_file_hash="$current_hash"
    fi

    return 0
}

# Reset circuit breaker
reset_circuit_breaker() {
    circuit_breaker_state="closed"
    no_change_count=0
    same_error_count=0
    log_dobby "INFO" "Circuit breaker reset"
}

# =============================================================================
# COMPLETION DETECTION
# =============================================================================

# Count completion signals in Claude's output
count_completion_signals() {
    local output_file=$1
    local signals=0

    # Completion keywords to look for
    local keywords=("complete" "completed" "done" "finished" "all tests passing"
                    "integration ready" "successfully" "EXIT_SIGNAL" "no more tasks"
                    "all tasks complete" "master pleased")

    for keyword in "${keywords[@]}"; do
        if grep -qi "$keyword" "$output_file" 2>/dev/null; then
            signals=$((signals + 1))
        fi
    done

    echo $signals
}

# Check if all tasks in magic plan are done
all_tasks_done() {
    if [[ ! -f "$MAGIC_PLAN" ]]; then
        return 1
    fi

    # Count incomplete tasks
    # NOTE: grep -c exits 1 when there are 0 matches but still prints "0".
    # Using $(grep ... || echo "0") would produce "0\n0" in that case.
    # Instead, assign then default to avoid double output.
    local incomplete; incomplete=$(grep -c "^\s*- \[ \]" "$MAGIC_PLAN" 2>/dev/null) || incomplete=0
    local complete;   complete=$(grep -c "^\s*- \[x\]"  "$MAGIC_PLAN" 2>/dev/null) || complete=0

    if [[ $incomplete -eq 0 ]] && [[ $complete -gt 0 ]]; then
        log_dobby "SUCCESS" "All ${complete} tasks in @magic_plan.md are complete!"
        return 0
    fi

    log_dobby "INFO" "Tasks: ${complete} complete, ${incomplete} remaining"
    return 1
}

# Calculate completion percentage
calculate_completion() {
    if [[ ! -f "$MAGIC_PLAN" ]]; then
        echo 0
        return
    fi

    local incomplete; incomplete=$(grep -c "^\s*- \[ \]" "$MAGIC_PLAN" 2>/dev/null) || incomplete=0
    local complete;   complete=$(grep -c "^\s*- \[x\]"  "$MAGIC_PLAN" 2>/dev/null) || complete=0
    local total=$((incomplete + complete))

    if [[ $total -eq 0 ]]; then
        echo 0
    else
        echo $((complete * 100 / total))
    fi
}

# Check all exit conditions
check_exit_conditions() {
    local output_file=${1:-""}

    # Check for explicit EXIT_SIGNAL
    if [[ -n "$output_file" ]] && grep -qi "EXIT_SIGNAL" "$output_file" 2>/dev/null; then
        log_dobby "SUCCESS" "EXIT_SIGNAL detected - Claude says we're done!"
        return 0
    fi

    # Count completion signals
    if [[ -n "$output_file" ]]; then
        local signals=$(count_completion_signals "$output_file")
        completion_signals=$((completion_signals + signals))

        if [[ $completion_signals -ge $MIN_COMPLETION_SIGNALS ]]; then
            log_dobby "SUCCESS" "Strong completion signals detected (${completion_signals})"
            return 0
        fi
    fi

    # Check if all tasks are complete
    if all_tasks_done; then
        return 0
    fi

    # Check max loops
    if [[ $loop_count -ge $MAX_LOOPS ]]; then
        log_dobby "INFO" "Maximum loops reached (${MAX_LOOPS})"
        return 0
    fi

    return 1
}

# =============================================================================
# CLAUDE CODE EXECUTION
# =============================================================================

# Build the prompt for Claude Code
build_prompt() {
    local prompt=""

    # Add agent instructions if available
    if [[ -f "$AGENT_FILE" ]]; then
        prompt+="$(cat "$AGENT_FILE")"$'\n\n'
    fi

    # Add master orders
    prompt+="# MASTER'S ORDERS"$'\n'
    prompt+="$(cat "$MASTER_ORDERS")"$'\n\n'

    # Add current task plan if available
    if [[ -f "$MAGIC_PLAN" ]]; then
        prompt+="# CURRENT TASK PLAN"$'\n'
        prompt+="$(cat "$MAGIC_PLAN")"$'\n\n'
    fi

    # Add context about the current state
    prompt+="# CURRENT STATE"$'\n'
    prompt+="- Loop: ${loop_count}/${MAX_LOOPS}"$'\n'
    prompt+="- Project directory: ${PROJECT_DIR}"$'\n'
    prompt+="- Please continue building the MuleSoft integration."$'\n'
    prompt+="- Mark completed tasks with [x] in @magic_plan.md"$'\n'
    prompt+="- Say 'EXIT_SIGNAL' when all tasks are complete."$'\n'

    echo "$prompt"
}

# Rotate old snap logs, keeping the most recent N
rotate_snap_logs() {
    local keep=${DOBBY_SNAP_LOG_KEEP:-20}
    # List snap logs sorted oldest-first, delete any beyond the keep limit
    local logs=()
    while IFS= read -r f; do logs+=("$f"); done < <(
        ls -t "${LOG_DIR}"/snap_*.log 2>/dev/null
    )
    local total=${#logs[@]}
    if [[ $total -gt $keep ]]; then
        local to_delete=$(( total - keep ))
        for (( i=total-1; i>=total-to_delete; i-- )); do
            rm -f "${logs[$i]}"
        done
        log_dobby "INFO" "Rotated snap logs: kept ${keep}, removed ${to_delete}"
    fi
}

# Execute Claude Code (the "snap")
snap_fingers() {
    local output_file="${LOG_DIR}/snap_${loop_count}.log"
    local prompt=$(build_prompt)

    log_dobby "SNAP" "*SNAP!* Creating MuleSoft magic!"
    show_dobby_snap

    # Record API call
    record_api_call

    # Execute Claude Code
    # Using timeout to prevent hanging (macOS-compatible)
    local timeout_duration=$((60 * 10))  # 10 minutes max per snap

    # Use timeout or gtimeout (macOS via brew), fallback to no timeout
    local timeout_cmd=""
    if command -v timeout &>/dev/null; then
        timeout_cmd="timeout $timeout_duration"
    elif command -v gtimeout &>/dev/null; then
        timeout_cmd="gtimeout $timeout_duration"
    fi

    if $timeout_cmd claude --print "$prompt" > "$output_file" 2>&1; then
        log_dobby "SUCCESS" "Magic completed successfully!"
        return 0
    else
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            log_dobby "WARN" "Claude Code timed out after ${timeout_duration}s"
        else
            log_dobby "ERROR" "Magic failed with exit code: ${exit_code}"
        fi
        return $exit_code
    fi
}

# =============================================================================
# MAIN LOOP
# =============================================================================

run_autonomous_loop() {
    log_dobby "INFO" "Starting autonomous development loop"
    log_dobby "INFO" "Max loops: ${MAX_LOOPS}"
    log_dobby "INFO" "Project: ${PROJECT_DIR}"

    # Initialize file hash for change detection
    last_file_hash=$(get_files_hash)

    while [[ $loop_count -lt $MAX_LOOPS ]]; do
        loop_count=$((loop_count + 1))

        log_dobby "INFO" "━━━━━━━━━━━━━ Loop ${loop_count}/${MAX_LOOPS} ━━━━━━━━━━━━━"

        # Check circuit breaker
        if ! check_circuit_breaker; then
            show_error_banner "Circuit breaker is open! Dobby is stuck."
            update_status "error" "Circuit breaker open" "$(calculate_completion)"
            return 1
        fi

        # Check rate limit
        if ! check_rate_limit; then
            wait_for_rate_limit
        fi

        # Update status
        local completion_pct=$(calculate_completion)
        update_status "working" "Loop ${loop_count}" "$completion_pct"

        # Execute Claude Code
        local output_file="${LOG_DIR}/snap_${loop_count}.log"
        if snap_fingers; then
            update_circuit_breaker "true"
            rotate_snap_logs

            # Check exit conditions
            if check_exit_conditions "$output_file"; then
                show_completion
                update_status "complete" "Integration complete!" 100
                log_dobby "SUCCESS" "Dobby has completed Master's integration!"
                return 0
            fi
        else
            update_circuit_breaker "false"
            show_dobby_sad
        fi

        # Brief delay between loops
        if [[ $loop_count -lt $MAX_LOOPS ]]; then
            log_dobby "INFO" "Dobby is taking a brief rest... (${LOOP_DELAY}s)"
            sleep "$LOOP_DELAY"
        fi
    done

    # Max loops reached
    log_dobby "INFO" "Maximum loops reached - stopping"
    local final_completion=$(calculate_completion)
    update_status "stopped" "Max loops reached" "$final_completion"

    echo ""
    echo -e "${YELLOW}Dobby reached maximum loops (${MAX_LOOPS}).${NC}"
    echo -e "${YELLOW}Completion: ${final_completion}%${NC}"
    echo -e "${YELLOW}Check logs in ${LOG_DIR}${NC}"

    return 0
}

# =============================================================================
# COMMAND LINE INTERFACE
# =============================================================================

show_current_status() {
    init_project_paths "$(pwd)"

    if [[ ! -f "$STATUS_FILE" ]]; then
        echo -e "${YELLOW}No status file found. Has Dobby been started?${NC}"
        return 1
    fi

    show_section "Dobby Status"

    # Parse status file
    local status=$(grep -o '"dobby_status": *"[^"]*"' "$STATUS_FILE" | cut -d'"' -f4)
    local loops=$(grep -o '"loop_count": *[0-9]*' "$STATUS_FILE" | grep -o '[0-9]*')
    local max_loops=$(grep -o '"max_loops": *[0-9]*' "$STATUS_FILE" | grep -o '[0-9]*')
    local completion=$(grep -o '"completion_percentage": *[0-9]*' "$STATUS_FILE" | grep -o '[0-9]*')
    local task=$(grep -o '"current_task": *"[^"]*"' "$STATUS_FILE" | cut -d'"' -f4)

    print_table_header "Current State"
    print_table_row "Status" "$status"
    print_table_row "Loop" "${loops}/${max_loops}"
    print_table_row "Completion" "${completion}%"
    print_table_row "Current Task" "$task"

    echo ""
    show_progress_bar "$completion" 100 "Overall Progress"
    echo ""

    return 0
}

reset_dobby() {
    init_project_paths "$(pwd)"

    if [[ ! -d "$DOBBY_DIR" ]]; then
        echo -e "${RED}Not a Dobby project directory${NC}"
        return 1
    fi

    echo -e "${YELLOW}Resetting Dobby's state...${NC}"

    # Remove status file
    rm -f "$STATUS_FILE"

    # Clear logs (but keep the directory)
    rm -f "${LOG_DIR}"/*.log

    # Reset @magic_plan.md tasks to unchecked (preserve the file)
    if [[ -f "$MAGIC_PLAN" ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' 's/- \[x\]/- [ ]/g' "$MAGIC_PLAN"
        else
            sed -i 's/- \[x\]/- [ ]/g' "$MAGIC_PLAN"
        fi
    fi

    echo -e "${GREEN}Dobby has been reset! Ready for new orders.${NC}"
    return 0
}

main() {
    local command=${1:-"--help"}

    case $command in
        "--snap"|"-s"|"snap")
            init_project_paths "$(pwd)"

            if ! validate_project; then
                exit 1
            fi

            show_welcome
            run_autonomous_loop
            ;;

        "--status"|"-t"|"status")
            show_current_status
            ;;

        "--reset"|"-r"|"reset")
            reset_dobby
            ;;

        "--help"|"-h"|"help")
            show_help
            ;;

        "--version"|"-v"|"version")
            show_version
            ;;

        *)
            echo -e "${RED}Unknown command: ${command}${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
