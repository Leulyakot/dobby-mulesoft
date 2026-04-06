#!/usr/bin/env bash
# test_loop.sh — Shell unit tests for dobby_loop.sh utility functions
#
# Tests the pure functions that can be exercised without a live Claude CLI:
#   - init_project_paths
#   - validate_project (structure checks)
#   - rate limit logic
#   - circuit breaker state machine
#   - completion detection
#   - calculate_completion
#   - all_tasks_done
#   - rotate_snap_logs
#
# Usage:  bash tests/test_loop.sh
# Exit:   0 = all passed, non-zero = failures

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Tiny test framework ───────────────────────────────────────────────────────
PASS=0
FAIL=0
_failures=()

pass() { ((PASS++)) || true; echo "  ✓  $1"; }
fail() {
    ((FAIL++)) || true
    _failures+=("$1")
    echo "  ✗  $1"
}

assert_eq() {
    local name=$1 expected=$2 actual=$3
    if [[ "$expected" == "$actual" ]]; then
        pass "$name"
    else
        fail "$name  (expected='${expected}' actual='${actual}')"
    fi
}

assert_true() {
    local name=$1
    shift
    if "$@" 2>/dev/null; then
        pass "$name"
    else
        fail "$name  (command returned non-zero)"
    fi
}

assert_false() {
    local name=$1
    shift
    if ! "$@" 2>/dev/null; then
        pass "$name"
    else
        fail "$name  (command returned zero, expected non-zero)"
    fi
}

section() { echo; echo "── $1 ──────────────────────────────"; }

# ── Load the module under test ────────────────────────────────────────────────
# Stub every display/UI function before sourcing so they're available
# immediately.  We also strip:
#   - set -euo pipefail  (incompatible with the test framework's arithmetic)
#   - The SCRIPT_DIR / source dobby_banner.sh block (BASH_SOURCE[0] resolves
#     to /dev/fd/N during process substitution, causing an exit 1)
#   - The "Run if executed directly" guard and everything after it

show_error_banner()       { :; }
show_rate_limit_warning() { :; }
show_circuit_breaker()    { :; }
show_countdown()          { :; }
show_completion()         { :; }
show_dobby_snap()         { :; }
show_dobby_sad()          { :; }
show_welcome()            { :; }
show_section()            { :; }
show_progress_bar()       { :; }
show_help()               { :; }
show_version()            { :; }
print_table_header()      { :; }
print_table_row()         { :; }
format_log()              { :; }
log_dobby()               { :; }   # also stub this; tests call update_status directly

# source <(...) is not portable across all bash environments;
# write the stripped script to a temp file and source that instead.
_LOOP_TMP=$(mktemp /tmp/dobby_loop_test_XXXXXX.sh)
trap 'rm -f "$_LOOP_TMP"' EXIT

awk '
    # Drop set -euo pipefail
    /^set -euo pipefail/ { next }

    # Drop the SCRIPT_DIR assignment
    /^SCRIPT_DIR=/ { next }

    # Skip the entire "Source the banner/UI library" if/elif/else/fi block
    /^# Source the banner\/UI library/ { skip=1 }
    skip && /^fi$/ { skip=0; next }
    skip { next }

    # Stop before the "Run if executed directly" guard
    /^# Run if executed directly/ { exit }

    { print }
' "$ROOT_DIR/dobby_loop.sh" > "$_LOOP_TMP"

# shellcheck disable=SC1090
source "$_LOOP_TMP"

# ── Helpers ───────────────────────────────────────────────────────────────────
make_project() {
    # Creates a minimal .dobby project in a temp dir; prints the path
    local tmp
    tmp=$(mktemp -d)
    mkdir -p "$tmp/.dobby/house-elf-magic"
    cat > "$tmp/.dobby/MASTER_ORDERS.md" <<'EOF'
# Orders
- [ ] Task A
- [ ] Task B
EOF
    cat > "$tmp/.dobby/@magic_plan.md" <<'EOF'
# Plan
- [x] Done
- [ ] Pending
EOF
    echo "$tmp"
}

# ── Tests: init_project_paths ─────────────────────────────────────────────────
section "init_project_paths"

TMP=$(make_project)
init_project_paths "$TMP"

assert_eq "PROJECT_DIR set"          "$TMP"                            "$PROJECT_DIR"
assert_eq "DOBBY_DIR set"            "$TMP/.dobby"                     "$DOBBY_DIR"
assert_eq "MASTER_ORDERS set"        "$TMP/.dobby/MASTER_ORDERS.md"    "$MASTER_ORDERS"
assert_eq "MAGIC_PLAN set"           "$TMP/.dobby/@magic_plan.md"      "$MAGIC_PLAN"
assert_eq "LOG_DIR set"              "$TMP/.dobby/house-elf-magic"     "$LOG_DIR"
assert_eq "STATUS_FILE set"         "$TMP/.dobby/dobby_status.json"   "$STATUS_FILE"

rm -rf "$TMP"

# ── Tests: validate_project ───────────────────────────────────────────────────
section "validate_project"

TMP=$(make_project)
init_project_paths "$TMP"

# Happy path — valid project with claude stubbed
claude() { :; }
assert_true  "valid project passes" validate_project

# Missing .dobby dir
TMP2=$(mktemp -d)
init_project_paths "$TMP2"
assert_false "missing .dobby fails"  validate_project

# Missing MASTER_ORDERS.md
TMP3=$(make_project)
init_project_paths "$TMP3"
rm "$TMP3/.dobby/MASTER_ORDERS.md"
assert_false "missing MASTER_ORDERS fails" validate_project

# Claude not found
TMP4=$(make_project)
init_project_paths "$TMP4"
unset -f claude
# Temporarily hide any real 'claude' in PATH
assert_false "missing claude CLI fails" bash -c '
    source <(awk "/^# Run if executed directly/{exit} {print}" '"$ROOT_DIR"'/dobby_loop.sh) 2>/dev/null
    show_error_banner() { :; }
    format_log() { :; }
    init_project_paths "'"$TMP4"'"
    validate_project
'

rm -rf "$TMP" "$TMP2" "$TMP3" "$TMP4"

# Re-stub claude for the rest of the tests
claude() { :; }

# ── Tests: rate limiting ───────────────────────────────────────────────────────
section "rate limiting"

TMP=$(make_project)
init_project_paths "$TMP"

# Reset state
api_call_timestamps=()
api_calls=0
MAX_API_CALLS_PER_HOUR=5

# Under the limit
assert_true  "under limit passes"    check_rate_limit

# Fill up to the limit
for i in {1..5}; do record_api_call; done
assert_false "at limit fails"        check_rate_limit
assert_eq    "api_calls counter"     "5" "$api_calls"

# Old timestamps (> 1 hour ago) should not count
api_call_timestamps=()
one_hour_ago=$(( $(date +%s) - 3700 ))
api_call_timestamps=("$one_hour_ago" "$one_hour_ago" "$one_hour_ago" "$one_hour_ago" "$one_hour_ago")
assert_true  "expired timestamps don't count" check_rate_limit

# Reset
MAX_API_CALLS_PER_HOUR=100
api_call_timestamps=()
api_calls=0
rm -rf "$TMP"

# ── Tests: circuit breaker ─────────────────────────────────────────────────────
section "circuit breaker"

TMP=$(make_project)
init_project_paths "$TMP"

circuit_breaker_state="closed"
no_change_count=0
same_error_count=0
last_file_hash=""
MAX_NO_CHANGE_LOOPS=3

assert_true  "closed breaker passes"      check_circuit_breaker

circuit_breaker_state="half-open"
assert_true  "half-open breaker passes"   check_circuit_breaker

circuit_breaker_state="open"
assert_false "open breaker fails"         check_circuit_breaker

# Reset and test update_circuit_breaker opening after no changes
circuit_breaker_state="closed"
no_change_count=0
last_file_hash="abc123"

# Simulate 3 consecutive loops with same hash (no change)
# We override get_files_hash to return a fixed value
get_files_hash() { echo "abc123"; }

update_circuit_breaker "false"
assert_eq "no_change_count=1 after 1st miss" "1" "$no_change_count"
assert_eq "still closed after 1st miss"      "closed" "$circuit_breaker_state"

update_circuit_breaker "false"
assert_eq "no_change_count=2 after 2nd miss" "2" "$no_change_count"

update_circuit_breaker "false"
assert_eq "circuit opens after 3rd miss"     "open" "$circuit_breaker_state"

# Success closes the breaker
update_circuit_breaker "true"
assert_eq "success closes breaker"           "closed" "$circuit_breaker_state"
assert_eq "no_change_count reset"            "0" "$no_change_count"

# reset_circuit_breaker
circuit_breaker_state="open"
no_change_count=99
reset_circuit_breaker
assert_eq "reset sets state to closed" "closed" "$circuit_breaker_state"
assert_eq "reset zeroes no_change_count" "0" "$no_change_count"

rm -rf "$TMP"

# ── Tests: completion detection ────────────────────────────────────────────────
section "completion detection"

TMP=$(make_project)
init_project_paths "$TMP"
LOG_DIR="$TMP/.dobby/house-elf-magic"

# count_completion_signals
SNAP="$LOG_DIR/snap_test.log"

echo "All tasks are complete. Integration is done!" > "$SNAP"
signals=$(count_completion_signals "$SNAP")
[[ $signals -ge 2 ]] && pass "detects multiple signals" || fail "detects multiple signals (got $signals)"

echo "Nothing useful here." > "$SNAP"
signals=$(count_completion_signals "$SNAP")
assert_eq "no signals in boring output" "0" "$signals"

echo "EXIT_SIGNAL" > "$SNAP"
signals=$(count_completion_signals "$SNAP")
[[ $signals -ge 1 ]] && pass "detects EXIT_SIGNAL" || fail "detects EXIT_SIGNAL (got $signals)"

# all_tasks_done
cat > "$MAGIC_PLAN" <<'EOF'
# Plan
- [x] Done A
- [x] Done B
EOF
assert_true "all_tasks_done when all [x]" all_tasks_done

cat > "$MAGIC_PLAN" <<'EOF'
# Plan
- [x] Done A
- [ ] Still pending
EOF
assert_false "all_tasks_done fails when pending exist" all_tasks_done

cat > "$MAGIC_PLAN" <<'EOF'
# Plan
(empty plan)
EOF
assert_false "all_tasks_done fails on empty plan" all_tasks_done

# calculate_completion
cat > "$MAGIC_PLAN" <<'EOF'
# Plan
- [x] Done
- [x] Done
- [ ] Pending
- [ ] Pending
EOF
pct=$(calculate_completion)
assert_eq "50% completion" "50" "$pct"

cat > "$MAGIC_PLAN" <<'EOF'
# Plan
- [x] Done
- [x] Done
EOF
pct=$(calculate_completion)
assert_eq "100% completion" "100" "$pct"

cat > "$MAGIC_PLAN" <<'EOF'
# Plan
- [ ] A
- [ ] B
EOF
pct=$(calculate_completion)
assert_eq "0% completion" "0" "$pct"

rm -rf "$TMP"

# ── Tests: check_exit_conditions ──────────────────────────────────────────────
section "check_exit_conditions"

TMP=$(make_project)
init_project_paths "$TMP"
LOG_DIR="$TMP/.dobby/house-elf-magic"
SNAP="$LOG_DIR/snap_exit.log"

# EXIT_SIGNAL
echo "EXIT_SIGNAL" > "$SNAP"
completion_signals=0
assert_true "exits on EXIT_SIGNAL" check_exit_conditions "$SNAP"

# Enough completion signals
echo "All done and complete." > "$SNAP"
completion_signals=0
MIN_COMPLETION_SIGNALS=2
assert_true "exits on enough signals" check_exit_conditions "$SNAP"

# Max loops reached
echo "Nothing." > "$SNAP"
completion_signals=0
loop_count=100
MAX_LOOPS=100
assert_true "exits at max loops" check_exit_conditions "$SNAP"

# All tasks done
echo "Nothing." > "$SNAP"
completion_signals=0
loop_count=1
MAX_LOOPS=100
cat > "$MAGIC_PLAN" <<'EOF'
- [x] All done
EOF
assert_true "exits when all tasks done" check_exit_conditions "$SNAP"

# Should NOT exit — pending tasks, low signals, under limit
echo "Nothing." > "$SNAP"
completion_signals=0
loop_count=1
cat > "$MAGIC_PLAN" <<'EOF'
- [x] Done
- [ ] Pending
EOF
assert_false "does not exit prematurely" check_exit_conditions "$SNAP"

rm -rf "$TMP"

# ── Tests: update_status ──────────────────────────────────────────────────────
section "update_status"

TMP=$(make_project)
init_project_paths "$TMP"
loop_count=5
api_calls=10
MAX_LOOPS=100
circuit_breaker_state="closed"
completion_signals=2

update_status "working" "Building flows" 42

[[ -f "$STATUS_FILE" ]] && pass "status file created" || fail "status file created"

status_val=$(jq -r '.dobby_status' "$STATUS_FILE")
assert_eq "status value"       "working" "$status_val"

loop_val=$(jq -r '.loop_count' "$STATUS_FILE")
assert_eq "loop_count value"   "5" "$loop_val"

pct_val=$(jq -r '.completion_percentage' "$STATUS_FILE")
assert_eq "completion_pct"     "42" "$pct_val"

rm -rf "$TMP"

# ── Tests: rotate_snap_logs ───────────────────────────────────────────────────
section "rotate_snap_logs"

TMP=$(make_project)
init_project_paths "$TMP"
LOG_DIR="$TMP/.dobby/house-elf-magic"
DOBBY_SNAP_LOG_KEEP=5

# Create 10 snap logs
for i in $(seq 1 10); do
    echo "snap $i" > "$LOG_DIR/snap_${i}.log"
    sleep 0.01  # ensure distinct mtime ordering
done

rotate_snap_logs
remaining=$(ls "$LOG_DIR"/snap_*.log 2>/dev/null | wc -l | tr -d ' ')
assert_eq "keeps exactly DOBBY_SNAP_LOG_KEEP logs" "5" "$remaining"

# A second rotation when already at the limit should be a no-op
rotate_snap_logs
remaining2=$(ls "$LOG_DIR"/snap_*.log 2>/dev/null | wc -l | tr -d ' ')
assert_eq "second rotation is idempotent" "5" "$remaining2"

# When fewer logs exist than keep limit, nothing is deleted
for i in $(seq 11 13); do
    echo "snap $i" > "$LOG_DIR/snap_${i}.log"
done
DOBBY_SNAP_LOG_KEEP=20
rotate_snap_logs
remaining3=$(ls "$LOG_DIR"/snap_*.log 2>/dev/null | wc -l | tr -d ' ')
assert_eq "no deletion when under keep limit" "8" "$remaining3"

rm -rf "$TMP"

# ── Summary ───────────────────────────────────────────────────────────────────
echo
echo "════════════════════════════════════"
echo "  Results: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════"

if [[ ${#_failures[@]} -gt 0 ]]; then
    echo
    echo "Failed tests:"
    for f in "${_failures[@]}"; do
        echo "  - $f"
    done
fi

[[ $FAIL -eq 0 ]]
