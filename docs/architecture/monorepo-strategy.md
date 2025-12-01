# À la carte Monorepo Strategy

## 🎯 Overview

This document defines the versioning strategy, tooling, and release management approach for the À la carte monorepo.

**Last Updated:** October 2025  
**Status:** Active - Using release-please with Conventional Commits

## 📦 Monorepo Structure

```
alacarte/
├── .github/
│   └── workflows/
│       ├── pr-snapshot.yml       # Build & publish snapshots
│       ├── cleanup-snapshots.yml # Automated cleanup
│       ├── release-please.yml    # Create release PRs
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
├── release-please-config.json    # Release automation config
├── .release-please-manifest.json # Current versions
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

### **release-please** - Automated Release Management ⭐

**Purpose:** Fully automated versioning, changelog generation, and release management from conventional commits

**Why chosen:**
- ✅ Google-maintained, production-proven
- ✅ Native monorepo support
- ✅ Automatic version bumps from commit messages
- ✅ Auto-generated changelogs from commits
- ✅ Creates release PRs for review before release
- ✅ Works seamlessly with Git tags
- ✅ Supports independent and synchronized releases
- ✅ Zero manual versioning needed

**Configuration:** (`release-please-config.json`)
```json
{
  "packages": {
    "apps/api": {
      "release-type": "simple",
      "package-name": "api",
      "changelog-path": "CHANGELOG.md"
    },
    "apps/client": {
      "release-type": "simple",
      "package-name": "client",
      "changelog-path": "CHANGELOG.md"
    },
    "apps/admin": {
      "release-type": "simple",
      "package-name": "admin",
      "changelog-path": "CHANGELOG.md"
    }
  },
  "separate-pull-requests": false
}
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
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [2, 'always', ['api', 'client', 'admin', 'deps', 'ci', 'docs', 'release']],
    'scope-empty': [2, 'never'],  // Scope is REQUIRED
    'subject-case': [2, 'always', 'sentence-case']
  }
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
- `release-please.yml` - Creates release PRs from commits
- `release.yml` - Builds and releases from git tags
- `pr-snapshot.yml` - Creates snapshot builds for QA
- `cleanup-snapshots.yml` - Cleans up old snapshots

## 📌 Versioning Strategy

### **Automated Versioning with Synchronized & Independent Releases**

**Approach:**
- Commits in conventional format drive versioning
- release-please analyzes commits and determines version bumps
- Synchronized releases when any app has `feat` or `BREAKING CHANGE`
- Independent patch releases for single-app `fix` commits

**Example Timeline:**
```
v0.4.0 - Synchronized Feature Release (2025-10-15)
├── API: v0.4.0      (had feat commit)
├── Client: v0.4.0   (had feat commit)
└── Admin: v0.4.0    (synced, no changes)

v0.4.x - Independent Patch Releases
├── API: v0.4.1      (fix commit, 2025-10-18)
├── Client: v0.4.2   (fix commit, 2025-10-20)
└── Admin: v0.4.0    (unchanged)

v0.5.0 - Next Feature Release (2025-11-01)
├── API: v0.5.0      (had feat commit)
├── Client: v0.5.0   (synced from 0.4.2)
└── Admin: v0.5.0    (synced from 0.4.0)
```

**Benefits:**
- ✅ Zero manual versioning - fully automated
- ✅ Automatic changelog generation from commits
- ✅ Clear, semantic versioning per component
- ✅ Hotfixes release independently
- ✅ Features coordinate all apps automatically
- ✅ Enforced commit standards via git hooks

**Trade-offs:**
- ⚠️ Requires disciplined commit messages
- ⚠️ Must use correct conventional commit format
- ⚠️ All team members must understand the system

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

### **3. Merge to Master**

```bash
# PR approved and merged to master
# release-please workflow runs:
1. Analyzes commits since last release
   - Found: feat(api) → minor bump needed
2. Determines: API 0.3.1 → 0.4.0
3. Checks if other apps need sync: YES (any feat)
4. Creates/updates "Release PR" with:
   - All apps bumped to 0.4.0
   - Auto-generated CHANGELOGs
   - All pending changes
```

### **4. Review & Merge Release PR**

```bash
# Review Release PR on GitHub
- Check versions look correct
- Review auto-generated changelogs
- Verify all changes are included

# Merge Release PR
# On merge, release-please:
1. Creates git tags: v0.4.0
2. Tags trigger build workflow
3. All apps built (synced release)
4. Docker images pushed
5. Client APK built
6. GitHub release created with artifacts
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
# PR merged → release-please creates Release PR
# Release PR shows: Client 0.4.0 → 0.4.1 (patch, independent)
# Merge Release PR → client-v0.4.1 tag created
# Build workflow runs → only Client APK built
# GitHub release created: "Client v0.4.1"
```

## 🎭 Prerelease Strategy for QA

### **Snapshot Versions**

**Purpose:** Build and publish every PR commit for manual QA deployment

**Version Format:**
```
Production:  v0.4.0
Prerelease:  v0.4.0-pr-123.abc1234  (PR number + short commit SHA)
```

**How It Works:**
```bash
# PR commit triggers CI
commit: abc1234, PR: #123

# CI generates snapshot version
CURRENT_VERSION="0.4.0"
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

# Production tags (from release-please)
alacarte-api:0.4.0
alacarte-api:latest
```

**Automated Cleanup:**
- Keeps snapshots from open PRs
- Keeps snapshots from last merged PR (rollback)
- Deletes all other snapshots
- Runs on PR close + daily at 2 AM UTC

## 📝 Release Notes Strategy

### **Auto-Generated Changelogs Per App**

Each app maintains its own CHANGELOG.md, auto-generated from conventional commits.

**Example: API CHANGELOG.md**
```markdown
# Changelog

## 0.4.0 (2025-10-15)

### Features

* Add wine filtering endpoint ([abc1234](https://github.com/.../commit/abc1234))
* Add terroir field support ([def5678](https://github.com/.../commit/def5678))

### Bug Fixes

* Resolve database connection timeout ([789abcd](https://github.com/.../commit/789abcd))
```

**Example: Client CHANGELOG.md**
```markdown
# Changelog

## 0.4.2 (2025-10-20)

### Bug Fixes

* Resolve authentication timeout ([abc1234](https://github.com/.../commit/abc1234))

## 0.4.0 (2025-10-15)

### Features

* Add wine browsing UI ([def5678](https://github.com/.../commit/def5678))
* Implement offline mode ([789abcd](https://github.com/.../commit/789abcd))
```

## 🏗️ CI/CD Pipeline

### **Three-Stage Pipeline**

```
┌─────────────────────────────────────────────────────────┐
│  STAGE 1: PR Commits (Snapshots)                      │
│  • Detect changed apps                                 │
│  • Generate snapshot version (v0.4.0-pr-123.abc1234)   │
│  • Build only changed apps                             │
│  • Push Docker images + APK artifacts                  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  STAGE 2: Master Merge (Release PR)                   │
│  • release-please analyzes commits                     │
│  • Determines version bumps                            │
│  • Creates/updates Release PR                          │
│  • Auto-generates CHANGELOGs                           │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  STAGE 3: Release PR Merge (Production)               │
│  • Git tags created (v0.4.0, api-v0.4.1, etc.)         │
│  • Tags trigger build workflow                         │
│  • Build changed apps                                  │
│  • Push production Docker images                       │
│  • Create GitHub releases with artifacts               │
└─────────────────────────────────────────────────────────┘
```

### **Workflow Files**

```
.github/workflows/
├── pr-snapshot.yml       # Stage 1: Snapshot builds
├── cleanup-snapshots.yml # Cleanup old snapshots
├── release-please.yml    # Stage 2: Create release PRs
└── release.yml           # Stage 3: Build & release from tags
```

## 📚 Resources

**release-please:**
- [Official Documentation](https://github.com/googleapis/release-please)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Monorepo Configuration](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md)

**Commitlint:**
- [Official Documentation](https://commitlint.js.org/)
- [Config Conventional](https://github.com/conventional-changelog/commitlint/tree/master/%40commitlint/config-conventional)

**Examples:**
- [Google Cloud Client Libraries](https://github.com/googleapis/google-cloud-node) (uses release-please)
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

### Issue: Release PR not created

**Problem:** No commits since last release or no version-worthy commits

**Solution:**
- Verify commits follow conventional format
- Check that commits have `feat:` or `fix:` (not just `docs:` or `chore:`)
- Wait a few minutes for workflow to run
- Check GitHub Actions tab for errors

### Issue: Wrong apps in release

**Problem:** Only API changed but all apps in Release PR

**Solution:**
- This is expected if commit was `feat:` (synchronized release)
- If only patch needed: use `fix:` commit type
- For independent releases: ensure only `fix:` commits, no `feat:`

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

---

**Last reviewed:** October 2025  
**Next review:** After first production release
