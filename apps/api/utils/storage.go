package utils

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"os"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
)

var (
	s3Client   *s3.S3
	bucketName string
	publicURL  string
)

// InitStorageClient initializes the S3-compatible client (MinIO or GCS)
func InitStorageClient() {
	bucketName = os.Getenv("STORAGE_BUCKET_NAME")
	if bucketName == "" {
		log.Fatal("STORAGE_BUCKET_NAME environment variable not set")
	}

	endpoint := os.Getenv("STORAGE_ENDPOINT")
	region := os.Getenv("STORAGE_REGION")
	accessKey := os.Getenv("STORAGE_ACCESS_KEY")
	secretKey := os.Getenv("STORAGE_SECRET_KEY")
	useSSL := os.Getenv("STORAGE_USE_SSL") != "false" // Default to true, only disable if explicitly set to "false"

	// Construct public URL based on environment
	// Use STORAGE_PUBLIC_ENDPOINT if provided, otherwise fallback to STORAGE_ENDPOINT
	publicEndpoint := os.Getenv("STORAGE_PUBLIC_ENDPOINT")
	if publicEndpoint == "" {
		publicEndpoint = endpoint
	}

	// Build public URL
	protocol := "https"
	if !useSSL {
		protocol = "http"
	}
	publicURL = fmt.Sprintf("%s://%s/%s", protocol, publicEndpoint, bucketName)

	// Configure AWS SDK
	config := &aws.Config{
		Region:           aws.String(region),
		DisableSSL:       aws.Bool(!useSSL),
		S3ForcePathStyle: aws.Bool(true), // Required for MinIO
	}

	// Set endpoint if provided (MinIO or custom S3)
	if endpoint != "" {
		config.Endpoint = aws.String(endpoint)
	}

	// Set credentials if provided (MinIO or AWS)
	if accessKey != "" && secretKey != "" {
		config.Credentials = credentials.NewStaticCredentials(accessKey, secretKey, "")
	}
	// If not provided, AWS SDK will use IAM role (for Cloud Run/EC2)

	fmt.Printf("Connecting to storage bucket %s at %s\n", bucketName, endpoint)

	// Create session
	sess, err := session.NewSession(config)
	if err != nil {
		log.Fatal("Failed to create storage session:", err)
	}

	s3Client = s3.New(sess)

	// Test connectivity with bucket
	_, err = s3Client.HeadBucket(&s3.HeadBucketInput{
		Bucket: aws.String(bucketName),
	})
	if err != nil {
		log.Fatalf("Failed to connect to storage bucket '%s' at '%s': connection refused", bucketName, endpoint)
	}

	fmt.Println("Storage connection successful")
}

// UploadToStorage uploads a file to S3-compatible storage
// Returns the public URL of the uploaded file
func UploadToStorage(data io.Reader, filename string, contentType string) (string, error) {
	// Read data into buffer (required for S3 SDK)
	buf := new(bytes.Buffer)
	size, err := io.Copy(buf, data)
	if err != nil {
		return "", fmt.Errorf("failed to read data: %w", err)
	}

	// Upload to S3
	_, err = s3Client.PutObject(&s3.PutObjectInput{
		Bucket:        aws.String(bucketName),
		Key:           aws.String(filename),
		Body:          bytes.NewReader(buf.Bytes()),
		ContentType:   aws.String(contentType),
		ContentLength: aws.Int64(size),
		CacheControl:  aws.String("public, max-age=86400"), // 24 hours
		ACL:           aws.String("public-read"),           // Make publicly readable
	})
	if err != nil {
		return "", fmt.Errorf("failed to upload to storage: %w", err)
	}

	// Construct public URL
	imageURL := fmt.Sprintf("%s/%s", publicURL, filename)

	log.Printf("✅ Uploaded to storage: %s", imageURL)

	return imageURL, nil
}

// DeleteFromStorage deletes a file from S3-compatible storage
func DeleteFromStorage(filename string) error {
	_, err := s3Client.DeleteObject(&s3.DeleteObjectInput{
		Bucket: aws.String(bucketName),
		Key:    aws.String(filename),
	})
	if err != nil {
		return fmt.Errorf("failed to delete from storage: %w", err)
	}

	log.Printf("🗑️  Deleted from storage: %s", filename)

	return nil
}

// ExtractFilenameFromURL extracts filename from storage URL
// Example: "http://localhost:9000/bucket/wine_123.jpg" → "wine_123.jpg"
func ExtractFilenameFromURL(url string) string {
	if url == "" {
		return ""
	}

	parts := strings.Split(url, "/")
	if len(parts) > 0 {
		return parts[len(parts)-1]
	}

	return ""
}

// CheckIfFileExists checks if a file exists in storage
func CheckIfFileExists(filename string) (bool, error) {
	_, err := s3Client.HeadObject(&s3.HeadObjectInput{
		Bucket: aws.String(bucketName),
		Key:    aws.String(filename),
	})
	if err != nil {
		if strings.Contains(err.Error(), "NotFound") {
			return false, nil
		}
		return false, err
	}

	return true, nil
}
