# À la carte Project Context for AI Agents

## Project Overview

À la carte is a multi-platform rating and sharing system for consumables such as cheese, gin, wine, beer, coffee, etc. Its primary goal is to provide a comprehensive platform for users to rate and share their experiences with various consumables.

## Tech Stack

- **API:** Go (>=1.21), Gin, GORM, MySQL (8.0+), Google OAuth 2.0, JWT tokens
- **Client:** Flutter SDK (>=3.27), Riverpod, Google Sign-In (google_sign_in package), Cross-platform OAuth (Web, Android, Desktop)
- **Admin:** Next.js, TypeScript (strict, no `any`), NextAuth.js for Google OAuth integration
- **Infrastructure:** Google Cloud Run, Cloud SQL (MySQL), Docker & Docker Compose
- **CI/CD:** GitHub Actions, GHCR (GitHub Container Registry), Snapshot builds for PRs (Docker images for API/Admin, APK for Client)
- **Release Automation:** Conventional Commits, semantic-release, GitHub Actions
- **Monorepo Tools:** commitlint, husky Git hooks

## Monorepo Structure

The project uses a monorepo structure with three main applications:

- `apps/api` - Go REST API
- `apps/client` - Flutter mobile/web client
- `apps/admin` - Next.js admin panel

## Development Commands

### Run the web stack (API and admin)

- **Run** `docker compose up -d` (in project root)

API will be reachable at http://localhost:8080 and admin at http://localhost:3000

Project rebuild and reload when file changes

### API (Go)

- **Build:** `go build ./...` (in `apps/api`)
- **Test:** `go test ./...` (in `apps/api`)

### Client (Flutter)

**MANDATORY COMMAND TO RUN BEFORE ANY BUILD OR TEST:** `flutter gen-l10n` (in `apps/client`)

- **Build:** `flutter build` (in `apps/client`)
- **Test:** `flutter test` (in `apps/client`)

### Admin (Next.js)

- **Build:** `npm run build` (in `apps/admin`)
- **Test:** `npm test` (in `apps/admin`)

## Critical Development Guidelines

### Commit Guidelines

All commits MUST follow conventional commit format with required scopes as defined in `commitlint.config.js`. Refer to the monorepo strategy documentation for details.

### Automated Versioning

The project uses automated versioning with semantic-release. Version bumps happen automatically based on commit types when pushing to master:

- `feat(scope)` → minor bump (0.1.0 → 0.2.0)
- `fix(scope)` → patch bump (0.1.0 → 0.1.1)
- `BREAKING CHANGE:` → major bump (0.1.0 → 1.0.0)
- Other types → no version change

Each app (api, client, admin) is versioned independently with tags:
- `api-v1.0.0` - API releases
- `client-v1.0.0` - Client releases
- `admin-v1.0.0` - Admin releases

### Code Style Guidelines

**Go (API):**

- Follow [Effective Go](https://golang.org/doc/effective_go.html)
- Use `gofmt` for formatting
- Meaningful variable names
- Explicit error handling

**Dart/Flutter (Client):**

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `dart format` for formatting
- Riverpod for state management
- Follow existing widget patterns

**TypeScript/Next.js (Admin):**

- Follow [Next.js best practices](https://nextjs.org/docs)
- Strict TypeScript (no `any`)
- Use provided UI components
- Follow existing page patterns

**General Principles:**

- Follow existing patterns in the codebase
- Keep code DRY (Don't Repeat Yourself)
- Write self-documenting code
- Add comments for complex logic only
- Prefer readability over cleverness

## Key Project Conventions

### Git Workflow

- Branch naming: `feat/`, `fix/`, `refactor/`, `docs/`, `chore/`
- Feature branches merged to `master`
- Conventional commits enforced by commitlint/husky
- No manual versioning - fully automated

### Testing Strategy

Currently no formal testing strategy defined. Add tests as appropriate for new functionality.

### Documentation

Documentation is organized by purpose rather than by app:

- `docs/features/` - General features
- `docs/api/` - API-specific
- `docs/client/` - Client-specific
- `docs/admin/` - Admin-specific
- `docs/architecture/` - Architecture
- `docs/operations/` - Operations

Update documentation when adding new features or changing existing behavior.

## Domain Context

The project focuses on consumables with entities likely including:

- Consumable types (wine, beer, cheese, coffee, gin)
- Specific consumable items
- User ratings and reviews
- Sharing functionalities
- User profiles

## Important Constraints

1. **Automated Releases:** Strict adherence to commit message guidelines
2. **Monorepo Structure:** Respect organization and shared resources
3. **Multi-platform:** Client targets both mobile and web
4. **Private License:** All rights reserved

## External Dependencies

- GitHub Actions for CI/CD
- GHCR (GitHub Container Registry) for Docker images
- Google Cloud Run for deployment
- Cloud SQL (MySQL) for database
- semantic-release for automated versioning
- commitlint/husky for Git hooks
- Docker Compose for local development
