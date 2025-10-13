# A la carte - Monorepo

Multi-platform rating and sharing system for consumables (cheese, gin, wine, beer, coffee, etc.)

## 📦 Project Structure

```
alacarte/
├── apps/
│   ├── api/          # Go REST API (GORM + MySQL)
│   ├── client/       # Flutter mobile/web app
│   └── admin/        # Next.js admin panel
├── docs/             # Consolidated documentation
├── .github/
│   └── workflows/    # CI/CD pipelines
└── .changeset/       # Version management
```

## 🚀 Quick Start

### Prerequisites
- Node.js >= 18.0.0
- Go >= 1.21
- Flutter SDK >= 3.16
- Docker & Docker Compose

### Installation

```bash
# Install monorepo tooling
npm install

# Install dependencies for all apps
cd apps/api && go mod download
cd apps/client && flutter pub get
cd apps/admin && npm install
```

### Development

```bash
# Run backend services (API + MySQL + Admin)
docker-compose up

# Run Flutter client (separate terminal)
cd apps/client && flutter run
```

See [Local Development Guide](./docs/local-development.md) for detailed setup instructions.

## 🔄 Versioning & Releases

This monorepo uses [Changesets](https://github.com/changesets/changesets) for version management.

### Creating a Changeset

```bash
npm run changeset
```

Follow the prompts:
1. Select which apps changed (api, client, admin)
2. Select change type (major, minor, patch)
3. Write a summary of changes

### Release Process

Releases are automated via GitHub Actions:
1. Merge PR to `master`
2. Changesets bot creates a "Version Packages" PR
3. Merge the version PR to trigger release

## 🎭 Prerelease (Snapshot) Versions

Every PR commit generates snapshot versions for manual QA:

```
Format: v2.1.0-pr-123.abc1234
```

Docker images are published automatically:
- `davidcharbonnier/alacarte-api:2.1.0-pr-123.abc1234`
- `davidcharbonnier/alacarte-client:2.1.0-pr-123.abc1234`
- `davidcharbonnier/alacarte-admin:2.1.0-pr-123.abc1234`

## 🏗️ Technology Stack

- **API:** Go + Gin + GORM + MySQL
- **Client:** Flutter + Riverpod
- **Admin:** Next.js + TypeScript
- **Infrastructure:** Google Cloud Run + Cloud SQL
- **CI/CD:** GitHub Actions + Docker Hub

## 📚 Documentation

- [Local Development Guide](./docs/local-development.md) ⭐
- [API Documentation](./apps/api/README.md)
- [Client Documentation](./apps/client/README.md)
- [Admin Documentation](./apps/admin/README.md)

## 🔧 Monorepo Tools

- **Changesets:** Version management and changelogs
- **Docker Compose:** Local development orchestration
- **GitHub Actions:** CI/CD with change detection

## 📋 Available Scripts

```bash
npm run changeset      # Create a changeset
npm run version        # Bump versions (automated)
npm run release        # Publish releases (automated)
```

## 🤝 Contributing

**See [Contributing Guide](./docs/guides/contributing.md) for detailed guidelines!**

Quick workflow:
1. Create a feature branch
2. Make changes
3. **Create a changeset:** `npm run changeset` (required!)
4. Push and open PR
5. Snapshot versions are automatically published
6. After merge, changesets bot handles versioning

Key points:
- Every code change requires a changeset
- Select correct apps in changeset (only those you changed)
- Choose correct version bump (major/minor/patch)
- See [Monorepo Strategy](./docs/architecture/monorepo-strategy.md) for versioning details

## 📄 License

Private - All Rights Reserved
