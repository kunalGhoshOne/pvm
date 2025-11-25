#!/usr/bin/env bash

# PHP Version Manager (pvm)
# Similar to nvm but for PHP with pre-compiled binary installation

PVM_DIR="${PVM_DIR:-$HOME/.pvm}"
PVM_VERSIONS_DIR="$PVM_DIR/versions"
PVM_ALIAS_DIR="$PVM_DIR/alias"
PVM_CURRENT_FILE="$PVM_DIR/current"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

pvm_echo() {
    echo -e "${GREEN}pvm:${NC} $1"
}

pvm_error() {
    echo -e "${RED}pvm error:${NC} $1" >&2
}

pvm_warn() {
    echo -e "${YELLOW}pvm warning:${NC} $1"
}

pvm_info() {
    echo -e "${BLUE}pvm:${NC} $1"
}

pvm_init() {
    mkdir -p "$PVM_VERSIONS_DIR"
    mkdir -p "$PVM_ALIAS_DIR"
}

# Detect operating system
pvm_detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            echo "$ID"
        elif [ -f /etc/debian_version ]; then
            echo "debian"
        elif [ -f /etc/redhat-release ]; then
            echo "rhel"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Detect architecture
pvm_detect_arch() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo "$arch"
            ;;
    esac
}

# Check if a command exists
pvm_command_exists() {
    command -v "$1" &> /dev/null
}

pvm_list_remote() {
    pvm_echo "Fetching available PHP versions..."
    
    if ! command -v jq &> /dev/null; then
        pvm_warn "jq not found, showing raw data..."
        curl -s https://www.php.net/releases/index.php?json
        return
    fi
    
    curl -s https://www.php.net/releases/index.php?json | \
        jq -r 'keys[]' | sort -V | tail -20
}

pvm_list() {
    if [ ! -d "$PVM_VERSIONS_DIR" ] || [ -z "$(ls -A $PVM_VERSIONS_DIR 2>/dev/null)" ]; then
        pvm_echo "No PHP versions installed yet"
        return
    fi
    
    local current_version=""
    if [ -f "$PVM_CURRENT_FILE" ]; then
        current_version=$(cat "$PVM_CURRENT_FILE")
    fi
    
    pvm_echo "Installed PHP versions:"
    for version_dir in "$PVM_VERSIONS_DIR"/*; do
        if [ -d "$version_dir" ]; then
            local version=$(basename "$version_dir")
            if [ "$version" = "$current_version" ]; then
                echo -e "  ${GREEN}* $version (currently active)${NC}"
            else
                echo "    $version"
            fi
        fi
    done
}

# Install PHP using system package manager
pvm_install() {
    local version=$1
    
    if [ -z "$version" ]; then
        pvm_error "Please specify a version to install"
        echo "Usage: pvm install <version>"
        return 1
    fi
    
    # Remove 'v' prefix if present
    version=${version#v}
    
    local install_dir="$PVM_VERSIONS_DIR/$version"
    
    if [ -d "$install_dir" ]; then
        pvm_warn "PHP $version is already installed"
        return 0
    fi
    
    local os=$(pvm_detect_os)
    local arch=$(pvm_detect_arch)
    
    pvm_echo "Installing PHP $version for $os ($arch)..."
    
    mkdir -p "$install_dir"
    
    case "$os" in
        ubuntu|debian|pop|linuxmint)
            pvm_install_deb "$version" "$install_dir"
            ;;
        fedora|rhel|centos|rocky|almalinux)
            pvm_install_rpm "$version" "$install_dir"
            ;;
        arch|manjaro)
            pvm_install_arch "$version" "$install_dir"
            ;;
        macos)
            pvm_install_macos "$version" "$install_dir"
            ;;
        *)
            pvm_error "Unsupported operating system: $os"
            pvm_info "Supported: Ubuntu/Debian, Fedora/RHEL, Arch, macOS"
            return 1
            ;;
    esac
}

# Install on Debian/Ubuntu using ondrej/php PPA
pvm_install_deb() {
    local version=$1
    local install_dir=$2
    
    pvm_info "Installing via system packages (using ondrej/php repository)..."
    
    # Add ondrej/php repository if not present
    if ! grep -q "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        pvm_info "Adding ondrej/php repository..."
        sudo apt-get update -qq
        sudo apt-get install -y software-properties-common
        sudo add-apt-repository -y ppa:ondrej/php
        sudo apt-get update -qq
    fi
    
    # Extract major.minor version (e.g., 8.3.0 -> 8.3)
    local short_version=$(echo "$version" | cut -d. -f1-2)
    
    pvm_info "Installing PHP $short_version packages..."
    
    # Install PHP and common extensions
    sudo apt-get install -y \
        php${short_version}-cli \
        php${short_version}-common \
        php${short_version}-fpm \
        php${short_version}-mysql \
        php${short_version}-zip \
        php${short_version}-gd \
        php${short_version}-mbstring \
        php${short_version}-curl \
        php${short_version}-xml \
        php${short_version}-bcmath \
        php${short_version}-sqlite3 \
        php${short_version}-pgsql
    
    if [ $? -ne 0 ]; then
        pvm_error "Failed to install PHP $short_version"
        return 1
    fi
    
    # Create symlinks in install directory
    mkdir -p "$install_dir/bin"
    ln -sf /usr/bin/php${short_version} "$install_dir/bin/php"
    ln -sf /usr/bin/php-config${short_version} "$install_dir/bin/php-config" 2>/dev/null
    ln -sf /usr/bin/phpize${short_version} "$install_dir/bin/phpize" 2>/dev/null
    
    pvm_echo "✓ Successfully installed PHP $version!"
    pvm_echo "Run 'pvm use $version' to activate it"
}

# Install on Fedora/RHEL using Remi repository
pvm_install_rpm() {
    local version=$1
    local install_dir=$2
    
    pvm_info "Installing via system packages (using Remi repository)..."
    
    # Add Remi repository if not present
    if ! rpm -qa | grep -q remi-release; then
        pvm_info "Adding Remi repository..."
        local os_version=$(rpm -E %{rhel})
        sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-${os_version}.rpm
        sudo dnf install -y dnf-plugins-core
    fi
    
    local short_version=$(echo "$version" | cut -d. -f1-2 | tr -d '.')
    
    pvm_info "Enabling PHP $short_version module..."
    sudo dnf module reset php -y
    sudo dnf module enable php:remi-${short_version} -y
    
    pvm_info "Installing PHP packages..."
    sudo dnf install -y \
        php \
        php-cli \
        php-fpm \
        php-mysqlnd \
        php-zip \
        php-gd \
        php-mbstring \
        php-xml \
        php-bcmath \
        php-pgsql
    
    if [ $? -ne 0 ]; then
        pvm_error "Failed to install PHP"
        return 1
    fi
    
    mkdir -p "$install_dir/bin"
    ln -sf /usr/bin/php "$install_dir/bin/php"
    ln -sf /usr/bin/php-config "$install_dir/bin/php-config" 2>/dev/null
    
    pvm_echo "✓ Successfully installed PHP $version!"
    pvm_echo "Run 'pvm use $version' to activate it"
}

# Install on Arch Linux
pvm_install_arch() {
    local version=$1
    local install_dir=$2
    
    pvm_info "Installing via pacman..."
    
    local short_version=$(echo "$version" | cut -d. -f1-2 | tr -d '.')
    
    # Arch usually has php package for current version
    pvm_info "Installing PHP packages..."
    sudo pacman -S --noconfirm --needed \
        php \
        php-fpm \
        php-gd \
        php-sqlite \
        php-pgsql
    
    if [ $? -ne 0 ]; then
        pvm_error "Failed to install PHP"
        return 1
    fi
    
    mkdir -p "$install_dir/bin"
    ln -sf /usr/bin/php "$install_dir/bin/php"
    ln -sf /usr/bin/php-config "$install_dir/bin/php-config" 2>/dev/null
    
    pvm_echo "✓ Successfully installed PHP $version!"
    pvm_echo "Run 'pvm use $version' to activate it"
}

# Install on macOS using Homebrew
pvm_install_macos() {
    local version=$1
    local install_dir=$2
    
    pvm_info "Installing via Homebrew..."
    
    # Check if Homebrew is installed
    if ! pvm_command_exists brew; then
        pvm_error "Homebrew is not installed"
        pvm_info "Install Homebrew from https://brew.sh"
        return 1
    fi
    
    local short_version=$(echo "$version" | cut -d. -f1-2)
    local formula="php@${short_version}"
    
    # Add shivammathur/php tap for older versions
    if ! brew tap | grep -q shivammathur/php; then
        pvm_info "Adding shivammathur/php tap..."
        brew tap shivammathur/php
    fi
    
    pvm_info "Installing $formula..."
    brew install "$formula"
    
    if [ $? -ne 0 ]; then
        pvm_error "Failed to install $formula"
        return 1
    fi
    
    # Find PHP installation path
    local brew_prefix=$(brew --prefix "$formula")
    
    mkdir -p "$install_dir/bin"
    ln -sf "$brew_prefix/bin/php" "$install_dir/bin/php"
    ln -sf "$brew_prefix/bin/php-config" "$install_dir/bin/php-config" 2>/dev/null
    ln -sf "$brew_prefix/bin/phpize" "$install_dir/bin/phpize" 2>/dev/null
    
    pvm_echo "✓ Successfully installed PHP $version!"
    pvm_echo "Run 'pvm use $version' to activate it"
}

pvm_use() {
    local version=$1
    
    if [ -z "$version" ]; then
        # Check for .phpversion file
        if [ -f ".phpversion" ]; then
            version=$(cat .phpversion | tr -d '[:space:]')
            pvm_echo "Using version from .phpversion: $version"
        else
            pvm_error "Please specify a version to use"
            echo "Usage: pvm use <version>"
            return 1
        fi
    fi
    
    # Remove 'v' prefix if present
    version=${version#v}
    
    local version_dir="$PVM_VERSIONS_DIR/$version"
    
    if [ ! -d "$version_dir" ]; then
        pvm_error "PHP $version is not installed"
        pvm_echo "Install it with: pvm install $version"
        return 1
    fi
    
    # Remove old pvm paths from PATH
    local new_path=""
    IFS=':' read -ra PATHS <<< "$PATH"
    for p in "${PATHS[@]}"; do
        if [[ ! "$p" =~ $PVM_VERSIONS_DIR ]]; then
            if [ -z "$new_path" ]; then
                new_path="$p"
            else
                new_path="$new_path:$p"
            fi
        fi
    done
    
    # Add new version to PATH
    export PATH="$version_dir/bin:$new_path"
    
    # Store current version
    echo "$version" > "$PVM_CURRENT_FILE"
    
    pvm_echo "Now using PHP $version"
    php -v | head -1
}

pvm_current() {
    if [ ! -f "$PVM_CURRENT_FILE" ]; then
        pvm_echo "No PHP version is currently active"
        return 1
    fi
    
    local version=$(cat "$PVM_CURRENT_FILE")
    pvm_echo "Currently using PHP $version"
    php -v | head -1
}

pvm_alias() {
    local alias_name=$1
    local version=$2
    
    if [ -z "$alias_name" ]; then
        # List all aliases
        pvm_echo "Available aliases:"
        if [ -d "$PVM_ALIAS_DIR" ] && [ -n "$(ls -A $PVM_ALIAS_DIR 2>/dev/null)" ]; then
            for alias_file in "$PVM_ALIAS_DIR"/*; do
                local name=$(basename "$alias_file")
                local target=$(cat "$alias_file")
                echo "  $name -> $target"
            done
        else
            echo "  (none)"
        fi
        return 0
    fi
    
    if [ -z "$version" ]; then
        # Show specific alias
        if [ -f "$PVM_ALIAS_DIR/$alias_name" ]; then
            cat "$PVM_ALIAS_DIR/$alias_name"
        else
            pvm_error "Alias '$alias_name' not found"
            return 1
        fi
        return 0
    fi
    
    # Create/update alias
    echo "$version" > "$PVM_ALIAS_DIR/$alias_name"
    pvm_echo "Alias '$alias_name' set to $version"
}

pvm_uninstall() {
    local version=$1
    
    if [ -z "$version" ]; then
        pvm_error "Please specify a version to uninstall"
        return 1
    fi
    
    version=${version#v}
    local version_dir="$PVM_VERSIONS_DIR/$version"
    
    if [ ! -d "$version_dir" ]; then
        pvm_error "PHP $version is not installed"
        return 1
    fi
    
    read -p "Are you sure you want to uninstall PHP $version? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$version_dir"
        pvm_echo "Uninstalled PHP $version (symlinks only)"
        pvm_info "Note: System packages are not removed. Use your package manager to remove them."
    fi
}

pvm_which() {
    local version=${1:-$(cat "$PVM_CURRENT_FILE" 2>/dev/null)}
    
    if [ -z "$version" ]; then
        pvm_error "No version specified or active"
        return 1
    fi
    
    version=${version#v}
    echo "$PVM_VERSIONS_DIR/$version/bin/php"
}

pvm_exec() {
    local version=$1
    shift
    
    if [ -z "$version" ]; then
        pvm_error "Please specify a version"
        echo "Usage: pvm exec <version> <command>"
        return 1
    fi
    
    version=${version#v}
    local php_bin="$PVM_VERSIONS_DIR/$version/bin/php"
    
    if [ ! -f "$php_bin" ] && [ ! -L "$php_bin" ]; then
        pvm_error "PHP $version is not installed"
        return 1
    fi
    
    "$php_bin" "$@"
}

pvm_help() {
    cat << EOF
${GREEN}PHP Version Manager (pvm)${NC} - Binary Installation

${BLUE}Usage:${NC}
  pvm install <version>     Install PHP using system packages (no compilation!)
  pvm use <version>         Use a specific PHP version
  pvm list                  List installed PHP versions
  pvm list-remote           List available PHP versions
  pvm current               Show currently active version
  pvm uninstall <version>   Uninstall a PHP version
  pvm alias [name] [ver]    Create/list version aliases
  pvm which [version]       Show path to PHP binary
  pvm exec <ver> <cmd>      Execute command with specific version
  pvm help                  Show this help message

${BLUE}Examples:${NC}
  pvm install 8.3.0         # Fast installation using pre-built packages
  pvm use 8.3.0
  pvm alias default 8.3.0
  pvm exec 8.2.0 script.php

${BLUE}Auto-switching:${NC}
Create a .phpversion file in your project with version number.
pvm will automatically switch when you cd into the directory.

${BLUE}Installation Method:${NC}
- Uses system package managers (apt, dnf, pacman, brew)
- No compilation required - fast and lightweight
- Common extensions included automatically

${BLUE}Detected OS:${NC} $(pvm_detect_os)
${BLUE}Architecture:${NC} $(pvm_detect_arch)
${BLUE}PVM Directory:${NC} $PVM_DIR
EOF
}

# Main command dispatcher
pvm() {
    local command=$1
    shift
    
    pvm_init
    
    case "$command" in
        install)
            pvm_install "$@"
            ;;
        use)
            pvm_use "$@"
            ;;
        list)
            pvm_list
            ;;
        list-remote|ls-remote)
            pvm_list_remote
            ;;
        current)
            pvm_current
            ;;
        uninstall)
            pvm_uninstall "$@"
            ;;
        alias)
            pvm_alias "$@"
            ;;
        which)
            pvm_which "$@"
            ;;
        exec)
            pvm_exec "$@"
            ;;
        help|--help|-h)
            pvm_help
            ;;
        *)
            if [ -z "$command" ]; then
                pvm_help
            else
                pvm_error "Unknown command: $command"
                pvm_help
                return 1
            fi
            ;;
    esac
}

# Auto-switch version when entering directory with .phpversion
pvm_auto_switch() {
    if [ -f ".phpversion" ]; then
        local version=$(cat .phpversion | tr -d '[:space:]')
        local current_version=$(cat "$PVM_CURRENT_FILE" 2>/dev/null)
        
        if [ "$version" != "$current_version" ]; then
            pvm use "$version"
        fi
    fi
}

# Hook into cd if PROMPT_COMMAND or chpwd is available
if [ -n "$BASH_VERSION" ]; then
    pvm_cd() {
        builtin cd "$@" && pvm_auto_switch
    }
    alias cd='pvm_cd'
elif [ -n "$ZSH_VERSION" ]; then
    chpwd_functions+=(pvm_auto_switch)
fi

pvm_echo "PHP Version Manager loaded! 🚀"
pvm_echo "Run 'pvm help' to get started"
pvm_info "Detected OS: $(pvm_detect_os) ($(pvm_detect_arch))"
