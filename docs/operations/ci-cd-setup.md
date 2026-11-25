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
- **`ADMIN_VITE_API_URL`**: Admin development API URL (baked into the bundle as `VITE_API_URL`)
  - Example: `https://alacarte-api-dev-123456.run.app`
- **`ADMIN_VITE_GOOGLE_CLIENT_ID`**: Admin Google OAuth Web Client ID (baked in as `VITE_GOOGLE_CLIENT_ID`)

#### Create `prod` Environment

Variables:
- **`CLIENT_API_BASE_URL`**: Client production API URL
- **`CLIENT_GOOGLE_CLIENT_ID`**: Client Google OAuth Client ID
- **`ADMIN_VITE_API_URL`**: Admin production API URL
- **`ADMIN_VITE_GOOGLE_CLIENT_ID`**: Admin Google OAuth Web Client ID

## 🔄 Workflows Overview

### 1. PR Snapshot (`pr-snapshot.yml`)

**Trigger:** Every commit on a pull request to `master`

**Environment:** Uses the `dev` environment for Client and Admin builds

**What it does:**
- Detects code changes excluding `.md` files (documentation-only changes skip build)
- Generates snapshot version: `pr-{number}.{increment}` (e.g., `pr-123.5`)
- Runs tests in parallel for all apps:
  - **API:** `go test ./...`
  - **Client:** `flutter gen-l10n && flutter test`
  - **Admin:** `npm run typecheck`, then `npm test` (the admin `test` script is a stub)
- Builds all apps in parallel (when any app has code changes):
  - **API:** Docker image with linux/amd64 (GHCR)
  - **Admin:** static `dist/` bundle (Vite build, uploaded as an artifact — no Docker image)
  - **Client:** Flutter APK (debug build with dev configuration)
- Pushes the API Docker image to GHCR:
  - Unique: `ghcr.io/{owner}/{repo}-api:pr-{number}.{increment}`
  - Convenience: `ghcr.io/{owner}/{repo}-api:pr-{number}-latest`
- Uploads Client APK (`alacarte-client-*`) and Admin `dist/` (`admin-dist-pr-{number}.{increment}`) as GitHub Actions artifacts
- Comments on PR with links and an API `docker pull` line

**Key Features:**
- Change detection: Excludes .md files, builds all apps when any app changes
- Tests run before builds (fails fast on test failures)
- Flutter 3.35.4 with Java 17 for Android builds
- Docker BuildKit caching for faster builds
- Parallel execution for speed

**Outputs:**
- API Docker image: `ghcr.io/{owner}/{repo}-api:pr-{number}.{increment}`
- Convenience tag: `ghcr.io/{owner}/{repo}-api:pr-{number}-latest`
- Client APK and Admin `dist/` artifacts (30-day retention)

### 2. Version Bump (`version.yml`)

**Trigger:** Every push to `master` branch

**What it does:**
- Runs semantic-release for api and client in separate jobs (admin has no job; see Admin tags below)
- Analyzes commits since last release using conventional commit format
- Determines version bump based on commit types:
  - `feat:` → minor bump
  - `fix:` → patch bump
  - `BREAKING CHANGE:` → major bump
- Creates git tags: `api-v{version}`, `client-v{version}`
- Generates CHANGELOG.md in each app directory

**Tag Format:**
- API: `api-v1.2.3`
- Client: `client-v1.2.3`
- Admin: `admin-v1.2.3` — pushed **manually** (no `.releaserc`, no `version.yml` job); see [Admin Releases](../architecture/monorepo-strategy.md#admin-releases)

### 3. Production Release (`release.yml`)

**Trigger:** `workflow_dispatch` with a `tag` input (sent by `version.yml` for api and client), or a push of a git tag matching:
- `api-v*` - API only
- `client-v*` - Client only
- `admin-v*` - Admin only

**Versioning:**
- API and client versions are managed by semantic-release
- API and client tags are created by the version.yml workflow; admin tags are pushed manually
- Format: `api-v1.2.3`, `client-v1.2.3`, `admin-v1.2.3`

**Process:**
On dispatch or tag push:
- Determines which app to build from the tag prefix
- Extracts version number from tag
- Triggers build job for the specific app

**Build Jobs:**
1. **API Docker image:**
   - Builds only for an `api-v*` tag (tag push or dispatch input)
   - Tags: `ghcr.io/{owner}/{repo}-api:{version}` + `:latest`

2. **Admin SPA:**
   - Builds the static bundle with the `prod` environment's `ADMIN_VITE_*` variables
   - Uploads `admin-dist-{version}` as an artifact (no Docker image)

3. **Client APK:**
   - Flutter 3.35.4 + Java 17
   - Builds release APK with production configuration
   - Uploads as artifact

4. **GitHub Releases:**
   - Creates/updates GitHub releases with changelogs (tag-push runs only; see caveats above)
   - Adds the API image pull command
   - Attaches APK for client releases

**Release Examples:**
```
API release: api-v1.2.3
→ Release: "API v1.2.3"
→ Builds: API only at version 1.2.3
→ Docker tags: ghcr.io/owner/repo-api:1.2.3

Client release: client-v1.2.4
→ Release: "Client v1.2.4"
→ Builds: Client only at version 1.2.4
→ APK: attached to release

Admin release: admin-v1.2.5
→ Release: "Admin v1.2.5"
→ Builds: Admin only at version 1.2.5
→ Artifact: admin-dist-1.2.5 (static bundle)
```

**Known caveats (as implemented, not yet fixed):**
- (Takes effect once the `npm ci` caveat below is fixed; today the dispatch step is not reached.) `version.yml` dispatches `release.yml` for the latest `api-v*`/`client-v*` tag on every master push, even when semantic-release created no new tag. `release.yml` checks out master HEAD, so it can re-push `ghcr.io/{owner}/{repo}-api:{old version}` and `:latest` with newer code.
- (Same: only reachable once the `npm ci` caveat below is fixed.) The `create-release` job derives the tag from `GITHUB_REF`, which is `refs/heads/master` on a dispatch run, so app, version and title come out empty and no usable GitHub Release is expected for dispatched api/client runs (not verified by a run). Manually pushed tags (e.g. `admin-v*`) resolve correctly. Fix: use `inputs.tag` in `create-release`.
- The `release-api` and `release-client` jobs run `npm ci --ignore-scripts` in `apps/api` and `apps/client`, but no `package-lock.json` is tracked there (`apps/api/.gitignore` ignores it), and the root `package.json` that once made them workspace members was removed in `346c5c9` (2026-07-16). `npm ci` needs a lockfile, so `version.yml` is expected to fail at that step; the last automated release commit is `chore(release): 2.3.2` (2026-07-01). Fix: commit lockfiles for both apps (and drop the ignore line) or switch the step to `npm install`.

- `version.yml` sets only `permissions: contents: write`, but `gh workflow run` needs `actions: write`, so the dispatch step is expected to fail with a 403 even after the `npm ci` caveat is fixed (not verified by a run). Fix: add `actions: write` to `version.yml`.

**Breaking Changes:**
- semantic-release detects breaking changes using conventional commit format
- A `BREAKING CHANGE:` footer in a commit triggers a major version bump
- Each package maintains independent versioning

**Outputs:**
- API Docker image: `ghcr.io/{owner}/{repo}-api:{version}` + `:latest`
- Admin `dist/` artifact
- GitHub releases with tags (app-specific; tag-push runs only, see caveats above)
- Client APK attached to the release (same limitation)

## 🚀 Developer Workflow

### Working on a Feature

```bash
# 1. Create feature branch
git checkout -b feat/add-wine-support

# 2. Make changes across apps
# ... edit code ...

# 3. Commit and push
git commit -m "feat(api): add wine support"
git push origin feat/add-wine-support

# 4. Open PR with conventional commit messages
# → Snapshot builds automatically trigger
# → Tests run in parallel
# → Wait for comment with image tags

# Example commits:
git commit -m "feat(api): add wine item type support"
git commit -m "fix(api): resolve image upload issue"
git commit -m "docs(docs): update wine documentation"
```

### Release Process

```bash
# 1. Merge feature PR to master with conventional commits
# → version.yml is meant to run semantic-release (see caveats above)

# 2. semantic-release analyzes commits and determines releases
# - Detects conventional commits (feat, fix, etc.)
# - Bumps versions according to semantic versioning rules
# - Only creates a new tag/changelog for packages with release-worthy commits (see caveats below)
# - Updates CHANGELOG.md files per package
# - Creates git tags

# 3. version.yml dispatches release.yml (tags pushed with GITHUB_TOKEN do not start other workflows)
# → Builds affected app
# → Pushes to GHCR
# → Updates GitHub releases (tag-push runs only; see caveats)

# 4. Monitor release completion
# - Check GitHub Actions for build status
# - Verify the API image is published to GHCR
# - Confirm APK attached to the release (tag-push runs only; see caveats)
```

**Breaking Change Handling:**
- Add a `BREAKING CHANGE:` footer to the commit body for breaking changes (the `!` shorthand is not parsed by this config)
- semantic-release bumps the major version

## 🧪 Manual QA Deployment

After snapshot build completes:

```bash
# Deploy API snapshot (image must be reachable by Cloud Run, e.g. via an Artifact Registry remote repo for ghcr.io)
gcloud run deploy alacarte-api-qa \
  --image=ghcr.io/owner/repo-api:pr-123.5 \
  --region=northamerica-northeast1

# Admin snapshot: download the admin-dist-pr-123.5 artifact and upload it to your static host
gh run download <run-id> -n admin-dist-pr-123.5

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

**Issue:** API Docker build fails
- Check `apps/api/Dockerfile` exists
- Verify GHCR credentials are set (GITHUB_TOKEN)
- Review build logs for specific errors
- Check if base images are accessible

**Issue:** Flutter APK build fails
- Verify Flutter version 3.35.4 is available
- Check if `pubspec.yaml` dependencies resolve
- Ensure localization files are valid
- Review Java 17 setup logs

**Issue:** Admin build fails
- Verify `ADMIN_VITE_API_URL` and `ADMIN_VITE_GOOGLE_CLIENT_ID` are set in the dev environment
- Check Vite build errors in logs

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
- Verify the API Dockerfile builds locally
- Review build logs for specific errors

## 🔧 Configuration Reference

### Semantic Release Configuration

Only `apps/api` and `apps/client` have a `.releaserc`. See the plugin list in [monorepo-strategy.md](../architecture/monorepo-strategy.md#-versioning-strategy). The GitHub Release itself is created by `release.yml`.

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
- **Dev:** `CLIENT_API_BASE_URL`, `CLIENT_GOOGLE_CLIENT_ID`, `ADMIN_VITE_API_URL`, `ADMIN_VITE_GOOGLE_CLIENT_ID`
- **Prod:** Same as dev (production values)

## 📝 Best Practices

### Commit Message Guidelines
- Use conventional commits (checked by an opt-in local commitlint hook; not enforced in CI)
- Commit types trigger version bumps:
  - `feat:` → minor version bump (new features)
  - `fix:` → patch version bump (bug fixes)
  - `BREAKING CHANGE:` footer → major version bump
- `docs`, `chore`, `refactor`, `test`, `build`, `ci` release a patch only with an `api` or `client` scope; `style` never releases; `feat`, `fix` and `perf` release both apps whatever the scope
- Write clear, descriptive commit messages
- Example: `feat(api): add wine item type support`

### PR Practices
- Keep PRs focused and small
- Test snapshot builds before requesting review
- Deploy to QA manually if needed
- Ensure all checks pass before merge
- Documentation-only changes (`.md` files) will skip builds

### Release Management
- semantic-release is meant to run on master push (see caveats)
- Review generated CHANGELOG.md before merging
- Monitor release workflow completion after tag creation
- Version comes from semantic-release analysis

## 🎯 Quick Reference

**Required Secrets:** 4 for signed Android releases (`CLIENT_KEYSTORE_BASE64`, `CLIENT_KEYSTORE_PASSWORD`, `CLIENT_KEY_ALIAS`, `CLIENT_KEY_PASSWORD`; see [github-secrets.md](github-secrets.md)). `GITHUB_TOKEN` is automatic.  
**Required Variables:** 8 (CLIENT_API_BASE_URL, CLIENT_GOOGLE_CLIENT_ID, ADMIN_VITE_API_URL, ADMIN_VITE_GOOGLE_CLIENT_ID in dev + prod)  
**Workflows:** 3 (pr-snapshot, version, release)  
**Environments:** 2 (dev, prod)

**Workflow Triggers:**
- PR commit → Snapshot build (excludes .md files)
- Master push → Version bump (semantic-release)

**Artifact Retention:**
- Snapshot artifacts (client APK, admin `dist/`): 30 days
- Snapshot GHCR tags: never pruned automatically
- Release client APK: attached to the GitHub Release only when the release job resolves the tag (see caveats above)
- Release admin `dist/`: Actions artifact, default retention (not on the Release)

## 📚 Additional Resources

- [semantic-release Documentation](https://semantic-release.gitbook.io/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Docker BuildKit](https://docs.docker.com/build/buildkit/)
- [GitHub Actions Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments)
- [Semantic Versioning](https://semver.org/)

---

**Last Updated:** February 2026
**Workflow Versions:** v2.0.0
