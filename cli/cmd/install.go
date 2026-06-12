package cmd

import (
	"github.com/kunalGhoshOne/pvm/internal/config"
	"github.com/kunalGhoshOne/pvm/internal/installer"
	"github.com/spf13/cobra"
)

var installCmd = &cobra.Command{
	Use:   "install <version>",
	Short: "Install a PHP version (e.g. pvm install 8.3)",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		cfg := config.New()
		if err := cfg.EnsureDirs(); err != nil {
			return err
		}
		return installer.New(cfg).Install(args[0])
	},
}
