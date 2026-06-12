package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "pvm",
	Short: "PHP Version Manager",
	Long:  "pvm — install and switch PHP versions on Linux",
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func init() {
	rootCmd.AddCommand(installCmd)
	rootCmd.AddCommand(useCmd)
	rootCmd.AddCommand(listCmd)
	rootCmd.AddCommand(listRemoteCmd)
	rootCmd.AddCommand(uninstallCmd)
	rootCmd.AddCommand(currentCmd)
	rootCmd.AddCommand(initCmd)
}
