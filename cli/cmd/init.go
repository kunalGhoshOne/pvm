package cmd

import (
	"fmt"

	"github.com/kunalGhoshOne/pvm/internal/config"
	"github.com/kunalGhoshOne/pvm/internal/switcher"
	"github.com/spf13/cobra"
)

var initCmd = &cobra.Command{
	Use:   "init",
	Short: "Set up pvm shims and print PATH instructions",
	RunE: func(cmd *cobra.Command, args []string) error {
		cfg := config.New()
		if err := cfg.EnsureDirs(); err != nil {
			return err
		}
		if err := switcher.New(cfg).EnsureShims(); err != nil {
			return err
		}
		fmt.Printf("pvm shims created at %s\n\n", cfg.ShimsDir)
		fmt.Println("Add the following line to your ~/.bashrc or ~/.zshrc:")
		fmt.Printf("  export PATH=\"%s:$PATH\"\n\n", cfg.ShimsDir)
		fmt.Println("Then restart your shell or run:")
		fmt.Printf("  source ~/.bashrc\n")
		return nil
	},
}
