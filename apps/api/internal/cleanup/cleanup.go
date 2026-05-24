package cleanup

import (
	"fmt"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
)

func RunCleanupMigration() error {
	fmt.Println("=============================================")
	fmt.Println("  A LA CARTE - POST-MIGRATION CLEANUP")
	fmt.Println("=============================================")
	fmt.Println()

	if err := dropOldTables(); err != nil {
		fmt.Println("❌ Step 1 failed:", err)
		return err
	}

	fmt.Println()
	if err := dropRatingColumn(); err != nil {
		fmt.Println("❌ Step 2 failed:", err)
		return err
	}

	fmt.Println()
	if err := verifyIndexes(); err != nil {
		return err
	}

	fmt.Println()
	fmt.Println("=============================================")
	fmt.Println("  CLEANUP SUCCESSFUL")
	fmt.Println("=============================================")
	return nil
}

func dropOldTables() error {
	fmt.Println("Step 1: Dropping old item type tables...")
	tables := []string{"cheeses", "gins", "wines", "coffees", "chili_sauces", "migration_logs"}

	for _, name := range tables {
		if utils.DB.Migrator().HasTable(name) {
			if err := utils.DB.Migrator().DropTable(name); err != nil {
				fmt.Printf("  ⚠️  Failed to drop %s: %v\n", name, err)
				return fmt.Errorf("failed to drop table %s: %w", name, err)
			}
			fmt.Printf("  ✓ Dropped table %s\n", name)
		} else {
			fmt.Printf("  - Table %s does not exist (skipped)\n", name)
		}
	}
	return nil
}

func dropRatingColumn() error {
	fmt.Println("Step 2: Dropping ratings composite index and item_type column...")

	if utils.DB.Migrator().HasIndex(&models.Rating{}, "idx_ratings_item") {
		if err := utils.DB.Migrator().DropIndex(&models.Rating{}, "idx_ratings_item"); err != nil {
			fmt.Printf("  ⚠️  Failed to drop idx_ratings_item: %v\n", err)
			return err
		}
		fmt.Println("  ✓ Dropped index idx_ratings_item")
	} else {
		fmt.Println("  - Index idx_ratings_item does not exist (skipped)")
	}

	if utils.DB.Migrator().HasColumn(&models.Rating{}, "item_type") {
		if err := utils.DB.Migrator().DropColumn(&models.Rating{}, "item_type"); err != nil {
			fmt.Printf("  ⚠️  Failed to drop item_type column: %v\n", err)
			return err
		}
		fmt.Println("  ✓ Dropped column item_type from ratings")
	} else {
		fmt.Println("  - Column item_type does not exist (skipped)")
	}

	return nil
}

func verifyIndexes() error {
	fmt.Println("Step 3: Verifying new indexes...")
	indexes := []struct {
		table string
		name  string
	}{
		{"ratings", "idx_ratings_user_item"},
		{"ratings", "idx_ratings_item"},
	}

	allOk := true
	for _, idx := range indexes {
		if utils.DB.Migrator().HasIndex("ratings", idx.name) {
			fmt.Printf("  ✓ Index %s exists on %s\n", idx.name, idx.table)
		} else {
			fmt.Printf("  ❌ Index %s MISSING on %s\n", idx.name, idx.table)
			allOk = false
		}
	}

	if !allOk {
		fmt.Println()
		return fmt.Errorf("some indexes are missing - run AutoMigrate to recreate them")
	}
	fmt.Println("\n  All expected indexes verified ✓")
	return nil
}