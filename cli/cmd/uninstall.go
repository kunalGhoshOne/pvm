package cmd

import (
	"fmt"

	"github.com/kunalGhoshOne/pvm/internal/config"
	"github.com/kunalGhoshOne/pvm/internal/installer"
	"github.com/spf13/cobra"
)

var uninstallCmd = &cobra.Command{
	Use:   "uninstall <version>",
	Short: "Remove an installed PHP version",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		cfg := config.New()
		if err := installer.New(cfg).Uninstall(args[0]); err != nil {
			return err
		}
		fmt.Printf("PHP %s removed\n", args[0])
		return nil
	},
}
