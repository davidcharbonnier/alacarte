# À la carte - Monorepo

Multi-platform rating and sharing system for consumables (cheese, gin, wine, beer, coffee, etc.)

## 📦 Project Structure

```
alacarte/
├── apps/
│   ├── api/          # Go REST API (GORM + MySQL)
│   ├── client/       # Flutter mobile/web app
│   └── admin/        # Next.js admin panel
├── docs/             # Consolidated documentation
└── .github/
    └── workflows/    # CI/CD pipelines
```

## 🚀 Quick Start

### Prerequisites
- Node.js >= 18.0.0
- Go >= 1.21
- Flutter SDK >= 3.27
- Docker & Docker Compose

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd alacarte

# Install monorepo tooling (includes commit hooks)
npm install

# Install dependencies for all apps
cd apps/api && go mod download
cd apps/client && flutter pub get
cd apps/admin && npm install
```

### Development

```bash
# Start backend services (API + MySQL + MinIO + Admin)
docker-compose up -d

# Run Flutter client (separate terminal)
cd apps/client && flutter run -d chrome
```

See [Getting Started Guide](./docs/getting-started/) for detailed setup instructions.

## 🔄 Versioning & Releases

This monorepo uses **[semantic-release](https://semantic-release.gitbook.io/)** with **[Conventional Commits](https://www.conventionalcommits.org/)** for fully automated releases.

### Making Commits

All commits must follow the conventional format:

```bash
<type>(<scope>): <subject>

# Examples:
git commit -m "feat(api): Add wine filtering endpoint"
git commit -m "fix(client): Resolve cache invalidation"
git commit -m "docs(admin): Update deployment guide"
```

**Valid types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`  
**Valid scopes:** `api`, `client`, `admin`, `deps`, `ci`, `docs`, `release`

Commits are automatically validated via git hooks powered by commitlint.

### Release Process

Releases are **fully automated**:

1. **Make conventional commits** and merge to `master`
2. **semantic-release runs automatically** on master push
   - Analyzes commits since last release
   - Determines version bumps
   - Updates CHANGELOG.md files
3. **Git tags are created** automatically
4. **Builds & releases** are triggered by tags

**Version bumps:**
- `feat:` → minor bump (0.3.1 → 0.4.0)
- `fix:` → patch bump (0.3.1 → 0.3.2)
- `BREAKING CHANGE:` → major bump (0.3.1 → 1.0.0)
- `docs:`, `chore:`, etc → no version bump

Each app (api, client, admin) is versioned independently with tags:
- `api-v1.2.3` - API releases
- `client-v1.2.3` - Client releases
- `admin-v1.2.3` - Admin releases

See [CI/CD Setup Guide](./docs/operations/ci-cd-setup.md) for complete details.

## 🎭 Prerelease (Snapshot) Versions

Every PR commit generates snapshot versions for manual QA:

```
Format: pr-{number}.{increment}
Example: pr-123.5
```

Docker images are published automatically to GHCR:
- `ghcr.io/{owner}/alacarte-api:pr-123.5`
- `ghcr.io/{owner}/alacarte-client:pr-123.5`
- `ghcr.io/{owner}/alacarte-admin:pr-123.5`

**Note:** Documentation-only changes (.md files) are excluded from builds.

## 🏗️ Technology Stack

- **API:** Go + Gin + GORM + MySQL
- **Client:** Flutter + Riverpod
- **Admin:** Next.js + TypeScript
- **Infrastructure:** Google Cloud Run + Cloud SQL
- **CI/CD:** GitHub Actions + GHCR (GitHub Container Registry)
- **Release Automation:** semantic-release + Conventional Commits

## 🧩 Dynamic Schema System

À la carte uses a **dynamic schema system** that allows administrators to define new consumable types through the admin panel without code changes.

### Key Features

- **Schema Management UI** - Create, edit, and manage item type schemas in the admin panel
- **Dynamic API Endpoints** - `/api/items/:type` automatically adapts to any active schema
- **Client Discovery** - Flutter client fetches schemas at startup and renders forms dynamically
- **Validation Engine** - Server-side validation based on schema-defined rules
- **Hybrid Storage** - JSON column for fast reads + EAV pattern for efficient filtering
- **Schema Versioning** - Immutable versions preserve data integrity as schemas evolve

### Adding a New Item Type

```bash
# No code changes needed! Just use the admin panel:
# 1. Go to /admin/schemas
# 2. Click "New Schema"
# 3. Define fields, validation, and display hints
# 4. Save - the new type is immediately available in API and client
```

See [Schema Management Guide](/docs/admin/schema-management.md) for detailed instructions.

### Supported Field Types

- `text` - Single-line text
- `textarea` - Multi-line text
- `number` - Numeric values with min/max validation
- `select` - Dropdown with predefined options
- `checkbox` - Boolean toggles
- `enum` - Categorized selections

### Migration from Legacy System

Existing deployments with hardcoded item types can migrate to the dynamic schema system:

```bash
cd apps/api
go run scripts/migrate_to_dynamic.go
```

See [Migration Process Guide](/docs/guides/migration-process.md) for complete instructions.

## 📚 Documentation

- [CI/CD Setup Guide](./docs/operations/ci-cd-setup.md) ⭐ **UPDATED!**
- [Local Development Guide](./docs/getting-started/local-development.md)
- [API Documentation](./docs/api/README.md)
- [Client Documentation](./docs/client/README.md)
- [Admin Documentation](./docs/admin/README.md)
- [Schema Management Guide](./docs/admin/schema-management.md) - Admin UI for managing item types
- [Adding New Item Types](./docs/guides/adding-new-item-types.md) - Dynamic schema guide
- [Migration Process](./docs/guides/migration-process.md) - Migrate from legacy to dynamic schemas

## 🔧 Monorepo Tools

- **semantic-release:** Automated versioning and changelogs
- **commitlint:** Enforces conventional commit format
- **husky:** Git hooks for commit validation
- **Docker Compose:** Local development orchestration
- **GitHub Actions:** CI/CD with automated releases

## 🤝 Contributing

**Quick workflow:**
1. Create a feature branch
2. Make changes with **conventional commits** (format enforced automatically)
3. Push and open PR
4. Snapshot versions are automatically published
5. After merge, semantic-release handles versioning automatically
6. Git tags trigger production builds

**Important:**
- Commit messages must follow conventional format (enforced by git hooks)
- Choose correct scope: `api`, `client`, `admin`, etc.
- Use correct type: `feat` for features, `fix` for bugs, etc.
- See [CI/CD Setup Guide](./docs/operations/ci-cd-setup.md) for details

## 📄 License

Private - All Rights Reserved
