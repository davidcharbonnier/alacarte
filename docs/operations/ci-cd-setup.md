# CI/CD Setup Guide

This document explains the CI/CD workflows and required configuration.

## 📋 Required GitHub Secrets & Variables

### Repository Secrets

Navigate to: `Settings` → `Secrets and variables` → `Actions` → `Secrets`

1. **`GITHUB_TOKEN`**
   - ✅ Automatically provided by GitHub Actions (no setup needed)
   - Requires `contents: write` permissions for releases

### Environment Variables

Navigate to: `Settings` → `Environments`

#### Create `dev` Environment

Variables:
- **`CLIENT_API_BASE_URL`**: Client development API URL
  - Example: `https://alacarte-api-dev-123456.run.app`
- **`CLIENT_GOOGLE_CLIENT_ID`**: Client Google OAuth Client ID
- **`ADMIN_NEXT_PUBLIC_API_URL`**: Admin development API URL
  - Example: `https://alacarte-api-prod-123456.run.app`

#### Create `prod` Environment

Variables:
- **`CLIENT_API_BASE_URL`**: Client production API URL
- **`CLIENT_GOOGLE_CLIENT_ID`**: Client Google OAuth Client ID
- **`ADMIN_NEXT_PUBLIC_API_URL`**: Admin production API URL

## 🔄 Workflows Overview

### 1. PR Snapshot (`pr-snapshot.yml`)

**Trigger:** Every commit on a pull request to `master`

**Environment:** Uses `dev` environment for Admin builds

**What it does:**
- Detects code changes excluding `.md` files (documentation-only changes skip build)
- Generates snapshot version: `pr-{number}.{increment}` (e.g., `pr-123.5`)
- Runs tests in parallel for all apps:
  - **API:** `go test ./...`
  - **Client:** `flutter gen-l10n && flutter test`
  - **Admin:** `npm test`
- Builds all apps in parallel (when any app has code changes):
  - **API:** Docker image with linux/amd64 (GHCR)
  - **Admin:** Docker image with Next.js production build (GHCR)
  - **Client:** Flutter APK (debug build with dev configuration)
- Pushes Docker images to GHCR:
  - Unique: `ghcr.io/{owner}/{repo}/{app}:pr-{number}.{increment}`
  - Convenience: `ghcr.io/{owner}/{repo}/{app}:pr-{number}-latest`
- Uploads Client APK as GitHub Actions artifact
- Comments on PR with available images and manual deployment instructions

**Key Features:**
- Change detection: Excludes .md files, builds all apps when any app changes
- Tests run before builds (fails fast on test failures)
- Flutter 3.35.4 with Java 17 for Android builds
- Docker BuildKit caching for faster builds
- Parallel execution for speed

**Outputs:**
- Docker images: `ghcr.io/{owner}/{repo}/{app}:pr-{number}.{increment}`
- Convenience tags: `ghcr.io/{owner}/{repo}/{app}:pr-{number}-latest`
- Client APK artifact (30-day retention)

### 2. Version Bump (`version.yml`)

**Trigger:** Every push to `master` branch

**What it does:**
- Runs semantic-release for each app in separate jobs
- Analyzes commits since last release using conventional commit format
- Determines version bump based on commit types:
  - `feat:` → minor bump
  - `fix:` → patch bump
  - `BREAKING CHANGE:` → major bump
- Creates git tags: `api-v{version}`, `client-v{version}`, `admin-v{version}`
- Generates CHANGELOG.md in each app directory
- Creates GitHub releases with changelogs

**Tag Format:**
- API: `api-v1.2.3`
- Client: `client-v1.2.3`
- Admin: `admin-v1.2.3`

### 3. Production Release (`release.yml`)

**Trigger:** Push of git tags matching patterns:
- `api-v*` - API only
- `client-v*` - Client only
- `admin-v*` - Admin only

**Versioning:**
- Versions are managed by semantic-release
- Tags created by version.yml workflow
- Format: `api-v1.2.3`, `client-v1.2.3`, `admin-v1.2.3`

**Process:**
When a tag is pushed:
- Validates tag format and determines which app to build
- Extracts version number from tag
- Triggers build job for the specific app

**Build Jobs:**
1. **Docker Images (API + Admin):**
   - Builds only the affected app
   - Uses production environment variables
   - Tags: `ghcr.io/{owner}/{repo}/{app}:v{version}` + `:latest`

2. **Client APK:**
   - Flutter 3.35.4 + Java 17
   - Builds release APK with production configuration
   - Uploads as artifact

3. **GitHub Releases:**
   - Creates/updates GitHub releases with changelogs
   - Adds Docker image pull commands
   - Attaches APK for client releases

**Release Examples:**
```
API release: api-v1.2.3
→ Release: "API v1.2.3"
→ Builds: API only at version 1.2.3
→ Docker tags: ghcr.io/owner/repo/api:1.2.3

Client release: client-v1.2.4
→ Release: "Client v1.2.4"
→ Builds: Client only at version 1.2.4
→ APK: attached to release

Admin release: admin-v1.2.5
→ Release: "Admin v1.2.5"
→ Builds: Admin only at version 1.2.5
→ Docker tags: ghcr.io/owner/repo/admin:1.2.5
```

**Breaking Changes:**
- semantic-release automatically detects breaking changes using conventional commit format
- `feat!:` or `BREAKING CHANGE:` commits trigger major version bumps
- Each package maintains independent versioning

**Outputs:**
- Docker images: `ghcr.io/{owner}/{repo}/{app}:v{version}` + `:latest`
- GitHub releases with tags (app-specific)
- Client APK attached to relevant release

## 🚀 Developer Workflow

### Working on a Feature

```bash
# 1. Create feature branch
git checkout -b feat/add-wine-support

# 2. Make changes across apps
# ... edit code ...

# 3. Commit and push
git commit -m "feat: add wine support"
git push origin feat/add-wine-support

# 4. Open PR with conventional commit messages
# → Snapshot builds automatically trigger
# → Tests run in parallel
# → Wait for comment with image tags

# Example commits:
git commit -m "feat: add wine item type support"
git commit -m "fix: resolve image upload issue"
git commit -m "docs: update wine documentation"
```

### Release Process

```bash
# 1. Merge feature PR to master with conventional commits
# → version.yml runs semantic-release automatically

# 2. semantic-release analyzes commits and determines releases
# - Detects conventional commits (feat, fix, feat!, etc.)
# - Bumps versions according to semantic versioning rules
# - Only releases packages that have changes
# - Updates CHANGELOG.md files per package
# - Creates git tags automatically

# 3. Tag push triggers release.yml workflow
# → Validates tag format
# → Builds affected app
# → Pushes to GHCR
# → Updates GitHub releases

# 4. Monitor release completion
# - Check GitHub Actions for build status
# - Verify Docker images published to GHCR
# - Confirm APK attached to releases
```

**Breaking Change Handling:**
- Use `feat!:` for breaking feature additions
- Use `fix!:` or include `BREAKING CHANGE:` in body for breaking bug fixes
- semantic-release automatically bumps major version

## 🧪 Manual QA Deployment

After snapshot build completes:

```bash
# Deploy API snapshot
gcloud run deploy alacarte-api-qa \
  --image=ghcr.io/owner/repo/api:pr-123.5 \
  --region=northamerica-northeast1

# Deploy Admin snapshot
gcloud run deploy alacarte-admin-qa \
  --image=ghcr.io/owner/repo/admin:pr-123.5 \
  --region=northamerica-northeast1

# Download Client APK
# Go to PR → Checks → build-client → Artifacts
# Or use GitHub CLI:
gh run download <run-id> -n alacarte-client-pr-123.5
```

## 📊 Monitoring

### Workflow Status
- **GitHub Actions Tab:** View all workflow runs
- **PR Checks:** See build status directly on PRs
- **Email Notifications:** Configure in GitHub settings

### GitHub Container Registry
- View published images: https://github.com/orgs/{org}/packages
- Check tag timestamps and sizes

### Release Verification
- **GitHub Releases:** All production releases listed
- **Git Tags:** Matches GitHub releases
- **Changelog:** Each app has `CHANGELOG.md`

## 🐛 Troubleshooting

### Snapshot Build Failures

**Issue:** Docker build fails
- Check Dockerfile exists in `apps/{app}/`
- Verify GHCR credentials are set (GITHUB_TOKEN)
- Review build logs for specific errors
- Check if base images are accessible

**Issue:** Flutter APK build fails
- Verify Flutter version 3.35.4 is available
- Check if `pubspec.yaml` dependencies resolve
- Ensure localization files are valid
- Review Java 17 setup logs

**Issue:** Admin build fails
- Verify `ADMIN_NEXT_PUBLIC_API_URL` is set in dev environment
- Check Next.js build errors in logs
- Ensure Dockerfile has `prod` target

### Test Failures

**Issue:** API tests fail
- Run `go test ./...` locally in `apps/api`
- Check for test flakiness

**Issue:** Client tests fail
- Run `flutter gen-l10n && flutter test` locally in `apps/client`
- Check for test flakiness

**Issue:** Admin tests fail
- Run `npm test` locally in `apps/admin`
- Check for test flakiness

### Release Issues

**Issue:** Version not detected correctly
- Check git tag format matches patterns (api-v*, client-v*, admin-v*)
- Verify tag was pushed (not just created locally)
- Review version.yml workflow logs
- Ensure commits follow conventional format

**Issue:** Production build fails
- Check environment variables in prod environment
- Verify Dockerfile builds locally
- Review build logs for specific errors

## 🔧 Configuration Reference

### Semantic Release Configuration

Each app has a `.releaserc` file with:
```json
{
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/github",
    "@semantic-release/git"
  ]
}
```

### Action Versions
- `actions/checkout@v4`
- `actions/setup-node@v4` (Node 20)
- `actions/setup-go@v5` (Go 1.21)
- `actions/setup-java@v3` (Java 17, Zulu)
- `actions/upload-artifact@v4`
- `actions/download-artifact@v4`
- `docker/setup-buildx-action@v3`
- `docker/login-action@v3`
- `docker/build-push-action@v5`
- `subosito/flutter-action@v2` (Flutter 3.35.4)
- `actions/github-script@v7`

### Build Specifications
- **Flutter:** 3.35.4 (stable channel)
- **Java:** 17 (Zulu distribution)
- **Node:** 20.x
- **Go:** 1.21
- **Docker Platform:** linux/amd64
- **Gradle Cache:** Enabled for Flutter builds

### Environment Variables
- **Dev:** `CLIENT_API_BASE_URL`, `CLIENT_GOOGLE_CLIENT_ID`, `ADMIN_NEXT_PUBLIC_API_URL`
- **Prod:** Same as dev (production values)

## 📝 Best Practices

### Commit Message Guidelines
- Use conventional commits (enforced by commitlint)
- Commit types trigger version bumps:
  - `feat:` → minor version bump (new features)
  - `fix:` → patch version bump (bug fixes)
  - `feat!:` or `BREAKING CHANGE:` → major version bump
- Other types (docs, chore, refactor) don't trigger releases
- Write clear, descriptive commit messages
- Example: `feat: add wine item type support`

### PR Practices
- Keep PRs focused and small
- Test snapshot builds before requesting review
- Deploy to QA manually if needed
- Ensure all checks pass before merge
- Documentation-only changes (`.md` files) will skip builds

### Release Management
- semantic-release runs automatically on master push
- Review generated CHANGELOG.md before merging
- Monitor release workflow completion after tag creation
- Version comes from semantic-release analysis

## 🎯 Quick Reference

**Required Secrets:** 0 (GITHUB_TOKEN is automatic)  
**Required Variables:** 6 (CLIENT_API_BASE_URL, CLIENT_GOOGLE_CLIENT_ID, ADMIN_NEXT_PUBLIC_API_URL in dev + prod)  
**Workflows:** 3 (pr-snapshot, version, release)  
**Environments:** 2 (dev, prod)

**Workflow Triggers:**
- PR commit → Snapshot build (excludes .md files)
- Master push → Version bump (semantic-release)

**Artifact Retention:**
- Snapshots: Until PR closes
- Production: Forever (GitHub releases)
- APK artifacts: 30 days

## 📚 Additional Resources

- [semantic-release Documentation](https://semantic-release.gitbook.io/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Docker BuildKit](https://docs.docker.com/build/buildkit/)
- [GitHub Actions Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments)
- [Semantic Versioning](https://semver.org/)

---

**Last Updated:** February 2026
**Workflow Versions:** v2.0.0
