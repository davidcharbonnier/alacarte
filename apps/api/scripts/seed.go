package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"gorm.io/gorm"
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

	seedCheese()
	seedGin()
	seedChiliSauce()

	fmt.Println("\n✅ Database seeding completed successfully!")
}

func seedCheese() {
	source := os.Getenv("CHEESE_DATA_SOURCE")
	if source == "" {
		fmt.Println("ℹ️  CHEESE_DATA_SOURCE not set, skipping cheese seeding")
		return
	}

	fmt.Println("📦 Seeding cheeses...")

	// Fetch data using generic utility
	data, err := utils.FetchURLData(source)
	if err != nil {
		log.Printf("❌ Failed to fetch cheese data: %v", err)
		return
	}

	// Parse cheese-specific JSON structure
	var jsonData struct {
		Cheeses []models.Cheese `json:"cheeses"`
	}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		log.Printf("❌ Failed to parse cheese JSON: %v", err)
		return
	}

	// Import cheeses with cheese-specific natural key logic
	result := utils.SeedResult{Errors: []string{}}

	for _, cheese := range jsonData.Cheeses {
		// Check if cheese already exists (natural key: name + origin)
		var existing models.Cheese
		err := utils.DB.Where("name = ? AND origin = ?", cheese.Name, cheese.Origin).First(&existing).Error

		if err == nil {
			// Already exists - skip
			result.Skipped++
			continue
		}

		if err != gorm.ErrRecordNotFound {
			result.Errors = append(result.Errors, fmt.Sprintf("Error checking %s: %v", cheese.Name, err))
			continue
		}

		// Create new cheese
		if err := utils.DB.Create(&cheese).Error; err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("Failed to create %s: %v", cheese.Name, err))
			continue
		}
		result.Added++
	}

	fmt.Printf("   ✓ Added: %d\n", result.Added)
	fmt.Printf("   ⊘ Skipped: %d (already exist)\n", result.Skipped)
	if len(result.Errors) > 0 {
		fmt.Printf("   ✗ Errors: %d\n", len(result.Errors))
		for _, err := range result.Errors {
			fmt.Printf("      - %s\n", err)
		}
	}
}

func seedGin() {
	source := os.Getenv("GIN_DATA_SOURCE")
	if source == "" {
		fmt.Println("ℹ️  GIN_DATA_SOURCE not set, skipping gin seeding")
		return
	}

	fmt.Println("📦 Seeding gins...")

	// Fetch data using generic utility
	data, err := utils.FetchURLData(source)
	if err != nil {
		log.Printf("❌ Failed to fetch gin data: %v", err)
		return
	}

	// Parse gin-specific JSON structure
	var jsonData struct {
		Gins []models.Gin `json:"gins"`
	}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		log.Printf("❌ Failed to parse gin JSON: %v", err)
		return
	}

	// Import gins with gin-specific natural key logic
	result := utils.SeedResult{Errors: []string{}}

	for _, gin := range jsonData.Gins {
		// Check if gin already exists (natural key: name + origin)
		var existing models.Gin
		err := utils.DB.Where("name = ? AND origin = ?", gin.Name, gin.Origin).First(&existing).Error

		if err == nil {
			// Already exists - skip
			result.Skipped++
			continue
		}

		if err != gorm.ErrRecordNotFound {
			result.Errors = append(result.Errors, fmt.Sprintf("Error checking %s: %v", gin.Name, err))
			continue
		}

		// Create new gin
		if err := utils.DB.Create(&gin).Error; err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("Failed to create %s: %v", gin.Name, err))
			continue
		}
		result.Added++
	}

	fmt.Printf("   ✓ Added: %d\n", result.Added)
	fmt.Printf("   ⊘ Skipped: %d (already exist)\n", result.Skipped)
	if len(result.Errors) > 0 {
		fmt.Printf("   ✗ Errors: %d\n", len(result.Errors))
		for _, err := range result.Errors {
			fmt.Printf("      - %s\n", err)
		}
	}
}

func seedChiliSauce() {
	source := os.Getenv("CHILI_SAUCE_DATA_SOURCE")
	if source == "" {
		fmt.Println("ℹ️  CHILI_SAUCE_DATA_SOURCE not set, skipping chili sauce seeding")
		return
	}

	fmt.Println("📦 Seeding chili sauces...")

	// Fetch data using generic utility
	data, err := utils.FetchURLData(source)
	if err != nil {
		log.Printf("❌ Failed to fetch chili sauce data: %v", err)
		return
	}

	// Parse chili sauce-specific JSON structure
	var jsonData struct {
		ChiliSauces []models.ChiliSauce `json:"chiliSauces"`
	}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		log.Printf("❌ Failed to parse chili sauce JSON: %v", err)
		return
	}

	// Import chili sauces with chili sauce-specific natural key logic
	result := utils.SeedResult{Errors: []string{}}

	for _, chiliSauce := range jsonData.ChiliSauces {
		// Check if chili sauce already exists (natural key: name + brand)
		var existing models.ChiliSauce
		err := utils.DB.Where("name = ? AND brand = ?", chiliSauce.Name, chiliSauce.Brand).First(&existing).Error

		if err == nil {
			// Already exists - skip
			result.Skipped++
			continue
		}

		if err != gorm.ErrRecordNotFound {
			result.Errors = append(result.Errors, fmt.Sprintf("Error checking %s: %v", chiliSauce.Name, err))
			continue
		}

		// Create new chili sauce
		if err := utils.DB.Create(&chiliSauce).Error; err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("Failed to create %s: %v", chiliSauce.Name, err))
			continue
		}
		result.Added++
	}

	fmt.Printf("   ✓ Added: %d\n", result.Added)
	fmt.Printf("   ⊘ Skipped: %d (already exist)\n", result.Skipped)
	if len(result.Errors) > 0 {
		fmt.Printf("   ✗ Errors: %d\n", len(result.Errors))
		for _, err := range result.Errors {
			fmt.Printf("      - %s\n", err)
		}
	}
}
