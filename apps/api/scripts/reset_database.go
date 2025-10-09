package main

import (
	"fmt"
	"os"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
)

func init() {
	if _, err := os.Stat(".env"); err == nil {
		utils.LoadEnvVars()
	}
	utils.MySQLConnect()
}

func main() {
	fmt.Println("🚨 DEVELOPMENT ONLY: Resetting database...")
	fmt.Println("⚠️  This will drop all tables and data!")

	// Drop tables in reverse dependency order
	if err := utils.DB.Migrator().DropTable(&models.Rating{}); err != nil {
		fmt.Printf("Note: Could not drop ratings table: %v\n", err)
	}

	if err := utils.DB.Migrator().DropTable("rating_viewers"); err != nil {
		fmt.Printf("Note: Could not drop rating_viewers table: %v\n", err)
	}

	if err := utils.DB.Migrator().DropTable(&models.User{}); err != nil {
		fmt.Printf("Note: Could not drop users table: %v\n", err)
	}

	if err := utils.DB.Migrator().DropTable(&models.Cheese{}); err != nil {
		fmt.Printf("Note: Could not drop cheeses table: %v\n", err)
	}

	if err := utils.DB.Migrator().DropTable(&models.Gin{}); err != nil {
		fmt.Printf("Note: Could not drop gins table: %v\n", err)
	}

	if err := utils.DB.Migrator().DropTable("sharing_relationships"); err != nil {
		fmt.Printf("Note: Could not drop sharing_relationships table: %v\n", err)
	}

	fmt.Println("✅ Tables dropped - restart your app to recreate schema via AutoMigrate")
	fmt.Println("💡 Then run 'go run scripts/seed.go' to add test data")
}
