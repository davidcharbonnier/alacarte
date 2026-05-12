//go:build ignore
// +build ignore

package main

import (
	"fmt"
	"os"

	"github.com/davidcharbonnier/alacarte-api/utils"
)

func init() {
	fmt.Println("=== MIGRATION TO DYNAMIC SCHEMA ===")

	if _, err := os.Stat(".env"); err == nil {
		fmt.Println("Loading .env file...")
		utils.LoadEnvVars()
	} else {
		fmt.Println("No .env file found (using environment variables)")
	}

	fmt.Println("Connecting to database...")
	utils.MySQLConnect()

	fmt.Println("Running migrations for new tables...")
	utils.RunMigrations()

	fmt.Println("=== INITIALIZATION COMPLETE ===\n")
}

func main() {
	fmt.Println("🚀 Starting migration to dynamic schema system...\n")

	if len(os.Args) > 1 && os.Args[1] == "rollback" {
		fmt.Println("⚠️  ROLLBACK MODE - Reverting to old schema structure")
		PerformRollback()
		return
	}

	if len(os.Args) > 1 && os.Args[1] == "verify" {
		fmt.Println("🔍 VERIFICATION MODE - Checking migration integrity")
		VerifyMigration()
		return
	}

	step := ""
	if len(os.Args) > 1 {
		step = os.Args[1]
	}

	if step == "" || step == "schemas" {
		fmt.Println("📋 Step 1: Creating schema definitions...")
		CreateSchemaDefinitions()
	}

	if step == "" || step == "versions" {
		fmt.Println("\n📋 Step 2: Creating initial schema versions...")
		CreateSchemaVersions()
	}

	if step == "" || step == "data" {
		fmt.Println("\n📋 Step 3: Migrating data...")
		MigrateData()
	}

	if step == "" {
		fmt.Println("\n📋 Step 4: Verification...")
		VerifyMigration()
	}

	fmt.Println("\n✅ Migration completed successfully!")
	fmt.Printf("   Items migrated: %d\n", MigratedItems)
	fmt.Printf("   Ratings migrated: %d\n", MigratedRatings)
	fmt.Printf("   Items with errors: %d\n", ErrorItems)
}
