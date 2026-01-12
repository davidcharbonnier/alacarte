# À la carte Monorepo Strategy

## 🎯 Overview

This document defines the versioning strategy, tooling, and release management approach for the À la carte monorepo.

**Last Updated:** January 2026  
**Status:** Active - Using versio with Conventional Commits  
**Key Change:** Simplified workflow - tags created directly on master merge, no release PR step

## 📦 Monorepo Structure

```
alacarte/
├── .github/
│   └── workflows/
│       ├── pr-snapshot.yml       # Build & publish snapshots
│       ├── cleanup-snapshots.yml # Automated cleanup
│       ├── version.yml           # Create release PRs (using versio)
│       └── release.yml           # Build & release from tags
├── apps/
│   ├── api/                      # Go REST API
│   │   ├── Dockerfile
│   │   └── ... (Go code)
│   ├── client/                   # Flutter mobile/web app
│   │   ├── Dockerfile
│   │   └── ... (Flutter code)
│   └── admin/                    # Next.js admin panel
│       ├── Dockerfile
│       └── ... (Next.js code)
├── .versio.yaml                  # Release automation config (versio)
├── commitlint.config.js          # Commit validation rules
├── .husky/                       # Git hooks
├── docker-compose.yml            # Root orchestration
├── package.json                  # Root package.json for tooling
├── docs/                         # Consolidated documentation
│   ├── architecture/
│   ├── development/
│   └── deployment/
└── README.md                     # Monorepo overview
```

## 🛠️ Tooling Stack

### **versio** - Automated Release Management ⭐

**Purpose:** Fully automated versioning, changelog generation, and release management from conventional commits

**Why chosen:**

- ✅ Lightweight, Go-based alternative to release-please
- ✅ Native monorepo support
- ✅ Automatic version bumps from commit messages
- ✅ Auto-generated changelogs from commits
- ✅ Creates release PRs for review before release
- ✅ Works seamlessly with Git tags
- ✅ Supports independent and synchronized releases
- ✅ Zero manual versioning needed

**Configuration:** (`.versio.yaml`)

```yaml
version: "1"
options:
  prev_tag: "versio-prev"

projects:
  - name: "client"
    id: 1
    root: "apps/client"
    changelog: "CHANGELOG.md"
    tag_prefix: "client" # versio will create tags like "client-v1.0.0"
    version:
      tags:
        default: "1.0.0"

  - name: "admin"
    id: 2
    root: "apps/admin"
    changelog: "CHANGELOG.md"
    tag_prefix: "admin" # versio will create tags like "admin-v1.0.0"
    version:
      tags:
        default: "1.0.0"

  - name: "api"
    id: 3
    root: "apps/api"
    changelog: "CHANGELOG.md"
    tag_prefix: "api" # versio will create tags like "api-v1.0.0"
    version:
      tags:
        default: "1.0.0"

sizes:
  use_angular: true
  fail: ["*"]
```

### **Conventional Commits** - Commit Format Standard

**Purpose:** Structured commit messages that enable automated versioning

**Format:**

```
<type>(<scope>): <subject>

type: feat, fix, docs, style, refactor, perf, test, build, ci, chore
scope: api, client, admin, deps, ci, docs, release (REQUIRED)
subject: Brief description in sentence case
```

**Version Bumps:**

- `feat:` → **minor** bump (0.3.1 → 0.4.0)
- `fix:` → **patch** bump (0.3.1 → 0.3.2)
- `BREAKING CHANGE:` → **major** bump (0.3.1 → 1.0.0)
- `docs:`, `chore:`, etc → no version bump

**Examples:**

```bash
feat(api): Add wine filtering endpoint
fix(client): Resolve cache invalidation bug
docs(admin): Update deployment guide
chore(deps): Bump dependencies
```

### **commitlint** - Commit Message Validation

**Purpose:** Enforce conventional commit format via git hooks

**Installation:**

```bash
npm install  # Installs commitlint + husky
```

**Configuration:** (`commitlint.config.js`)

```javascript
module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "scope-enum": [
      2,
      "always",
      ["api", "client", "admin", "deps", "ci", "docs", "release"],
    ],
    "scope-empty": [2, "never"], // Scope is REQUIRED
    "subject-case": [2, "always", "sentence-case"],
  },
};
```

**Git Hook:** (`.husky/commit-msg`)

```bash
npx --no -- commitlint --edit $1
```

**Result:** Commits are automatically validated before push. Invalid format = commit rejected.

### **GitHub Actions** - Change Detection & Build Orchestration

**Purpose:** Detect which apps changed and build only those apps

**Why chosen:**

- ✅ Native GitHub integration
- ✅ Simple, transparent change detection
- ✅ Conditional job execution
- ✅ No black box behavior

**Workflows:**

- `version.yml` - Creates version tags and updates changelogs on master merge (using versio)
- `release.yml` - Builds and releases from git tags
- `pr-snapshot.yml` - Creates snapshot builds for QA
- `cleanup-snapshots.yml` - Cleans up old snapshots

## 📌 Versioning Strategy

### **Automated Versioning with Independent Releases**

**Approach:**

- Commits in conventional format drive versioning
- versio analyzes commits and determines version bumps
- **All apps are tagged together** when code is merged to master, but each app's version is determined independently
- Version bumps are determined by commit types for each app's own history
- Tags created directly when code is merged to master

**Version Bump Rules:**

- `BREAKING CHANGE:` → **major** bump for the affected app (1.0.0 → 2.0.0)
- `feat:` → **minor** bump for the affected app (1.0.0 → 1.1.0)
- `fix:` → **patch** bump for the affected app (1.0.0 → 1.0.1)
- `docs:`, `chore:`, etc → no version bump

**Example Timeline:**

```
January 10, 2026 - Merge feat(api): Add wine filtering endpoint
├── API: api-v1.1.0      (minor bump from feat)
├── Client: client-v1.0.0   (no change, remains at current version)
└── Admin: admin-v1.0.0    (no change, remains at current version)

January 12, 2026 - Merge fix(client): Fix authentication bug
├── API: api-v1.1.0      (no change)
├── Client: client-v1.0.1   (patch bump from fix)
└── Admin: admin-v1.0.0    (no change)

January 15, 2026 - Merge feat(client): Add offline mode
├── API: api-v1.1.0      (no change)
├── Client: client-v1.1.0   (minor bump from feat)
└── Admin: admin-v1.0.0    (no change)
```

**Benefits:**

- ✅ Zero manual versioning - fully automated
- ✅ Automatic changelog generation from commits
- ✅ Simplified workflow - no release PR step
- ✅ Independent versioning reflects actual changes per app
- ✅ Enforced commit standards via git hooks
- ✅ Direct tag creation on master merge

**Trade-offs:**

- ⚠️ Apps can have different version numbers, which may require more coordination for deployments
- ⚠️ Requires disciplined commit messages
- ⚠️ Must use correct conventional commit format
- ⚠️ All team members must understand the system

**Rationale for Independent Releases:**

- **Accurate versioning:** Each app's version reflects its own change history
- **Flexible deployment:** Apps can be deployed independently based on their actual changes
- **Clear changelogs:** Each app's CHANGELOG.md only contains its own changes
- **Simplified coordination:** No need to synchronize version bumps across unrelated changes
- **Faster releases:** Tags created immediately on master merge for all apps

## 🎨 Commit Best Practices

### **When to Use Each Commit Type**

**Features (`feat:`)** - New functionality:

```bash
feat(api): Add wine filtering endpoint
feat(client): Implement offline mode
feat(admin): Add user management dashboard
```

**Result:** Minor version bump (0.3.1 → 0.4.0)

**Bug Fixes (`fix:`)** - Bug corrections:

```bash
fix(api): Resolve database connection timeout
fix(client): Fix cache invalidation issue
fix(admin): Correct pagination bug
```

**Result:** Patch version bump (0.3.1 → 0.3.2)

**Breaking Changes (`BREAKING CHANGE:`)** - Incompatible changes:

```bash
feat(api): Redesign authentication system

BREAKING CHANGE: OAuth flow now requires additional redirect_uri parameter
```

**Result:** Major version bump (0.3.1 → 1.0.0)

**No Version Bump:**

```bash
docs(api): Update API documentation
chore(deps): Bump dependencies
style(client): Format code
refactor(admin): Restructure components
test(api): Add unit tests
ci(release): Update workflow
```

**Result:** No version change, not in changelog

### **Scope Guidelines**

**Always use appropriate scope:**

- `api` - Backend API changes
- `client` - Flutter app changes
- `admin` - Admin panel changes
- `deps` - Dependency updates
- `ci` - CI/CD workflow changes
- `docs` - Documentation updates
- `release` - Release-related changes

**Multiple apps affected?** Make multiple commits:

```bash
feat(api): Add wine endpoints
feat(client): Add wine browsing UI
feat(admin): Add wine management interface
```

### **PR Review Checklist**

When reviewing PRs:

✅ **Commit messages follow conventional format?**

- Type is valid (`feat`, `fix`, etc.)
- Scope is present and correct
- Subject is clear and descriptive

✅ **Correct scopes used?**

- If PR changes API, commits have `(api)` scope
- If PR changes multiple apps, multiple commits with different scopes

✅ **Appropriate version bump?**

- New features use `feat:`
- Bug fixes use `fix:`
- Breaking changes have `BREAKING CHANGE:` footer

## 🔄 Developer Workflow

### **1. Making Changes with Conventional Commits**

```bash
# Create feature branch
git checkout -b feat/add-wine-filtering

# Make changes in apps/api
# ... edit files ...

# Commit with conventional format (validated automatically)
git commit -m "feat(api): Add wine filtering endpoint

Implements regional filtering with fuzzy matching support."

# Git hook validates commit message
# ✅ Valid format - commit succeeds
# ❌ Invalid format - commit rejected, fix and retry

# Push to create PR
git push origin feat/add-wine-filtering
```

### **2. CI Builds Snapshot for QA**

```bash
# PR created → CI workflow runs automatically
1. Detects API changed (only API)
2. Generates snapshot: v0.3.1-pr-123.abc1234
3. Builds API Docker image
4. Pushes to Docker Hub
5. Comments on PR with image tag

# QA can manually deploy snapshot for testing
```

### **3. Merge to Master (Triggers Release)**

```bash
# PR approved and merged to master
# versio workflow runs automatically:
1. Analyzes commits since last release
   - Found: feat(api) → minor bump needed
2. Determines new versions for each app independently:
   - API: 1.0.0 → 1.1.0 (minor bump from feat(api))
   - Client: 1.0.0 → 1.0.0 (no change, no feat/fix commits for client)
   - Admin: 1.0.0 → 1.0.0 (no change, no feat/fix commits for admin)
3. Creates git tags directly:
   - api-v1.1.0
   - client-v1.0.0
   - admin-v1.0.0
4. Updates CHANGELOG.md files with HTML format
5. Tags trigger build workflow automatically
6. All apps built and released
7. Docker images pushed
8. GitHub releases created with artifacts
```

### **Example: Hotfix Workflow**

```bash
# Urgent bug in client only
git checkout -b fix/client-auth-timeout

# Fix the bug
# ... edit apps/client files ...

# Commit with conventional format
git commit -m "fix(client): Resolve authentication timeout

Fixes issue where offline mode caused 401 errors after 30 seconds."

git push origin fix/client-auth-timeout

# PR created → snapshot built (client only)
# PR merged → versio runs automatically:
1. Analyzes commit: fix(client) → patch bump needed
2. Determines new versions for each app independently:
   - API: 1.1.0 → 1.1.0 (no change, no fix commits for api)
   - Client: 1.1.0 → 1.1.1 (patch bump from fix(client))
   - Admin: 1.1.0 → 1.1.0 (no change, no fix commits for admin)
3. Creates tags: api-v1.1.0, client-v1.1.1, admin-v1.1.0
4. Tags trigger build workflow → all apps built
5. GitHub releases created: "API v1.1.0", "Client v1.1.1", "Admin v1.1.0"
```

## 🎭 Prerelease Strategy for QA

### **Snapshot Versions**

**Purpose:** Build and publish every PR commit for manual QA deployment

**Version Format:**

```
Production:  api-v0.4.0, client-v0.4.0, admin-v0.4.0
Prerelease:  0.4.0-pr-123.abc1234  (next version + PR number + short commit SHA)
```

**How It Works:**

```bash
# PR commit triggers CI
commit: abc1234, PR: #123

# CI generates snapshot version using versio
# versio calculates next versions for each app
NEXT_API_VERSION="0.4.0"      # from versio plan
NEXT_CLIENT_VERSION="0.4.0"   # from versio plan
NEXT_ADMIN_VERSION="0.4.0"    # from versio plan

# Use highest next version as base
BASE_VERSION="0.4.0"          # highest of next versions
SNAPSHOT="0.4.0-pr-123.abc1234"

# Builds only changed apps
API changed → docker build alacarte-api:0.4.0-pr-123.abc1234
```

**Docker Tag Strategy:**

```bash
# Per-commit snapshots (unique, traceable)
alacarte-api:0.4.0-pr-123.abc1234
alacarte-client:0.4.0-pr-123.abc1234
alacarte-admin:0.4.0-pr-123.abc1234

# PR convenience tags (latest in PR)
alacarte-api:pr-123-latest

# Production tags (from versio)
alacarte-api:0.4.0
alacarte-api:latest
```

**Automated Cleanup:**

- Keeps stable tags (no `-pr-` suffix)
- Keeps snapshots from same minor version as latest stable release
- Keeps snapshots with higher version than stable release
- Deletes older snapshots from previous minor versions
- Runs manually via workflow dispatch (can be scheduled)

## 📝 Release Notes Strategy

### **Auto-Generated HTML Changelogs Per App**

Each app maintains its own CHANGELOG.md in HTML format, auto-generated from conventional commits by versio.

**Example: API CHANGELOG.md**

```html
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
      /* CSS styles for changelog formatting */
    </style>
  </head>
  <body>
    <div class="release">
      <div class="release-head">1.1.0 (2025-12-02)</div>
      <div class="pr">
        <div class="pr-head">PR #123: Add wine filtering endpoint</div>
        <div class="commit">
          <div>feat(api): Add wine filtering endpoint</div>
          <div>Implements regional filtering with fuzzy matching support.</div>
        </div>
      </div>
    </div>
    <div class="release">
      <div class="release-head">1.0.0 (2025-11-15)</div>
      <div class="pr">
        <div class="pr-head">Initial release</div>
        <div class="commit">
          <div>feat(api): Initial API implementation</div>
          <div>Basic CRUD operations for wines and producers.</div>
        </div>
      </div>
    </div>
  </body>
</html>
```

**Example: Client CHANGELOG.md**

```html
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
      /* CSS styles for changelog formatting */
    </style>
  </head>
  <body>
    <div class="release">
      <div class="release-head">1.1.0 (2025-12-02)</div>
      <div class="pr">
        <div class="pr-head">PR #124: Add wine browsing UI</div>
        <div class="commit">
          <div>feat(client): Add wine browsing UI</div>
          <div>Implements infinite scroll and search functionality.</div>
        </div>
      </div>
    </div>
  </body>
</html>
```

## 🏗️ CI/CD Pipeline

### **Two-Stage Pipeline**

```
┌─────────────────────────────────────────────────────────┐
│  STAGE 1: PR Commits (Snapshots)                      │
│  • Detect changed apps using git diff                 │
│  • Generate snapshot version using versio             │
│  • Build only changed apps                            │
│  • Push Docker images + APK artifacts                 │
│  • Comment on PR with build status                    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  STAGE 2: Master Merge (Production Release)            │
│  • versio analyzes commits                             │
│  • Determines version bumps for each app independently │
│  • Creates git tags directly (api-v*, client-v*, admin-v*)│
│  • Auto-generates HTML CHANGELOGs                      │
│  • Tags trigger build workflow                         │
│  • Build ALL apps                                      │
│  • Push production Docker images                       │
│  • Create GitHub releases with artifacts               │
└─────────────────────────────────────────────────────────┘
```

### **Workflow Files**

```
.github/workflows/
├── pr-snapshot.yml       # Stage 1: Snapshot builds for PRs
├── cleanup-snapshots.yml # Cleanup old snapshot Docker tags
├── version.yml           # Stage 2: Create version tags and update changelogs on master merge
└── release.yml           # Build & release from tags (triggered by version.yml)
```

## 📚 Resources

**versio:**

- [GitHub Repository](https://github.com/versio/versio)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Monorepo Configuration](https://github.com/versio/versio/blob/main/docs/monorepo.md)

**Commitlint:**

- [Official Documentation](https://commitlint.js.org/)
- [Config Conventional](https://github.com/conventional-changelog/commitlint/tree/master/%40commitlint/config-conventional)

**Examples:**

- [À la carte Repository](https://github.com/your-org/alacarte) (current implementation)
- [Angular](https://github.com/angular/angular) (conventional commits)

## 📋 Common Issues & Solutions

### Issue: Commit rejected by git hook

**Problem:** Invalid conventional commit format

**Solution:**

```bash
# Error: "scope may not be empty"
git commit -m "feat: Add feature"  # ❌ No scope
git commit -m "feat(api): Add feature"  # ✅ With scope

# Error: "type must be one of..."
git commit -m "feature(api): Add thing"  # ❌ Invalid type
git commit -m "feat(api): Add thing"  # ✅ Valid type
```

### Issue: Tags not created on master merge

**Problem:** No tags created after merging to master

**Solution:**

- Verify commits follow conventional format
- Check that commits have `feat:` or `fix:` (not just `docs:` or `chore:`)
- Wait a few minutes for versio workflow to run
- Check GitHub Actions tab for errors in `version.yml` workflow
- Check that `.versio.yaml` is correctly configured
- Verify versio has permission to create tags

### Issue: Understanding independent versioning

**Problem:** Confusion about why apps have different version numbers

**Solution:**

- This is **expected behavior** - each app is versioned independently based on its own commit history
- Version bumps are determined by commit types for each app separately
- If you want to keep apps in sync, consider:
  - Making related changes across apps in the same PR with appropriate scopes
  - Using coordinated releases when multiple apps need the same version
  - Understanding that independent versioning accurately reflects each app's change history

### Issue: Git hook not working

**Problem:** Commits not being validated

**Solution:**

```bash
# Reinstall husky
npm install
npx husky install

# Check hook exists and is executable
ls -la .husky/commit-msg
chmod +x .husky/commit-msg
```

## 🔄 Current Implementation Status

### **Active Components**

- ✅ **versio** configured in `.versio.yaml` for automated versioning
- ✅ **GitHub Actions** workflows for CI/CD
- ✅ **Conventional Commits** enforced via commitlint/husky
- ✅ **HTML changelogs** auto-generated by versio
- ✅ **Snapshot builds** for PRs
- ✅ **Production releases** triggered by tags

### **Simplified Workflow**

- **No release PR step** - Tags created directly on master merge by versio
- **Independent versioning** - Each app versioned based on its own commit history
- **Two-stage pipeline** - PR snapshots for QA, production releases on master merge
- **Direct tag creation** - versio runs automatically on master push
- **Conditional builds** - PRs build only changed apps, tags build all apps

### **Tag Naming Convention**

Versio automatically appends `-v` to the configured `tag_prefix` when creating tags. The configured prefixes and resulting tags are:

- **Configured prefix:** `api` → **Tag pattern:** `api-v*` (e.g., `api-v1.1.0`)
- **Configured prefix:** `client` → **Tag pattern:** `client-v*` (e.g., `client-v1.1.0`)
- **Configured prefix:** `admin` → **Tag pattern:** `admin-v*` (e.g., `admin-v1.1.0`)

### **Snapshot Version Format**

- Base version calculated by versio
- Format: `{version}-pr-{pr_number}.{commit_sha}`
- Example: `1.1.0-pr-123.abc1234`

### **Key Changes from Previous Approach**

- ✅ **Simplified workflow** - No release PR step, tags created directly on master merge
- ✅ **Independent versioning** - Each app versioned based on its own commit history
- ✅ **Direct master triggers** - versio runs automatically on master push
- ✅ **HTML changelogs** - Auto-generated changelogs in HTML format
- ✅ **Snapshot builds** - PRs generate preview builds for QA testing

---

**Last reviewed:** January 2026  
**Next review:** After next major version release
