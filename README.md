# PVM - PHP Version Manager

Simple and powerful PHP version manager for Linux and macOS. Install, switch, and manage multiple PHP versions effortlessly.

## 🚀 Installation

### Step 1: Download PVM

```bash
curl -o install.sh https://raw.githubusercontent.com/kunalGhoshOne/pvm/development/install.sh && chmod +x install.sh && ./install.sh
```
curl -o ~/.pvm.sh https://[save-the-artifact-content]
# Or manually save the artifact to ~/.pvm.sh
```

**For Zsh:**
```bash
echo 'source ~/.pvm.sh' >> ~/.zshrc
source ~/.zshrc
```
source ~/.pvm.sh
```

That's it! PVM will automatically install dependencies when needed.

---

## 📖 Usage

### Install PHP Version

```bash
pvm install 8.3.0
```
source ~/.bashrc  # or source ~/.zshrc
```

### List Installed Versions

```bash
pvm list
```
sudo apt-get install build-essential libxml2-dev libssl-dev \
  libcurl4-openssl-dev libzip-dev pkg-config
```

### Show Current Version

```bash
pvm current
```
brew install openssl curl zlib pkg-config
```

### Execute with Specific Version

```bash
pvm exec 8.2.0 script.php
```
pvm install 8.3.0      # Install PHP 8.3.0
pvm use 8.3.0          # Switch to it
php -v                 # Verify

---

## 🎯 Project-Specific Versions

Create a `.phpversion` file in your project:

```bash
echo "8.3.0" > .phpversion
```

PVM will automatically switch to this version when you `cd` into the directory.

---

## 🔧 Additional Commands

### Reinstall Dependencies

```bash
pvm reinstall-deps
```

### Show PHP Binary Path

```bash
pvm which 8.3.0
```

### View Help

```bash
pvm help
```

---

## 💡 Example Workflow

```bash
# Install PHP 8.3.0
pvm install 8.3.0

# Switch to it
pvm use 8.3.0

# Verify
php -v

# Set as default
pvm alias default 8.3.0

# Install another version
pvm install 8.2.15
pvm use 8.2.15

# List all installed versions
pvm list
```

---

## 🛠️ What Gets Installed?

PVM automatically installs these dependencies based on your OS:

- Build tools (gcc, make, autoconf)
- Required libraries (openssl, curl, libzip, libxml2)
- Development headers
- PHP compilation tools

**Note:** You may be prompted for your sudo password during first installation.

---

## 📝 Uninstallation

Remove PVM and all installed PHP versions:

```bash
rm -rf ~/.pvm
```

Remove from shell profile:

```bash
# Remove this line from ~/.bashrc or ~/.zshrc
source ~/.pvm.sh
```

---

## ⚡ Tips

- Use `pvm list-remote` to see all available PHP versions
- Create a `.phpversion` file for automatic version switching
- Use aliases for quick switching: `pvm alias prod 8.3.0`
- Compilation takes 5-15 minutes depending on your system

---

## 🐛 Troubleshooting

**Dependencies failed to install:**
```bash
pvm reinstall-deps
```

**Compilation failed:**
- Check error messages for missing libraries
- Run `pvm reinstall-deps` and try again

**Version not switching:**
```bash
source ~/.bashrc  # or source ~/.zshrc
pvm use 8.3.0
```

---

## 📄 License

MIT License - Feel free to use and modify!
