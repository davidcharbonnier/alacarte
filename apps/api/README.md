# A la carte REST API

[![🚀 CI/CD Pipeline](https://github.com/davidcharbonnier/alacarte/actions/workflows/release.yml/badge.svg)](https://github.com/davidcharbonnier/alacarte/actions/workflows/release.yml)
[![🧪 Test Build](https://github.com/davidcharbonnier/alacarte/actions/workflows/test-build.yml/badge.svg)](https://github.com/davidcharbonnier/alacarte/actions/workflows/test-build.yml)
[![Docker Hub](https://img.shields.io/docker/pulls/davidcharbonnier/alacarte-api.svg)](https://hub.docker.com/r/davidcharbonnier/alacarte-api)
[![Docker Image Size](https://img.shields.io/docker/image-size/davidcharbonnier/alacarte-api/latest.svg)](https://hub.docker.com/r/davidcharbonnier/alacarte-api)

**Go REST API for the A la carte rating platform**

A la carte's backend is a Go-based REST API built with Gin framework and GORM ORM, providing secure endpoints for the Flutter frontend application.

## 🎯 Project Overview

The REST API serves as the backend for A la carte, a sophisticated rating platform designed to help users curate and discover their preferences across various categories. The API features:

- **Google OAuth Authentication** - Secure user authentication with JWT tokens
- **Privacy-First Rating System** - Private ratings by default with explicit sharing controls
- **Polymorphic Item Support** - Extensible architecture supporting multiple item types
- **Advanced Sharing System** - Selective rating sharing with user discovery controls
- **Community Statistics** - Anonymous aggregate data for item insights

## 🗺️ Project Roadmap

### **✅ Completed Features**

#### **Database & Schema Management**
- ✅ **Automatic Migrations** - Schema migrations run on application startup
- ✅ **Safe Additive Migrations** - Only adds new tables/columns, never removes data
- ✅ **Flexible Data Seeding** - Remote and local data source support for bootstrap
- ✅ **Production-Safe Seeding** - User-safe seeding that preserves existing ratings
- ✅ **Gin HTTP Framework** - Fast, lightweight REST API with middleware support
- ✅ **GORM Database Layer** - Type-safe ORM with MySQL integration
- ✅ **Health Check Endpoint** - Connectivity monitoring for frontend applications
- ✅ **CORS Configuration** - Cross-origin support for web and mobile clients
- ✅ **Environment Configuration** - Flexible config management for development/production

#### **Data Models**
- ✅ **User Model** - OAuth-based user management with admin role support
- ✅ **Cheese Model** - Complete cheese item with metadata (name, type, origin, producer)
- ✅ **Gin Model** - Complete gin item with metadata (name, producer, origin, profile)
- ✅ **Rating Model** - Polymorphic rating system supporting any item type
- ✅ **Sharing Relationships** - Many-to-many rating viewer permissions

#### **API Endpoints**
- ✅ **Cheese Management** - Full CRUD operations for cheese items
- ✅ **User Management** - Profile creation, editing, and management
- ✅ **Rating System** - Create, edit, delete ratings with sharing capabilities
- ✅ **Rating Queries** - Personal ratings, shared ratings, community ratings
- ✅ **Sharing Operations** - Share/unshare ratings with specific users

#### **Authentication System (Production Ready)**
- ✅ **Google OAuth Integration** - Production Google tokeninfo API validation with complete profile extraction
- ✅ **JWT Token Management** - Secure stateless authentication with automatic refresh
- ✅ **Fail-Fast Validation** - Rejects incomplete profile data with detailed error messages
- ✅ **Profile Completion Workflow** - Display name setup with privacy controls
- ✅ **Authentication Middleware** - Seamless integration with protected API routes
- ✅ **Admin Role System** - Database-backed admin privileges with initial admin bootstrap
- ✅ **Privacy-First Model** - User discovery controls and private-by-default ratings
- ✅ **Clean Architecture** - Production-only OAuth implementation without mock code

#### **Privacy Architecture (Complete)**
- ✅ **Private-by-Default Ratings** - New ratings only visible to author
- ✅ **Selective User Discovery** - Privacy-controlled user visibility for sharing
- ✅ **Display Name Protection** - User identity protection via chosen display names
- ✅ **Enhanced Sharing Controls** - Granular permissions for rating visibility
- ✅ **Complete Profile Filtering** - Only show users who completed setup in sharing dialogs
- ✅ **Privacy Settings API** - Comprehensive privacy management endpoints
- ✅ **Bulk Privacy Operations** - Make all ratings private and remove users from all shares
- ✅ **Privacy Analytics** - User sharing statistics and relationship tracking

#### **Community Statistics (Complete)**
- ✅ **Anonymous Aggregate Data** - Community rating statistics without privacy violations
- ✅ **Efficient Statistics Endpoint** - Single API call for community insights
- ✅ **Real-time Computation** - Live statistics calculated from all user ratings
- ✅ **Privacy-Safe Analytics** - No individual rating exposure in community data

#### **Admin Management System (Complete)**
- ✅ **Role-Based Access Control** - Admin role with database flag and middleware protection
- ✅ **Initial Admin Bootstrap** - Environment-based initial admin configuration
- ✅ **Item Management** - Delete impact assessment, bulk seeding, and cascade deletion
- ✅ **User Administration** - User management with delete impact analysis
- ✅ **Admin Promotion/Demotion** - Manage admin privileges with initial admin protection
- ✅ **Data Validation** - JSON structure validation before bulk imports

### **📋 Future Features**
- 📋 **Rate Limiting** - API abuse prevention and throttling
- 📋 **API Versioning** - Support for multiple API versions
- 📋 **Enhanced Validation** - Comprehensive input validation and sanitization
- 📋 **Audit Logging** - Security event logging and monitoring
- 📋 **Batch Operations** - Bulk data operations for performance

#### **Item Type Expansion**
- 📋 **Wine API** - Wine-specific endpoints with varietal and vintage support
- 📋 **Beer API** - Beer ratings with style, brewery, and ABV fields
- 📋 **Coffee API** - Coffee bean ratings with origin and roast information
- 📋 **Restaurant API** - Restaurant and dish rating capabilities
- 📋 **Generic Item Framework** - Simplified addition of new item types

#### **Advanced Features**
- 📋 **Search API** - Full-text search across items and ratings
- 📋 **Recommendation Engine** - ML-based item recommendations
- 📋 **Real-time Features** - WebSocket support for live updates
- 📋 **Community Features** - Public ratings, leaderboards, trending items
- 📋 **Analytics API** - User insights and preference analytics

#### **Infrastructure & Operations**
- 📋 **Performance Monitoring** - API performance metrics and alerting
- 📋 **Caching Layer** - Redis integration for improved performance
- 📋 **Database Optimization** - Query optimization and indexing strategies
- 📋 **Horizontal Scaling** - Multi-instance deployment support
- 📋 **Backup & Recovery** - Automated database backup and restore

#### **Security & Compliance**
- 📋 **Enhanced Security** - Additional OAuth providers, 2FA support
- 📋 **Data Privacy** - GDPR compliance features and data portability
- 📋 **Security Auditing** - Comprehensive security event logging
- 📋 **Penetration Testing** - Regular security assessments

#### **Developer Experience**
- 📋 **API Documentation** - Interactive OpenAPI/Swagger documentation
- 📋 **SDK Generation** - Auto-generated client SDKs for multiple languages
- 📋 **Development Tools** - Enhanced debugging and profiling capabilities
- 📋 **Testing Framework** - Comprehensive integration and load testing

## 🏗️ Architecture Overview

### **Technical Stack**
- **Language**: Go 1.21+
- **Framework**: Gin (HTTP web framework)
- **Database**: MySQL with GORM ORM
- **Authentication**: Google OAuth 2.0 + JWT tokens
- **Deployment**: Docker-ready with environment configuration

### **Database Design**
```
Users (OAuth-based accounts with admin role)
├── Personal ratings (private by default)
├── Display names (privacy-friendly identity)
├── Discoverable settings (user privacy control)
└── Admin role (IsAdmin flag + initial admin from env)

Ratings (Polymorphic design)
├── Works with any item type (cheese, gin, wine, etc.)
├── Viewer permissions (explicit sharing)
└── Community statistics (anonymous aggregates)

Items (Type-specific models)
├── Cheese (name, type, origin, producer)
├── Gin (name, producer, origin, profile)
├── Future: Wine, Beer, Coffee, etc.
└── Generic RateableItem interface support
```

### **API Architecture**
```
┌─────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION LAYER                     │
│  🔐 Google OAuth (token exchange)                          │
│  🎫 JWT Tokens (stateless auth)                            │
│  🛡️ Middleware (route protection)                          │
└─────────────────────────────────────────────────────────────┘
                               │
┌─────────────────────────────────────────────────────────────┐
│                    CONTROLLER LAYER                         │
│  🌐 HTTP Handlers (request/response)                       │
│  📝 Input Validation (request binding)                     │
│  🔍 Privacy Enforcement (access control)                   │
└─────────────────────────────────────────────────────────────┘
                               │
┌─────────────────────────────────────────────────────────────┐
│                     MODEL LAYER                             │
│  📊 GORM Models (database entities)                        │
│  🔗 Relationships (user ratings, sharing)                  │
│  🏷️ Polymorphic Design (multi-item support)                │
└─────────────────────────────────────────────────────────────┘
                               │
┌─────────────────────────────────────────────────────────────┐
│                    DATABASE LAYER                           │
│  🗄️ MySQL (data persistence)                               │
│  📈 Indexes (performance optimization)                     │
│  🔄 Migrations (schema evolution)                          │
└─────────────────────────────────────────────────────────────┘
```

## 🔐 Security Model

### **Authentication Flow**
1. **Frontend initiates Google OAuth** - User signs in with Google account
2. **Google returns authorization code** - Verified by Google's servers
3. **Backend exchanges code for user info** - Validates with Google API
4. **JWT token generated** - Application-specific authentication token
5. **Protected API access** - All subsequent requests use JWT bearer token

### **Admin Access Control**
- **Initial Admin Bootstrap** - First admin configured via `INITIAL_ADMIN_EMAIL` environment variable
- **Database-Backed Roles** - `is_admin` flag in User model for persistent admin status
- **Dual Authorization** - Admin middleware checks both database flag AND initial admin email
- **Protected Initial Admin** - Initial admin cannot be demoted, ensuring permanent access
- **Promotion/Demotion** - Admins can promote other users to admin or demote them
- **Middleware Protection** - All `/admin/*` routes require `RequireAuth()` + `RequireAdmin()` middleware

### **Privacy Protection**
- **Private by Default** - New ratings only visible to author
- **Explicit Sharing** - Users choose exactly who can see their ratings
- **Display Name System** - Real identity protected via user-chosen names
- **Selective Discovery** - Users control visibility in sharing dialogs
- **Anonymous Community Data** - Aggregate statistics without individual attribution

## 📂 Project Structure

```
rest-api/
├── controllers/          # HTTP request handlers
│   ├── authController.go     # Google OAuth & JWT management
│   ├── userController.go     # User profile & privacy settings
│   ├── cheeseController.go   # Cheese item CRUD operations
│   ├── ginController.go      # Gin item CRUD operations
│   └── ratingController.go   # Rating CRUD & sharing logic
├── models/              # Database entities
│   ├── userModel.go         # User accounts with OAuth fields
│   ├── cheeseModel.go       # Cheese item structure
│   ├── ginModel.go          # Gin item structure
│   └── ratingModel.go       # Polymorphic rating system
├── middleware/          # HTTP middleware
│   ├── auth.go             # JWT validation & user context
│   └── cors.go             # Cross-origin request handling
├── utils/               # Utilities and helpers
│   ├── database.go         # MySQL connection, migrations & seeding
│   ├── jwt.go             # Token generation & validation
│   └── privacy.go         # Privacy query builders
├── scripts/             # Development utility scripts
│   ├── reset_database.go   # Reset database (drops all tables)
│   └── seed.go            # Seed development/production data
├── docs/               # Technical documentation
│   ├── authentication-system.md  # OAuth & JWT implementation
│   └── privacy-model.md          # Privacy architecture
├── .env                # Environment configuration
├── main.go             # Application entry point
└── docker-compose.yaml # Docker deployment configuration

Note: Seed data (cheeses.json, gins.json) hosted in separate alacarte-seed repository
```

## 🚀 API Endpoints

### **Authentication**
```
POST /auth/google              - Exchange Google OAuth tokens for JWT token
```

### **Profile Setup**
```
POST /profile/complete         - Complete user profile setup
GET  /profile/check-display-name - Check display name availability
```

### **User Management**
```
GET  /api/user/me              - Get current user profile
PATCH /api/user/me             - Update user profile (display name, discoverability)
GET  /api/user/sharing-stats   - Get user's sharing statistics
GET  /api/user/export          - Export user data (privacy compliance)
DELETE /api/user/account       - Delete user account and all data
```

### **Item Management (Cheese)**
```
GET    /api/cheese/all         - List all available cheeses
GET    /api/cheese/:id         - Get specific cheese details
POST   /api/cheese/new         - Create new cheese entry
PUT    /api/cheese/:id         - Update cheese information
DELETE /api/cheese/:id         - Delete cheese entry
```

### **Item Management (Gin)**
```
GET    /api/gin/all            - List all available gins
GET    /api/gin/:id            - Get specific gin details
POST   /api/gin/new            - Create new gin entry
PUT    /api/gin/:id            - Update gin information
DELETE /api/gin/:id            - Delete gin entry
```

### **Rating System**
```
POST   /api/rating/new         - Create new rating
GET    /api/rating/author/:id  - Get user's own ratings
GET    /api/rating/viewer/:id  - Get user's reference list (own + shared)
GET    /api/rating/:type/:id   - Get community ratings for item
PUT    /api/rating/:id         - Update existing rating
PUT    /api/rating/:id/share   - Share rating with specific users
PUT    /api/rating/:id/unshare - Remove sharing from specific user
PUT    /api/rating/:id/private - Make rating completely private
DELETE /api/rating/:id         - Delete rating
```

### **Privacy & Discovery**
```
GET  /api/users/shareable      - Get users available for sharing (completed profiles only)
GET  /api/users/search         - Search users by display name (privacy-aware)
GET  /api/stats/community/:type/:id - Get anonymous community statistics
GET  /api/stats/trending       - Get trending items based on sharing activity
```

### **Admin Endpoints (Requires Admin Role)**

#### **Cheese Administration**
```
GET    /admin/cheese/:id/delete-impact - Preview deletion consequences
DELETE /admin/cheese/:id               - Delete cheese with cascade (ratings + sharing)
POST   /admin/cheese/seed               - Bulk import cheeses from JSON URL
POST   /admin/cheese/validate           - Validate JSON structure without importing
```

#### **Gin Administration**
```
GET    /admin/gin/:id/delete-impact - Preview deletion consequences
DELETE /admin/gin/:id               - Delete gin with cascade (ratings + sharing)
POST   /admin/gin/seed               - Bulk import gins from JSON URL
POST   /admin/gin/validate           - Validate JSON structure without importing
```

#### **User Administration**
```
GET    /admin/users/all              - List all users (exposes emails, admin-only)
GET    /admin/user/:id               - Get specific user details
GET    /admin/user/:id/delete-impact - Preview user deletion consequences
DELETE /admin/user/:id               - Delete user with full cascade
PATCH  /admin/user/:id/promote       - Promote user to admin
PATCH  /admin/user/:id/demote        - Demote user from admin (protects initial admin)
```

## 🗄️ Database Schema

### **Core Tables**
```sql
-- User accounts with OAuth integration and admin role
users (
    id, google_id, email, full_name, 
    display_name, avatar, discoverable, is_admin,
    created_at, updated_at, last_login_at
)

-- Polymorphic rating system
ratings (
    id, user_id, item_id, item_type,
    grade, note, created_at, updated_at
)

-- Rating sharing permissions
rating_viewers (
    rating_id, user_id, created_at
)

-- Item-specific tables
cheeses (
    id, name, type, origin, producer, description,
    created_at, updated_at
)

gins (
    id, name, producer, origin, profile, description,
    created_at, updated_at
)

-- Future: wines, beers, etc.
```

### **Privacy Relationships**
```sql
-- Sharing relationship tracking (analytics)
sharing_relationships (
    user_a_id, user_b_id, first_shared_at, 
    last_shared_at, total_shares
)
```

## 🛠️ Development Setup

### **Prerequisites**
- Go 1.21 or higher
- MySQL 8.0 or higher
- Google OAuth credentials (for development)

### **Installation**

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd rest-api
   ```

2. **Install dependencies**
   ```bash
   go mod download
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Setup database and run application**
   ```bash
   # Create MySQL database
   mysql -u root -p
   CREATE DATABASE alacarte;
   
   # Start the application (migrations run automatically)
   go run main.go
   ```

5. **Start the application**
   ```bash
   # Migrations run automatically on startup
   go run main.go
   ```

6. **Seed initial data** (optional)
   ```bash
   # Use standalone script for development
   CHEESE_DATA_SOURCE=https://raw.githubusercontent.com/username/alacarte-seed/main/cheeses.json \
   GIN_DATA_SOURCE=https://raw.githubusercontent.com/username/alacarte-seed/main/gins.json \
   go run scripts/seed.go
   
   # Or use admin panel for production seeding
   # Login to admin panel → Navigate to item type → Seed Data
   ```

### **Environment Configuration**

```bash
# .env file template
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USERNAME=root
MYSQL_PASSWORD=your-mysql-password
MYSQL_DATABASE=alacarte

JWT_SECRET_KEY=your-super-secure-jwt-secret-key-64-characters-minimum

# Admin Access
INITIAL_ADMIN_EMAIL=your-admin-email@gmail.com

# Google OAuth Configuration
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# Server Configuration
GIN_MODE=debug
TRUSTED_PROXIES=127.0.0.1,::1
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

## 🚀 Development Workflow

### **API Testing**
```bash
# Health check
curl http://localhost:8080/health

# Test protected endpoint (requires JWT)
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     http://localhost:8080/api/user/me
```

### **Database Operations**
```bash
# Migrations run automatically on startup
# No manual migration commands needed

# For development: Reset database (drops all tables)
go run scripts/reset_database.go

# Seed development/production data
go run scripts/seed.go

# Bootstrap content during API startup (alternative approach)
RUN_SEEDING=true \
  CHEESE_DATA_SOURCE=../alacarte-seed/cheeses.json \
  GIN_DATA_SOURCE=../alacarte-seed/gins.json \
  go run main.go
```

### **Hot Reload Development**
```bash
# Install air for hot reload
go install github.com/cosmtrek/air@latest

# Run with hot reload
air
```

## 🔧 Integration with Frontend

### **CORS Configuration**
The API is configured to work with Flutter web development:

```go
// Allowed origins for development
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,http://127.0.0.1:3000
```

### **API Response Format**
All endpoints use consistent JSON response format:

```json
// Success response
{
  "data": { ... },
  "message": "Operation successful"
}

// Error response  
{
  "error": "Error description",
  "code": "ERROR_CODE",
  "details": { ... }
}
```

## 🚀 Deployment

### **Docker Deployment**
```bash
# Build and run with Docker Compose
docker-compose up --build

# Production deployment
docker-compose -f docker-compose.prod.yaml up -d
```

### **Environment Variables (Production)**
```env
# Database Configuration
MYSQL_HOST=your-cloud-sql-ip
MYSQL_PORT=3306
MYSQL_USERNAME=alacarte
MYSQL_PASSWORD=your-secure-password
MYSQL_DATABASE=alacarte

# Authentication
JWT_SECRET_KEY=your-production-jwt-secret
INITIAL_ADMIN_EMAIL=admin@yourdomain.com

# Google OAuth Configuration
GOOGLE_CLIENT_ID=your-production-client-id
GOOGLE_CLIENT_SECRET=your-production-client-secret

# Server Configuration
GIN_MODE=release
TRUSTED_PROXIES=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
ALLOWED_ORIGINS=https://yourdomain.com
```

## 🔄 Database Management

### **Automatic Migrations**
The API automatically runs database migrations on startup:
- **Safe Additive Changes** - Only adds new tables/columns, never removes existing data
- **Production Safe** - Existing user data and ratings are preserved
- **No Manual Steps** - Migrations happen automatically when the application starts

### **Data Seeding System**

**Note:** Seed data files (cheeses.json, gins.json) are maintained in the separate `alacarte-seed` repository to keep data management independent from API code.

#### **Seeding Methods**

**Method 1: Admin Panel (Recommended for Production)**
- Web-based UI with validation
- Per-item-type seeding control
- Impact preview before import
- Requires admin authentication

**Method 2: Standalone Script (Development)**
```bash
# Seed from remote URLs
CHEESE_DATA_SOURCE=https://raw.githubusercontent.com/username/alacarte-seed/main/cheeses.json \
GIN_DATA_SOURCE=https://raw.githubusercontent.com/username/alacarte-seed/main/gins.json \
go run scripts/seed.go

# Or seed from local paths
CHEESE_DATA_SOURCE=../alacarte-seed/cheeses.json \
GIN_DATA_SOURCE=../alacarte-seed/gins.json \
go run scripts/seed.go
```

#### **Seeding Architecture**

The seeding system uses a **separation of concerns** architecture:

- **Generic Utilities** (`utils/seeding.go`)
  - `FetchURLData()` - Fetch from URL or local file (works for any item type)
  - `SeedResult` - Standard result format
  - `ValidationResult` - Standard validation format

- **Item-Specific Logic** (in each controller)
  - JSON structure parsing (`{"cheeses": [...]}` vs `{"gins": [...]}`)
  - Natural key definition (e.g., name + origin)
  - Validation rules (item-specific required fields)
  - Database operations

**Benefits:**
- Generic helpers are truly reusable
- Each controller owns its item-specific logic
- Easy to add new item types with different requirements
- No code duplication

#### **Environment Variables**
- `CHEESE_DATA_SOURCE` - URL or file path to cheese data JSON
- `GIN_DATA_SOURCE` - URL or file path to gin data JSON

#### **Seeding Behavior**
- **User-Safe** - Only adds new items, never overwrites existing data
- **Natural Key Matching** - Uses `name + origin` to identify duplicates
- **Error Resilient** - Validation happens before import

#### **Data Source Format**
```json
// Cheese data
{
  "cheeses": [
    {
      "name": "Oka",
      "type": "Pâte pressée cuite",
      "origin": "Oka",
      "producer": "Fromagerie d'Oka",
      "description": "Fromage à pâte ferme..."
    }
  ]
}

// Gin data
{
  "gins": [
    {
      "name": "Ungava",
      "producer": "Les Spiritueux Ungava",
      "origin": "Quebec",
      "profile": "Forestier / boréal",
      "description": "Ungava révèle un style..."
    }
  ]
}
```

### **Development Workflow**

1. **Fresh Development Setup**
   ```bash
   go run scripts/reset_database.go  # Reset database (drops all tables)
   go run main.go                     # Start with auto-migrations
   
   # Seed data via script
   CHEESE_DATA_SOURCE=../alacarte-seed/cheeses.json \
   GIN_DATA_SOURCE=../alacarte-seed/gins.json \
   go run scripts/seed.go
   
   # Or seed via admin panel (login and use web UI)
   ```

2. **Production Deployment**
   ```bash
   # Deploy API
   go run main.go
   
   # Seed data via admin panel (recommended)
   # - Login to admin panel with INITIAL_ADMIN_EMAIL
   # - Navigate to each item type (cheese, gin)
   # - Use "Seed Data" feature with remote URLs
   ```

3. **Adding New Item Types**
   ```go
   // In utils/RunMigrations()
   err := DB.AutoMigrate(
       &models.User{},
       &models.Cheese{},
       &models.Rating{},
       &models.Wine{},    // New item type
   )
   ```

### **Migration Strategy**
- **Forward-Only** - Never drops columns or tables automatically
- **Additive** - New fields and tables are safe to add
- **Backward Compatible** - Old code continues to work after migrations
- **Manual Breaking Changes** - Destructive changes require manual SQL scripts

## 🗺️ Roadmap

### **Current Features**
- ✅ Google OAuth authentication with JWT tokens
- ✅ User profile management with display names
- ✅ Privacy-first rating system
- ✅ Cheese item CRUD operations
- ✅ Rating sharing with selective user discovery
- ✅ Community statistics (anonymous aggregates)
- ✅ Cross-platform CORS support

### **Planned Enhancements**
- [ ] **Additional Item Types** - Wine, beer, coffee API endpoints
- [ ] **Enhanced Privacy Controls** - Bulk privacy operations, audit logs
- [ ] **Performance Optimization** - Database query optimization, caching
- [ ] **Rate Limiting** - API abuse prevention
- [ ] **Monitoring & Logging** - Comprehensive request logging and metrics
- [ ] **API Versioning** - Support for multiple API versions

## 🏛️ Technical Decisions

### **Why Go?**
- **Performance** - Fast execution and low memory footprint
- **Simplicity** - Clean syntax and standard library
- **Concurrency** - Built-in goroutines for handling multiple requests
- **Deployment** - Single binary with no runtime dependencies

### **Why Gin Framework?**
- **Performance** - One of the fastest Go web frameworks
- **Middleware Support** - Easy authentication and CORS handling
- **JSON Handling** - Built-in request/response JSON binding
- **Testing** - Excellent testing support with httptest

### **Why GORM?**
- **Type Safety** - Compile-time SQL query validation
- **Relationship Handling** - Complex joins and associations
- **Migration Support** - Database schema evolution
- **Performance** - Optimized query generation

### **Why JWT Tokens?**
- **Stateless** - No server-side session storage required
- **Scalable** - Tokens contain all necessary user information
- **Cross-Platform** - Works identically across web, mobile, desktop
- **Standard** - Industry-standard authentication approach

## 🤝 Contributing

This backend API is designed for extensibility. Key areas for contribution:

1. **New Item Types** - Adding support for wine, beer, coffee, etc.
2. **Performance** - Query optimization and caching implementations
3. **Security** - Enhanced authentication and authorization features
4. **Monitoring** - Logging, metrics, and health check improvements

## 📄 License

[Choose appropriate license - MIT, Apache 2.0, etc.]

---

**Built with ❤️ using Go & Gin**

*A la carte REST API - Powering your taste preferences*

## 📚 Documentation

### **System Architecture & Implementation**
- **[🔒 Authentication System](docs/authentication-system.md)** - Google OAuth integration and JWT token management
- **[🛡️ Privacy Model](docs/privacy-model.md)** - Privacy-first rating architecture and sharing controls
- **[🐳 Docker Deployment](docs/docker-deployment.md)** - Containerization and deployment guide
- **[🚀 CI/CD Setup](docs/ci-cd-setup.md)** - Automated builds and releases with GitHub Actions
- **[🔒 Security Improvements](docs/security-improvements.md)** - Security enhancements and best practices

### **Development Resources**
- **[📊 Database Schema](#🗄️-database-schema)** - Complete database design and relationships
- **[🚀 API Endpoints](#🚀-api-endpoints)** - Full REST API documentation
- **[🛠️ Development Setup](#🛠️-development-setup)** - Local development guide
- **[🔧 Integration Guide](#🔧-integration-with-frontend)** - Frontend integration patterns
