#!/usr/bin/env bash
#
# install.sh - Global Installation Script
# The Autonomous MuleSoft Development Elf
#
# Installs Dobby globally so you can use it from anywhere:
# - Copies scripts to ~/.dobby/
# - Creates commands in ~/.local/bin/
# - Updates shell configuration
#

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

DOBBY_HOME="${HOME}/.dobby"
BIN_DIR="${HOME}/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Version
DOBBY_VERSION="1.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# =============================================================================
# BANNER
# =============================================================================

show_install_banner() {
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
|        | o o |   INSTALLER                                 |
|        |  >  |                                             |
|         \___/    Autonomous MuleSoft Development Elf       |
|          |||                                               |
|         /|||\                                              |
+============================================================+
EOF
    echo -e "${NC}"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_snap() {
    echo -e "${PURPLE}[SNAP]${NC} $*"
}

# =============================================================================
# DEPENDENCY CHECKS
# =============================================================================

check_dependencies() {
    local missing=()

    # Required: bash 4.0+
    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
        log_error "Bash 4.0+ is required. Current version: ${BASH_VERSION}"
        return 1
    fi

    # Optional but recommended
    if ! command -v claude &> /dev/null; then
        log_warn "Claude Code CLI not found."
        log_warn "Install it with: npm install -g @anthropic-ai/claude-code"
        missing+=("claude-code")
    fi

    if ! command -v git &> /dev/null; then
        log_warn "git not found. Version control features will be limited."
        missing+=("git")
    fi

    if ! command -v jq &> /dev/null; then
        log_warn "jq not found. Some features may be limited."
        missing+=("jq")
    fi

    if ! command -v tmux &> /dev/null; then
        log_warn "tmux not found. Monitoring dashboard will run in terminal."
        missing+=("tmux")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo ""
        log_warn "Some optional dependencies are missing: ${missing[*]}"
        echo ""
    fi

    return 0
}

# =============================================================================
# INSTALLATION
# =============================================================================

create_directories() {
    log_snap "Creating directories..."

    mkdir -p "$DOBBY_HOME"
    mkdir -p "$BIN_DIR"
    mkdir -p "${DOBBY_HOME}/templates"

    log_success "Directories created"
}

copy_scripts() {
    log_snap "Copying scripts to ${DOBBY_HOME}..."

    # Copy main scripts
    cp "${SCRIPT_DIR}/dobby_banner.sh" "$DOBBY_HOME/"
    cp "${SCRIPT_DIR}/dobby_loop.sh" "$DOBBY_HOME/"
    cp "${SCRIPT_DIR}/dobby_setup.sh" "$DOBBY_HOME/"
    cp "${SCRIPT_DIR}/dobby_monitor.sh" "$DOBBY_HOME/"
    cp "${SCRIPT_DIR}/dobby_ui.sh" "$DOBBY_HOME/"
    cp "${SCRIPT_DIR}/dobby_server.py" "$DOBBY_HOME/"

    # Copy UI files
    mkdir -p "${DOBBY_HOME}/ui"
    cp "${SCRIPT_DIR}/ui/index.html" "${DOBBY_HOME}/ui/"

    # Copy templates if they exist
    if [[ -d "${SCRIPT_DIR}/templates" ]]; then
        cp -r "${SCRIPT_DIR}/templates/"* "${DOBBY_HOME}/templates/" 2>/dev/null || true
    fi

    # Make scripts executable
    chmod +x "${DOBBY_HOME}/"*.sh
    chmod +x "${DOBBY_HOME}/dobby_server.py"

    log_success "Scripts copied"
}

create_commands() {
    log_snap "Creating commands in ${BIN_DIR}..."

    # Main 'dobby' command
    cat > "${BIN_DIR}/dobby" << 'DOBBY_CMD'
#!/usr/bin/env bash
# Dobby - The Autonomous MuleSoft Development Elf
# Main command wrapper

DOBBY_HOME="${HOME}/.dobby"

if [[ ! -f "${DOBBY_HOME}/dobby_loop.sh" ]]; then
    echo "Error: Dobby is not properly installed."
    echo "Please run the install.sh script again."
    exit 1
fi

source "${DOBBY_HOME}/dobby_loop.sh"
main "$@"
DOBBY_CMD
    chmod +x "${BIN_DIR}/dobby"

    # 'dobby-setup' command
    cat > "${BIN_DIR}/dobby-setup" << 'SETUP_CMD'
#!/usr/bin/env bash
# Dobby Setup - Create new MuleSoft projects

DOBBY_HOME="${HOME}/.dobby"

if [[ ! -f "${DOBBY_HOME}/dobby_setup.sh" ]]; then
    echo "Error: Dobby is not properly installed."
    echo "Please run the install.sh script again."
    exit 1
fi

source "${DOBBY_HOME}/dobby_setup.sh"
main "$@"
SETUP_CMD
    chmod +x "${BIN_DIR}/dobby-setup"

    # 'dobby-monitor' command
    cat > "${BIN_DIR}/dobby-monitor" << 'MONITOR_CMD'
#!/usr/bin/env bash
# Dobby Monitor - Live monitoring dashboard

DOBBY_HOME="${HOME}/.dobby"

if [[ ! -f "${DOBBY_HOME}/dobby_monitor.sh" ]]; then
    echo "Error: Dobby is not properly installed."
    echo "Please run the install.sh script again."
    exit 1
fi

source "${DOBBY_HOME}/dobby_monitor.sh"
main "$@"
MONITOR_CMD
    chmod +x "${BIN_DIR}/dobby-monitor"

    # 'dobby-ui' command
    cat > "${BIN_DIR}/dobby-ui" << 'UI_CMD'
#!/usr/bin/env bash
# Dobby UI - Web-based monitoring dashboard

DOBBY_HOME="${HOME}/.dobby"

if [[ ! -f "${DOBBY_HOME}/dobby_ui.sh" ]]; then
    echo "Error: Dobby is not properly installed."
    echo "Please run the install.sh script again."
    exit 1
fi

exec bash "${DOBBY_HOME}/dobby_ui.sh" "$@"
UI_CMD
    chmod +x "${BIN_DIR}/dobby-ui"

    log_success "Commands created"
}

update_shell_config() {
    log_snap "Updating shell configuration..."

    # Determine shell config file
    local shell_config=""
    local shell_name=$(basename "$SHELL")

    case $shell_name in
        "zsh")
            shell_config="${HOME}/.zshrc"
            ;;
        "bash")
            if [[ -f "${HOME}/.bashrc" ]]; then
                shell_config="${HOME}/.bashrc"
            elif [[ -f "${HOME}/.bash_profile" ]]; then
                shell_config="${HOME}/.bash_profile"
            fi
            ;;
        *)
            shell_config="${HOME}/.profile"
            ;;
    esac

    if [[ -z "$shell_config" ]]; then
        log_warn "Could not determine shell config file"
        log_warn "Please add ${BIN_DIR} to your PATH manually"
        return 0
    fi

    # Check if PATH already includes our bin directory
    if grep -q "\.local/bin" "$shell_config" 2>/dev/null; then
        log_info "PATH already configured in ${shell_config}"
    else
        # Add PATH update
        echo "" >> "$shell_config"
        echo "# Dobby - The Autonomous MuleSoft Development Elf" >> "$shell_config"
        echo 'export PATH="${HOME}/.local/bin:${PATH}"' >> "$shell_config"
        log_success "Updated ${shell_config}"
    fi

    # Add DOBBY_HOME environment variable if not present
    if ! grep -q "DOBBY_HOME" "$shell_config" 2>/dev/null; then
        echo 'export DOBBY_HOME="${HOME}/.dobby"' >> "$shell_config"
    fi

    return 0
}

create_version_file() {
    echo "$DOBBY_VERSION" > "${DOBBY_HOME}/VERSION"
}

# =============================================================================
# UNINSTALLATION
# =============================================================================

uninstall_dobby() {
    log_info "Uninstalling Dobby..."

    # Remove commands
    rm -f "${BIN_DIR}/dobby"
    rm -f "${BIN_DIR}/dobby-setup"
    rm -f "${BIN_DIR}/dobby-monitor"
    rm -f "${BIN_DIR}/dobby-ui"

    # Remove dobby home directory
    if [[ -d "$DOBBY_HOME" ]]; then
        rm -rf "$DOBBY_HOME"
    fi

    log_success "Dobby has been uninstalled"
    echo ""
    echo "Note: You may want to remove the PATH update from your shell config."
    echo ""
}

# =============================================================================
# VERIFICATION
# =============================================================================

verify_installation() {
    log_snap "Verifying installation..."

    local errors=0

    # Check scripts exist
    for script in dobby_banner.sh dobby_loop.sh dobby_setup.sh dobby_monitor.sh; do
        if [[ ! -f "${DOBBY_HOME}/${script}" ]]; then
            log_error "Missing: ${DOBBY_HOME}/${script}"
            ((errors++))
        fi
    done

    # Check commands exist
    for cmd in dobby dobby-setup dobby-monitor dobby-ui; do
        if [[ ! -f "${BIN_DIR}/${cmd}" ]]; then
            log_error "Missing: ${BIN_DIR}/${cmd}"
            ((errors++))
        fi
    done

    if [[ $errors -gt 0 ]]; then
        log_error "Installation verification failed with ${errors} errors"
        return 1
    fi

    log_success "Installation verified"
    return 0
}

# =============================================================================
# SUCCESS BANNER
# =============================================================================

show_success() {
    echo ""
    echo -e "${GREEN}+============================================================+${NC}"
    echo -e "${GREEN}|                                                            |${NC}"
    echo -e "${GREEN}|         .---.                                              |${NC}"
    echo -e "${GREEN}|        | O O |   Dobby is successfully installed!          |${NC}"
    echo -e "${GREEN}|        | \\_/ |                                             |${NC}"
    echo -e "${GREEN}|         \\___/    Dobby is ready to serve Master!           |${NC}"
    echo -e "${GREEN}|          |||                                               |${NC}"
    echo -e "${GREEN}|         /|||\\                                              |${NC}"
    echo -e "${GREEN}|                                                            |${NC}"
    echo -e "${GREEN}+============================================================+${NC}"
    echo ""
    echo -e "${CYAN}INSTALLED TO:${NC}"
    echo "  Scripts:  ${DOBBY_HOME}/"
    echo "  Commands: ${BIN_DIR}/"
    echo ""
    echo -e "${CYAN}AVAILABLE COMMANDS:${NC}"
    echo -e "  ${GREEN}dobby${NC}           Main command (--snap, --status, --help)"
    echo -e "  ${GREEN}dobby-setup${NC}     Create new MuleSoft projects"
    echo -e "  ${GREEN}dobby-monitor${NC}   Live monitoring dashboard (terminal)"
    echo -e "  ${GREEN}dobby-ui${NC}        Web-based UI dashboard (browser)"
    echo ""
    echo -e "${CYAN}QUICK START:${NC}"
    echo "  1. Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
    echo "  2. Create a project:  dobby-setup my-integration"
    echo "  3. Configure:         cd my-integration && edit .dobby/MASTER_ORDERS.md"
    echo "  4. Start Dobby:       dobby --snap"
    echo ""
    echo -e "${YELLOW}\"Master has given Dobby a sock! Dobby is FREE!\"${NC}"
    echo ""
}

# =============================================================================
# HELP
# =============================================================================

show_help() {
    show_install_banner
    echo ""
    echo -e "${CYAN}USAGE:${NC}"
    echo "  ./install.sh [OPTIONS]"
    echo ""
    echo -e "${CYAN}OPTIONS:${NC}"
    echo -e "  ${GREEN}--install${NC}     Install Dobby (default)"
    echo -e "  ${GREEN}--uninstall${NC}   Remove Dobby from system"
    echo -e "  ${GREEN}--upgrade${NC}     Upgrade existing installation"
    echo -e "  ${GREEN}--verify${NC}      Verify installation"
    echo -e "  ${GREEN}--help${NC}        Show this help message"
    echo ""
    echo -e "${CYAN}INSTALLATION LOCATIONS:${NC}"
    echo "  Scripts:  ~/.dobby/"
    echo "  Commands: ~/.local/bin/"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    local action="${1:-install}"

    case $action in
        "--help"|"-h"|"help")
            show_help
            exit 0
            ;;

        "--uninstall"|"-u"|"uninstall")
            show_install_banner
            uninstall_dobby
            exit 0
            ;;

        "--verify"|"-v"|"verify")
            show_install_banner
            verify_installation
            exit $?
            ;;

        "--upgrade"|"upgrade")
            show_install_banner
            echo ""
            log_info "Upgrading Dobby..."
            echo ""
            copy_scripts
            create_commands
            create_version_file
            verify_installation
            echo ""
            log_success "Dobby has been upgraded to version ${DOBBY_VERSION}"
            echo ""
            exit 0
            ;;

        "--install"|"-i"|"install"|"")
            show_install_banner
            echo ""
            log_info "Installing Dobby v${DOBBY_VERSION}..."
            echo ""

            # Run installation steps
            check_dependencies
            create_directories
            copy_scripts
            create_commands
            update_shell_config
            create_version_file
            verify_installation

            show_success
            exit 0
            ;;

        *)
            log_error "Unknown option: $action"
            show_help
            exit 1
            ;;
    esac
}

# Run installer
main "$@"
