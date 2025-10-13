package utils

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
)

// SeedResult contains the results of a seeding operation
type SeedResult struct {
	Added   int
	Skipped int
	Errors  []string
}

// ValidationResult contains the results of a validation operation
type ValidationResult struct {
	Valid      bool
	Errors     []string
	ItemCount  int
	Duplicates int
}

// SeedRequest represents the generic request structure for seeding
// Supports both URL-based and direct data seeding
type SeedRequest struct {
	URL  string          `json:"url"`  // Optional: URL to fetch data from
	Data json.RawMessage `json:"data"` // Optional: Direct JSON data
}

// GetSeedData is a generic helper that extracts data from either URL or direct upload
// This allows all item type controllers to support both seeding methods
func GetSeedData(c *gin.Context) ([]byte, error) {
	var req SeedRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		return nil, fmt.Errorf("invalid request format: %w", err)
	}

	// Validate that at least one source is provided
	if req.URL == "" && len(req.Data) == 0 {
		return nil, fmt.Errorf("either 'url' or 'data' must be provided")
	}

	// Prioritize direct data if both are provided
	if len(req.Data) > 0 {
		log.Printf("Using direct JSON data upload (%d bytes)", len(req.Data))
		return req.Data, nil
	}

	// Fall back to URL fetching
	log.Printf("Fetching data from URL: %s", req.URL)
	return FetchURLData(req.URL)
}

// FetchURLData fetches data from a URL or local file path
// This is a generic utility that can be used by any controller
func FetchURLData(source string) ([]byte, error) {
	var data []byte
	var err error

	if strings.HasPrefix(source, "http://") || strings.HasPrefix(source, "https://") {
		// Remote URL
		log.Printf("Fetching data from URL: %s", source)
		resp, err := http.Get(source)
		if err != nil {
			return nil, fmt.Errorf("failed to fetch remote data: %w", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			return nil, fmt.Errorf("HTTP error: %s", resp.Status)
		}

		data, err = io.ReadAll(resp.Body)
		if err != nil {
			return nil, fmt.Errorf("failed to read response: %w", err)
		}
	} else {
		// Local file path
		log.Printf("Loading data from file: %s", source)
		data, err = os.ReadFile(source)
		if err != nil {
			return nil, fmt.Errorf("failed to read file: %w", err)
		}
	}

	return data, nil
}
