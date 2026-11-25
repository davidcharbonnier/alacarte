# Local Development Setup

This guide explains how to run all À la carte applications locally.

## Prerequisites

- Docker & Docker Compose
- Node.js >= 20 (for the admin SPA)
- Go >= 1.25 (optional, if running API outside Docker)
- Flutter SDK >= 3.32 (for client development)

## Quick Start - All Apps

### 1. Start Backend Services (API + Database + MinIO + Admin)

```bash
# From monorepo root
docker-compose up -d
```

This will start:
- **API**: http://localhost:8080
- **Postgres**: localhost:5432
- **MinIO**: http://localhost:9000 (API), http://localhost:9001 (Console)
- **Admin Panel**: http://localhost:3000

### 2. Run Flutter Client

The Flutter client runs outside Docker for development:

```bash
cd apps/client
flutter pub get

# Android (the only target where Google sign-in works today):
flutter run -d android

# UI work without sign-in:
# flutter run -d chrome
# flutter run -d linux
```

Google sign-in currently works only on Android (web and desktop sign-in are a known gap, see [authentication](/docs/client/authentication-system.md)); use an Android emulator or device for anything behind login. On an emulator set `API_BASE_URL=http://10.0.2.2:8080` in `apps/client/.env`. On a physical device use your computer's LAN IP, and see the cleartext note in [android-setup.md](/docs/client/setup/android-setup.md).

## Individual App Development

### API Only

```bash
# Start API, Postgres, and MinIO
docker-compose up api postgres minio create-bucket

# Or run without Docker (needs postgres + minio running, e.g. `docker-compose up -d postgres minio create-bucket`):
cd apps/api
cp .env.example .env   # set DATABASE_URL and STORAGE_ENDPOINT hosts to localhost
go mod download
air  # hot-reload development server (requires the `air` tool installed; `go run main.go` also works)
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
flutter run -d android  # sign-in works on Android only
```

## Environment Variables

Each app has its own environment configuration:

- **API**: Copy `apps/api/.env.example` to `apps/api/.env`
- **Admin**: Copy `apps/admin/.env.example` to `apps/admin/.env` (Docker) or `.env.local` (bare Vite)
- **Client**: Create `apps/client/.env` with API URL and OAuth configuration

Make sure these are configured before running.

## Networking

The API, Postgres and MinIO share the `alacarte-network` bridge network (the admin container is only on `default`). The admin SPA and the client call the API from the browser/device through the published port (`http://localhost:8080`), not through container networking. Postgres and MinIO ports are published for direct debugging.

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
- Postgres: Change `5432:5432`
- Admin: Change `3000:3000`
- MinIO: Change `9000:9000` and `9001:9001`

### Admin Can't Connect to API

1. Verify API is running: `curl http://localhost:8080/health`
2. Check admin `.env` has `VITE_API_URL=http://localhost:8080` (the browser calls the API, so it cannot use the Docker name `api`; rebuild/restart after changing)

### Postgres Connection Issues

```bash
# Check Postgres is ready
docker-compose logs postgres

# Connect directly to debug
docker-compose exec postgres psql -U rest_api -d rest_api
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

Default schemas (cheese, gin, wine, coffee, chili-sauce) are seeded at API startup when `RUN_SEEDING=true` is set (already true in `apps/api/.env.example`). Item data can be bulk-imported via the admin endpoint `POST /admin/items/:type/seed` (JSON URL payload — see [API endpoints](../api/endpoints.md)).

Note: the standalone scripts in `apps/api/scripts/` (including `seed.go`) are currently broken — they call an undefined `utils.MySQLConnect` and do not compile.

## Logs

```bash
# View logs for all services
docker-compose logs -f

# View logs for specific service
docker-compose logs -f api
docker-compose logs -f admin
docker-compose logs -f postgres
docker-compose logs -f minio
```

## Clean Start

```bash
# Remove all containers, volumes, and start fresh
docker-compose down -v
docker-compose up --build
```
