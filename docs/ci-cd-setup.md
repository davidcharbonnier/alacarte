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

**Trigger:** Push to `master` branch (typically from merging Version Packages PR)

**Environment:** Uses `prod` environment for Docker builds

**Two-Stage Process:**

#### Stage 1: Version Packages PR Creation
When changesets exist:
- Changesets Action bumps versions in `package.json` files
- Updates `CHANGELOG.md` files
- Creates/updates "Version Packages" PR
- Commits: `chore: version packages`

#### Stage 2: Production Release (after merging Version Packages PR)
When Version Packages PR is merged:
- Changesets Action runs `publish` (creates git tags)
- Sets `published: true` output
- Triggers build jobs:

**Build Jobs:**
1. **Docker Images (API + Admin):**
   - Matrix build for both apps
   - Uses production environment variables
   - Admin gets `NEXT_PUBLIC_API_URL` from prod env
   - Tags: `{app}:v{version}` + `{app}:latest`

2. **Client APK:**
   - Flutter 3.35.4 + Java 17
   - Generates localizations
   - Builds release APK
   - Uploads as artifact

3. **GitHub Releases:**
   - **Synchronized versions (all apps same):** Single release `v2.1.0`
   - **Independent patches (versions differ):** Separate releases per changed app
   - Detection uses Changesets `publishedPackages` output
   - Includes relevant assets (APK for client, links for Docker)

**Release Strategy Examples:**
```
Synchronized: API 2.1.0, Client 2.1.0, Admin 2.1.0
→ 1 release: v2.1.0 (combined)

Single patch: API 2.1.0, Client 2.1.0, Admin 2.1.1
→ 1 release: admin-v2.1.1 (admin only)

Multiple patches: API 2.1.5, Client 2.1.0, Admin 2.1.3
→ 2 releases: api-v2.1.5, admin-v2.1.3 (changed apps only)
```

**Outputs:**
- Docker images: `davidcharbonnier/alacarte-{app}:v{version}` + `:latest`
- GitHub releases with tags (combined or per-app)
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

# 4. Open PR
# → Snapshot builds automatically trigger
# → Wait for comment with image tags
```

### Before Merging

```bash
# Create changeset (REQUIRED before merge)
npm run changeset

# Prompts:
# - Which packages changed? Select: api, client, admin
# - What type of change? Select: minor (for features)
# - Summary: "Added wine item type support"

# Commit changeset
git add .changeset/
git commit -m "docs: add changeset"
git push
```

### Release Process

```bash
# 1. Merge feature PR to master
# → Changesets bot creates/updates "Version Packages" PR

# 2. Review Version Packages PR
# - Check version bumps are correct
# - Review CHANGELOG.md updates
# - Verify all changesets are consumed

# 3. Merge Version Packages PR
# → Production release triggers automatically
# → Docker images published
# → GitHub releases created
# → APK published
```

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

**Issue:** Version Packages PR not created
- Verify changeset files exist in `.changeset/`
- Check Changesets Action logs
- Ensure push is to `master` branch
- Verify `package.json` files are valid

**Issue:** Wrong release strategy (combined vs separate)
- Check if all `package.json` versions match
- Review `publishedPackages` output
- Verify Changesets consumed correct files

**Issue:** Production build fails
- Check `NEXT_PUBLIC_API_URL` in prod environment
- Verify Dockerfile builds locally
- Review build logs for specific errors

## 🔧 Configuration Reference

### Action Versions
- `actions/checkout@v4`
- `actions/setup-node@v4` (Node 18)
- `actions/setup-java@v3` (Java 17, Zulu)
- `actions/upload-artifact@v4`
- `actions/download-artifact@v4`
- `docker/setup-buildx-action@v3`
- `docker/login-action@v3`
- `docker/build-push-action@v5`
- `subosito/flutter-action@v2` (Flutter 3.35.4)
- `dorny/paths-filter@v3`
- `changesets/action@v1`
- `softprops/action-gh-release@v1`
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

### Changeset Guidelines
- Create changeset BEFORE merging PR
- Choose appropriate bump type:
  - `major`: Breaking changes
  - `minor`: New features (backward compatible)
  - `patch`: Bug fixes
- Write clear, user-facing summaries
- Select all affected packages

### PR Practices
- Keep PRs focused and small
- Test snapshot builds before requesting review
- Deploy to QA manually if needed
- Ensure all checks pass before merge

### Release Management
- Batch multiple features into one release
- Review Version Packages PR carefully
- Don't merge Version Packages PR until ready
- Monitor release workflow completion

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

- [Changesets Documentation](https://github.com/changesets/changesets)
- [Turborepo Filtering](https://turbo.build/repo/docs/core-concepts/monorepos/filtering)
- [Docker BuildKit](https://docs.docker.com/build/buildkit/)
- [GitHub Actions Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments)
- [Monorepo Strategy Document](../A%20la%20carte%20Monorepo%20Strategy.md)

---

**Last Updated:** January 2025  
**Workflow Versions:** v1.0.0
