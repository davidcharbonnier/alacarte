# A la carte API

Go REST API for the A la carte rating platform.

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

## 📚 Full Documentation

Complete API documentation available at [/docs/api/](/docs/api/)

### API-Specific Docs
- [API Endpoints](/docs/api/endpoints.md) - Complete API reference
- [Deployment Guide](/docs/api/deployment.md) - Docker and Cloud Run deployment
- [Security Improvements](/docs/api/security.md) - Security best practices

### Cross-App Features
- [Authentication System](/docs/features/authentication.md) - OAuth and JWT
- [Privacy Model](/docs/features/privacy-model.md) - Privacy architecture
- [Rating System](/docs/features/rating-system.md) - Polymorphic ratings

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
├── docs/            # (moved to /docs/api/)
├── main.go          # Application entry point
└── .env             # Environment configuration
```

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
