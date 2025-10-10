# Quick Start Guide

Get A la carte running in 5 minutes.

## Prerequisites

- [Prerequisites installed](prerequisites.md)
- MySQL running (or use Docker Compose)

## 1. Clone Repository

```bash
git clone <repository-url>
cd alacarte
```

## 2. Install Dependencies

```bash
# Monorepo tooling
npm install

# API dependencies
cd apps/api && go mod download && cd ../..

# Client dependencies
cd apps/client && flutter pub get && cd ../..

# Admin dependencies
cd apps/admin && npm install && cd ../..
```

## 3. Configure Environment

```bash
# API configuration
cp apps/api/.env.example apps/api/.env
# Edit apps/api/.env with your MySQL credentials

# Client configuration
cp apps/client/.env.example apps/client/.env
# Edit apps/client/.env with API URL and OAuth client ID

# Admin configuration
cp apps/admin/.env.example apps/admin/.env
# Edit apps/admin/.env with API URL and NextAuth secrets
```

## 4. Start Backend Services

```bash
# Using Docker Compose (recommended)
docker-compose up -d

# Or manually:
cd apps/api
RUN_SEEDING=true go run main.go
```

## 5. Start Client

```bash
cd apps/client
flutter run -d linux  # or -d chrome for web
```

## 6. Start Admin Panel

```bash
cd apps/admin
npm run dev
```

## Access Points

- **API:** http://localhost:8080
- **Client:** http://localhost:3000 (or as shown in Flutter console)
- **Admin:** http://localhost:3001

## Next Steps

- [Local Development Guide](local-development.md) - Complete setup details
- [Architecture Overview](/docs/architecture/overview.md) - Understanding the system
