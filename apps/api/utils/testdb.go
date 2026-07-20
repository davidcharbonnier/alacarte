package utils

import (
	"context"
	"fmt"
	"log"
	"time"

	tpg "github.com/testcontainers/testcontainers-go/modules/postgres"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// SetupTestDB creates a fresh Postgres 16 container, runs migrations, and returns a cleanup function.
// Use it in tests like:
//
//	cleanup, err := utils.SetupTestDB()
//	if err != nil { t.Fatal(err) }
//	defer cleanup()
func SetupTestDB() (func(), error) {
	ctx := context.Background()

	ctr, err := tpg.Run(ctx,
		"postgres:16-alpine",
		tpg.WithDatabase("test_alacarte"),
		tpg.WithUsername("test"),
		tpg.WithPassword("test"),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to start postgres container: %w", err)
	}

	connStr, err := ctr.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		_ = ctr.Terminate(ctx)
		return nil, fmt.Errorf("failed to get connection string: %w", err)
	}

	// ponytail: retry connect, Postgres sometimes not ready when container reports ready
	var db *gorm.DB
	for i := 0; i < 10; i++ {
		db, err = gorm.Open(postgres.Open(connStr), &gorm.Config{})
		if err == nil {
			break
		}
		time.Sleep(500 * time.Millisecond)
	}
	if err != nil {
		_ = ctr.Terminate(ctx)
		return nil, fmt.Errorf("failed to connect to test db after retries: %w", err)
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
