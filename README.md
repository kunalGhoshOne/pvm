# pvm — PHP Version Manager

> Install and switch between PHP versions on Linux. No root required.

```
$ pvm install 8.3
Installing PHP 8.3.21 (amd64)...
PHP 8.3.21 installed to ~/.pvm/versions/8.3

$ pvm use 8.3
Now using PHP 8.3

$ php -v
PHP 8.3.21 (cli) built with pvm
```

---

## How it works

pvm pre-builds PHP for each version and architecture and stores the tarballs as GitHub Release assets. When you run `pvm install`, it downloads the right tarball for your machine and unpacks it to `~/.pvm/versions/`. Switching versions updates a single file (`~/.pvm/version`) — no shell functions or PATH hacks needed.

```
~/.pvm/
├── version          ← active version (just a text file)
├── shims/           ← always in your PATH
│   ├── php          ← reads ~/.pvm/version and delegates
│   ├── php-fpm
│   ├── phpize
│   └── ...
└── versions/
    ├── 8.2/
    ├── 8.3/         ← full PHP install lives here
    └── 8.4/
```

---

## Supported Versions

| Version | Full Release | Status        |
|---------|-------------|---------------|
| 8.4     | 8.4.7       | Latest        |
| 8.3     | 8.3.21      | Active        |
| 8.2     | 8.2.28      | Active        |
| 8.1     | 8.1.32      | Security only |
| 8.0     | 8.0.30      | End of life   |

**Architectures:** `linux/amd64` · `linux/arm64`

**Distros:** Ubuntu 20.04, 22.04, 24.04 — and any Linux with GLIBC 2.31+

---

## Installation

**1. Run the installer**

```bash
curl -fsSL https://raw.githubusercontent.com/kunalGhoshOne/pvm/main/install.sh | bash
```

The installer detects your architecture (amd64 / arm64) automatically and puts `pvm` in `/usr/local/bin`.

**2. Set up shims and add to PATH**

```bash
pvm init
```

Then add the line it prints to your `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$HOME/.pvm/shims:$PATH"
```

Restart your shell or run `source ~/.bashrc`.

---

## Usage

```bash
# Install a PHP version
pvm install 8.3

# Switch to it (installs automatically if not already installed)
pvm use 8.3

# See what's active
pvm current

# List installed versions
pvm list

# List all available versions from the build repo
pvm list-remote

# Remove a version
pvm uninstall 8.2
```

### Example workflow

```bash
# Project A needs PHP 8.1
cd ~/projects/legacy-app
pvm use 8.1
php artisan serve

# Project B needs PHP 8.4
cd ~/projects/new-app
pvm use 8.4
php -v
```

---

## Included Extensions

Every PHP build ships with these extensions ready to use — no compiling needed:

| Category    | Extensions                                              |
|-------------|---------------------------------------------------------|
| String      | mbstring, bcmath                                        |
| Database    | mysqli, pdo_mysql, pdo_sqlite, sqlite3, mysqlnd         |
| Image       | gd (freetype, jpeg, webp), exif                         |
| Network     | curl, soap, sockets                                     |
| Compression | zlib, zip                                               |
| Performance | opcache                                                 |
| System      | pcntl, shmop, sysvmsg, sysvsem, sysvshm                |
| Crypto      | openssl, sodium, argon2                                 |
| Other       | intl, gmp, calendar, readline                           |
| Server      | php-fpm                                                 |

---

## Building from source

If you want to build PHP tarballs yourself (e.g. to customise extensions):

```bash
# Build PHP 8.3 for your current architecture
cd server
./scripts/build.sh 8.3 amd64

# Build all versions and all architectures
./scripts/build-all.sh

# Upload a built version to GitHub Releases
./scripts/upload-release.sh 8.3
```

To build the `pvm` CLI binary:

```bash
cd cli
./build.sh          # amd64
./build.sh arm64    # arm64
# output → dist/pvm-linux-amd64
```

---

## Adding a new PHP version

1. Edit `server/scripts/versions.sh` and `server/versions.json` — add the new minor → full version mapping
2. Commit and push — the GitHub Actions workflow triggers automatically and builds + uploads the new version for both architectures

---

## Project layout

```
pvm/
├── cli/                        # Go CLI source
│   ├── cmd/                    # Commands (install, use, list, ...)
│   ├── internal/
│   │   ├── config/             # Paths and constants
│   │   ├── installer/          # Download + extract tarballs
│   │   └── switcher/           # Shim management + version switching
│   ├── Dockerfile              # Builds the CLI binary
│   └── build.sh                # Local build script
│
├── server/
│   ├── dockerfiles/Dockerfile  # Builds PHP from source
│   ├── scripts/
│   │   ├── versions.sh         # Minor → full version map
│   │   ├── build.sh            # Build one version + arch
│   │   ├── build-all.sh        # Build everything
│   │   └── upload-release.sh   # Push to GitHub Releases
│   └── versions.json           # Consumed by the CLI at install time
│
└── .github/workflows/
    ├── build-php.yml           # CI: build + release PHP on version changes
    └── release-cli.yml         # CI: build + release CLI on version tags
```

---

## License

MIT
