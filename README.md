# Installation

Save the script:
```
curl -o ~/.pvm.sh https://[save-the-artifact-content]
# Or manually save the artifact to ~/.pvm.sh
```
Add to your shell profile (~/.bashrc or ~/.zshrc):
```
source ~/.pvm.sh
```
Reload your shell:
```
source ~/.bashrc  # or source ~/.zshrc
```
Key Features

Install PHP versions: pvm install 8.3.0
Switch versions: pvm use 8.3.0
List installed: pvm list
Auto-switching: Create a .phpversion file in your project with the version number
Aliases: pvm alias default 8.3.0
Execute with specific version: pvm exec 8.2.0 script.php

Prerequisites
Before installing PHP versions, you'll need build dependencies:
Ubuntu/Debian:
```
sudo apt-get install build-essential libxml2-dev libssl-dev \
  libcurl4-openssl-dev libzip-dev pkg-config
```
macOS:
```
brew install openssl curl zlib pkg-config
```
Example Workflow
```
pvm install 8.3.0      # Install PHP 8.3.0
pvm use 8.3.0          # Switch to it
php -v                 # Verify

# In your project
echo "8.3.0" > .phpversion
cd .  # Auto-switches when you cd into directory
```
#### The manager works just like nvm - it compiles PHP from source and manages PATH automatically!
