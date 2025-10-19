# Image Upload System

**Last Updated:** October 2025  
**Status:** Production Ready (Backend + Admin Display)

The A la carte platform supports image uploads for all item types (cheese, gin, wine, etc.) using S3-compatible storage with automatic image processing and optimization.

---

## 🎯 Overview

### Architecture
- **Storage:** S3-compatible API (MinIO for development, GCS for production)
- **Processing:** Server-side validation, resizing, and compression
- **Delivery:** Public URLs with configurable endpoints
- **Integration:** Generic implementation works for all item types

### Current Status
- ✅ Backend API endpoints (upload, delete)
- ✅ Image validation and processing
- ✅ Admin panel display (thumbnails, full-size, zoom)
- ⏳ Admin panel upload UI (not yet implemented)
- ⏳ Client app display and upload (not yet implemented)

---

## 🗄️ Database Schema

### Image URL Field

All item models include an optional `image_url` field:

```go
type Wine struct {
    gorm.Model
    Name        string
    // ... other fields ...
    ImageURL    *string  `json:"image_url,omitempty"`
    Ratings     []Rating `gorm:"polymorphic:Item;"`
}
```

**Properties:**
- **Type:** Nullable string pointer
- **Format:** Full public URL (e.g., `http://localhost:9000/alacarte-images/wine_uuid.jpg`)
- **Omitted:** Not included in JSON if null/empty
- **Migration:** Auto-added by GORM on startup

---

## 📡 Backend API

### Upload Image

**Endpoint:** `POST /admin/:itemType/:id/image`

**Authentication:** Admin JWT required

**Request:**
- Content-Type: `multipart/form-data`
- Field name: `image`
- Max size: 5MB

**Example:**
```bash
curl -X POST \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -F "image=@wine-bottle.jpg" \
  http://localhost:8080/admin/wine/1/image
```

**Response (200 OK):**
```json
{
  "message": "Image uploaded successfully",
  "image_url": "http://localhost:9000/alacarte-images/wine_550e8400-e29b-41d4-a716-446655440000.jpg"
}
```

**Errors:**
- `400 Bad Request` - Invalid image (format, size, dimensions)
- `404 Not Found` - Item doesn't exist
- `500 Internal Server Error` - Upload or database failure

### Delete Image

**Endpoint:** `DELETE /admin/:itemType/:id/image`

**Authentication:** Admin JWT required

**Example:**
```bash
curl -X DELETE \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  http://localhost:8080/admin/wine/1/image
```

**Response (200 OK):**
```json
{
  "message": "Image deleted successfully"
}
```

**Behavior:**
- Deletes image from storage bucket
- Sets `image_url` to `NULL` in database
- Returns error if item has no image

---

## 🔍 Image Validation

### File Constraints

| Constraint | Value | Reason |
|------------|-------|--------|
| Max size | 5MB | Prevents abuse, reasonable for photos |
| Min dimensions | 100x100px | Ensures usable quality |
| Max dimensions | 8000x8000px | Prevents memory issues |
| Allowed formats | JPEG, PNG, WebP | Standard web formats |

### Validation Process

1. **Extension check** - Validates file extension (`.jpg`, `.jpeg`, `.png`, `.webp`)
2. **Size check** - Ensures file ≤ 5MB
3. **Magic bytes check** - Detects actual content type (prevents fake extensions)
4. **Image decode** - Validates image structure (catches corrupted files)
5. **Dimension check** - Ensures 100px ≤ dimensions ≤ 8000px

**Security benefits:**
- Prevents uploading malware disguised as images
- Catches corrupted/invalid files early
- Protects against memory exhaustion attacks

---

## 🎨 Image Processing

### Automatic Optimization

All uploaded images are automatically processed:

1. **Resize** - Fit within 1200x1200px (maintains aspect ratio)
2. **Sharpen** - Apply 0.5 sharpening to compensate for resize blur
3. **Convert** - Output as JPEG with 85% quality
4. **Compress** - Reduces file size while maintaining visual quality

### Processing Details

```go
// Resize if needed
if width > 1200 || height > 1200 {
    processed = imaging.Fit(img, 1200, 1200, imaging.Lanczos)
    processed = imaging.Sharpen(processed, 0.5)
}

// Encode with compression
imaging.Encode(buf, processed, imaging.JPEG, imaging.JPEGQuality(85))
```

**Filter:** Lanczos resampling (highest quality)  
**Output:** Always JPEG (even if input is PNG/WebP)  
**Quality:** 85% (sweet spot for file size vs quality)

### File Naming

Images use UUID-based naming to prevent collisions and guessing:

```
{itemType}_{uuid}.jpg

Examples:
- wine_550e8400-e29b-41d4-a716-446655440000.jpg
- cheese_a1b2c3d4-e5f6-7890-abcd-ef1234567890.jpg
- gin_12345678-90ab-cdef-1234-567890abcdef.jpg
```

---

## 🗂️ Storage Configuration

### Environment Variables

```bash
# Storage endpoint (internal - API uses this to connect)
STORAGE_ENDPOINT=minio:9000

# Public endpoint (external - URLs stored in database use this)
STORAGE_PUBLIC_ENDPOINT=localhost:9000

# Bucket name
STORAGE_BUCKET_NAME=alacarte-images

# AWS region (required even for MinIO)
STORAGE_REGION=us-east-1

# Access credentials
STORAGE_ACCESS_KEY=minioadmin
STORAGE_SECRET_KEY=minioadmin

# SSL/TLS (default: true, set to "false" to disable)
STORAGE_USE_SSL=false
```

### Development Setup (MinIO)

```bash
# MinIO runs in Docker
STORAGE_ENDPOINT=minio:9000
STORAGE_PUBLIC_ENDPOINT=localhost:9000
STORAGE_BUCKET_NAME=alacarte-images
STORAGE_REGION=us-east-1
STORAGE_ACCESS_KEY=minioadmin
STORAGE_SECRET_KEY=minioadmin
STORAGE_USE_SSL=false
```

**Docker Compose:**
- MinIO service with health checks
- Auto-create bucket job
- Set public read permissions
- API depends on bucket creation

### Production Setup (GCS)

```bash
# GCS with S3 interoperability
STORAGE_ENDPOINT=storage.googleapis.com
STORAGE_PUBLIC_ENDPOINT=storage.googleapis.com
STORAGE_BUCKET_NAME=alacarte-item-images
STORAGE_REGION=us-central1
STORAGE_ACCESS_KEY=your-gcs-access-key
STORAGE_SECRET_KEY=your-gcs-secret-key
STORAGE_USE_SSL=true
```

**GCS Setup:**
1. Create HMAC keys for S3 compatibility:
   ```bash
   gsutil hmac create service-account@project.iam.gserviceaccount.com
   ```
2. Use Access Key ID and Secret as credentials
3. Both endpoints are the same (storage.googleapis.com)

**Alternative (Workload Identity):**
```bash
# Leave credentials empty - Cloud Run uses Workload Identity
STORAGE_ENDPOINT=storage.googleapis.com
STORAGE_PUBLIC_ENDPOINT=storage.googleapis.com
STORAGE_BUCKET_NAME=alacarte-item-images
STORAGE_REGION=us-central1
STORAGE_ACCESS_KEY=
STORAGE_SECRET_KEY=
STORAGE_USE_SSL=true
```

---

## 🔧 Implementation Details

### Generic Item Interface

All item types implement `ItemWithImage` interface:

```go
type ItemWithImage interface {
    GetImageURL() *string
    SetImageURL(url *string)
}

// Example implementation
func (c *Cheese) GetImageURL() *string {
    return c.ImageURL
}

func (c *Cheese) SetImageURL(url *string) {
    c.ImageURL = url
}
```

**Benefits:**
- Upload/delete controllers work for all item types
- No item-specific code needed
- Easy to add new item types

### Upload Flow

```
1. Admin uploads image via API
2. Backend validates file (size, format, content)
3. Backend processes image (resize, compress)
4. Backend generates UUID filename
5. Backend uploads to S3 storage
6. Backend constructs public URL
7. Backend fetches existing item from database
8. Backend deletes old image if exists
9. Backend updates item with new image URL
10. Backend returns success with image URL
```

**Error Handling:**
- Upload fails → cleanup uploaded image, return error
- Database fails → cleanup uploaded image, return error
- Old image delete fails → log warning, continue (not critical)

### Delete Flow

```
1. Admin deletes image via API
2. Backend fetches item from database
3. Backend extracts filename from URL
4. Backend deletes image from storage
5. Backend sets image_url to NULL
6. Backend saves item to database
7. Backend returns success
```

---

## 🖼️ Admin Panel Display

### Table View (List Page)

**Features:**
- Thumbnail column (48x48px) at the beginning
- Shows image if available
- Shows colored placeholder icon if no image
- Placeholder uses item type color

**Implementation:**
```tsx
{item.image_url ? (
  <div className="w-12 h-12 rounded-md overflow-hidden">
    <img src={item.image_url} alt={item.name} />
  </div>
) : (
  <div className="w-12 h-12 rounded-md" style={{ backgroundColor: colors.hex }}>
    <Package className="w-6 h-6" />
  </div>
)}
```

### Detail View (Item Page)

**Features:**
- Full-size image card (one of three columns)
- Click to zoom (opens modal with black background)
- Placeholder if no image
- Positioned third (after Basic Info and Description)

**Zoom Modal:**
- Black background for better viewing
- White close button (visible on any background)
- Max height: 85vh (prevents overflow)
- Click outside or ESC to close
- Accessible (screen reader support)

---

## 🔐 Security Considerations

### Upload Security

**Validation:**
- ✅ File extension whitelist
- ✅ MIME type verification (magic bytes)
- ✅ Image structure validation
- ✅ Size and dimension limits

**What's prevented:**
- Malware disguised as images
- Corrupted/invalid files
- Memory exhaustion attacks
- Path traversal attempts

### Storage Security

**Public Access:**
- Images are publicly readable (product photos, not sensitive)
- URLs are non-guessable (UUID-based)
- No directory listing enabled

**Access Control:**
- Only admins can upload/delete images
- JWT authentication required
- Rate limiting recommended (not yet implemented)

---

## 📊 Performance Considerations

### Image Optimization

**File Size Reduction:**
- Original: Variable (up to 5MB)
- Processed: Typically 100-500KB
- Reduction: ~80-90% average

**Impact:**
- Faster page loads
- Reduced bandwidth costs
- Better mobile experience

### Caching

**Browser Caching:**
- S3 sets `Cache-Control: public, max-age=86400` (24 hours)
- Images cached by browsers automatically
- Reduces server load

**CDN (Future):**
- Can add Cloud CDN in front of GCS
- Further reduces latency globally
- Lower egress costs

---

## 🧪 Testing

### Manual Testing

**Upload Test:**
```bash
# Get admin token
export ADMIN_TOKEN="your-jwt-token"

# Upload image
curl -X POST \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -F "image=@test-image.jpg" \
  http://localhost:8080/admin/wine/1/image

# Verify in admin panel
# Navigate to http://localhost:3001/wine/1
```

**Delete Test:**
```bash
# Delete image
curl -X DELETE \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  http://localhost:8080/admin/wine/1/image

# Verify in admin panel (should show placeholder)
```

### Edge Cases

**Test scenarios:**
- Upload very small image (< 100x100px) → should fail
- Upload very large image (> 8000x8000px) → should fail
- Upload non-image file → should fail
- Upload corrupted image → should fail
- Upload to non-existent item → should fail
- Replace existing image → old image should be deleted
- Delete non-existent image → should return error

---

## 🚀 Future Enhancements

### Planned Features

- [ ] **Admin panel upload UI** - Drag-and-drop interface
- [ ] **Client app image display** - Show images in Flutter app
- [ ] **Client app image upload** - Users can photograph items
- [ ] **Multiple images per item** - Gallery view (front, back, label)
- [ ] **Image moderation** - Admin approval for user-uploaded images
- [ ] **Advanced compression** - WebP with fallback to JPEG
- [ ] **Responsive images** - Generate multiple sizes for different devices
- [ ] **Image CDN** - Cloud CDN for faster global delivery
- [ ] **Rate limiting** - Prevent upload abuse

### Under Consideration

- [ ] **Image cropping** - Crop before upload (admin/client)
- [ ] **Filters** - Apply filters/adjustments
- [ ] **OCR** - Extract text from labels
- [ ] **Image search** - Find items by visual similarity
- [ ] **Batch upload** - Upload multiple images at once

---

## 📚 Related Documentation

### Implementation Guides
- [Adding New Item Types](/docs/guides/adding-new-item-types.md) - Images work automatically for new types

### Related Features
- [Admin Panel](/docs/admin/README.md) - Admin interface overview
- [API Endpoints](/docs/api/endpoints.md) - Complete API reference

### Configuration
- [Environment Variables](/docs/getting-started/local-development.md) - Storage configuration
- [Docker Setup](/docs/operations/ci-cd-setup.md) - MinIO in docker-compose

---

## 🐛 Troubleshooting

### API won't start

**Error:** `Failed to connect to storage bucket 'alacarte-images' at 'minio:9000': connection refused`

**Solution:**
1. Ensure MinIO is running: `docker-compose ps`
2. Check bucket exists: Visit http://localhost:9001
3. Verify environment variables in `.env`

### Image upload fails

**Error:** `Failed to upload to storage`

**Possible causes:**
1. MinIO not running
2. Bucket doesn't exist
3. Bucket permissions incorrect
4. Network connectivity issues

**Debug:**
```bash
# Check MinIO is accessible
curl http://localhost:9000/minio/health/live

# Check bucket exists
mc ls local/alacarte-images
```

### Images not displaying

**Issue:** Placeholder shown instead of image

**Check:**
1. Image URL in database: Query item and check `image_url` field
2. Image accessible: Visit URL directly in browser
3. CORS settings: Check browser console for CORS errors
4. Public endpoint correct: Should be accessible from browser

**Database check:**
```sql
SELECT id, name, image_url FROM wines WHERE id = 1;
```

### Wrong public URL

**Issue:** URLs use internal Docker hostname instead of localhost

**Solution:**
1. Check `STORAGE_PUBLIC_ENDPOINT` in `.env`
2. Should be `localhost:9000` (not `minio:9000`)
3. Restart API after changing
4. Re-upload images (old URLs won't auto-update)

---

## 📝 Code Examples

### Adding Image Support to New Item Type

**Step 1: Update model**
```go
type Beer struct {
    gorm.Model
    Name     string
    ImageURL *string `json:"image_url,omitempty"`
    // ... other fields
}

func (b *Beer) GetImageURL() *string { return b.ImageURL }
func (b *Beer) SetImageURL(url *string) { b.ImageURL = url }
```

**Step 2: Register in item helper**
```go
func GetItemByType(itemType string, itemID string) (ItemWithImage, error) {
    switch itemType {
    case "beer":
        model = &models.Beer{}
    // ... other cases
    }
}

func ValidateItemType(itemType string) bool {
    validTypes := map[string]bool{
        "beer": true,
        // ... other types
    }
}
```

**That's it!** Upload/delete endpoints work automatically.

### Custom Image Processing

If you need different processing for a specific item type:

```go
// In image_validation.go
func processImageCustom(img image.Image, itemType string) (*bytes.Buffer, error) {
    // Different sizes per item type
    maxDimensions := map[string]int{
        "cheese": 1200,
        "gin":    1500,  // Larger for gin bottles
        "wine":   1200,
    }
    
    maxSize := maxDimensions[itemType]
    if maxSize == 0 {
        maxSize = 1200 // Default
    }
    
    processed := imaging.Fit(img, maxSize, maxSize, imaging.Lanczos)
    // ... rest of processing
}
```

---

**Image upload system provides a solid foundation for visual content across the A la carte platform while maintaining security, performance, and scalability.**
