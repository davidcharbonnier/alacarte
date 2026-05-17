//go:build ignore
// +build ignore

// This script runs the dynamic schema migration from the command line.
// For Cloud Run deployment, use RUN_SELF_HEALING_MIGRATION env var.
package main

import (
	"fmt"
	"os"

	"github.com/davidcharbonnier/alacarte-api/internal/migration"
	"github.com/davidcharbonnier/alacarte-api/utils"
)

func main() {
	fmt.Println("=== MIGRATION TO DYNAMIC SCHEMA ===")

	if _, err := os.Stat(".env"); err == nil {
		fmt.Println("Loading .env file...")
		utils.LoadEnvVars()
	} else {
		fmt.Println("No .env file found (using environment variables)")
	}

	fmt.Println("Connecting to database...")
	utils.MySQLConnect()

	fmt.Println("Running base migrations for new tables...")
	utils.RunMigrations()

	fmt.Println("=== INITIALIZATION COMPLETE ===\n")

	// Run the migration from the internal package
	if err := migration.RunSelfHealingMigration(); err != nil {
		fmt.Println("\n❌ Migration failed:", err)
		os.Exit(1)
	}

	fmt.Println("\n✅ Migration completed successfully!")
}
