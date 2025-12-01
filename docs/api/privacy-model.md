# Privacy Model Documentation - Backend

## Table of Contents
- [Privacy Architecture](#privacy-architecture)
- [Database Schema](#database-schema)
- [Rating Visibility System](#rating-visibility-system)
- [User Discovery Implementation](#user-discovery-implementation)
- [API Endpoints](#api-endpoints)
- [Privacy Controls](#privacy-controls)
- [Privacy Settings API](#privacy-settings-api)
- [Bulk Privacy Operations](#bulk-privacy-operations)
- [Sharing Logic](#sharing-logic)
- [Community Statistics](#community-statistics)
- [Data Migration](#data-migration)
- [Security & Performance](#security--performance)

---
**Last Updated:** September 2025  
**Related Documentation:**
- [Authentication System](authentication-system.md)
---

## Privacy Architecture

The À la carte backend implements a **privacy-first rating system** where personal ratings remain private by default, with explicit sharing controls and selective user discovery.

### Core Privacy Principles

1. **Private by Default** - New ratings are only visible to the author
2. **Explicit Sharing** - Ratings shared only with selected users
3. **Display Name Protection** - Real identity protected via user-chosen display names
4. **Selective Discovery** - Users control visibility in sharing dialogs
5. **Anonymous Community Data** - Aggregate statistics without individual attribution

### Data Privacy Layers

```
Layer 1: Personal (UserID match)     → Full access to own ratings
Layer 2: Shared (Explicit viewers)   → Access to ratings shared with user
Layer 3: Community (Anonymous stats) → Aggregate data only, no individual ratings
Layer 4: Blocked (No access)         → No visibility to private/unshared ratings
```

## Database Schema

### Enhanced User Model

```go
// models/userModel.go (Privacy-focused)
package models

import (
    "strings"
    "gorm.io/gorm"
    "time"
)

type User struct {
    gorm.Model
    
    // Authentication fields
    GoogleID    string `gorm:"uniqueIndex;not null" json:"google_id"`
    Email       string `gorm:"uniqueIndex;not null" json:"email"`
    FullName    string `gorm:"not null" json:"full_name"`
    Avatar      string `json:"avatar"`
    
    // Privacy fields
    DisplayName  string `gorm:"uniqueIndex" json:"display_name"`
    Discoverable bool   `gorm:"default:true" json:"discoverable"`
    
    // Relationships
    Ratings           []Rating `gorm:"foreignKey:UserID" json:"ratings,omitempty"`
    SharedRatings     []Rating `gorm:"many2many:rating_viewers;" json:"shared_ratings,omitempty"`
    
    // Timestamps
    LastLoginAt time.Time `json:"last_login_at"`
}

// Privacy methods
func (u *User) HasCompletedSetup() bool {
    return u.DisplayName != ""
}

func (u *User) CanBeDiscoveredBy(requesterID uint) bool {
    if u.ID == requesterID {
        return false // Users can't discover themselves
    }
    return u.Discoverable
}
```

### Rating Model with Viewers

```go
// models/ratingModel.go (Enhanced for privacy)
package models

import (
    "gorm.io/gorm"
)

type Rating struct {
    gorm.Model
    
    // Rating data
    Grade    float32 `json:"grade"`
    Note     string  `json:"note"`
    
    // Item association (polymorphic)
    ItemID   int    `json:"item_id"`
    ItemType string `json:"item_type"`
    
    // User association
    UserID int  `json:"user_id"`
    User   User `gorm:"foreignKey:UserID" json:"user,omitempty"`
    
    // Privacy - users who can see this rating
    Viewers []User `gorm:"many2many:rating_viewers;" json:"viewers,omitempty"`
}

// Privacy methods
func (r *Rating) IsVisibleToUser(userID uint) bool {
    // Author can always see their own rating
    if r.UserID == int(userID) {
        return true
    }
    
    // Check if user is in viewers list
    for _, viewer := range r.Viewers {
        if viewer.ID == userID {
            return true
        }
    }
    
    return false
}
```

## API Endpoints

### Rating Privacy Endpoints

```go
// controllers/ratingController.go (Enhanced for privacy)
package controllers

import (
    "net/http"
    "strconv"
    "github.com/gin-gonic/gin"
    "github.com/davidcharbonnier/rest-api/models"
    "github.com/davidcharbonnier/rest-api/utils"
)

// Get user's complete reference list (own + shared ratings)
func RatingByViewer(c *gin.Context) {
    userID, err := strconv.Atoi(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
        return
    }
    
    // Ensure user can only access their own reference list
    currentUserID := getCurrentUserID(c)
    if uint(userID) != currentUserID {
        c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
        return
    }
    
    itemType := c.DefaultQuery("type", "%")
    
    var ratings []models.Rating
    err = utils.GetUserReferenceList(utils.DB, currentUserID, itemType).Find(&ratings).Error
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get ratings"})
        return
    }
    
    c.JSON(http.StatusOK, ratings)
}

// Share rating with specific users
func RatingShare(c *gin.Context) {
    ratingID, err := strconv.Atoi(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid rating ID"})
        return
    }
    
    var body struct {
        UserIDs []int `json:"user_ids" binding:"required"`
    }
    
    if err := c.ShouldBindJSON(&body); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
        return
    }
    
    // Get rating and verify ownership
    var rating models.Rating
    if err := utils.DB.Preload("Viewers").First(&rating, ratingID).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Rating not found"})
        return
    }
    
    currentUserID := getCurrentUserID(c)
    if uint(rating.UserID) != currentUserID {
        c.JSON(http.StatusForbidden, gin.H{"error": "You can only share your own ratings"})
        return
    }
    
    // Get users to share with
    var usersToAdd []models.User
    if err := utils.DB.Where("id IN ?", body.UserIDs).Find(&usersToAdd).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get users"})
        return
    }
    
    // Add new viewers (GORM handles duplicates)
    if err := utils.DB.Model(&rating).Association("Viewers").Append(&usersToAdd); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to share rating"})
        return
    }
    
    c.JSON(http.StatusOK, gin.H{"message": "Rating shared successfully"})
}
```

## Privacy Settings API

The backend provides comprehensive privacy management endpoints to support the frontend privacy settings screen.

### **📊 User Privacy Statistics**

```go
// GET /api/user/privacy-stats - Get user's privacy overview
func GetUserPrivacyStats(c *gin.Context) {
    userID := getUserIDFromToken(c)
    if userID == 0 {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
        return
    }
    
    // Get user's shared ratings
    var sharedRatings []models.Rating
    err := utils.DB.Where("user_id = ?", userID).
        Preload("Viewers").
        Find(&sharedRatings).Error
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get ratings"})
        return
    }
    
    // Filter ratings that have viewers (are shared)
    var actuallySharedRatings []models.Rating
    uniqueRecipients := make(map[uint]string)
    
    for _, rating := range sharedRatings {
        if len(rating.Viewers) > 0 {
            actuallySharedRatings = append(actuallySharedRatings, rating)
            
            // Track unique recipients
            for _, viewer := range rating.Viewers {
                if viewer.ID != uint(userID) { // Don't count self
                    uniqueRecipients[viewer.ID] = viewer.DisplayName
                }
            }
        }
    }
    
    // Build recipient list
    var recipients []map[string]interface{}
    for id, name := range uniqueRecipients {
        recipients = append(recipients, map[string]interface{}{
            "id":   id,
            "name": name,
        })
    }
    
    response := gin.H{
        "shared_ratings_count": len(actuallySharedRatings),
        "recipients_count":     len(uniqueRecipients),
        "recipients":           recipients,
        "shared_ratings":       actuallySharedRatings,
    }
    
    c.JSON(http.StatusOK, response)
}
```

### **🔍 User Discovery Settings**

```go
// PATCH /api/user/me - Update user discoverability and other privacy settings
func UpdateUserProfile(c *gin.Context) {
    userID := getUserIDFromToken(c)
    if userID == 0 {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
        return
    }
    
    var updateData struct {
        DisplayName  *string `json:"display_name"`
        Discoverable *bool   `json:"discoverable"`
    }
    
    if err := c.ShouldBindJSON(&updateData); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
        return
    }
    
    // Get current user
    var user models.User
    if err := utils.DB.First(&user, userID).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
        return
    }
    
    // Update fields if provided
    updates := make(map[string]interface{})
    
    if updateData.DisplayName != nil {
        // Validate display name
        displayName := strings.TrimSpace(*updateData.DisplayName)
        if displayName == "" {
            c.JSON(http.StatusBadRequest, gin.H{"error": "Display name cannot be empty"})
            return
        }
        
        // Check uniqueness
        var existingUser models.User
        if err := utils.DB.Where("display_name = ? AND id != ?", displayName, userID).First(&existingUser).Error; err == nil {
            c.JSON(http.StatusConflict, gin.H{"error": "Display name already taken"})
            return
        }
        
        updates["display_name"] = displayName
    }
    
    if updateData.Discoverable != nil {
        updates["discoverable"] = *updateData.Discoverable
    }
    
    // Apply updates
    if err := utils.DB.Model(&user).Updates(updates).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update profile"})
        return
    }
    
    // Return updated user
    if err := utils.DB.First(&user, userID).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get updated user"})
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "message": "Profile updated successfully",
        "user":    user,
    })
}
```

## Bulk Privacy Operations

Advanced privacy management endpoints for bulk operations on user ratings.

### **🔒 Make All Ratings Private**

```go
// PUT /api/ratings/bulk/make-private - Remove all viewers from all user's ratings
func MakeAllRatingsPrivate(c *gin.Context) {
    userID := getUserIDFromToken(c)
    if userID == 0 {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
        return
    }
    
    // Get all user's ratings with viewers
    var ratings []models.Rating
    err := utils.DB.Where("user_id = ?", userID).
        Preload("Viewers").
        Find(&ratings).Error
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get ratings"})
        return
    }
    
    ratingsAffected := 0
    viewersRemoved := 0
    
    // Start transaction for atomic operation
    tx := utils.DB.Begin()
    defer func() {
        if r := recover(); r != nil {
            tx.Rollback()
        }
    }()
    
    if tx.Error != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to start transaction"})
        return
    }
    
    // Remove all viewers from each rating
    for _, rating := range ratings {
        if len(rating.Viewers) > 0 {
            viewersRemoved += len(rating.Viewers)
            
            // Clear all viewers for this rating
            if err := tx.Model(&rating).Association("Viewers").Clear(); err != nil {
                tx.Rollback()
                c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to clear rating viewers"})
                return
            }
            
            ratingsAffected++
        }
    }
    
    // Commit transaction
    if err := tx.Commit().Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit changes"})
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "message":           "All ratings made private successfully",
        "ratings_affected":  ratingsAffected,
        "viewers_removed":   viewersRemoved,
    })
}
```

### **👤 Remove User from All Shares**

```go
// PUT /api/ratings/bulk/remove-user/:user_id - Remove specific user from all shared ratings
func RemoveUserFromAllShares(c *gin.Context) {
    userID := getUserIDFromToken(c)
    if userID == 0 {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
        return
    }
    
    targetUserID, err := strconv.Atoi(c.Param("user_id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
        return
    }
    
    // Verify target user exists
    var targetUser models.User
    if err := utils.DB.First(&targetUser, targetUserID).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Target user not found"})
        return
    }
    
    // Get all user's ratings that are shared with the target user
    var ratings []models.Rating
    err = utils.DB.Where("user_id = ?", userID).
        Preload("Viewers").
        Find(&ratings).Error
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get ratings"})
        return
    }
    
    ratingsAffected := 0
    
    // Start transaction
    tx := utils.DB.Begin()
    defer func() {
        if r := recover(); r != nil {
            tx.Rollback()
        }
    }()
    
    if tx.Error != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to start transaction"})
        return
    }
    
    // Remove target user from each rating's viewers
    for _, rating := range ratings {
        // Check if target user is a viewer of this rating
        isViewer := false
        for _, viewer := range rating.Viewers {
            if viewer.ID == uint(targetUserID) {
                isViewer = true
                break
            }
        }
        
        if isViewer {
            // Remove the target user from this rating's viewers
            if err := tx.Model(&rating).Association("Viewers").Delete(&targetUser); err != nil {
                tx.Rollback()
                c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove user from rating"})
                return
            }
            ratingsAffected++
        }
    }
    
    // Commit transaction
    if err := tx.Commit().Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit changes"})
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "message":          fmt.Sprintf("User %s removed from %d ratings", targetUser.DisplayName, ratingsAffected),
        "ratings_affected": ratingsAffected,
        "user_removed":     targetUser.DisplayName,
    })
}
```

### **📋 Get Shared Ratings with Recipients**

```go
// GET /api/ratings/shared - Get all user's shared ratings with detailed recipient info
func GetSharedRatings(c *gin.Context) {
    userID := getUserIDFromToken(c)
    if userID == 0 {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
        return
    }
    
    itemType := c.DefaultQuery("type", "%")
    
    var ratings []models.Rating
    query := utils.DB.Where("user_id = ?", userID).
        Preload("Viewers").
        Preload("User")
    
    if itemType != "%" {
        query = query.Where("item_type = ?", itemType)
    }
    
    err := query.Find(&ratings).Error
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get ratings"})
        return
    }
    
    // Filter to only ratings that are actually shared (have viewers)
    var sharedRatings []models.Rating
    for _, rating := range ratings {
        if len(rating.Viewers) > 0 {
            sharedRatings = append(sharedRatings, rating)
        }
    }
    
    c.JSON(http.StatusOK, gin.H{
        "shared_ratings": sharedRatings,
        "count":          len(sharedRatings),
    })
}
```

### **🔐 Enhanced Rating Privacy Endpoints**

```go
// PUT /api/rating/:id/unshare-from/:user_id - Remove specific user from rating viewers
func UnshareRatingFromUser(c *gin.Context) {
    ratingID, err := strconv.Atoi(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid rating ID"})
        return
    }
    
    targetUserID, err := strconv.Atoi(c.Param("user_id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
        return
    }
    
    userID := getUserIDFromToken(c)
    if userID == 0 {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
        return
    }
    
    // Get rating and verify ownership
    var rating models.Rating
    if err := utils.DB.Preload("Viewers").First(&rating, ratingID).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Rating not found"})
        return
    }
    
    if uint(rating.UserID) != userID {
        c.JSON(http.StatusForbidden, gin.H{"error": "You can only modify your own ratings"})
        return
    }
    
    // Get target user
    var targetUser models.User
    if err := utils.DB.First(&targetUser, targetUserID).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Target user not found"})
        return
    }
    
    // Remove target user from rating viewers
    if err := utils.DB.Model(&rating).Association("Viewers").Delete(&targetUser); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to unshare rating"})
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "message": fmt.Sprintf("Rating unshared from %s", targetUser.DisplayName),
    })
}

// PUT /api/rating/:id/make-private - Remove all viewers from rating
func MakeRatingPrivate(c *gin.Context) {
    ratingID, err := strconv.Atoi(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid rating ID"})
        return
    }
    
    userID := getUserIDFromToken(c)
    if userID == 0 {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
        return
    }
    
    // Get rating and verify ownership
    var rating models.Rating
    if err := utils.DB.Preload("Viewers").First(&rating, ratingID).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Rating not found"})
        return
    }
    
    if uint(rating.UserID) != userID {
        c.JSON(http.StatusForbidden, gin.H{"error": "You can only modify your own ratings"})
        return
    }
    
    viewersCount := len(rating.Viewers)
    
    // Clear all viewers
    if err := utils.DB.Model(&rating).Association("Viewers").Clear(); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to make rating private"})
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "message":         "Rating made private successfully",
        "viewers_removed": viewersCount,
    })
}
```

### **📊 Privacy Analytics Endpoints**

```go
// GET /api/user/sharing-relationships - Get user's sharing relationship analytics
func GetSharingRelationships(c *gin.Context) {
    userID := getUserIDFromToken(c)
    if userID == 0 {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
        return
    }
    
    // Query for sharing analytics
    type SharingRelationship struct {
        UserID      uint   `json:"user_id"`
        DisplayName string `json:"display_name"`
        SharedCount int    `json:"shared_count"`
    }
    
    var relationships []SharingRelationship
    
    err := utils.DB.Raw(`
        SELECT u.id as user_id, u.display_name, COUNT(rv.rating_id) as shared_count
        FROM users u
        INNER JOIN rating_viewers rv ON rv.user_id = u.id
        INNER JOIN ratings r ON r.id = rv.rating_id
        WHERE r.user_id = ? AND u.id != ?
        GROUP BY u.id, u.display_name
        ORDER BY shared_count DESC, u.display_name ASC
    `, userID, userID).Scan(&relationships).Error
    
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get sharing relationships"})
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "relationships": relationships,
        "count":         len(relationships),
    })
}
```

### **Router Setup for Privacy Endpoints**

```go
// main.go - Privacy-related route registration
func setupPrivacyRoutes(router *gin.Engine) {
    api := router.Group("/api")
    api.Use(authMiddleware()) // Require authentication for all privacy endpoints
    
    // User privacy settings
    api.GET("/user/privacy-stats", controllers.GetUserPrivacyStats)
    api.GET("/user/sharing-relationships", controllers.GetSharingRelationships)
    api.PATCH("/user/me", controllers.UpdateUserProfile)
    
    // Bulk privacy operations
    api.PUT("/ratings/bulk/make-private", controllers.MakeAllRatingsPrivate)
    api.PUT("/ratings/bulk/remove-user/:user_id", controllers.RemoveUserFromAllShares)
    
    // Individual rating privacy
    api.GET("/ratings/shared", controllers.GetSharedRatings)
    api.PUT("/rating/:id/unshare-from/:user_id", controllers.UnshareRatingFromUser)
    api.PUT("/rating/:id/make-private", controllers.MakeRatingPrivate)
}
```

These privacy endpoints provide comprehensive backend support for the frontend privacy settings screen, enabling users to have complete control over their rating sharing preferences with efficient bulk operations and detailed privacy analytics.

### User Discovery Implementation

```go
// controllers/userController.go

// Get users available for sharing (discoverable + previous connections)
func GetShareableUsers(c *gin.Context) {
    userID := getCurrentUserID(c)
    
    // Get users who have shared with current user (previous connections)
    previousConnections, err := getPreviousConnections(userID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get previous connections"})
        return
    }
    
    // Get IDs of previous connections to exclude from discoverable list
    excludeIDs := make([]uint, len(previousConnections))
    for i, user := range previousConnections {
        excludeIDs[i] = user.ID
    }
    
    // Get discoverable users (excluding current user and previous connections)
    discoverableUsers, err := getDiscoverableUsers(userID, excludeIDs)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get discoverable users"})
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "previous_connections": previousConnections,
        "discoverable":         discoverableUsers,
    })
}

// Get users who have shared ratings with current user
func getPreviousConnections(userID uint) ([]models.User, error) {
    var users []models.User
    
    err := utils.DB.Raw(`
        SELECT DISTINCT u.id, u.google_id, u.email, u.full_name, 
                       u.display_name, u.avatar, u.discoverable
        FROM users u
        INNER JOIN ratings r ON r.user_id = u.id
        INNER JOIN rating_viewers rv ON rv.rating_id = r.id
        WHERE rv.user_id = ? AND u.id != ?
        ORDER BY u.display_name
    `, userID, userID).Scan(&users).Error
    
    return users, err
}
```

## Security & Performance

### Database Indexes for Privacy Queries

```sql
-- Indexes for efficient privacy queries
CREATE INDEX idx_rating_viewers_user_id ON rating_viewers(user_id);
CREATE INDEX idx_rating_viewers_rating_id ON rating_viewers(rating_id);
CREATE INDEX idx_ratings_user_item ON ratings(user_id, item_type, item_id);
CREATE INDEX idx_ratings_item ON ratings(item_type, item_id);
CREATE INDEX idx_users_discoverable ON users(discoverable);
CREATE INDEX idx_users_display_name ON users(display_name);
```

---

**This privacy model backend implementation provides a secure, scalable foundation for user-controlled rating sharing while maintaining strong privacy protections and efficient query performance.**
