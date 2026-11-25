# À la carte - Monorepo

Multi-platform rating and sharing system for consumables (cheese, gin, wine, beer, coffee, etc.)

## 📦 Project Structure

```
alacarte/
├── apps/
│   ├── api/          # Go REST API (Gin + GORM + Postgres)
│   ├── client/       # Flutter cross-platform app
│   └── admin/        # Vite + React admin SPA
├── docs/             # Consolidated documentation
└── .github/
    └── workflows/    # CI/CD pipelines
```

## 🚀 Quick Start

### Prerequisites
- Node.js >= 20
- Go >= 1.25
- Flutter SDK >= 3.32
- Docker & Docker Compose

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd alacarte

# Install dependencies for all apps
(cd apps/api && go mod download)
(cd apps/client && flutter pub get)
(cd apps/admin && npm install)
```

### Development

```bash
# Start backend services (API + Postgres + MinIO + Admin)
docker-compose up -d

# Run Flutter client (separate terminal)
cd apps/client && flutter run -d android   # Google sign-in works on Android only (see apps/client/README.md)
```

See [Getting Started Guide](./docs/getting-started/) for detailed setup instructions.

## 🔄 Versioning & Releases

This monorepo uses **[semantic-release](https://semantic-release.gitbook.io/)** with **[Conventional Commits](https://www.conventionalcommits.org/)** for releases intended to be fully automated (see the known caveats in the [CI/CD Setup Guide](./docs/operations/ci-cd-setup.md)).

### Making Commits

All commits must follow the conventional format:

```bash
<type>(<scope>): <subject>

# Examples:
git commit -m "feat(api): add wine filtering endpoint"
git commit -m "fix(client): resolve cache invalidation"
git commit -m "docs(admin): update deployment guide"
```

**Valid types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`  
**Valid scopes:** `api`, `client`, `admin`, `deps`, `ci`, `docs`, `release`

The rules live in `commitlint.config.js` and are checked by `.husky/commit-msg`, but **hooks are not installed automatically** (there is no root `package.json`) and **CI does not check commit messages**. To check locally, run `git config core.hooksPath .husky` (the hook file is committed as executable) and make `commitlint` + `@commitlint/config-conventional` available to `npx`. Always use a scope (commitlint requires one).

### Release Process

Releases are **meant to be automated** (see the known caveats in the [CI/CD Setup Guide](./docs/operations/ci-cd-setup.md)):

1. **Make conventional commits** and merge to `master`
2. **semantic-release runs on master push** (see the known caveats in the [CI/CD Setup Guide](./docs/operations/ci-cd-setup.md))
   - Analyzes commits since last release
   - Determines version bumps
   - Updates CHANGELOG.md files
3. **Git tags are created** by semantic-release (api and client only)
4. **Builds & releases** run from `release.yml` (dispatched by `version.yml`, or by pushing a tag)

**Version bumps:**
- `feat:` → minor bump (0.3.1 → 0.4.0)
- `fix:` → patch bump (0.3.1 → 0.3.2)
- `BREAKING CHANGE:` → major bump (0.3.1 → 1.0.0)
- `docs`, `chore`, `test`, `build`, `ci`, `refactor` → **patch** bump when the scope is `api` or `client` (per `.releaserc`); with another scope these types do not release, and `style` never does. But `feat`, `fix`, `perf` and breaking changes release **both api and client whatever the scope** (commits that match none of the `.releaserc` rules fall back to the default rules of `@semantic-release/commit-analyzer`)

Each app (api, client, admin) is versioned independently with tags:
- `api-v1.2.3` - API releases
- `client-v1.2.3` - Client releases
- `admin-v1.2.3` - Admin releases (pushed manually; only api and client go through semantic-release)

See [CI/CD Setup Guide](./docs/operations/ci-cd-setup.md) for complete details.

## 🎭 Prerelease (Snapshot) Versions

Every PR commit generates snapshot versions for manual QA:

```
Format: pr-{number}.{increment}
Example: pr-123.5
```

The API Docker image is published automatically to GHCR:
- `ghcr.io/{owner}/alacarte-api:pr-123.5`

The client APK and admin `dist/` are uploaded as GitHub Actions artifacts (`alacarte-client-pr-123.5`, `admin-dist-pr-123.5`).

**Note:** Documentation-only changes (.md files) are excluded from builds.

## 🏗️ Technology Stack

- **API:** Go + Gin + GORM + Postgres
- **Client:** Flutter + Riverpod
- **Admin:** Vite + React 19 + TypeScript
- **Infrastructure:** Google Cloud Run + Neon Postgres
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
# 1. Go to /schemas in the admin SPA
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

Hardcoded item types were migrated to the dynamic schema system once, in production. The migration scripts no longer build (they still reference MySQL). See the [Migration Process Guide](/docs/guides/migration-process.md) for the historical procedure.

## 📚 Documentation

- [CI/CD Setup Guide](./docs/operations/ci-cd-setup.md)
- [Local Development Guide](./docs/getting-started/local-development.md)
- [API Documentation](./docs/api/README.md)
- [Client Documentation](./docs/client/README.md)
- [Admin Documentation](./docs/admin/README.md)
- [Schema Management Guide](./docs/admin/schema-management.md) - Admin UI for managing item types
- [Adding New Item Types](./docs/guides/adding-new-item-types.md) - Dynamic schema guide
- [Migration Process](./docs/guides/migration-process.md) - Historical: legacy to dynamic schemas (MySQL era)

## 🔧 Monorepo Tools

- **semantic-release:** Automated versioning and changelogs
- **commitlint:** Conventional commit rules (`commitlint.config.js`; opt-in local hook, not run in CI)
- **Docker Compose:** Local development orchestration
- **GitHub Actions:** CI/CD (release automation has known caveats; see the CI/CD Setup Guide)

## 🤝 Contributing

**Quick workflow:**
1. Create a feature branch
2. Make changes with **conventional commits** (format rules in `commitlint.config.js`; hook is opt-in)
3. Push and open PR
4. Snapshot versions are published by `pr-snapshot.yml`
5. After merge, semantic-release is meant to handle versioning (see the [CI/CD Setup Guide](./docs/operations/ci-cd-setup.md) caveats)
6. `version.yml` dispatches the production build (admin: push an `admin-v*` tag)

**Important:**
- Commit messages must follow conventional format (opt-in local hook; not checked in CI)
- Choose correct scope: `api`, `client`, `admin`, etc.
- Use correct type: `feat` for features, `fix` for bugs, etc.
- See [CI/CD Setup Guide](./docs/operations/ci-cd-setup.md) for details

## 📄 License

Private - All Rights Reserved
