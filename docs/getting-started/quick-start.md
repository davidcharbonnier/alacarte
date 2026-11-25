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
cp apps/api/.env.example apps/api/.env

# Edit apps/api/.env with your configuration:
# - Database credentials
# - JWT secret
# - GOOGLE_CLIENT_ID (Google OAuth)
# - STORAGE_PUBLIC_ENDPOINT: set it to localhost:9000 (host only, no scheme); the example file's http://localhost:9000 would give image URLs like http://http://localhost:9000/...
# - INITIAL_ADMIN_EMAIL (your Google account; without it the first admin login lands on /access-denied)
# - ALLOWED_ORIGINS (the example value is a placeholder and replaces the localhost default;
#   use e.g. http://localhost:3000 for the admin (plus any other browser origin that calls the API), or the browser blocks requests with a CORS error)
```

### Admin Configuration
```bash
# Copy the example file (Docker Compose reads apps/admin/.env)
cp apps/admin/.env.example apps/admin/.env

# Edit apps/admin/.env with your configuration:
# - VITE_API_URL (http://localhost:8080)
# - VITE_GOOGLE_CLIENT_ID (Google OAuth Web Client ID)

```

### Client Configuration
```bash
# Create .env file in apps/client/
# The client may not have a .env.example file, so create from scratch:
# - API_BASE_URL=http://localhost:8080
# - GOOGLE_CLIENT_ID=your_google_client_id
# - APP_VERSION=1.0.0-dev   (required: the app throws when the Settings screen opens without it)
```

## 3. Start Backend Services

```bash
# Start all services using Docker Compose
docker-compose up -d

# This will start:
# - API on port 8080
# - Postgres on port 5432 (connection string in DATABASE_URL)
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
# Android (the only target where Google sign-in works today):
flutter run -d android

# UI work without sign-in:
# flutter run -d chrome
# flutter run -d linux
```

Google sign-in currently works only on Android (web and desktop sign-in are a known gap, see [authentication](/docs/client/authentication-system.md)); use an Android emulator or device for anything behind login. On an emulator set `API_BASE_URL=http://10.0.2.2:8080` in `apps/client/.env`. On a physical device use your computer's LAN IP, and see the cleartext note in [android-setup.md](/docs/client/setup/android-setup.md).

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
- **Client Web:** http://localhost:<port> (Flutter web picks an ephemeral port unless you pass `--web-port`)
- **MinIO Console:** http://localhost:9001 (for file storage management)
- **Postgres:** localhost:5432 (connection string: see `apps/api/.env.example`)

## Next Steps

- [Local Development Guide](local-development.md) - Complete setup details
- [Monorepo Strategy](/docs/architecture/monorepo-strategy.md) - Repository structure and versioning
