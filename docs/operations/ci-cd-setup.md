# CI/CD Setup Guide

This document explains the CI/CD workflows and required configuration.

## 📋 Required GitHub Secrets & Variables

### Repository Secrets

Navigate to: `Settings` → `Secrets and variables` → `Actions` → `Secrets`

1. **`DOCKERHUB_USERNAME`**
   - Your Docker Hub username
   - Example: `davidcharbonnier`

2. **`DOCKERHUB_TOKEN`**
   - Docker Hub Access Token with **Read, Write, Delete** permissions
   - How to create:
     1. Go to [Docker Hub Security](https://hub.docker.com/settings/security)
     2. Click "New Access Token"
     3. Name: `alacarte-github-actions`
     4. Permissions: **Read, Write, Delete** (Delete is required for cleanup)
     5. Copy the token immediately (shown only once)

3. **`GITHUB_TOKEN`**
   - ✅ Automatically provided by GitHub Actions (no setup needed)

### Environment Variables

Navigate to: `Settings` → `Environments`

#### Create `dev` Environment

Variables:
- **`NEXT_PUBLIC_API_URL`**: Your development API URL
  - Example: `https://alacarte-api-dev-123456.run.app`

#### Create `prod` Environment

Variables:
- **`NEXT_PUBLIC_API_URL`**: Your production API URL
  - Example: `https://alacarte-api-prod-123456.run.app`

## 🔄 Workflows Overview

### 1. PR Snapshot (`pr-snapshot.yml`)

**Trigger:** Every commit on a pull request to `master`

**Environment:** Uses `dev` environment for Admin builds

**What it does:**
- Detects which apps changed (API, Client, Admin) using path filters
- Generates snapshot version: `v0.1.0-pr-123.abc1234` (format: current-version-pr-number.commit-sha)
- Builds only changed apps in parallel:
  - **API:** Docker image with linux/amd64
  - **Admin:** Docker image with Next.js production build, dev API URL
  - **Client:** Flutter APK (debug build with dev configuration)
- Pushes Docker images with two tags:
  - Unique: `{app}:v0.1.0-pr-123.abc1234`
  - Convenience: `{app}:pr-123-latest`
- Uploads Client APK as GitHub Actions artifact
- Comments on PR with available images and manual deployment instructions

**Key Features:**
- Change detection: Only builds affected apps
- Flutter 3.35.4 with Java 17 for Android builds
- Docker BuildKit caching for faster builds
- Parallel execution for speed

**Outputs:**
- Docker images: `davidcharbonnier/alacarte-{app}:{snapshot-version}`
- Convenience tags: `davidcharbonnier/alacarte-{app}:pr-{number}-latest`
- Client APK artifact (30-day retention)

### 2. Cleanup Snapshots (`cleanup-snapshots.yml`)

**Triggers:**
- When a PR is closed (merged or not) - immediate cleanup
- Daily at 2 AM UTC (safety net)
- Manual trigger via `workflow_dispatch`

**What it does:**
1. **Determine what to keep:**
   - Lists all open PRs
   - Identifies last merged PR
   - Creates keep list: open PRs + last merged PR

2. **Parallel Docker cleanup:**
   - For each app (api, admin) independently
   - Lists all Docker Hub tags
   - Deletes tags matching old PR numbers
   - Uses `regctl` for Docker Hub API access

3. **Sequential GitHub cleanup:**
   - Deletes pre-release GitHub releases (must be first)
   - Deletes orphaned git tags (after releases)
   - Deletes old APK artifacts (safety net)

**Retention Policy:**
- ✅ Keep all snapshots from **open PRs** (active development)
- ✅ Keep snapshots from **last merged PR** (rollback capability)
- ❌ Delete all other snapshots (old PRs)

**Cleanup Order:**
```
Docker Hub Tags (parallel, independent)
        ↓
GitHub Releases (sequential - first)
        ↓
Git Tags (sequential - after releases)
        ↓
Artifacts (sequential - safety net)
```

### 3. Production Release (`release.yml`)

**Trigger:** Push of git tags matching patterns:
- `api-v*` - API only
- `client-v*` - Client only  
- `admin-v*` - Admin only

**Versioning:**
- Versions are managed by versio in `versio.toml`
- Tags created by versio release workflow
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
   - Tags: `{app}:v{version}` + `{app}:latest`

2. **Client APK:**
   - Flutter 3.35.4 + Java 17
   - Builds release APK
   - Uploads as artifact

3. **GitHub Releases:**
   - Versio creates GitHub releases with changelogs
   - Workflow updates releases with build status and deployment information
   - Adds Docker image pull commands
   - Attaches APK for client releases
   - Links to relevant changelogs

**Release Examples:**
```
API release: api-v1.2.3
→ Release: "API v1.2.3"
→ Builds: API only at version 1.2.3
→ Docker tags: api:1.2.3

Client release: client-v1.2.4  
→ Release: "Client v1.2.4"
→ Builds: Client only at version 1.2.4
→ APK: client 1.2.4
```

**Breaking Changes:**
- Versio automatically detects breaking changes using conventional commit format
- `feat!:` commits trigger major version bumps for affected packages
- Each package maintains independent versioning
- Breaking changes only affect packages that implement them

**Outputs:**
- Docker images: `davidcharbonnier/alacarte-{app}:v{version}` + `:latest`
- GitHub releases with tags (app-specific)
- Client APK attached to relevant release
- Build status indicators in release notes

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
# → Wait for comment with image tags

# Example commits:
git commit -m "feat: add wine item type support"
git commit -m "fix: resolve image upload issue"
git commit -m "docs: update wine documentation"
```

### Release Process

```bash
# 1. Merge feature PR to master with conventional commits
# → Versio workflow runs automatically on master push

# 2. Versio analyzes commits and determines releases
# - Detects conventional commits (feat, fix, feat!, etc.)
# - Bumps versions according to semantic versioning rules
# - Only releases packages that have changes
# - Updates CHANGELOG.md files per package
# - Creates git tags automatically

# 3. Tag push triggers release.yml workflow
# → Validates tag format
# → Builds affected apps in parallel
# → Updates GitHub releases with build status and deployment info
# → Attaches APK for client releases

# 4. Monitor release completion
# - Check GitHub Actions for build status
# - Verify Docker images published
# - Confirm APK attached to releases
```

**Breaking Change Handling:**
- Use `feat!:` for breaking feature additions
- Use `fix!:` for breaking bug fixes
- Versio automatically bumps major version for affected packages
- Each package versions independently

## 🧪 Manual QA Deployment

After snapshot build completes:

```bash
# Deploy API snapshot
gcloud run deploy alacarte-api-qa \
  --image=davidcharbonnier/alacarte-api:v0.1.0-pr-123.abc1234 \
  --region=northamerica-northeast1

# Deploy Admin snapshot
gcloud run deploy alacarte-admin-qa \
  --image=davidcharbonnier/alacarte-admin:v0.1.0-pr-123.abc1234 \
  --region=northamerica-northeast1

# Download Client APK
# Go to PR → Checks → build-client → Artifacts
# Or use GitHub CLI:
gh run download <run-id> -n client-apk-<version>
```

## 📊 Monitoring

### Workflow Status
- **GitHub Actions Tab:** View all workflow runs
- **PR Checks:** See build status directly on PRs
- **Email Notifications:** Configure in GitHub settings

### Docker Hub
- View published images: https://hub.docker.com/u/davidcharbonnier
- Check tag timestamps and sizes
- Verify cleanup removed old tags

### Release Verification
- **GitHub Releases:** All production releases listed
- **Git Tags:** Matches GitHub releases
- **Changelog:** Each app has `CHANGELOG.md`

## 🐛 Troubleshooting

### Snapshot Build Failures

**Issue:** Docker build fails
- Check Dockerfile exists in `apps/{app}/`
- Verify Docker Hub credentials are set
- Review build logs for specific errors
- Check if base images are accessible

**Issue:** Flutter APK build fails
- Verify Flutter version 3.35.4 is available
- Check if `pubspec.yaml` dependencies resolve
- Ensure localization files are valid
- Review Java 17 setup logs

**Issue:** Admin build fails
- Verify `NEXT_PUBLIC_API_URL` is set in dev environment
- Check Next.js build errors in logs
- Ensure Dockerfile has `prod` target

### Cleanup Not Working

**Issue:** Docker tags not deleted
- Verify `DOCKERHUB_TOKEN` has **Delete** permissions
- Check if `regctl` installed successfully
- Review cleanup logs for API errors
- Ensure Docker Hub is accessible

**Issue:** GitHub releases not deleted
- Check if releases reference git tags (must delete releases first)
- Verify `GITHUB_TOKEN` has write permissions
- Review error messages in cleanup logs

### Release Issues

**Issue:** Release-please PR not created
- Verify conventional commits exist since last release
- Check release-please workflow logs
- Ensure commits are pushed to `master` branch
- Verify `.release-please-manifest.json` is valid

**Issue:** Version not detected correctly
- Check git tag format matches patterns (v*, api-v*, etc.)
- Verify tag was pushed (not just created locally)
- Review release.yml workflow logs for version extraction
- Ensure tag follows semantic versioning (e.g., v0.6.0)

**Issue:** Production build fails
- Check `NEXT_PUBLIC_API_URL` in prod environment
- Verify Dockerfile builds locally
- Review build logs for specific errors

## 🔧 Configuration Reference

### Action Versions
- `actions/checkout@v4`
- `actions/setup-java@v3` (Java 17, Zulu)
- `actions/upload-artifact@v4`
- `actions/download-artifact@v4`
- `docker/setup-buildx-action@v3`
- `docker/login-action@v3`
- `docker/build-push-action@v5`
- `subosito/flutter-action@v2` (Flutter 3.35.4)
- `dorny/paths-filter@v3`
- `google-github-actions/release-please-action@v4`
- `actions/github-script@v7`

### Build Specifications
- **Flutter:** 3.35.4 (stable channel)
- **Java:** 17 (Zulu distribution)
- **Node:** 18.x
- **Docker Platform:** linux/amd64
- **Gradle Cache:** Enabled for Flutter builds

### Environment Variables
- **Dev:** `NEXT_PUBLIC_API_URL` (development API)
- **Prod:** `NEXT_PUBLIC_API_URL` (production API)

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

### Release Management
- Batch multiple features into one release
- Review release-please PR carefully
- Don't merge release PR until ready for deployment
- Monitor release workflow completion after tag creation
- Version comes from git tag, not package.json

### Cleanup Maintenance
- Cleanup runs automatically (no action needed)
- Check cleanup logs if storage concerns arise
- Last merged PR kept for emergency rollback

## 🎯 Quick Reference

**Required Secrets:** 2 (DOCKERHUB_USERNAME, DOCKERHUB_TOKEN)  
**Required Variables:** 2 (NEXT_PUBLIC_API_URL in dev + prod)  
**Workflows:** 3 (pr-snapshot, cleanup, release)  
**Environments:** 2 (dev, prod)

**Workflow Triggers:**
- PR commit → Snapshot build
- PR close → Cleanup
- Master push → Release (if Version Packages PR)

**Artifact Retention:**
- Snapshots: Until PR closes + 1 (last merged)
- Production: Forever (GitHub releases)
- APK artifacts: 30 days

## 📚 Additional Resources

- [Release Please Documentation](https://github.com/googleapis/release-please)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Docker BuildKit](https://docs.docker.com/build/buildkit/)
- [GitHub Actions Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments)
- [Semantic Versioning](https://semver.org/)

---

**Last Updated:** March 2025  
**Workflow Versions:** v1.1.0
