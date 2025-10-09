package models

import (
	"gorm.io/gorm"
)

type Rating struct {
	gorm.Model
	Grade    float32 `json:"grade"`
	Note     string  `json:"note"`
	
	// User association with CASCADE deletion
	UserID int  `json:"user_id"`
	User   User `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"user,omitempty"`
	
	// Item association (polymorphic)
	ItemID   int    `json:"item_id"`
	ItemType string `json:"item_type"`
	
	// Privacy - users who can see this rating
	Viewers []User `gorm:"many2many:rating_viewers;" json:"viewers,omitempty"`
}

// Check if rating is visible to a specific user
func (r *Rating) IsVisibleToUser(userID uint) bool {
	// Author can always see their own rating (ownership model)
	if r.UserID == int(userID) {
		return true
	}
	
	// Check if user is in viewers list (shared access)
	for _, viewer := range r.Viewers {
		if viewer.ID == userID {
			return true
		}
	}
	
	return false
}

// Check if rating is shared with a specific user (excluding author)
func (r *Rating) IsSharedWithUser(userID uint) bool {
	if r.UserID == int(userID) {
		return false // Not "shared" with yourself - you own it
	}
	
	for _, viewer := range r.Viewers {
		if viewer.ID == userID {
			return true
		}
	}
	
	return false
}

// Get count of external viewers (excluding the author)
func (r *Rating) GetViewerCount() int {
	// All viewers in the list are external since authors are no longer added as viewers
	return len(r.Viewers)
}
