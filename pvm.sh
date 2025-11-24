#!/usr/bin/env bash

# PHP Version Manager (pvm)
# Similar to nvm but for PHP

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

pvm_init() {
    mkdir -p "$PVM_VERSIONS_DIR"
    mkdir -p "$PVM_ALIAS_DIR"
}

pvm_list_remote() {
    pvm_echo "Fetching available PHP versions from php.net..."
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
    
    pvm_echo "Installing PHP $version..."
    pvm_echo "This will download and compile PHP from source"
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir" || return 1
    
    # Download PHP source
    pvm_echo "Downloading PHP $version source..."
    local download_url="https://www.php.net/distributions/php-${version}.tar.gz"
    
    if ! curl -LO "$download_url"; then
        pvm_error "Failed to download PHP $version"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Extract
    pvm_echo "Extracting..."
    tar -xzf "php-${version}.tar.gz"
    cd "php-${version}" || return 1
    
    # Configure with common options
    pvm_echo "Configuring PHP $version..."
    ./configure \
        --prefix="$install_dir" \
        --enable-mbstring \
        --enable-zip \
        --with-curl \
        --with-openssl \
        --with-zlib \
        --enable-fpm \
        --enable-bcmath \
        --with-pdo-mysql \
        --disable-cgi 2>&1 | grep -E "(error|warning|checking)"
    
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        pvm_error "Configuration failed. Make sure you have required dependencies installed."
        pvm_echo "On Ubuntu/Debian: sudo apt-get install build-essential libxml2-dev libssl-dev libcurl4-openssl-dev libzip-dev"
        pvm_echo "On macOS: brew install openssl curl zlib"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Compile
    pvm_echo "Compiling PHP $version (this may take a while)..."
    if ! make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2); then
        pvm_error "Compilation failed"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Install
    pvm_echo "Installing to $install_dir..."
    make install
    
    # Cleanup
    cd "$HOME" || return 1
    rm -rf "$temp_dir"
    
    pvm_echo "Successfully installed PHP $version"
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
    
    # Update PATH
    export PATH="$version_dir/bin:${PATH//$PVM_VERSIONS_DIR\/*/}"
    
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
        pvm_echo "Uninstalled PHP $version"
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
    
    if [ ! -f "$php_bin" ]; then
        pvm_error "PHP $version is not installed"
        return 1
    fi
    
    "$php_bin" "$@"
}

pvm_help() {
    cat << EOF
PHP Version Manager (pvm)

Usage:
  pvm install <version>     Install a specific PHP version
  pvm use <version>         Use a specific PHP version
  pvm list                  List installed PHP versions
  pvm list-remote           List available PHP versions
  pvm current               Show currently active version
  pvm uninstall <version>   Uninstall a PHP version
  pvm alias [name] [ver]    Create/list version aliases
  pvm which [version]       Show path to PHP binary
  pvm exec <ver> <cmd>      Execute command with specific version
  pvm help                  Show this help message

Examples:
  pvm install 8.3.0
  pvm use 8.3.0
  pvm alias default 8.3.0
  pvm exec 8.2.0 script.php

Create a .phpversion file in your project to auto-switch versions.
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

pvm_echo "PHP Version Manager loaded"
pvm_echo "Run 'pvm help' to get started"
