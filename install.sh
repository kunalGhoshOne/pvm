#!/usr/bin/env bash

# PVM Installer - Run and Forget Installation Script
# This script will download, install, and configure PVM automatically

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PVM_DIR="${PVM_DIR:-$HOME/.pvm}"
PVM_SCRIPT_URL="https://raw.githubusercontent.com/yourusername/pvm/main/pvm.sh"
PVM_SCRIPT_PATH="/usr/bin/pvm"

echo_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if running as root
is_root() {
    [ "$EUID" -eq 0 ]
}

# Execute command with sudo only if not root
run_as_root() {
    if is_root; then
        "$@"
    else
        sudo "$@"
    fi
}

print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║                                                    ║"
    echo "║          PVM - PHP Version Manager                 ║"
    echo "║         Binary Installation - v2.0                 ║"
    echo "║                                                    ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

detect_shell() {
    if [ -n "$BASH_VERSION" ]; then
        echo "bash"
    elif [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    else
        case "$SHELL" in
            */bash)
                echo "bash"
                ;;
            */zsh)
                echo "zsh"
                ;;
            *)
                echo "unknown"
                ;;
        esac
    fi
}

get_shell_profile() {
    local shell_type=$(detect_shell)
    
    case "$shell_type" in
        bash)
            if [ -f "$HOME/.bashrc" ]; then
                echo "$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        zsh)
            echo "$HOME/.zshrc"
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

check_requirements() {
    echo_info "Checking system requirements..."
    
    local missing=()
    
    if ! command -v curl &> /dev/null; then
        missing+=("curl")
    fi
    
    if ! command -v tar &> /dev/null; then
        missing+=("tar")
    fi

    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo_info "Missing required tools: ${missing[*]}"
        echo_info "Installing missing dependencies..."
        
        if command -v apt-get &> /dev/null; then
            run_as_root apt-get update -qq
            run_as_root apt-get install -y ${missing[*]}
        elif command -v dnf &> /dev/null; then
            run_as_root dnf install -y ${missing[*]}
        elif command -v pacman &> /dev/null; then
            run_as_root pacman -S --noconfirm ${missing[*]}
        elif command -v brew &> /dev/null; then
            brew install ${missing[*]}
        else
            echo_error "Could not install missing dependencies automatically"
            echo_info "Please install: ${missing[*]}"
            return 1
        fi
        
        echo_success "Dependencies installed: ${missing[*]}"
    fi
    
    echo_success "All basic requirements met"
}

download_pvm() {
    echo_info "Downloading PVM script..."
    
    if [ -f "$PVM_SCRIPT_PATH" ]; then
        echo_warn "PVM script already exists at $PVM_SCRIPT_PATH"
        read -p "Do you want to overwrite it? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo_info "Keeping existing installation"
            return 0
        fi
        
        echo_info "Backing up existing installation..."
        run_as_root mv "$PVM_SCRIPT_PATH" "$PVM_SCRIPT_PATH.backup.$(date +%s)"
    fi
    
    if [ -f "./pvm.sh" ]; then
        echo_info "Using pvm.sh from current directory"
        run_as_root cp ./pvm.sh "$PVM_SCRIPT_PATH"
        run_as_root chmod +x "$PVM_SCRIPT_PATH"
        echo_success "PVM script installed to $PVM_SCRIPT_PATH"
    else
        echo_error "pvm.sh not found. Please ensure pvm.sh is in the current directory"
        echo_info "Or update PVM_SCRIPT_URL in this script to download from GitHub"
        return 1
    fi
}

configure_shell() {
    local shell_profile=$(get_shell_profile)
    local shell_type=$(detect_shell)
    
    echo_info "Configuring shell profile..."
    echo_info "Detected shell: $shell_type"
    echo_info "Profile file: $shell_profile"
    
    if grep -q "source.*pvm" "$shell_profile" 2>/dev/null; then
        echo_warn "PVM already configured in $shell_profile"
        read -p "Do you want to reconfigure it? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo_info "Keeping existing configuration"
            return 0
        fi
        
        echo_info "Removing old PVM configuration..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' '/# PVM - PHP Version Manager/d' "$shell_profile"
            sed -i '' '/source.*pvm/d' "$shell_profile"
        else
            sed -i '/# PVM - PHP Version Manager/d' "$shell_profile"
            sed -i '/source.*pvm/d' "$shell_profile"
        fi
    fi
    
    if [ ! -f "$shell_profile" ]; then
        echo_info "Creating $shell_profile..."
        touch "$shell_profile"
    fi
    
    echo_info "Adding PVM to $shell_profile..."
    echo "" >> "$shell_profile"
    echo "# PVM - PHP Version Manager" >> "$shell_profile"
    echo "source $PVM_SCRIPT_PATH" >> "$shell_profile"
    
    echo_success "✓ PVM added to shell profile"
}

print_next_steps() {
    local shell_profile=$(get_shell_profile)
    
    echo ""
    echo_success "🎉 PVM installed successfully!"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installation Summary:${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo "✅ PVM script installed to: $PVM_SCRIPT_PATH"
    echo "✅ Shell profile configured: $shell_profile"
    echo "✅ PVM is now available in your shell"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installation Method:${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo "⚡ Uses pre-built system packages (no compilation!)"
    echo "⚡ Fast installation - completes in seconds"
    echo "⚡ No CPU/RAM spikes during installation"
    echo "⚡ Common PHP extensions included automatically"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Quick Start:${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo "📦 Install PHP:"
    echo -e "   ${YELLOW}pvm install 8.3.0${NC}    (installs in seconds!)"
    echo ""
    echo "🔄 Switch version:"
    echo -e "   ${YELLOW}pvm use 8.3.0${NC}"
    echo ""
    echo "📋 List installed:"
    echo -e "   ${YELLOW}pvm list${NC}"
    echo ""
    echo "📚 View all commands:"
    echo -e "   ${YELLOW}pvm help${NC}"
    echo ""
}

offer_install_php() {
    echo ""
    read -p "Would you like to install PHP 8.3.0 now? (y/N) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo_info "Installing PHP 8.3.0..."
        echo_info "This uses pre-built packages, so it's fast! ⚡"
        echo ""
        
        # Source PVM to make it available in this script
        source "$PVM_SCRIPT_PATH"
        
        if pvm install 8.3.0; then
            echo ""
            echo_success "PHP 8.3.0 installed successfully!"
            echo_info "Activating PHP 8.3.0..."
            pvm use 8.3.0
            echo ""
            php -v
            echo ""
            echo_success "All done! PHP is ready to use! 🚀"
        else
            echo_error "Failed to install PHP 8.3.0"
            echo_info "You can try again later with: pvm install 8.3.0"
        fi
    else
        echo_info "Skipped PHP installation"
        echo_info "You can install PHP later with: pvm install <version>"
    fi
}

reload_shell() {
    local shell_type=$(detect_shell)
    local shell_profile=$(get_shell_profile)
    
    echo ""
    echo_info "Reloading your shell to activate PVM..."
    echo ""
    
    # Execute the user's shell with the profile loaded
    if [ "$shell_type" = "zsh" ]; then
        exec zsh
    elif [ "$shell_type" = "bash" ]; then
        exec bash
    else
        echo_warn "Could not detect shell type for auto-reload"
        echo_info "Please run: source $shell_profile"
    fi
}

cleanup_on_error() {
    echo_error "Installation failed!"
    echo_info "Cleaning up..."
    
    if [ -f "$PVM_SCRIPT_PATH.backup."* ]; then
        echo_info "Restoring backup..."
        run_as_root mv "$PVM_SCRIPT_PATH.backup."* "$PVM_SCRIPT_PATH" 2>/dev/null || true
    fi
    
    exit 1
}

main() {
    trap cleanup_on_error ERR
    
    print_header
    
    # Check if running as root
    if is_root; then
        echo_warn "Running as root user"
        echo_info "Installation will proceed without sudo"
        echo ""
    fi
    
    echo_info "Starting PVM installation..."
    echo_info "This will automatically:"
    echo "  • Install PVM script to /usr/bin/pvm"
    echo "  • Detect your shell (bash/zsh)"
    echo "  • Add PVM to your shell profile"
    echo "  • Reload your shell"
    echo ""
    echo_info "Installation method: Pre-built binaries (no compilation!)"
    echo ""
    
    check_requirements || exit 1
    echo ""
    
    download_pvm || exit 1
    echo ""
    
    configure_shell || exit 1
    echo ""
    
    print_next_steps
    
    # Offer to install PHP (sources PVM internally if needed)
    offer_install_php
    
    echo ""
    echo_success "Installation complete! Restarting your shell..."
    echo ""
    
    # Reload shell so PVM is immediately available
    reload_shell
}

# Run main function
main
