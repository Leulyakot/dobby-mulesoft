#!/usr/bin/env bash
# ============================================================================
#  DOBBY UI - Lightweight Web Interface for the Autonomous MuleSoft Elf
# ============================================================================
#  Usage:
#    dobby-ui [OPTIONS] [PROJECT_PATH]
#
#  Options:
#    --port PORT   Set server port (default: 3131)
#    --open        Auto-open browser
#    --help        Show help
# ============================================================================

set -euo pipefail

# ── Colors ──
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# ── Defaults ──
PORT=3131
OPEN_BROWSER=false
PROJECT_PATH=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Parse args ──
while [[ $# -gt 0 ]]; do
    case "$1" in
        --port)
            PORT="$2"; shift 2 ;;
        --open)
            OPEN_BROWSER=true; shift ;;
        --help|-h)
            echo -e "${CYAN}${BOLD}DOBBY UI${NC} - Web interface for the Autonomous MuleSoft Elf"
            echo ""
            echo "Usage: dobby-ui [OPTIONS] [PROJECT_PATH]"
            echo ""
            echo "Options:"
            echo "  --port PORT   Set server port (default: 3131)"
            echo "  --open        Auto-open browser after starting"
            echo "  --help, -h    Show this help message"
            echo ""
            echo "Examples:"
            echo "  dobby-ui                        # Start on port 3131"
            echo "  dobby-ui --port 8080            # Start on port 8080"
            echo "  dobby-ui --open ./my-project    # Start and open browser"
            echo ""
            exit 0
            ;;
        *)
            PROJECT_PATH="$1"; shift ;;
    esac
done

# ── Check Python 3 ──
if ! command -v python3 &>/dev/null; then
    echo -e "${RED}Error:${NC} Python 3 is required but not found."
    echo "Install it with: sudo apt install python3"
    exit 1
fi

# ── Find server script ──
SERVER_SCRIPT=""
CANDIDATES=(
    "${SCRIPT_DIR}/dobby_server.py"
    "${DOBBY_HOME:-}/dobby_server.py"
    "${HOME}/.dobby/dobby_server.py"
)

for candidate in "${CANDIDATES[@]}"; do
    if [[ -f "$candidate" ]]; then
        SERVER_SCRIPT="$candidate"
        break
    fi
done

if [[ -z "$SERVER_SCRIPT" ]]; then
    echo -e "${RED}Error:${NC} Cannot find dobby_server.py"
    exit 1
fi

# ── Build command ──
CMD="python3 ${SERVER_SCRIPT} ${PORT}"
if [[ -n "$PROJECT_PATH" ]]; then
    CMD="${CMD} ${PROJECT_PATH}"
fi

# ── Open browser ──
if [[ "$OPEN_BROWSER" == true ]]; then
    (
        sleep 1
        URL="http://localhost:${PORT}"
        if command -v xdg-open &>/dev/null; then
            xdg-open "$URL" 2>/dev/null
        elif command -v open &>/dev/null; then
            open "$URL"
        else
            echo -e "${DIM}Open ${URL} in your browser${NC}"
        fi
    ) &
fi

# ── Start server ──
exec $CMD
