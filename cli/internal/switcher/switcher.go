package switcher

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/kunalGhoshOne/pvm/internal/config"
)

// shimTemplate is a shell script that reads the active PHP version at runtime
// and delegates to the correct binary. This means `pvm use` only needs to
// update ~/.pvm/version — no need to rewrite shims on every switch.
const shimTemplate = `#!/bin/sh
PVM_VERSION_FILE="${HOME}/.pvm/version"
if [ ! -f "$PVM_VERSION_FILE" ]; then
    echo "pvm: no PHP version selected. Run: pvm use <version>" >&2
    exit 1
fi
PVM_PHP="$(cat "$PVM_VERSION_FILE")"
PVM_DIR="${HOME}/.pvm/versions/${PVM_PHP}"
export PHPRC="${PVM_DIR}/lib"
export PHP_INI_SCAN_DIR="${PVM_DIR}/lib/conf.d"
exec "${PVM_DIR}/%s" "$@"
`

// phpBinaries maps shim name -> path relative to the version dir
var phpBinaries = map[string]string{
	"php":        "bin/php",
	"php-cgi":    "bin/php-cgi",
	"phpdbg":     "bin/phpdbg",
	"phpize":     "bin/phpize",
	"php-config": "bin/php-config",
	"phar":       "bin/phar",
	"phar.phar":  "bin/phar.phar",
	// php-fpm lands in sbin/ on most builds
	"php-fpm": "sbin/php-fpm",
}

type Switcher struct {
	cfg *config.Config
}

func New(cfg *config.Config) *Switcher {
	return &Switcher{cfg: cfg}
}

// Use sets the active PHP version and ensures shims exist.
func (s *Switcher) Use(version string) error {
	binDir := filepath.Join(s.cfg.VersionDir(version), "bin")
	if _, err := os.Stat(binDir); os.IsNotExist(err) {
		return fmt.Errorf("PHP %s is not installed — run: pvm install %s", version, version)
	}

	if err := s.EnsureShims(); err != nil {
		return err
	}

	if err := os.WriteFile(s.cfg.CurrentFile, []byte(version), 0644); err != nil {
		return err
	}

	fmt.Printf("Now using PHP %s\n", version)
	return nil
}

// EnsureShims creates the shim scripts in ~/.pvm/shims/ if they do not exist.
func (s *Switcher) EnsureShims() error {
	if err := os.MkdirAll(s.cfg.ShimsDir, 0755); err != nil {
		return err
	}

	for name, relPath := range phpBinaries {
		shimPath := filepath.Join(s.cfg.ShimsDir, name)
		if _, err := os.Stat(shimPath); err == nil {
			continue // already exists
		}
		content := fmt.Sprintf(shimTemplate, relPath)
		if err := os.WriteFile(shimPath, []byte(content), 0755); err != nil {
			return fmt.Errorf("failed to write shim %s: %w", name, err)
		}
	}
	return nil
}

// Current returns the active PHP version, or "" if none is set.
func (s *Switcher) Current() (string, error) {
	data, err := os.ReadFile(s.cfg.CurrentFile)
	if err != nil {
		if os.IsNotExist(err) {
			return "", nil
		}
		return "", err
	}
	return strings.TrimSpace(string(data)), nil
}
