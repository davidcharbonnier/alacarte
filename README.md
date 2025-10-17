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
└── .github/
    └── workflows/    # CI/CD pipelines
```

## 🚀 Quick Start

### Prerequisites
- Node.js >= 18.0.0
- Go >= 1.21
- Flutter SDK >= 3.16
- Docker & Docker Compose

### Installation

```bash
# Install monorepo tooling (includes commit hooks)
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

This monorepo uses **[release-please](https://github.com/googleapis/release-please)** with **[Conventional Commits](https://www.conventionalcommits.org/)** for fully automated releases.

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
2. **Release PR is auto-created** by release-please bot
   - Contains version bumps
   - Auto-generated changelogs
   - All pending changes
3. **Review & merge** the Release PR
4. **Git tags are created** automatically
5. **Builds & releases** are triggered by tags

**Version bumps:**
- `feat:` → minor bump (0.3.1 → 0.4.0)
- `fix:` → patch bump (0.3.1 → 0.3.2)
- `BREAKING CHANGE:` → major bump (0.3.1 → 1.0.0)
- `docs:`, `chore:`, etc → no version bump

See [Release Workflow Guide](./docs/RELEASE_WORKFLOW.md) for complete details.

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
- **Release Automation:** release-please + Conventional Commits

## 📚 Documentation

- [Release Workflow Guide](./docs/RELEASE_WORKFLOW.md) ⭐ **NEW!**
- [Local Development Guide](./docs/local-development.md)
- [API Documentation](./apps/api/README.md)
- [Client Documentation](./apps/client/README.md)
- [Admin Documentation](./apps/admin/README.md)

## 🔧 Monorepo Tools

- **release-please:** Automated versioning and changelogs
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
5. After merge, release-please handles versioning
6. Merge the auto-generated Release PR when ready

**Important:**
- Commit messages must follow conventional format (enforced by git hooks)
- Choose correct scope: `api`, `client`, `admin`, etc.
- Use correct type: `feat` for features, `fix` for bugs, etc.
- See [Release Workflow Guide](./docs/RELEASE_WORKFLOW.md) for details

## 📄 License

Private - All Rights Reserved
