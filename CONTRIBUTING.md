# Contributing to Dobby

Thank you for your interest in contributing to Dobby - The Autonomous MuleSoft Development Elf! We welcome contributions from the community.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone.

## How to Contribute

### Reporting Bugs

1. Check existing issues to avoid duplicates
2. Create a new issue with:
   - Clear, descriptive title
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, Bash version, Claude Code version)
   - Relevant logs from `.dobby/house-elf-magic/`

### Suggesting Features

1. Check existing issues and discussions
2. Create a new issue with:
   - Clear description of the feature
   - Use case and benefits
   - Proposed implementation (if any)

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test thoroughly
5. Commit with clear messages
6. Push to your fork
7. Open a pull request

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/dobby-mulesoft.git
cd dobby-mulesoft

# Make scripts executable
chmod +x *.sh

# Test locally without installing
./dobby_setup.sh test-project
cd test-project
../dobby_loop.sh --help
```

## Code Style

### Bash Scripts

- Use `#!/usr/bin/env bash` shebang
- Start with `set -euo pipefail`
- Use meaningful variable names in UPPER_CASE for globals
- Use lower_case for local variables
- Add comments for complex logic
- Follow function naming: `verb_noun()` (e.g., `show_banner`, `check_status`)

### Example

```bash
#!/usr/bin/env bash
set -euo pipefail

# Configuration
MAX_RETRIES=3
LOG_FILE="/var/log/dobby.log"

# Function: Log a message
log_message() {
    local level=$1
    local message=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}" >> "$LOG_FILE"
}

# Main logic
main() {
    log_message "INFO" "Starting process"
    # ... implementation
}

main "$@"
```

## Project Structure

```
dobby-mulesoft/
├── dobby_banner.sh    # UI components and ASCII art
├── dobby_loop.sh      # Main autonomous loop
├── dobby_setup.sh     # Project creation
├── dobby_monitor.sh   # Monitoring dashboard
├── install.sh         # Installation script
├── templates/         # Template files
├── README.md          # Documentation
├── CONTRIBUTING.md    # This file
└── LICENSE            # MIT License
```

## Testing

### Manual Testing Checklist

Before submitting a PR, please verify:

- [ ] `./install.sh` completes without errors
- [ ] `dobby --help` shows help text
- [ ] `dobby-setup test-project` creates correct structure
- [ ] `dobby --status` works in a project directory
- [ ] `dobby-monitor --once` displays dashboard
- [ ] Scripts work on both bash and zsh
- [ ] No shellcheck warnings (if installed)

### Running Tests

```bash
# Install shellcheck for linting
# Ubuntu/Debian: sudo apt install shellcheck
# macOS: brew install shellcheck

# Lint all scripts
shellcheck *.sh

# Test installation
./install.sh --verify

# Test project creation
dobby-setup test-project
cd test-project
dobby --status
```

## Documentation

- Update README.md for user-facing changes
- Add inline comments for complex code
- Update help text in scripts
- Include examples where helpful

## Commit Messages

Use clear, descriptive commit messages:

```
feat: Add circuit breaker recovery mode

- Implement half-open state for circuit breaker
- Add configurable recovery threshold
- Update monitoring to show circuit state
```

Prefixes:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `refactor:` Code refactoring
- `test:` Testing changes
- `chore:` Maintenance tasks

## Review Process

1. Maintainers will review your PR
2. Address any feedback
3. Once approved, your PR will be merged
4. Your contribution will be acknowledged

## Questions?

- Open an issue for questions
- Check existing documentation
- Review closed issues for similar topics

## Recognition

Contributors are recognized in:
- Git history
- Release notes (for significant contributions)
- README acknowledgments (for major features)

---

Thank you for helping make Dobby better! Dobby appreciates Master's contributions!

*"Dobby is honored to have such helpful friends!"*
