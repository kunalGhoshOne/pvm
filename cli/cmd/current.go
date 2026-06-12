package cmd

import (
	"fmt"

	"github.com/kunalGhoshOne/pvm/internal/config"
	"github.com/kunalGhoshOne/pvm/internal/switcher"
	"github.com/spf13/cobra"
)

var currentCmd = &cobra.Command{
	Use:   "current",
	Short: "Show the active PHP version",
	RunE: func(cmd *cobra.Command, args []string) error {
		cfg := config.New()
		current, err := switcher.New(cfg).Current()
		if err != nil {
			return err
		}
		if current == "" {
			fmt.Println("No PHP version active — run: pvm use <version>")
		} else {
			fmt.Printf("PHP %s\n", current)
		}
		return nil
	},
}
