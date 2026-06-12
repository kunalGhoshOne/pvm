package installer

import (
	"archive/tar"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"

	"github.com/kunalGhoshOne/pvm/internal/config"
)

type VersionMap struct {
	Versions map[string]string `json:"versions"` // "8.3" -> "8.3.21"
}

type Installer struct {
	cfg *config.Config
}

func New(cfg *config.Config) *Installer {
	return &Installer{cfg: cfg}
}

func (i *Installer) FetchVersionMap() (*VersionMap, error) {
	resp, err := http.Get(config.VersionsURL)
	if err != nil {
		return nil, fmt.Errorf("failed to reach versions list: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("versions list returned HTTP %d", resp.StatusCode)
	}

	var vm VersionMap
	if err := json.NewDecoder(resp.Body).Decode(&vm); err != nil {
		return nil, fmt.Errorf("invalid versions list: %w", err)
	}
	return &vm, nil
}

func (i *Installer) Install(minorVersion string) error {
	vm, err := i.FetchVersionMap()
	if err != nil {
		return err
	}

	fullVersion, ok := vm.Versions[minorVersion]
	if !ok {
		return fmt.Errorf("PHP %s is not available — run 'pvm list-remote' to see available versions", minorVersion)
	}

	arch := runtime.GOARCH // "amd64" or "arm64"
	assetName := fmt.Sprintf("php-%s-linux-%s.tar.gz", fullVersion, arch)
	url := fmt.Sprintf("%s/releases/download/php-%s/%s", config.BuildsRepoBase, minorVersion, assetName)

	fmt.Printf("Installing PHP %s (%s)...\n", fullVersion, arch)

	destDir := i.cfg.VersionDir(minorVersion)
	if err := os.MkdirAll(destDir, 0755); err != nil {
		return err
	}

	if err := downloadAndExtract(url, destDir); err != nil {
		os.RemoveAll(destDir)
		return fmt.Errorf("install failed: %w", err)
	}

	if err := patchPHPIni(destDir, minorVersion); err != nil {
		return fmt.Errorf("warning: could not patch php.ini: %w", err)
	}

	fmt.Printf("PHP %s installed to %s\n", fullVersion, destDir)
	return nil
}

func (i *Installer) IsInstalled(version string) bool {
	_, err := os.Stat(i.cfg.VersionDir(version))
	return !os.IsNotExist(err)
}

func (i *Installer) ListInstalled() ([]string, error) {
	entries, err := os.ReadDir(i.cfg.VersionsDir)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, err
	}
	var versions []string
	for _, e := range entries {
		if e.IsDir() {
			versions = append(versions, e.Name())
		}
	}
	return versions, nil
}

func (i *Installer) Uninstall(version string) error {
	dir := i.cfg.VersionDir(version)
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		return fmt.Errorf("PHP %s is not installed", version)
	}
	return os.RemoveAll(dir)
}

// patchPHPIni replaces the build-time prefix (/pvm) in php.ini with the
// actual install path so extensions and configs resolve correctly at runtime.
func patchPHPIni(destDir, version string) error {
	iniPath := filepath.Join(destDir, "lib", "php.ini")
	data, err := os.ReadFile(iniPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil // no php.ini to patch
		}
		return err
	}

	patched := strings.ReplaceAll(string(data), config.BuildPrefix, destDir)
	return os.WriteFile(iniPath, []byte(patched), 0644)
}

func downloadAndExtract(url, destDir string) error {
	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("download failed: HTTP %d — check that the version exists in releases", resp.StatusCode)
	}

	gr, err := gzip.NewReader(resp.Body)
	if err != nil {
		return fmt.Errorf("invalid gzip: %w", err)
	}
	defer gr.Close()

	tr := tar.NewReader(gr)
	for {
		hdr, err := tr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return fmt.Errorf("corrupt archive: %w", err)
		}

		// Strip the leading "php/" directory from the archive
		parts := strings.SplitN(hdr.Name, "/", 2)
		if len(parts) < 2 || parts[1] == "" {
			continue
		}
		relPath := parts[1]

		target := filepath.Join(destDir, relPath)

		// Guard against path traversal
		if !strings.HasPrefix(filepath.Clean(target), filepath.Clean(destDir)+string(os.PathSeparator)) {
			return fmt.Errorf("unsafe path in archive: %s", hdr.Name)
		}

		switch hdr.Typeflag {
		case tar.TypeDir:
			if err := os.MkdirAll(target, os.FileMode(hdr.Mode)); err != nil {
				return err
			}
		case tar.TypeReg:
			if err := os.MkdirAll(filepath.Dir(target), 0755); err != nil {
				return err
			}
			f, err := os.OpenFile(target, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, os.FileMode(hdr.Mode))
			if err != nil {
				return err
			}
			_, copyErr := io.Copy(f, tr)
			f.Close()
			if copyErr != nil {
				return copyErr
			}
		case tar.TypeSymlink:
			os.Remove(target)
			if err := os.Symlink(hdr.Linkname, target); err != nil {
				return err
			}
		}
	}
	return nil
}
