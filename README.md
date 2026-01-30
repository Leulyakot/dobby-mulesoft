# DOBBY - The Autonomous MuleSoft Development Elf

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

**Dobby** is an autonomous MuleSoft integration development agent powered by Claude Code. Give Dobby a specification (the "sock"), and Dobby works tirelessly and autonomously until your integration is complete!

Named after Harry Potter's loyal house-elf, Dobby embodies dedication and autonomous service. Just as Dobby was freed by receiving a sock, Dobby the agent is "freed" to work autonomously when given your integration specification.

## Features

- **Autonomous Development Loop** - Dobby continuously iterates on your MuleSoft project until complete
- **Intelligent Exit Detection** - Automatically detects when the integration is done
- **Rate Limiting** - Respects API limits with automatic cooldown
- **Circuit Breaker** - Detects stuck loops and prevents infinite cycling
- **Live Monitoring** - Real-time dashboard showing progress
- **Web UI** - Futuristic black web dashboard for browser-based control
- **Beautiful Terminal UI** - ASCII art and colorful status indicators
- **MuleSoft Best Practices** - Generates API-led architecture, DataWeave, and MUnit tests

## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/dobby-mulesoft.git
cd dobby-mulesoft

# Install globally
./install.sh
```

### Create a Project

```bash
# Create a new MuleSoft project
dobby-setup customer-sync

# Navigate to the project
cd customer-sync
```

### Configure Your Integration

Edit `.dobby/MASTER_ORDERS.md` with your integration requirements:

```bash
# Open the specification file
nano .dobby/MASTER_ORDERS.md
# or
code .dobby/MASTER_ORDERS.md
```

### Start Dobby

```bash
# Start autonomous development
dobby --snap

# In another terminal, monitor progress
dobby-monitor
```

## How It Works

```
User gives Dobby a specification ("the sock") -> Dobby is FREE to work autonomously!

+--------------------------------------------------------------+
|  1. READ specification (MASTER_ORDERS.md)                    |
|  2. PLAN tasks (@magic_plan.md)                              |
|  3. SNAP! Execute Claude Code                                |
|  4. GENERATE MuleSoft flows, DataWeave, tests                |
|  5. ANALYZE completion signals                               |
|  6. REPEAT until integration complete                        |
+--------------------------------------------------------------+
```

### The Loop

1. **Read**: Dobby reads `MASTER_ORDERS.md` for integration requirements
2. **Plan**: Creates and updates tasks in `@magic_plan.md`
3. **Snap**: Executes Claude Code to generate MuleSoft components
4. **Track**: Monitors file changes and completion signals
5. **Decide**: Continues looping or exits when done

### Exit Detection

Dobby intelligently detects when to stop:

- Completion keywords ("complete", "done", "finished")
- Explicit `EXIT_SIGNAL` from Claude
- All tasks in `@magic_plan.md` marked `[x]`
- Maximum loops reached
- Circuit breaker tripped (stuck loop detection)

## Project Structure

When you run `dobby-setup`, this structure is created:

```
my-integration/
├── .dobby/
│   ├── MASTER_ORDERS.md       # Your integration requirements ("the sock")
│   ├── @magic_plan.md         # Task tracking and progress
│   ├── @AGENT.md              # Instructions for Claude Code
│   ├── house-elf-magic/       # Logs directory
│   │   └── dobby.log          # Execution logs
│   ├── blueprints/            # API specifications
│   ├── sock-drawer/           # Additional specifications
│   └── dobby_status.json      # Current status
├── src/
│   ├── main/
│   │   ├── mule/              # MuleSoft flow XML files
│   │   └── resources/
│   │       ├── dwl/           # DataWeave transformations
│   │       └── api/           # RAML specifications
│   └── test/
│       └── munit/             # MUnit test files
├── pom.xml                    # Maven configuration
└── README.md                  # Project documentation
```

## Commands

### `dobby`

Main command for running Dobby.

```bash
dobby --snap      # Start autonomous development loop
dobby --status    # Show current project status
dobby --reset     # Reset progress and start over
dobby --help      # Show help
dobby --version   # Show version
```

### `dobby-setup`

Create new MuleSoft projects.

```bash
dobby-setup <project-name> [target-directory]

# Examples
dobby-setup customer-sync
dobby-setup order-api /path/to/projects
```

### `dobby-monitor`

Live terminal monitoring dashboard.

```bash
dobby-monitor           # Monitor current directory
dobby-monitor --once    # Show status once and exit
dobby-monitor --tmux    # Start in tmux session
```

### `dobby-ui`

Web-based UI dashboard. Opens a lightweight local web server with a futuristic dark interface.

```bash
dobby-ui                          # Start on default port 3131
dobby-ui --port 8080              # Start on custom port
dobby-ui --open ./my-project      # Start and auto-open browser
```

Features:
- Real-time status monitoring with auto-refresh
- Edit MASTER_ORDERS.md directly in the browser
- View task plan with completion tracking
- Live log streaming with color-coded entries
- Start/stop Dobby from the browser
- Zero dependencies (Python 3 stdlib only)

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOBBY_MAX_LOOPS` | 100 | Maximum development loops |
| `DOBBY_LOOP_DELAY` | 5 | Seconds between loops |
| `DOBBY_MAX_API_CALLS` | 100 | API calls per hour limit |
| `DOBBY_RATE_COOLDOWN` | 3600 | Rate limit cooldown (seconds) |
| `DOBBY_MAX_NO_CHANGE` | 3 | Max loops without file changes |
| `DOBBY_MIN_COMPLETION` | 4 | Min completion signals to exit |
| `DOBBY_VERBOSE` | true | Show verbose output |
| `DOBBY_MONITOR_REFRESH` | 2 | Monitor refresh interval |

### MASTER_ORDERS.md Format

The specification file should include:

```markdown
# Master's Integration Orders

## What Dobby Must Build
- Project name and type
- Integration overview

## Source Systems
- System details
- Connection information
- Data requirements

## Target Systems
- Destination details
- Output requirements

## Data Transformations
- Input/output schemas
- Transformation logic

## Business Rules
- Validation rules
- Processing logic

## Acceptance Criteria
- [ ] Checkboxes for completion tracking
```

See `templates/MASTER_ORDERS_example.md` for a complete example.

## What Dobby Generates

### MuleSoft Components

- **System APIs**: Connector configurations for Salesforce, databases, REST APIs
- **Process APIs**: Business logic, orchestration, transformation flows
- **Experience APIs**: Consumer-facing REST endpoints

### DataWeave Transformations

```dataweave
%dw 2.0
output application/json
---
{
  customers: payload map {
    customerId: $.Id,
    fullName: $.Name,
    email: $.Email default "unknown@example.com"
  }
}
```

### MUnit Tests

```xml
<munit:test name="test-customer-retrieval">
    <munit:behavior>
        <munit-tools:mock-when processor="salesforce:query">
            <munit-tools:return-payload value="#[[{Id: '001', Name: 'Test'}]]"/>
        </munit-tools:mock-when>
    </munit:behavior>
    <munit:execution>
        <flow-ref name="retrieve-customers"/>
    </munit:execution>
    <munit:validation>
        <munit-tools:assert-that expression="#[sizeOf(payload)]"
                                 is="#[MunitTools::equalTo(1)]"/>
    </munit:validation>
</munit:test>
```

## Monitoring Dashboard

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

+------------------------------------------------------------+
|                        STATUS                              |
+------------------------------------------------------------+

  Status:            working              Loop:      12/100
  API Calls:         45                   Circuit:   closed
  Current Task:      Building Process API Tasks:     8/15

  Progress:
  [████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 53%

+------------------------------------------------------------+
|                    RECENT ACTIVITY                         |
+------------------------------------------------------------+

  [SUCCESS] Created customer-system-api.xml
  [SNAP] Generated address-transform.dwl
  [SUCCESS] All MUnit tests passing
```

## Troubleshooting

### Dobby is stuck (circuit breaker opens)

1. Check logs: `cat .dobby/house-elf-magic/dobby.log`
2. Review `MASTER_ORDERS.md` for clarity
3. Reset and try again: `dobby --reset && dobby --snap`

### Rate limit reached

Dobby automatically waits for the cooldown period. You can also:
- Reduce `DOBBY_MAX_API_CALLS` environment variable
- Wait for the rate limit window to reset

### Claude Code not found

Install the Claude Code CLI:
```bash
npm install -g @anthropic-ai/claude-code
```

### Not generating expected code

1. Make `MASTER_ORDERS.md` more specific
2. Add example input/output in transformations
3. List explicit acceptance criteria

## Best Practices

### Writing Good Specifications

1. **Be Specific**: Include exact field names, data types, and formats
2. **Provide Examples**: Show sample input and expected output
3. **Define Acceptance Criteria**: Use checkboxes for clear completion tracking
4. **Document Business Rules**: Explain validation and transformation logic

### Monitoring Progress

1. Run `dobby-monitor` in a separate terminal
2. Check `.dobby/house-elf-magic/dobby.log` for detailed logs
3. Review `@magic_plan.md` for task progress

### Optimizing Performance

1. Set reasonable `DOBBY_MAX_LOOPS` based on project complexity
2. Use `DOBBY_LOOP_DELAY` to balance speed and API usage
3. Monitor circuit breaker state for stuck detection

## Requirements

### Required

- **Bash 4.0+**: Shell interpreter
- **Claude Code CLI**: `npm install -g @anthropic-ai/claude-code`

### Optional (Recommended)

- **Python 3**: For the web UI (`dobby-ui`)
- **tmux**: For terminal monitoring dashboard
- **jq**: For JSON processing
- **git**: For version control

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by the [Ralph technique](https://ghuntley.com/ralph/)
- Named after Dobby from Harry Potter
- Powered by [Claude Code](https://github.com/anthropics/claude-code)

---

*"Master has given Dobby a specification! Dobby is FREE to build integrations!"*
