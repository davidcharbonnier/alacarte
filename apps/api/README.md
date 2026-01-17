# À la carte API

Go REST API for the À la carte rating platform.

## 🎯 Purpose of This README

This README provides **quick start instructions and common tasks** for the API. For comprehensive API documentation, see the [API Documentation](/docs/api/README.md).

## Quick Start

```bash
cd apps/api
go mod download
go run main.go
```

**API runs on:** http://localhost:8080

## Key Features

- Google OAuth authentication with JWT tokens
- Polymorphic rating system supporting multiple item types
- Privacy-first architecture with granular sharing controls
- Admin endpoints for item and user management
- Automatic database migrations on startup
- Flexible data seeding system

## Common Tasks

### Adding a New Item Type
See [Adding New Item Types - Backend Section](/docs/guides/adding-new-item-types.md#phase-1-backend-implementation-65-min)

Quick reference: [Backend Checklist](/docs/guides/backend-checklist.md)

### Running Migrations
```bash
# Migrations run automatically on startup
go run main.go
```

### Seeding Data
```bash
RUN_SEEDING=true \
  CHEESE_DATA_SOURCE=../alacarte-seed/cheeses.json \
  GIN_DATA_SOURCE=../alacarte-seed/gins.json \
  go run main.go
```

### Resetting Database (Development)
```bash
go run scripts/reset_database.go
```

### Testing Endpoints
```bash
# Health check
curl http://localhost:8080/api/health

# Get items (requires auth)
curl -H "Authorization: Bearer YOUR_JWT" \
  http://localhost:8080/api/cheese/all
```

## 📚 Documentation Structure

### API Documentation
For complete API documentation:
- **[API Documentation](/docs/api/README.md)** - Primary API reference
- **[API Endpoints Reference](/docs/api/endpoints.md)** - Complete endpoint documentation
- **[Deployment Guide](/docs/api/deployment.md)** - Docker and Cloud Run deployment
- **[Security Best Practices](/docs/api/security.md)** - Security improvements

### Cross-App Features
For features that span multiple applications:
- **[Authentication System](/docs/features/authentication.md)** - OAuth and JWT across all apps
- **[Privacy Model](/docs/features/privacy-model.md)** - Privacy-first architecture
- **[Rating System](/docs/features/rating-system.md)** - Polymorphic rating system

### Implementation Guides
- **[Adding New Item Types](/docs/guides/adding-new-item-types.md)** - Complete platform guide
- **[Backend Checklist](/docs/guides/backend-checklist.md)** - Quick reference checklist

## Technology Stack

- **Language:** Go 1.21+
- **Framework:** Gin (HTTP web framework)
- **Database:** MySQL 8.0+ with GORM ORM
- **Authentication:** Google OAuth 2.0 + JWT
- **Deployment:** Docker + Google Cloud Run

## Project Structure

```
apps/api/
├── controllers/     # HTTP request handlers
├── models/          # Database entities (GORM)
├── middleware/      # Authentication, CORS, etc.
├── utils/           # Database, JWT, helpers
├── scripts/         # Development utilities
├── main.go          # Application entry point
└── .env             # Environment configuration
```

**Note:** API documentation has been moved to `/docs/api/` for centralized documentation management.

## Environment Variables

See `.env.example` for complete list. Key variables:

```bash
# Database
MYSQL_HOST=localhost
MYSQL_DATABASE=alacarte

# Authentication
JWT_SECRET_KEY=your-secret-key
INITIAL_ADMIN_EMAIL=admin@example.com

# Google OAuth
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-client-secret

# Server
GIN_MODE=debug
ALLOWED_ORIGINS=http://localhost:3000
```

## License

Private - All Rights Reserved
