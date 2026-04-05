# Dobby — Autonomous MuleSoft Development Elf

```
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
```

**Dobby** is an autonomous agent that builds MuleSoft integrations for you. Write a plain-English specification — Dobby calls [Claude Code](https://github.com/anthropics/claude-code) in a loop, generating MuleSoft XML flows, DataWeave transformations, and MUnit tests, iterating until the integration is complete.

Named after Harry Potter's loyal house-elf: just as Dobby was freed by a sock, Dobby the agent is freed to work when you hand it a specification.

---

## Table of Contents

- [How It Works](#how-it-works)
- [Quick Start](#quick-start)
- [Docker](#docker)
- [Web UI Walkthrough](#web-ui-walkthrough)
- [Writing a Specification](#writing-a-specification)
- [Sample Specification](#sample-specification)
- [Project Structure](#project-structure)
- [Commands](#commands)
- [Configuration](#configuration)
- [Monitoring](#monitoring)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Requirements](#requirements)

---

## How It Works

```
You write MASTER_ORDERS.md
        │
        ▼
  dobby --snap
        │
        ▼
┌───────────────────────────────────────────┐
│              Dobby Loop                   │
│                                           │
│  1. Read MASTER_ORDERS.md + @magic_plan   │
│  2. Build prompt for Claude Code          │
│  3. claude --print "$prompt"              │
│  4. Claude writes MuleSoft files          │
│  5. Check completion signals              │
│  6. Check circuit breaker                 │
│  7. Check rate limit                      │
│  8. Update dobby_status.json              │
│  9. Sleep 5s → repeat                     │
└───────────────────────────────────────────┘
        │
        ▼
  Integration complete ✓
  (or max loops / EXIT_SIGNAL / all tasks [x])
```

### The Loop in Detail

Each iteration ("snap") does the following:

| Step | What happens |
|------|-------------|
| **Read** | Loads `MASTER_ORDERS.md` (your spec) and `@magic_plan.md` (task checklist) |
| **Prompt** | Combines spec + plan + loop context into a single prompt |
| **Snap** | Runs `claude --print "$prompt"` — Claude reads and writes files in your project |
| **Detect** | Checks Claude's output for `EXIT_SIGNAL`, completion keywords, or all `[x]` tasks |
| **Guard** | Circuit breaker opens if no files changed for 3 consecutive loops |
| **Rate** | Pauses automatically if API call limit for the hour is reached |
| **Status** | Writes `dobby_status.json` so the monitor and web UI can show live progress |

### What Dobby Generates

Dobby follows MuleSoft's **API-led connectivity** pattern:

```
Experience API  ──  consumer-facing REST endpoints (RAML)
      │
Process API     ──  business logic, orchestration, DataWeave transforms
      │
System API      ──  raw connectors (Salesforce, databases, HTTP, etc.)
```

Each layer gets:
- MuleSoft flow XML (`src/main/mule/`)
- DataWeave scripts (`src/main/resources/dwl/`)
- MUnit tests (`src/test/munit/`)

### Safeguards

| Safeguard | Behaviour |
|-----------|-----------|
| **Circuit breaker** | Opens after 3 loops with no file changes — stops stuck loops |
| **Rate limiter** | Caps Claude API calls per hour; waits automatically when reached |
| **Max loops** | Hard ceiling (default 100) regardless of completion state |
| **Timeout** | Each Claude invocation times out at 10 minutes |

---

## Quick Start

### 1. Prerequisites

```bash
# Claude Code CLI (required)
npm install -g @anthropic-ai/claude-code

# Recommended
brew install jq tmux      # macOS
# apt install jq tmux     # Linux
```

### 2. Install Dobby

```bash
git clone https://github.com/yourusername/dobby-mulesoft.git
cd dobby-mulesoft
./install.sh
```

### 3. Create a project

```bash
dobby-setup my-integration
cd my-integration
```

### 4. Write your specification

```bash
# Edit the spec in your preferred editor
code .dobby/MASTER_ORDERS.md
```

See [Writing a Specification](#writing-a-specification) and the [Sample Specification](#sample-specification) below.

### 5. Run

**Terminal mode:**
```bash
# Terminal 1 — run the loop
dobby --snap

# Terminal 2 — watch progress
dobby-monitor
```

**Web UI mode:**
```bash
# Start the web dashboard
dobby-ui --open

# Then click Load, enter your project path, and click Start
```

---

## Docker

Run Dobby in a container — no local installation required.

### Prerequisites

- Docker + Docker Compose
- Your Anthropic API key

### Start

```bash
# Set your API key
export ANTHROPIC_API_KEY=sk-ant-...

# Create a workspace directory for your projects
mkdir -p workspace/my-integration

# Build and run
docker compose up --build
```

Open **http://localhost:3131** in your browser.

### Using the UI from Docker

After the container is running:

1. Click **Load** in the web UI
2. Enter `/workspace/my-integration` as the project path (this maps to `./workspace/my-integration` on your host)
3. Edit the MASTER_ORDERS.md in the browser editor
4. Click **Start**

### Custom workspace path

```bash
DOBBY_WORKSPACE=/path/to/your/projects docker compose up
```

### Configuration via environment

```bash
# docker-compose.yml already passes these; override as needed:
DOBBY_MAX_LOOPS=50 DOBBY_LOOP_DELAY=3 docker compose up
```

### Stop

```bash
docker compose down
```

---

## Web UI Walkthrough

Start the web UI with `dobby-ui --open` (or via Docker at http://localhost:3131).

```
┌─────────────────────────────────────────────────────────┐
│  DOBBY                                          ● idle  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Project path: [ /path/to/my-integration    ] [Load]   │
│                                                         │
│  Max loops: [100]          [▶ Start]  [■ Stop]          │
│                                                         │
│  Progress ████████████░░░░░░░░░░░░░░░ 42%               │
│  Tasks: 5 / 12   Loop: 8 / 100   API calls: 8          │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  MASTER_ORDERS  [▼ expand]                              │
│  LOG STREAM                                             │
│  [2024-01-15 10:32:01] [SNAP] Creating MuleSoft magic!  │
│  [2024-01-15 10:32:45] [SUCCESS] Created flow XML       │
│  [2024-01-15 10:32:45] [INFO] Tasks: 5 done, 7 remain   │
└─────────────────────────────────────────────────────────┘
```

**Workflow:**
1. Enter your project path and click **Load** — creates `.dobby/` structure if missing
2. Expand **MASTER_ORDERS** to write or paste your specification directly in the browser
3. Set **Max loops** (lower = faster feedback for testing, e.g. `5`)
4. Click **Start** — the loop begins and the log stream updates live
5. Click **Stop** at any time to interrupt cleanly

The UI polls every 2 seconds and requires no page refresh.

---

## Writing a Specification

`MASTER_ORDERS.md` is plain Markdown. The more specific you are, the better Dobby's output.

### Essential sections

```markdown
# Master's Integration Orders

## What Dobby Must Build
Brief description of the integration.

## Runtime Configuration
MuleSoft Runtime Version, Java version, Maven version.

## Source Systems
What data comes from where, how to connect, what fields matter.

## Target Systems
Where data goes, what the output format should look like.

## Data Transformations
Input JSON → output JSON examples with field mapping logic.

## Business Rules
Validation logic, deduplication, error handling behaviour.

## Acceptance Criteria
- [ ] Checkbox for each deliverable  ← Dobby marks these [x] as it works
```

### Tips for better output

| Do | Don't |
|----|-------|
| Provide sample JSON input/output | Leave transformations vague ("transform the data") |
| List exact field names | Use generic names ("some fields") |
| Specify runtime versions | Omit version numbers |
| Write checkbox acceptance criteria | Use prose-only completion criteria |
| Keep scope focused | Pack 10 integrations into one spec |

---

## Sample Specification

A minimal spec that requires no external systems — good for a first test run:

```markdown
# Master's Integration Orders

## What Dobby Must Build
**Project Name**: Hello World REST API
**Integration Type**: Experience API only

## Runtime Configuration
**MuleSoft Runtime Version**: 4.8.0
**Java Version**: 17
**Maven Version**: 3.9.6
**Mule Maven Plugin Version**: 4.3.0
**MUnit Version**: 3.3.0

## Integration Overview
A simple HTTP REST API that:
- Exposes GET /greet
- Accepts optional `name` query parameter
- Returns a JSON greeting
- Defaults name to "World" when omitted

## API Specification

### GET /greet?name=Dobby → 200 OK
```json
{
  "message": "Hello, Dobby!",
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "ok"
}
```

### GET /greet (no param) → 200 OK
```json
{
  "message": "Hello, World!",
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "ok"
}
```

## DataWeave Logic
- message: `"Hello, " ++ (attributes.queryParams.name default "World") ++ "!"`
- timestamp: current datetime in ISO 8601
- status: always "ok"

## Acceptance Criteria
- [ ] HTTP Listener on 0.0.0.0:8081, path /greet
- [ ] DataWeave transforms query param into greeting JSON
- [ ] Default name "World" when param is absent
- [ ] MUnit test: GET /greet?name=Dobby → "Hello, Dobby!"
- [ ] MUnit test: GET /greet → "Hello, World!"
- [ ] Global error handler returning 500 on exceptions
- [ ] All MUnit tests pass
```

Once Dobby finishes, test it:
```bash
curl "http://localhost:8081/greet?name=Dobby"
# → {"message":"Hello, Dobby!","timestamp":"...","status":"ok"}
```

For a more complex real-world example (Salesforce → MySQL → NetSuite), see [`templates/MASTER_ORDERS_example.md`](templates/MASTER_ORDERS_example.md).

---

## Project Structure

```
my-integration/
├── .dobby/
│   ├── MASTER_ORDERS.md        # Your spec ("the sock")
│   ├── @magic_plan.md          # Task checklist — Dobby marks [x] as it works
│   ├── @AGENT.md               # System prompt sent to Claude each loop
│   ├── dobby_status.json       # Live status (read by monitor + web UI)
│   ├── house-elf-magic/
│   │   ├── dobby.log           # Main execution log
│   │   ├── dobby_stderr.log    # Subprocess stderr (debug)
│   │   └── snap_N.log          # Claude output per loop (last 20 kept)
│   ├── blueprints/             # RAML / API specs
│   └── sock-drawer/            # Additional reference docs
├── src/
│   ├── main/
│   │   ├── mule/               # Flow XML files
│   │   └── resources/
│   │       ├── dwl/            # DataWeave transformations
│   │       └── api/            # RAML specifications
│   └── test/
│       └── munit/              # MUnit test suites
├── pom.xml                     # Maven project descriptor
└── mule-artifact.json          # MuleSoft artifact metadata
```

---

## Commands

### `dobby`

```bash
dobby --snap        # Start the autonomous development loop
dobby --status      # Show current project status
dobby --reset       # Clear logs and uncheck all plan tasks
dobby --help
dobby --version
```

### `dobby-setup`

Scaffolds a new MuleSoft project with all required files.

```bash
dobby-setup <project-name> [target-directory]

dobby-setup my-api
dobby-setup order-sync /path/to/projects
```

### `dobby-monitor`

Live terminal dashboard. Run in a second terminal while `dobby --snap` is running.

```bash
dobby-monitor            # Auto-refresh every 2s
dobby-monitor --once     # Print status once and exit
dobby-monitor --tmux     # Launch inside a tmux session
```

### `dobby-ui`

Lightweight web dashboard (Python 3, zero dependencies).

```bash
dobby-ui                        # Start on port 3131
dobby-ui --port 8080            # Custom port
dobby-ui --open                 # Start and open browser automatically
dobby-ui --open ./my-project    # Pre-load a project on start
```

---

## Configuration

All settings are environment variables with sensible defaults.

| Variable | Default | Description |
|----------|---------|-------------|
| `DOBBY_MAX_LOOPS` | `100` | Maximum loop iterations |
| `DOBBY_LOOP_DELAY` | `5` | Seconds to sleep between loops |
| `DOBBY_MAX_API_CALLS` | `100` | Max Claude API calls per hour |
| `DOBBY_RATE_COOLDOWN` | `3600` | Rate limit cooldown window (seconds) |
| `DOBBY_MAX_NO_CHANGE` | `3` | Loops with no file change before circuit breaker opens |
| `DOBBY_MIN_COMPLETION` | `4` | Completion signal threshold to auto-exit |
| `DOBBY_VERBOSE` | `true` | Print log lines to the terminal |
| `DOBBY_SNAP_LOG_KEEP` | `20` | Number of per-loop snap logs to retain |

Example — fast test run with tight limits:

```bash
DOBBY_MAX_LOOPS=10 DOBBY_LOOP_DELAY=2 dobby --snap
```

---

## Monitoring

### Terminal dashboard

```
+============================================================+
|               DOBBY'S MAGIC MONITOR                        |
+============================================================+

        .---.
       | ^ ^ |   Dobby is working very hard!
       |  >  |
        \___/
         |||
        /|||\

  Status:         working          Loop:     12 / 100
  API Calls:      45               Circuit:  closed
  Current Task:   Building Process API
  Tasks:          8 / 15

  Progress:
  [████████████████████░░░░░░░░░░░░░░░░░░░░] 53%

  Recent logs:
  [SUCCESS] Created customer-system-api.xml
  [SNAP]    Generated address-transform.dwl
  [INFO]    Tasks: 8 done, 7 remaining
```

### Log files

| File | Contents |
|------|----------|
| `.dobby/house-elf-magic/dobby.log` | Main execution log, every loop |
| `.dobby/house-elf-magic/snap_N.log` | Full Claude output for loop N |
| `.dobby/house-elf-magic/dobby_stderr.log` | Subprocess stderr |
| `dobby_server.log` | Web UI server log |

```bash
# Follow the main log live
tail -f .dobby/house-elf-magic/dobby.log

# Read what Claude said in loop 5
cat .dobby/house-elf-magic/snap_5.log
```

---

## Testing

The test suite covers the HTTP API and all shell utility functions.

```bash
# Python tests — all API endpoints (35 tests)
python3 -m unittest discover -s tests -p "test_server.py" -v

# Shell tests — loop logic, circuit breaker, rate limiter, completion detection (46 tests)
bash tests/test_loop.sh
```

### What is tested

**`tests/test_server.py`** (Python, 35 tests)

- Every API endpoint: `/api/status`, `/api/logs`, `/api/orders`, `/api/plan`, `/api/config`
- `POST /api/load` — project creation, missing path, empty body
- `POST /api/start` — missing path, missing `.dobby` directory
- `POST /api/stop` — not-running guard
- Request body > 10 MB → 413
- CORS headers + OPTIONS preflight
- Unknown routes → 404
- UI file serving

**`tests/test_loop.sh`** (Bash, 46 tests)

- `init_project_paths` — all 6 path variables
- `validate_project` — missing `.dobby`, missing `MASTER_ORDERS.md`, missing `claude` CLI
- Rate limiter — under/at limit, counter, expired timestamps
- Circuit breaker — state transitions, opens after 3 no-change loops, closes on success
- `all_tasks_done` — all `[x]`, mixed, empty plan
- `calculate_completion` — 0%, 50%, 100%
- `check_exit_conditions` — EXIT_SIGNAL, signal threshold, max loops, all tasks done
- `update_status` — JSON written with correct values
- `rotate_snap_logs` — keeps N logs, idempotent, no-op under limit

---

## Troubleshooting

### Circuit breaker opened — Dobby is stuck

Claude ran but made no file changes for 3 consecutive loops.

```bash
# Read what Claude was saying
cat .dobby/house-elf-magic/snap_$(ls .dobby/house-elf-magic/snap_*.log | wc -l | tr -d ' ').log

# Common fixes:
# 1. Make MASTER_ORDERS.md more specific (add JSON examples, exact field names)
# 2. Reset and retry
dobby --reset && dobby --snap
```

### Rate limit reached

Dobby waits automatically. To adjust the limit:
```bash
DOBBY_MAX_API_CALLS=50 dobby --snap
```

### Claude Code not found

```bash
npm install -g @anthropic-ai/claude-code
claude --version   # verify
```

### Output looks wrong / missing fields

Add explicit JSON examples to your `MASTER_ORDERS.md`:
```markdown
## Data Transformations

Input:
```json
{ "first_name": "Jane", "last_name": "Doe" }
```

Output:
```json
{ "fullName": "Jane Doe" }
```
```

### Web UI shows "No project loaded"

Click **Load** and enter the **absolute path** to your project directory (the folder containing `.dobby/`).

### Docker: Claude can't authenticate

Make sure `ANTHROPIC_API_KEY` is set in your shell before running `docker compose up`:
```bash
echo $ANTHROPIC_API_KEY   # should print your key
docker compose up
```

---

## Requirements

### Required

| Dependency | Install |
|------------|---------|
| Bash 4.0+ | Pre-installed on Linux; `brew install bash` on macOS |
| Claude Code CLI | `npm install -g @anthropic-ai/claude-code` |
| ANTHROPIC_API_KEY | Set in your environment |

### Recommended

| Dependency | Used for |
|------------|----------|
| Python 3 | Web UI (`dobby-ui`) |
| jq | JSON parsing in scripts |
| tmux | Background monitoring |
| git | Version control of generated code |
| Docker + Compose | Containerised deployment |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT — see [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by the [Ralph technique](https://ghuntley.com/ralph/)
- Named after Dobby from Harry Potter
- Powered by [Claude Code](https://github.com/anthropics/claude-code)

---

*"Master has given Dobby a specification! Dobby is FREE to build integrations!"*
