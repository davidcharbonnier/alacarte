# Quick Start Guide

Get À la carte running in 5 minutes.

## Prerequisites

- [Prerequisites installed](prerequisites.md)
- Docker & Docker Compose installed and running

## 1. Clone Repository

```bash
git clone <repository-url>
cd alacarte
```

## 2. Configure Environment

### API Configuration
```bash
# Copy the production template to .env
cp apps/api/.env.prod.template apps/api/.env

# Edit apps/api/.env with your configuration:
# - Database credentials
# - JWT secret
# - Google OAuth credentials
```

### Admin Configuration
```bash
# Copy the example file to .env.local
cp apps/admin/.env.example apps/admin/.env.local

# Edit apps/admin/.env.local with your configuration:
# - API_URL (http://localhost:8080)
# - NEXT_PUBLIC_API_URL (http://localhost:8080)
# - Google OAuth credentials
# - NextAuth configuration
```

### Client Configuration
```bash
# Create .env file in apps/client/
# The client may not have a .env.example file, so create from scratch:
# - API_BASE_URL=http://localhost:8080
# - GOOGLE_CLIENT_ID=your_google_client_id
```

## 3. Start Backend Services

```bash
# Start all services using Docker Compose
docker-compose up -d

# This will start:
# - API on port 8080
# - MySQL on port 3306
# - MinIO on ports 9000/9001
# - Admin panel on port 3000
```

## 4. Start Client Application

```bash
# Navigate to client directory
cd apps/client

# Install dependencies
flutter pub get

# Run the application
# For web:
flutter run -d chrome

# For desktop (Linux):
# flutter run -d linux

# For mobile:
# flutter run -d android
# flutter run -d ios
```

## 5. Verify Services

Check that all services are running:

```bash
# Check Docker containers
docker-compose ps

# Check API health
curl http://localhost:8080/health

# Check Admin panel
curl -I http://localhost:3000
```

## Access Points

- **API:** http://localhost:8080
- **Admin Panel:** http://localhost:3000
- **Client Web:** http://localhost:3001 (when running Flutter web)
- **MinIO Console:** http://localhost:9001 (for file storage management)
- **MySQL:** localhost:3306 (username: root, password: password)

## Next Steps

- [Local Development Guide](local-development.md) - Complete setup details
- [Architecture Overview](/docs/architecture/overview.md) - Understanding the system
