package utils

import (
	"context"
	"fmt"
	"log"

	tcmysql "github.com/testcontainers/testcontainers-go/modules/mysql"
	gormmysql "gorm.io/driver/mysql"
	"gorm.io/gorm"
)

// SetupTestDB creates a fresh MySQL 8.4 container, runs migrations, and returns a cleanup function.
// Use it in tests like:
//
//	cleanup, err := utils.SetupTestDB()
//	if err != nil { t.Fatal(err) }
//	defer cleanup()
func SetupTestDB() (func(), error) {
	ctx := context.Background()

	ctr, err := tcmysql.Run(ctx,
		"mysql:8.4",
		tcmysql.WithDatabase("test_alacarte"),
		tcmysql.WithUsername("test"),
		tcmysql.WithPassword("test"),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to start mysql container: %w", err)
	}

	connStr, err := ctr.ConnectionString(ctx, "parseTime=true")
	if err != nil {
		_ = ctr.Terminate(ctx)
		return nil, fmt.Errorf("failed to get connection string: %w", err)
	}

	db, err := gorm.Open(gormmysql.Open(connStr), &gorm.Config{})
	if err != nil {
		_ = ctr.Terminate(ctx)
		return nil, fmt.Errorf("failed to connect to test db: %w", err)
	}

	// Set global DB so existing code works
	DB = db

	// Run migrations
	RunMigrations()

	cleanup := func() {
		if sqlDB, err := db.DB(); err == nil {
			sqlDB.Close()
		}
		if err := ctr.Terminate(ctx); err != nil {
			log.Printf("warning: failed to terminate test container: %v", err)
		}
	}

	return cleanup, nil
}
