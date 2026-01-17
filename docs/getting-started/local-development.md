# Local Development Setup

This guide explains how to run all À la carte applications locally.

## Prerequisites

- Docker & Docker Compose
- Node.js >= 18.0.0 (for tooling)
- Go >= 1.21 (optional, if running API outside Docker)
- Flutter SDK >= 3.27 (for client development)

## Quick Start - All Apps

### 1. Start Backend Services (API + Database + MinIO + Admin)

```bash
# From monorepo root
docker-compose up -d
```

This will start:
- **API**: http://localhost:8080
- **MySQL**: localhost:3306
- **MinIO**: http://localhost:9000 (API), http://localhost:9001 (Console)
- **Admin Panel**: http://localhost:3000

### 2. Run Flutter Client

The Flutter client runs outside Docker for development:

```bash
cd apps/client
flutter pub get

# For web development:
flutter run -d chrome

# For desktop (Linux):
# flutter run -d linux

# For mobile:
# flutter run -d android
# flutter run -d ios
```

## Individual App Development

### API Only

```bash
# Start API, MySQL, and MinIO
docker-compose up api mysql minio create-bucket

# Or run without Docker:
cd apps/api
go mod download
air  # hot-reload development server
```

### Admin Panel Only

```bash
# Start admin (requires API to be running)
docker-compose up admin

# Or run without Docker:
cd apps/admin
npm install
npm run dev
```

### Client Only

```bash
cd apps/client
flutter pub get
flutter run -d chrome  # or your preferred device
```

## Environment Variables

Each app has its own environment configuration:

- **API**: Copy `apps/api/.env.prod.template` to `apps/api/.env`
- **Admin**: Copy `apps/admin/.env.example` to `apps/admin/.env.local`
- **Client**: Create `apps/client/.env` with API URL and OAuth configuration

Make sure these are configured before running.

## Networking

All services share the `alacarte-network` bridge network, allowing:
- Admin → API communication
- Client → API communication
- Direct MySQL access for debugging
- MinIO file storage access

## Stopping Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (clean database)
docker-compose down -v
```

## Troubleshooting

### Port Conflicts

If ports are already in use, modify `docker-compose.yml`:
- API: Change `8080:8080`
- MySQL: Change `3306:3306`
- Admin: Change `3000:3000`
- MinIO: Change `9000:9000` and `9001:9001`

### Admin Can't Connect to API

1. Verify API is running: `curl http://localhost:8080/health`
2. Check admin `.env.local` has correct API URL (should be `http://api:8080` for Docker networking)
3. Ensure both services are on `alacarte-network`

### MySQL Connection Issues

```bash
# Check MySQL is ready
docker-compose logs mysql

# Connect directly to debug
docker-compose exec mysql mysql -u root -ppassword
```

### Client Can't Connect to API

1. Update `apps/client/.env` with correct API URL
2. For Android emulator, use `10.0.2.2:8080` instead of `localhost:8080`
3. For iOS simulator, use `localhost:8080`
4. For web, use `http://localhost:8080`

### MinIO File Storage

- Console: http://localhost:9001
- Default credentials: minioadmin/minioadmin
- Bucket creation is automated via the `create-bucket` service

## Database Seeding

```bash
# Seed the database with initial data
docker-compose exec api go run scripts/seed.go
```

## Logs

```bash
# View logs for all services
docker-compose logs -f

# View logs for specific service
docker-compose logs -f api
docker-compose logs -f admin
docker-compose logs -f mysql
docker-compose logs -f minio
```

## Clean Start

```bash
# Remove all containers, volumes, and start fresh
docker-compose down -v
docker-compose up --build
```
