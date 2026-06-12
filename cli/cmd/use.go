package cmd

import (
	"github.com/kunalGhoshOne/pvm/internal/config"
	"github.com/kunalGhoshOne/pvm/internal/installer"
	"github.com/kunalGhoshOne/pvm/internal/switcher"
	"github.com/spf13/cobra"
)

var useCmd = &cobra.Command{
	Use:   "use <version>",
	Short: "Switch to a PHP version (installs it first if needed)",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		cfg := config.New()
		inst := installer.New(cfg)
		sw := switcher.New(cfg)
		version := args[0]

		if !inst.IsInstalled(version) {
			if err := cfg.EnsureDirs(); err != nil {
				return err
			}
			if err := inst.Install(version); err != nil {
				return err
			}
		}
		return sw.Use(version)
	},
}
