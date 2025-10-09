package utils

import (
	"fmt"
	"log"
	"os"

	"github.com/davidcharbonnier/alacarte-api/models"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

var DB *gorm.DB

func MySQLConnect() {
	var err error

	mysql_host, defined := os.LookupEnv("MYSQL_HOST")
	if !defined {
		log.Fatal("MYSQL_HOST env var is not defined")
	}
	mysql_port, defined := os.LookupEnv("MYSQL_PORT")
	if !defined {
		mysql_port = "3306"
	}
	mysql_username, defined := os.LookupEnv("MYSQL_USERNAME")
	if !defined {
		log.Fatal("MYSQL_USERNAME env var is not defined")
	}
	mysql_password, defined := os.LookupEnv("MYSQL_PASSWORD")
	if !defined {
		log.Fatal("MYSQL_PASSWORD env var is not defined")
	}
	mysql_database, defined := os.LookupEnv("MYSQL_DATABASE")
	if !defined {
		log.Fatal("MYSQL_DATABASE env var is not defined")
	}

	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&allowNativePasswords=false", mysql_username, mysql_password, mysql_host, mysql_port, mysql_database)

	fmt.Println("Connecting to database " + mysql_database + " at " + mysql_host + ":" + mysql_port)

	DB, err = gorm.Open(mysql.Open(dsn), &gorm.Config{
		// Use standard GORM naming conventions (plural tables)
	})
	if err != nil {
		log.Fatal(err.Error())
	}

	// Simple connection test
	if sqlDB, err := DB.DB(); err == nil {
		if err := sqlDB.Ping(); err != nil {
			fmt.Println("Database ping failed:", err)
		} else {
			fmt.Println("Database connection successful")
		}
	}
}

// RunMigrations performs safe additive database migrations
func RunMigrations() {
	log.Println("Running database migrations...")

	// Safe additive migrations - only adds new tables/columns, never removes
	err := DB.AutoMigrate(
		&models.User{},
		&models.Cheese{},
		&models.Gin{},
		&models.Rating{},
	)
	if err != nil {
		log.Fatal("Database migration failed:", err)
	}

	log.Println("Database migrations completed successfully")
}
