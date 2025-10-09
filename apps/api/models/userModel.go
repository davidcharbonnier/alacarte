package models

import (
	"fmt"
	"strings"
	"time"

	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	
	// OAuth fields
	GoogleID    string `gorm:"uniqueIndex;size:255" json:"google_id"`
	Email       string `gorm:"uniqueIndex;size:255" json:"email"`
	FullName    string `gorm:"size:255" json:"full_name"`
	Avatar      string `gorm:"size:500" json:"avatar"`
	
	// Privacy fields
	DisplayName       string `gorm:"uniqueIndex;size:100" json:"display_name"`
	Discoverable      bool   `gorm:"default:true" json:"discoverable"`
	ProfileCompleted  bool   `gorm:"default:false" json:"profile_completed"`
	
	// Admin flag
	IsAdmin           bool   `gorm:"default:false" json:"is_admin"`
	
	// Timestamps
	LastLoginAt time.Time `json:"last_login_at"`
	
	// Relationships
	Ratings []Rating `gorm:"foreignKey:UserID" json:"ratings,omitempty"`
}

// Check if user has completed profile setup
func (u *User) HasCompletedSetup() bool {
	return u.DisplayName != "" && u.ProfileCompleted
}

// Generate privacy-friendly display name from full name
func (u *User) GenerateDisplayName() string {
	if u.FullName == "" {
		return ""
	}
	
	parts := strings.Fields(u.FullName)
	if len(parts) == 1 {
		return parts[0]
	}
	
	firstName := parts[0]
	lastInitial := strings.ToUpper(string(parts[len(parts)-1][0]))
	
	return fmt.Sprintf("%s %s.", firstName, lastInitial)
}

// Check if user can be discovered by another user
func (u *User) CanBeDiscoveredBy(requesterID uint) bool {
	if u.ID == requesterID {
		return false // Users can't discover themselves
	}
	return u.Discoverable
}
