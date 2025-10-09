package utils

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
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
