#!/usr/bin/env bash

# PHP Version Manager (pvm)
# Similar to nvm but for PHP with automatic dependency installation

PVM_DIR="${PVM_DIR:-$HOME/.pvm}"
PVM_VERSIONS_DIR="$PVM_DIR/versions"
PVM_ALIAS_DIR="$PVM_DIR/alias"
PVM_CURRENT_FILE="$PVM_DIR/current"
PVM_DEPS_INSTALLED_FILE="$PVM_DIR/.deps_installed"

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

# Check if running with sudo/root
pvm_has_sudo() {
    if [ "$EUID" -eq 0 ]; then
        return 0
    fi
    
    if sudo -n true 2>/dev/null; then
        return 0
    fi
    
    return 1
}

# Check if a command exists
pvm_command_exists() {
    command -v "$1" &> /dev/null
}

# Check which dependencies are missing
pvm_check_dependencies() {
    local missing_deps=()
    local os=$(pvm_detect_os)
    
    pvm_info "Checking for existing dependencies..."
    
    # Common tools
    local common_tools=("curl" "wget" "git" "tar" "gzip" "unzip" "make")
    local common_missing=()
    
    for tool in "${common_tools[@]}"; do
        if ! pvm_command_exists "$tool"; then
            common_missing+=("$tool")
        else
            pvm_info "✓ $tool is already installed"
        fi
    done
    
    # Build tools
    local build_tools=("gcc" "g++" "autoconf")
    local build_missing=()
    
    for tool in "${build_tools[@]}"; do
        if ! pvm_command_exists "$tool"; then
            build_missing+=("$tool")
        else
            pvm_info "✓ $tool is already installed"
        fi
    done
    
    # Check for pkg-config
    if ! pvm_command_exists "pkg-config"; then
        missing_deps+=("pkg-config")
    else
        pvm_info "✓ pkg-config is already installed"
    fi
    
    # Return status
    if [ ${#common_missing[@]} -eq 0 ] && [ ${#build_missing[@]} -eq 0 ]; then
        pvm_echo "All essential tools are already installed!"
        
        # Check if we've verified libraries before
        if [ -f "$PVM_DEPS_INSTALLED_FILE" ]; then
            pvm_info "Build libraries were verified before."
            return 0
        else
            pvm_info "Will verify development libraries..."
            return 2  # Need to check libraries
        fi
    else
        if [ ${#common_missing[@]} -gt 0 ]; then
            pvm_warn "Missing common tools: ${common_missing[*]}"
        fi
        if [ ${#build_missing[@]} -gt 0 ]; then
            pvm_warn "Missing build tools: ${build_missing[*]}"
        fi
        return 1  # Need to install
    fi
}

# Install dependencies based on OS
pvm_install_dependencies() {
    # Check current state
    local check_result
    pvm_check_dependencies
    check_result=$?
    
    if [ $check_result -eq 0 ]; then
        pvm_info "All dependencies verified. Skipping installation."
        return 0
    fi
    
    if [ -f "$PVM_DEPS_INSTALLED_FILE" ] && [ $check_result -ne 1 ]; then
        pvm_info "Dependencies already verified. Run 'pvm reinstall-deps' to reinstall."
        return 0
    fi
    
    local os=$(pvm_detect_os)
    
    pvm_echo "Detected OS: $os"
    
    if [ $check_result -eq 1 ]; then
        pvm_echo "Installing missing dependencies..."
    else
        pvm_echo "Verifying and installing development libraries..."
    fi
    
    case "$os" in
        ubuntu|debian|pop|linuxmint)
            pvm_info "Installing dependencies for Debian/Ubuntu..."
            
            if ! pvm_has_sudo; then
                pvm_warn "This requires sudo privileges. You may be prompted for your password."
            fi
            
            # Only update if we're actually installing something
            if [ $check_result -eq 1 ]; then
                pvm_info "Updating package lists..."
                sudo apt-get update -qq
            fi
            
            pvm_info "Installing required packages (this may take a moment)..."
            sudo apt-get install -y -qq \
                build-essential \
                autoconf \
                libtool \
                bison \
                re2c \
                libxml2-dev \
                libssl-dev \
                libcurl4-openssl-dev \
                libzip-dev \
                libpng-dev \
                libjpeg-dev \
                libfreetype6-dev \
                libonig-dev \
                libsqlite3-dev \
                libpq-dev \
                pkg-config \
                curl \
                wget \
                git \
                unzip
            
            if [ $? -eq 0 ]; then
                pvm_echo "✓ All dependencies installed successfully!"
                touch "$PVM_DEPS_INSTALLED_FILE"
            else
                pvm_error "Failed to install some dependencies"
                return 1
            fi
            ;;
            
        fedora|rhel|centos|rocky|almalinux)
            pvm_info "Installing dependencies for RHEL/Fedora/CentOS..."
            
            if ! pvm_has_sudo; then
                pvm_warn "This requires sudo privileges. You may be prompted for your password."
            fi
            
            pvm_info "Installing required packages (this may take a moment)..."
            sudo dnf install -y -q \
                gcc \
                gcc-c++ \
                make \
                autoconf \
                libtool \
                bison \
                re2c \
                libxml2-devel \
                openssl-devel \
                libcurl-devel \
                libzip-devel \
                libpng-devel \
                libjpeg-devel \
                freetype-devel \
                oniguruma-devel \
                sqlite-devel \
                postgresql-devel \
                pkgconfig \
                curl \
                wget \
                git \
                unzip
            
            if [ $? -eq 0 ]; then
                pvm_echo "✓ All dependencies installed successfully!"
                touch "$PVM_DEPS_INSTALLED_FILE"
            else
                pvm_error "Failed to install some dependencies"
                return 1
            fi
            ;;
            
        arch|manjaro)
            pvm_info "Installing dependencies for Arch Linux..."
            
            if ! pvm_has_sudo; then
                pvm_warn "This requires sudo privileges. You may be prompted for your password."
            fi
            
            pvm_info "Installing required packages (this may take a moment)..."
            sudo pacman -Sy --noconfirm --needed \
                base-devel \
                autoconf \
                libtool \
                bison \
                re2c \
                libxml2 \
                openssl \
                curl \
                libzip \
                libpng \
                libjpeg-turbo \
                freetype2 \
                oniguruma \
                sqlite \
                postgresql-libs \
                pkgconf \
                wget \
                git \
                unzip
            
            if [ $? -eq 0 ]; then
                pvm_echo "✓ All dependencies installed successfully!"
                touch "$PVM_DEPS_INSTALLED_FILE"
            else
                pvm_error "Failed to install some dependencies"
                return 1
            fi
            ;;
            
        macos)
            pvm_info "Installing dependencies for macOS..."
            
            # Check if Homebrew is installed
            if ! pvm_command_exists brew; then
                pvm_echo "Homebrew not found. Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                
                if [ $? -ne 0 ]; then
                    pvm_error "Failed to install Homebrew"
                    return 1
                fi
                pvm_echo "✓ Homebrew installed successfully!"
            else
                pvm_info "✓ Homebrew is already installed"
            fi
            
            pvm_info "Installing required packages (this may take a moment)..."
            brew install -q \
                autoconf \
                automake \
                libtool \
                bison \
                re2c \
                libxml2 \
                openssl@3 \
                curl \
                libzip \
                libpng \
                jpeg \
                freetype \
                oniguruma \
                sqlite \
                postgresql \
                pkg-config \
                wget
            
            if [ $? -eq 0 ]; then
                pvm_echo "✓ All dependencies installed successfully!"
                
                # Set environment variables for macOS
                export PKG_CONFIG_PATH="/usr/local/opt/openssl@3/lib/pkgconfig:/usr/local/opt/libxml2/lib/pkgconfig:$PKG_CONFIG_PATH"
                
                pvm_info "Note: Added PKG_CONFIG_PATH for OpenSSL and libxml2"
                pvm_info "Consider adding this to your shell profile for persistence"
                
                touch "$PVM_DEPS_INSTALLED_FILE"
            else
                pvm_error "Failed to install some dependencies"
                return 1
            fi
            ;;
            
        *)
            pvm_error "Unsupported operating system: $os"
            pvm_info "Please install build dependencies manually:"
            pvm_info "  - build-essential / gcc / make"
            pvm_info "  - autoconf, libtool, bison, re2c"
            pvm_info "  - libxml2, openssl, curl, libzip"
            pvm_info "  - libpng, libjpeg, freetype, oniguruma"
            pvm_info "  - sqlite, postgresql (optional)"
            return 1
            ;;
    esac
}

pvm_list_remote() {
    pvm_echo "Fetching available PHP versions from php.net..."
    
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

pvm_install() {
    local version=$1
    
    if [ -z "$version" ]; then
        pvm_error "Please specify a version to install"
        echo "Usage: pvm install <version>"
        return 1
    fi
    
    # Check and install dependencies first
    if [ ! -f "$PVM_DEPS_INSTALLED_FILE" ]; then
        pvm_echo "Installing build dependencies first..."
        pvm_install_dependencies
        if [ $? -ne 0 ]; then
            pvm_error "Failed to install dependencies. Cannot proceed with PHP installation."
            return 1
        fi
    fi
    
    # Remove 'v' prefix if present
    version=${version#v}
    
    local install_dir="$PVM_VERSIONS_DIR/$version"
    
    if [ -d "$install_dir" ]; then
        pvm_warn "PHP $version is already installed"
        return 0
    fi
    
    pvm_echo "Installing PHP $version..."
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir" || return 1
    
    # Download PHP source
    pvm_echo "Downloading PHP $version source..."
    local download_url="https://www.php.net/distributions/php-${version}.tar.gz"
    
    if ! curl -fL "$download_url" -o "php-${version}.tar.gz"; then
        pvm_error "Failed to download PHP $version"
        pvm_info "Make sure the version exists. Try 'pvm list-remote' to see available versions"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Extract
    pvm_echo "Extracting..."
    tar -xzf "php-${version}.tar.gz"
    cd "php-${version}" || return 1
    
    # Detect OS for configure options
    local os=$(pvm_detect_os)
    local configure_opts="--prefix=$install_dir"
    
    if [ "$os" = "macos" ]; then
        # macOS specific paths
        configure_opts="$configure_opts \
            --with-openssl=$(brew --prefix openssl@3) \
            --with-curl=$(brew --prefix curl) \
            --with-zlib=$(brew --prefix zlib)"
    fi
    
    # Configure with common options
    pvm_echo "Configuring PHP $version..."
    ./configure \
        $configure_opts \
        --enable-mbstring \
        --enable-zip \
        --with-curl \
        --with-openssl \
        --with-zlib \
        --enable-fpm \
        --enable-bcmath \
        --with-pdo-mysql \
        --with-jpeg \
        --with-freetype \
        --enable-gd \
        --disable-cgi 2>&1 | tee configure.log | grep -E "(error|warning|checking)" | tail -20
    
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        pvm_error "Configuration failed."
        pvm_info "Check $temp_dir/php-${version}/configure.log for details"
        pvm_info "Dependencies might be missing. Run 'pvm reinstall-deps' to reinstall them"
        return 1
    fi
    
    # Compile
    pvm_echo "Compiling PHP $version (this may take 5-15 minutes)..."
    local num_cores=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)
    
    if ! make -j"$num_cores"; then
        pvm_error "Compilation failed"
        pvm_info "Check the output above for errors"
        return 1
    fi
    
    # Install
    pvm_echo "Installing to $install_dir..."
    make install
    
    # Cleanup
    cd "$HOME" || return 1
    rm -rf "$temp_dir"
    
    pvm_echo "Successfully installed PHP $version! 🎉"
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

pvm_reinstall_deps() {
    rm -f "$PVM_DEPS_INSTALLED_FILE"
    pvm_echo "Reinstalling dependencies..."
    pvm_install_dependencies
}

pvm_help() {
    cat << EOF
${GREEN}PHP Version Manager (pvm)${NC}

${BLUE}Usage:${NC}
  pvm install <version>     Install a specific PHP version (auto-installs dependencies)
  pvm use <version>         Use a specific PHP version
  pvm list                  List installed PHP versions
  pvm list-remote           List available PHP versions
  pvm current               Show currently active version
  pvm uninstall <version>   Uninstall a PHP version
  pvm alias [name] [ver]    Create/list version aliases
  pvm which [version]       Show path to PHP binary
  pvm exec <ver> <cmd>      Execute command with specific version
  pvm reinstall-deps        Reinstall build dependencies
  pvm help                  Show this help message

${BLUE}Examples:${NC}
  pvm install 8.3.0         # Installs dependencies automatically first time
  pvm use 8.3.0
  pvm alias default 8.3.0
  pvm exec 8.2.0 script.php

${BLUE}Auto-switching:${NC}
Create a .phpversion file in your project with version number.
pvm will automatically switch when you cd into the directory.

${BLUE}Detected OS:${NC} $(pvm_detect_os)
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
        reinstall-deps)
            pvm_reinstall_deps
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
pvm_info "Detected OS: $(pvm_detect_os)"
