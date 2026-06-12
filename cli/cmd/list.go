package cmd

import (
	"fmt"

	"github.com/kunalGhoshOne/pvm/internal/config"
	"github.com/kunalGhoshOne/pvm/internal/installer"
	"github.com/kunalGhoshOne/pvm/internal/switcher"
	"github.com/spf13/cobra"
)

var listCmd = &cobra.Command{
	Use:     "list",
	Aliases: []string{"ls"},
	Short:   "List installed PHP versions",
	RunE: func(cmd *cobra.Command, args []string) error {
		cfg := config.New()
		inst := installer.New(cfg)
		sw := switcher.New(cfg)

		current, _ := sw.Current()
		versions, err := inst.ListInstalled()
		if err != nil {
			return err
		}
		if len(versions) == 0 {
			fmt.Println("No PHP versions installed. Run: pvm install <version>")
			return nil
		}
		for _, v := range versions {
			if v == current {
				fmt.Printf("* %s (active)\n", v)
			} else {
				fmt.Printf("  %s\n", v)
			}
		}
		return nil
	},
}

var listRemoteCmd = &cobra.Command{
	Use:   "list-remote",
	Short: "List available PHP versions from the build repo",
	RunE: func(cmd *cobra.Command, args []string) error {
		cfg := config.New()
		vm, err := installer.New(cfg).FetchVersionMap()
		if err != nil {
			return err
		}
		fmt.Println("Available PHP versions:")
		for minor, full := range vm.Versions {
			fmt.Printf("  %-6s  (%s)\n", minor, full)
		}
		return nil
	},
}
