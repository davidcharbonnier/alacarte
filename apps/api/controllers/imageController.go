package controllers

import (
	"bytes"
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/davidcharbonnier/alacarte-api/utils"
)

// UploadItemImage handles image upload for any item type
func UploadItemImage(c *gin.Context) {
	itemType := c.Param("itemType")
	itemID := c.Param("id")

	// Validate item type
	if !utils.ValidateItemType(itemType) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item type"})
		return
	}

	// Get uploaded file
	file, header, err := c.Request.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No image provided"})
		return
	}
	defer file.Close()

	// Validate and process image
	processedImage, err := utils.ValidateAndProcessImage(file, header)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Generate unique filename
	filename := fmt.Sprintf("%s_%s%s", itemType, uuid.New().String(), processedImage.Extension)

	// Upload to storage (works with MinIO or GCS!)
	imageURL, err := utils.UploadToStorage(
		bytes.NewReader(processedImage.Data.Bytes()),
		filename,
		processedImage.ContentType,
	)
	if err != nil {
		utils.AppLogger.LogError("Failed to upload to storage", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload image"})
		return
	}

	// Get item (generic!)
	item, err := utils.GetItemByType(itemType, itemID)
	if err != nil {
		// Cleanup uploaded image
		utils.DeleteFromStorage(filename)
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}

	// Delete old image if exists
	oldImageURL := item.GetImageURL()
	if oldImageURL != nil && *oldImageURL != "" {
		oldFilename := utils.ExtractFilenameFromURL(*oldImageURL)
		if err := utils.DeleteFromStorage(oldFilename); err != nil {
			// Log but don't fail
			utils.AppLogger.LogError("Failed to delete old image", err)
		}
	}

	// Update with new image URL
	item.SetImageURL(&imageURL)
	if err := utils.SaveItem(item); err != nil {
		// Cleanup uploaded image
		utils.DeleteFromStorage(filename)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update database"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":   "Image uploaded successfully",
		"image_url": imageURL,
	})
}

// DeleteItemImage handles image deletion for any item type
func DeleteItemImage(c *gin.Context) {
	itemType := c.Param("itemType")
	itemID := c.Param("id")

	// Validate item type
	if !utils.ValidateItemType(itemType) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item type"})
		return
	}

	// Get item (generic!)
	item, err := utils.GetItemByType(itemType, itemID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}

	// Get image URL
	imageURL := item.GetImageURL()
	if imageURL == nil || *imageURL == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Item has no image"})
		return
	}

	// Delete image from storage
	filename := utils.ExtractFilenameFromURL(*imageURL)
	if err := utils.DeleteFromStorage(filename); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete image"})
		return
	}

	// Clear image URL in database
	item.SetImageURL(nil)
	if err := utils.SaveItem(item); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update database"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Image deleted successfully"})
}
