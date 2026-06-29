package controllers

import (
	"bytes"
	"fmt"
	"log/slog"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
)

// UploadItemImage handles image upload for any item type
func UploadItemImage(c *gin.Context) {
	itemType := c.Param("itemType")
	itemID := c.Param("id")

	item, err := utils.GetItemByType(itemType, itemID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}

	processAndSaveImage(c, item, itemType)
}

func processAndSaveImage(c *gin.Context, item *models.Item, itemType string) {
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
		slog.Error("failed to upload to storage", "error", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload image"})
		return
	}

	// Delete old image if exists
	oldImageURL := item.GetImageURL()
	if oldImageURL != nil && *oldImageURL != "" {
		oldFilename := (*oldImageURL)[strings.LastIndex(*oldImageURL, "/")+1:]
		if err := utils.DeleteFromStorage(oldFilename); err != nil {
			// Log but don't fail
			slog.Error("failed to delete old image", "error", err)
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
	filename := (*imageURL)[strings.LastIndex(*imageURL, "/")+1:]
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
