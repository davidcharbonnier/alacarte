package utils

import (
	"bytes"
	"fmt"
	"image"
	"io"
	"mime/multipart"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/disintegration/imaging"
)

// ProcessedImage contains the processed image data and metadata
type ProcessedImage struct {
	Data        *bytes.Buffer
	ContentType string
	Extension   string
}

// ValidateAndProcessImage performs complete validation and processing of an uploaded image
func ValidateAndProcessImage(file multipart.File, header *multipart.FileHeader) (*ProcessedImage, error) {
	// Step 1: Validate file extension
	if err := validateFileExtension(header.Filename); err != nil {
		return nil, err
	}

	// Step 2: Validate file size
	const maxSize = 5 * 1024 * 1024 // 5MB
	if header.Size > maxSize {
		return nil, fmt.Errorf("file too large: %d bytes (max: %d bytes)", header.Size, maxSize)
	}

	// Step 3: Validate content type (magic bytes)
	if err := validateImageContent(file); err != nil {
		return nil, err
	}

	// Step 4: Decode and validate image structure
	img, format, err := decodeAndValidateImage(file)
	if err != nil {
		return nil, err
	}

	// Step 5: Process image (resize, optimize)
	processedData, err := processImage(img, format)
	if err != nil {
		return nil, err
	}

	// Step 6: Return processed image
	result := &ProcessedImage{
		Data:        processedData,
		ContentType: "image/jpeg",
		Extension:   ".jpg",
	}

	return result, nil
}

func validateFileExtension(filename string) error {
	allowedExtensions := map[string]bool{
		".jpg":  true,
		".jpeg": true,
		".png":  true,
		".webp": true,
	}

	ext := strings.ToLower(filepath.Ext(filename))
	if !allowedExtensions[ext] {
		return fmt.Errorf("unsupported file extension: %s. Allowed: jpg, jpeg, png, webp", ext)
	}

	return nil
}

func validateImageContent(file multipart.File) error {
	buffer := make([]byte, 512)
	n, err := file.Read(buffer)
	if err != nil && err != io.EOF {
		return fmt.Errorf("failed to read file: %w", err)
	}

	// Reset file pointer to beginning
	if _, err := file.Seek(0, 0); err != nil {
		return fmt.Errorf("failed to reset file pointer: %w", err)
	}

	contentType := http.DetectContentType(buffer[:n])

	allowedTypes := map[string]bool{
		"image/jpeg": true,
		"image/png":  true,
		"image/webp": true,
	}

	if !allowedTypes[contentType] {
		return fmt.Errorf("invalid content type: %s. Expected image/jpeg, image/png, or image/webp", contentType)
	}

	return nil
}

func decodeAndValidateImage(file multipart.File) (image.Image, string, error) {
	img, format, err := image.Decode(file)
	if err != nil {
		return nil, "", fmt.Errorf("failed to decode image: %w. File may be corrupted", err)
	}

	// Reset file pointer for later use
	if _, err := file.Seek(0, 0); err != nil {
		return nil, "", fmt.Errorf("failed to reset file pointer: %w", err)
	}

	// Validate image dimensions
	bounds := img.Bounds()
	width := bounds.Dx()
	height := bounds.Dy()

	const minDimension = 100  // At least 100px
	const maxDimension = 8000 // Max 8000px (prevents memory issues)

	if width < minDimension || height < minDimension {
		return nil, "", fmt.Errorf("image too small (%dx%d). Minimum dimensions: %dx%d",
			width, height, minDimension, minDimension)
	}

	if width > maxDimension || height > maxDimension {
		return nil, "", fmt.Errorf("image too large (%dx%d). Maximum dimensions: %dx%d",
			width, height, maxDimension, maxDimension)
	}

	return img, format, nil
}

func processImage(img image.Image, originalFormat string) (*bytes.Buffer, error) {
	const maxWidth = 1200
	const maxHeight = 1200

	bounds := img.Bounds()
	currentWidth := bounds.Dx()
	currentHeight := bounds.Dy()

	var processed image.Image

	// Only resize if image is larger than target dimensions
	if currentWidth > maxWidth || currentHeight > maxHeight {
		// imaging.Fit maintains aspect ratio and fits within bounds
		processed = imaging.Fit(img, maxWidth, maxHeight, imaging.Lanczos)
		// Apply sharpening to compensate for resize blur
		processed = imaging.Sharpen(processed, 0.5)
	} else {
		// Image is already small enough, use as-is
		processed = img
	}

	// Encode to JPEG with compression
	buf := new(bytes.Buffer)
	err := imaging.Encode(buf, processed, imaging.JPEG, imaging.JPEGQuality(85))
	if err != nil {
		return nil, fmt.Errorf("failed to encode image: %w", err)
	}

	return buf, nil
}
