# API Documentation

Complete REST API documentation for the À la carte platform.

## 🎯 Purpose of This Documentation

This documentation serves as the **primary reference for API developers** working with the À la carte backend. For cross-app feature documentation, see the [Features documentation](/docs/features/).

## 📚 Documentation Structure

### Quick Start & Reference
- **[API Quick Start](/apps/api/README.md)** - Getting started with the API
- **[API Endpoints Reference](endpoints.md)** - Complete endpoint documentation

### Deployment & Operations
- **[Deployment Guide](deployment.md)** - Docker and Cloud Run deployment
- **[Security Best Practices](security.md)** - Security improvements and guidelines

### Implementation Guides
- **[Adding New Item Types](/docs/guides/adding-new-item-types.md#phase-1-backend-implementation-65-min)** - Backend implementation guide
- **[Backend Checklist](/docs/guides/backend-checklist.md)** - Quick reference checklist

## 🔗 Related Documentation

### Cross-App Features
For feature documentation that spans multiple applications (API, Client, Admin):
- **[Authentication System](/docs/features/authentication.md)** - OAuth and JWT across all apps
- **[Privacy Model](/docs/features/privacy-model.md)** - Privacy-first architecture
- **[Rating System](/docs/features/rating-system.md)** - Polymorphic rating system

### App-Specific Documentation
- **[API Implementation Details](/apps/api/README.md)** - Detailed API setup and usage
- **[Client Documentation](/docs/client/)** - Flutter client documentation
- **[Admin Documentation](/docs/admin/)** - Next.js admin panel documentation

## 🚀 Quick Links

**Common Tasks:**
- [Running migrations](/apps/api/README.md#running-migrations) - Automatic on startup
- [Seeding data](/apps/api/README.md#seeding-data) - Development data setup
- [Testing endpoints](/apps/api/README.md#testing-endpoints) - API testing examples
- [Deployment](deployment.md) - Production deployment guide

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
