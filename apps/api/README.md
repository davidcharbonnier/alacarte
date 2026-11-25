# À la carte API

Go REST API for the À la carte rating platform.

## 🎯 Purpose of This README

This README provides **quick start instructions and common tasks** for the API. For comprehensive API documentation, see the [API Documentation](/docs/api/README.md).

## Quick Start

```bash
cd apps/api
cp .env.example .env   # then set DATABASE_URL and STORAGE_ENDPOINT hosts to localhost
(cd ../.. && docker-compose up -d postgres minio create-bucket)   # compose file is at the repo root
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
See [Adding New Item Types - Backend Section](/docs/guides/adding-new-item-types.md#step-1-plan-your-schema)


### Running Migrations
```bash
# Migrations run automatically on startup
go run main.go
```

### Seeding Data
```bash
RUN_SEEDING=true go run main.go
```

### Testing Endpoints
```bash
# Health check
curl http://localhost:8080/health

# Get items (requires auth)
curl -H "Authorization: Bearer YOUR_JWT" \
  http://localhost:8080/api/items/<type>
```

## 📚 Documentation Structure

### API Documentation
For complete API documentation:
- **[API Documentation](/docs/api/README.md)** - Primary API reference
- **[API Endpoints Reference](/docs/api/endpoints.md)** - Complete endpoint documentation
- **[Security Best Practices](/docs/api/security.md)** - Security improvements

### Cross-App Features
For features that span multiple applications:
- **[Authentication System](/docs/features/authentication.md)** - OAuth and JWT across all apps
- **[Privacy Model](/docs/features/privacy-model.md)** - Privacy-first architecture
- **[Rating System](/docs/features/rating-system.md)** - Polymorphic rating system

### Implementation Guides
- **[Adding New Item Types](/docs/guides/adding-new-item-types.md)** - Complete platform guide

## Technology Stack

- **Language:** Go 1.25+
- **Framework:** Gin (HTTP web framework)
- **Database:** Postgres 16+ with GORM ORM
- **Authentication:** Google OAuth 2.0 + JWT
- **Deployment:** Docker + Google Cloud Run

## Project Structure

```
apps/api/
├── controllers/     # HTTP request handlers
├── models/          # Database entities (GORM)
├── services/        # Business logic (schema registry, validation)
├── internal/        # Internal packages (cleanup migration)
├── utils/           # Database, JWT, auth middleware, helpers
├── scripts/         # Development utilities
├── main.go          # Application entry point
└── .env             # Environment configuration
```

**Note:** API documentation has been moved to `/docs/api/` for centralized documentation management.

## Environment Variables

See `.env.example` for complete list. Key variables:

```bash
# Database
DATABASE_URL=postgres://user:password@localhost:5432/alacarte?sslmode=disable

# Authentication
JWT_SECRET_KEY=your-secret-key
INITIAL_ADMIN_EMAIL=admin@example.com

# Google OAuth
GOOGLE_CLIENT_ID=your-client-id

# Server
GIN_MODE=debug
ALLOWED_ORIGINS=http://localhost:3000
```

## License

Private - All Rights Reserved
