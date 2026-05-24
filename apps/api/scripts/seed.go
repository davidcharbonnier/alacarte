//go:build ignore
// +build ignore

package main

import (
	"fmt"
	"os"

	"github.com/davidcharbonnier/alacarte-api/utils"
)

func init() {
	fmt.Println("=== SEED SCRIPT INITIALIZATION ===")

	if _, err := os.Stat(".env"); err == nil {
		fmt.Println("Loading .env file...")
		utils.LoadEnvVars()
	} else {
		fmt.Println("No .env file found (using environment variables)")
	}

	fmt.Println("Connecting to database...")
	utils.MySQLConnect()

	fmt.Println("Running migrations...")
	utils.RunMigrations()

	fmt.Println("=== INITIALIZATION COMPLETE ===\n")
}

func main() {
	fmt.Println("🌱 Starting data seeding process...\n")

	fmt.Println("ℹ️  Dynamic seed is now handled via the admin API: POST /admin/items/:type/seed")

	fmt.Println("\n✅ Database seeding completed successfully!")
}
