package config

import (
	"os"
	"path/filepath"
)

const (
	// Update these to match your actual GitHub repo
	BuildsRepoBase = "https://github.com/kunalGhoshOne/pvm"
	VersionsURL    = "https://raw.githubusercontent.com/kunalGhoshOne/pvm/main/server/versions.json"

	// Path PHP was compiled with inside the tarball
	BuildPrefix = "/pvm"
)

type Config struct {
	PVMDir      string
	VersionsDir string
	ShimsDir    string
	CurrentFile string
}

func New() *Config {
	home, _ := os.UserHomeDir()
	pvmDir := filepath.Join(home, ".pvm")
	return &Config{
		PVMDir:      pvmDir,
		VersionsDir: filepath.Join(pvmDir, "versions"),
		ShimsDir:    filepath.Join(pvmDir, "shims"),
		CurrentFile: filepath.Join(pvmDir, "version"),
	}
}

func (c *Config) VersionDir(version string) string {
	return filepath.Join(c.VersionsDir, version)
}

func (c *Config) EnsureDirs() error {
	for _, dir := range []string{c.VersionsDir, c.ShimsDir} {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return err
		}
	}
	return nil
}
