# API Documentation

Complete REST API documentation for the À la carte platform.

## 📚 Documentation Index

### Core Documentation
- [API Overview](../api/README.md) - Quick start and common tasks (see apps/api/)
- [API Endpoints](endpoints.md) - Complete API reference
- [Deployment Guide](deployment.md) - Docker and Cloud Run deployment
- [Security Best Practices](security.md) - Security improvements and guidelines

### Implementation Details
- [Authentication System](authentication-system.md) - OAuth and JWT implementation
- [Privacy Model](privacy-model.md) - Privacy architecture and queries

### Cross-App Features
- [Authentication](/docs/features/authentication.md) - Overview across all apps
- [Privacy Model](/docs/features/privacy-model.md) - Privacy-first architecture
- [Rating System](/docs/features/rating-system.md) - Polymorphic rating system

### Guides
- [Adding New Item Types](/docs/guides/adding-new-item-types.md#phase-1-backend-implementation-65-min) - Backend section
- [Backend Checklist](/docs/guides/backend-checklist.md) - Quick reference

## 🚀 Quick Links

**Common Tasks:**
- [Running migrations](#) - Automatic on startup
- [Seeding data](#) - See API README
- [Testing endpoints](#) - See API README
- [Deployment](#) - See deployment.md

**API Reference:**
- [Authentication endpoints](endpoints.md#authentication)
- [User management](endpoints.md#user-management)
- [Item endpoints](endpoints.md#items)
- [Rating endpoints](endpoints.md#ratings)
- [Admin endpoints](endpoints.md#admin)

## 📦 Technology Stack

- **Language:** Go 1.21+
- **Framework:** Gin
- **Database:** MySQL 8.0+ with GORM
- **Authentication:** Google OAuth + JWT
- **Deployment:** Docker + Google Cloud Run
