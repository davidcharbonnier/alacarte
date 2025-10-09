package utils

import (
	"fmt"
	"log"
	"os"
	"strings"
)

// Production-safe logging utilities
type Logger struct {
	isProduction bool
}

var AppLogger *Logger

func InitLogger() {
	AppLogger = &Logger{
		isProduction: os.Getenv("GIN_MODE") == "release",
	}
}

// Log authentication events safely (no sensitive data)
func (l *Logger) LogAuthSuccess(userEmail string) {
	if l.isProduction {
		// In production: log without email
		log.Printf("🔐 User authentication successful")
	} else {
		// In development: include email for debugging
		log.Printf("🔐 User authentication successful: %s", userEmail)
	}
}

func (l *Logger) LogAuthFailure(reason string) {
	// Safe to log - no sensitive data
	log.Printf("🚫 Authentication failed: %s", reason)
}

func (l *Logger) LogOAuthError(err error) {
	if l.isProduction {
		// In production: log generic error without details
		log.Printf("🔍 OAuth validation error (check server logs)")
	} else {
		// In development: include details for debugging
		log.Printf("🔍 OAuth validation error: %v", err)
	}
}

// Sanitize sensitive data from logs
func (l *Logger) SanitizeToken(token string) string {
	if len(token) < 10 {
		return "[invalid-token]"
	}
	return fmt.Sprintf("%s...%s", token[:4], token[len(token)-4:])
}

// Log API requests safely
func (l *Logger) LogAPIRequest(method, path, userAgent string) {
	if l.isProduction {
		log.Printf("📡 %s %s", method, path)
	} else {
		log.Printf("📡 %s %s - %s", method, path, userAgent)
	}
}

// Check if a string contains sensitive data patterns
func (l *Logger) ContainsSensitiveData(text string) bool {
	sensitivePatterns := []string{
		"password",
		"token",
		"secret",
		"key",
		"authorization",
		"bearer",
		"oauth",
	}
	
	lowerText := strings.ToLower(text)
	for _, pattern := range sensitivePatterns {
		if strings.Contains(lowerText, pattern) {
			return true
		}
	}
	return false
}

// Safe error logging that prevents sensitive data leaks
func (l *Logger) LogError(context string, err error) {
	errorMsg := err.Error()
	
	if l.ContainsSensitiveData(errorMsg) && l.isProduction {
		log.Printf("❌ %s: [sensitive error hidden in production]", context)
	} else {
		log.Printf("❌ %s: %v", context, err)
	}
}
