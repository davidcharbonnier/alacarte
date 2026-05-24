//go:build ignore
// +build ignore

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

	// Drop dynamic and legacy tables
	if err := utils.DB.Migrator().DropTable(&models.ItemFieldValue{}); err != nil {
		fmt.Printf("Note: Could not drop item_field_values table: %v\n", err)
	}
	if err := utils.DB.Migrator().DropTable(&models.Item{}); err != nil {
		fmt.Printf("Note: Could not drop items table: %v\n", err)
	}
	if err := utils.DB.Migrator().DropTable(&models.SchemaVersion{}); err != nil {
		fmt.Printf("Note: Could not drop schema_versions table: %v\n", err)
	}
	if err := utils.DB.Migrator().DropTable(&models.ItemTypeField{}); err != nil {
		fmt.Printf("Note: Could not drop item_type_fields table: %v\n", err)
	}
	if err := utils.DB.Migrator().DropTable(&models.ItemTypeSchema{}); err != nil {
		fmt.Printf("Note: Could not drop item_type_schemas table: %v\n", err)
	}

	if err := utils.DB.Migrator().DropTable("sharing_relationships"); err != nil {
		fmt.Printf("Note: Could not drop sharing_relationships table: %v\n", err)
	}

	fmt.Println("✅ Tables dropped - restart your app to recreate schema via AutoMigrate")
}
