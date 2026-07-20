package utils

import (
	"log"
	"os"

	"github.com/davidcharbonnier/alacarte-api/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func Connect() {
	databaseURL, defined := os.LookupEnv("DATABASE_URL")
	if !defined {
		log.Fatal("DATABASE_URL env var is not defined")
	}

	var err error
	DB, err = gorm.Open(postgres.Open(databaseURL), &gorm.Config{})
	if err != nil {
		log.Fatal(err.Error())
	}

	if sqlDB, err := DB.DB(); err == nil {
		if err := sqlDB.Ping(); err != nil {
			log.Println("Database ping failed:", err)
		} else {
			log.Println("Database connection successful")
		}
	}
}

// RunMigrations performs safe additive database migrations
func RunMigrations() {
	log.Println("Running database migrations...")

	err := DB.AutoMigrate(
		&models.User{},
		&models.Rating{},
		&models.ItemTypeSchema{},
		&models.ItemTypeField{},
		&models.SchemaVersion{},
		&models.Item{},
		&models.ItemFieldValue{},
	)
	if err != nil {
		log.Fatal("Database migration failed:", err)
	}

	log.Println("Database migrations completed successfully")
}
