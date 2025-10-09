package utils

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

func LoadEnvVars() {
	if err := godotenv.Load(); err != nil {
		log.Fatal("Error loading variables from .env file")
	}
}

// GetEnv gets an environment variable with a default value
func GetEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
