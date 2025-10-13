# A la carte Monorepo Strategy

## 🎯 Overview

This document defines the versioning strategy, tooling, and release management approach for the A la carte monorepo.

**Last Updated:** January 2025  
**Status:** Active

## 📦 Monorepo Structure

```
alacarte/
├── .github/
│   └── workflows/
│       ├── pr-snapshot.yml       # Build & publish snapshots
│       ├── cleanup-snapshots.yml # Automated cleanup
│       └── release.yml           # Production releases
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
├── .changeset/                   # Changesets configuration
├── docker-compose.yml            # Root orchestration
├── package.json                  # Root package.json for tooling
├── docs/                         # Consolidated documentation
│   ├── architecture/
│   ├── development/
│   └── deployment/
└── README.md                     # Monorepo overview
```

## 🛠️ Tooling Stack

### **Changesets** - Version Management ⭐

**Purpose:** Independent versioning and changelog generation per app

**Why chosen:**
- ✅ Industry standard for monorepo versioning
- ✅ Human-readable changeset files (reviewable in PRs)
- ✅ Supports independent versioning per app
- ✅ Automatic CHANGELOG.md generation
- ✅ GitHub Action available for CI automation
- ✅ Flexible enough to coordinate releases when needed

**Installation:**
```bash
npm install -D @changesets/cli @changesets/changelog-github
npx changeset init
```

**Configuration:** (`.changeset/config.json`)
```json
{
  "changelog": [
    "@changesets/changelog-github",
    { "repo": "davidcharbonnier/alacarte" }
  ],
  "commit": false,
  "fixed": [],
  "linked": [],
  "access": "public",
  "baseBranch": "master",
  "updateInternalDependencies": "patch",
  "ignore": []
}
```

**Key Configuration Notes:**
- `"fixed": []` - Allows independent versioning per app (patches can be released separately)
- `"updateInternalDependencies": "patch"` - Bumps patch versions when dependencies update
- `"baseBranch": "master"` - Main branch for releases

### **GitHub Actions** - Change Detection & Build Orchestration

**Purpose:** Detect which apps changed and build only those apps

**Why chosen:**
- ✅ Native GitHub integration
- ✅ Simple bash scripts with `git diff` for reliable change detection
- ✅ Conditional job execution based on file changes
- ✅ Transparent logic - no black box behavior
- ✅ No external dependencies

**PR Change Detection Pattern:**
```bash
# Get changed files comparing PR branch to base
git fetch origin ${{ github.event.pull_request.base.ref }}
CHANGED_FILES=$(git diff --name-only origin/${{ github.event.pull_request.base.ref }}...HEAD)

# Check if API changed (excluding markdown)
if echo "$CHANGED_FILES" | grep '^apps/api/' | grep -v '\.md

## 📌 Versioning Strategy

### **Independent Versioning with Manual Coordination**

**Approach:**
- Each app versions independently based on its changesets
- Coordinated releases require manually selecting all affected apps
- True semantic versioning per component

**Example Timeline:**
```
v2.1.0 - Coordinated Feature Release (2025-01-15)
├── API: v2.1.0      (selected in changeset)
├── Client: v2.1.0   (selected in changeset)
└── Admin: v2.1.0    (selected in changeset)

v2.1.x - Independent Patch Releases
├── API: v2.1.5      (hotfix, 2025-01-20)
├── Client: v2.1.3   (hotfix, 2025-01-18)
└── Admin: v2.1.1    (hotfix, 2025-01-16)

v2.2.0 - Next Coordinated Feature (2025-02-01)
├── API: v2.2.0      (selected in changeset)
├── Client: v2.2.0   (selected in changeset)
└── Admin: v2.2.0    (selected in changeset)
```

**Benefits:**
- ✅ True semantic versioning per component
- ✅ Hotfixes don't force unnecessary version bumps
- ✅ Clear understanding of what changed per app
- ✅ Flexibility to release independently when needed

**Trade-offs:**
- ⚠️ Requires manual selection of apps in changesets
- ⚠️ Developer must remember to select all apps for coordinated features
- ⚠️ Version numbers may drift between apps over time

## 🎨 Changeset Best Practices

### **When to Select Single App**

Use single-app changesets for:
- **Hotfixes:** Bug fixes that only affect one component
- **Refactoring:** Internal improvements with no external impact
- **Documentation:** Updates to app-specific docs
- **Dependencies:** Updating libraries for one app
- **Performance:** Optimizations isolated to one app

**Example:**
```bash
npx changeset
# Select: client only
# Type: patch
# Summary: "Fixed authentication timeout issue"
```

### **When to Select Multiple Apps**

Use multi-app changesets for:
- **New Features:** Features that span across apps
- **API Changes:** Backend changes requiring frontend updates
- **Breaking Changes:** Changes that affect multiple components
- **Major Releases:** Coordinated version bumps
- **Cross-App Improvements:** Performance or security updates across apps

**Example:**
```bash
npx changeset
# Select: api, client, admin
# Type: minor
# Summary: "Added wine item type support"
```

### **PR Review Checklist**

When reviewing changesets in PRs:

✅ **Correct apps selected?**
- If PR changes multiple apps, changeset should select all affected apps
- If PR changes one app, changeset should select only that app

✅ **Correct version bump type?**
- `major`: Breaking changes
- `minor`: New features (backward compatible)
- `patch`: Bug fixes, refactoring

✅ **Clear summary?**
- Describes what changed
- Will make sense in CHANGELOG.md
- Uses conventional commit style (optional but recommended)

## 🎭 Prerelease Strategy for QA

### **Snapshot Versions**

**Purpose:** Build and publish every PR commit with unique versions for manual QA deployment

**Version Format:**
```
Production:  v2.1.0
Prerelease:  v2.1.0-pr-123.abc1234  (PR number + short commit SHA)
```

**Benefits:**
- ✅ Unique per commit (SHA ensures uniqueness)
- ✅ Traceable to PR and exact commit
- ✅ Doesn't interfere with Changesets production versioning
- ✅ Clearly identifiable as non-production
- ✅ Ready for manual deployment to QA

### **How It Works**

```bash
# PR commit triggers CI
commit: abc1234
branch: feat/add-wine
PR: #123

# CI detects which apps changed
Changed: apps/api, apps/client

# CI generates snapshot version
CURRENT_VERSION="2.1.0"  # from package.json
SNAPSHOT_VERSION="2.1.0-pr-123.abc1234"

# Build only changed apps (conditional GitHub Actions jobs)
if: needs.detect-changes.outputs.api == 'true'
  → docker build -t alacarte-api:2.1.0-pr-123.abc1234 apps/api

if: needs.detect-changes.outputs.client == 'true'
  → flutter build apk (with APP_VERSION=2.1.0-pr-123.abc1234)

# Tag and push Docker images with snapshot version
docker push davidcharbonnier/alacarte-api:2.1.0-pr-123.abc1234
docker push davidcharbonnier/alacarte-api:pr-123-latest

# Comment on PR with available images for manual deployment
```

### **Docker Tag Strategy**

```bash
# Per-commit snapshots (unique, traceable)
alacarte-api:2.1.0-pr-123.abc1234
alacarte-client:2.1.0-pr-123.abc1234
alacarte-admin:2.1.0-pr-123.abc1234

# PR convenience tags (always latest in PR)
alacarte-api:pr-123-latest
alacarte-client:pr-123-latest
alacarte-admin:pr-123-latest

# Production tags (master branch, managed by Changesets)
alacarte-api:2.1.0
alacarte-api:latest
```

### **Manual QA Deployment**

After snapshot images are published, deploy manually:

```bash
# Deploy API to QA
gcloud run deploy alacarte-api-qa \
  --image=davidcharbonnier/alacarte-api:2.1.0-pr-123.abc1234 \
  --region=northamerica-northeast1

# Deploy Admin to QA
gcloud run deploy alacarte-admin-qa \
  --image=davidcharbonnier/alacarte-admin:2.1.0-pr-123.abc1234 \
  --region=northamerica-northeast1

# Download Client APK from GitHub Actions artifacts
# Test locally or distribute to QA team
```

### **Snapshot Lifecycle**

1. **Creation:** Every PR commit generates unique snapshot (only for changed apps)
2. **Publishing:** Docker images pushed to Docker Hub (only changed apps)
3. **Manual Deployment:** QA team deploys as needed
4. **Testing:** QA team tests using deployed versions
5. **Cleanup:** Automated cleanup keeps only active snapshots

### **Automated Cleanup Strategy**

**Retention Policy:**
- ✅ Keep all snapshots from **open PRs** (active development)
- ✅ Keep snapshots from **last merged PR** (rollback capability)
- ❌ Delete all other snapshots (closed/merged PRs older than last merge)

**What Gets Cleaned:**
1. **Docker Hub Tags** - Snapshot image tags (parallel cleanup, independent)
2. **GitHub Releases** - Pre-release entries (must be deleted before git tags)
3. **Git Tags** - Snapshot version tags (deleted after releases)
4. **GitHub Artifacts** - Client APK builds (deleted with releases)

**Cleanup Order (Important!):**
```
Step 1: Docker Hub cleanup (parallel) ─┐
                                        ├─→ Can run independently
Step 2: GitHub Releases cleanup ───────┘
         ↓ (releases reference git tags)
Step 3: Git Tags cleanup
         ↓ (artifacts attached to releases)
Step 4: Artifacts cleanup (if not auto-deleted)
```

**Cleanup Triggers:**
- When a PR is closed (merged or not) - immediate cleanup
- Daily scheduled cleanup at 2 AM UTC (safety net)
- Manual trigger (workflow_dispatch)

**Example Scenario:**
```
Open PRs: #123, #125, #127
Last merged PR: #124

Keep:
✅ All tags/images from PR #123 (open)
✅ All tags/images from PR #125 (open)
✅ All tags/images from PR #127 (open)
✅ All tags/images from PR #124 (last merged - rollback)

Delete:
❌ All tags/images from PR #122 (merged before #124)
❌ All tags/images from PR #120, #121 (old merged PRs)
❌ All tags/images from PR #126 (closed without merge)
```

### **PR Comment Example**

```markdown
## 📦 Snapshot Build Available

**Version:** `v2.1.0-pr-123.abc1234`
**Commit:** abc1234

### Published Images
✅ **API:** `davidcharbonnier/alacarte-api:2.1.0-pr-123.abc1234`
   - Convenience: `davidcharbonnier/alacarte-api:pr-123-latest`

✅ **Client APK:** [Download from artifacts](https://github.com/.../actions/runs/...)

✅ **Admin:** `davidcharbonnier/alacarte-admin:2.1.0-pr-123.abc1234`
   - Convenience: `davidcharbonnier/alacarte-admin:pr-123-latest`
```

## 🔄 Developer Workflow

### **1. Feature Development (Single App)**

```bash
# Create feature branch
git checkout -b fix/client-auth-timeout

# Make changes in apps/client only
# ... edit files ...

# Commit and push
git commit -m "fix: client authentication timeout"
git push

# CI automatically:
# 1. Detects only client changed (dorny/paths-filter)
# 2. Generates snapshot version: v2.1.0-pr-123.abc1234
# 3. Builds only client app
# 4. Uploads Client APK as artifact
# 5. Comments on PR with artifact link

# Create changeset (required before merge)
npx changeset

# Prompts:
# - Which packages changed? (select: client only)
# - What type of change? (select: patch)
# - Summary: "Fixed authentication timeout issue"

# Creates .changeset/random-words.md
git add .changeset/
git commit -m "docs: add changeset"
git push

# Merge PR when ready
```

**Changeset File Example:**
```markdown
---
"@alacarte/client": patch
---

Fixed authentication timeout issue causing 401 errors in offline mode.
```

### **2. Coordinated Feature (Multiple Apps)**

```bash
git checkout -b feat/add-wine-support

# Make changes across apps/api, apps/client, apps/admin
# ... edit files in all three apps ...

# Commit and push
git commit -m "feat: add wine support"
git push

# CI automatically:
# 1. Detects all three apps changed
# 2. Generates snapshot version: v2.1.0-pr-124.def5678
# 3. Builds API, Client, and Admin in parallel
# 4. Pushes Docker images for API and Admin
# 5. Uploads Client APK
# 6. Comments on PR with all artifacts

# Create changeset selecting ALL affected apps
npx changeset

# Prompts:
# - Which packages? (select: api, client, admin)
# - What type? (select: minor for new feature)
# - Summary: "Added wine item type support"

git add .changeset/
git commit -m "docs: add changeset for coordinated release"
git push
```

**Changeset File Example:**
```markdown
---
"@alacarte/api": minor
"@alacarte/client": minor
"@alacarte/admin": minor
---

Added wine item type support across all applications.
Includes wine-specific endpoints, UI screens, and admin management.
```

### **3. CI Validation (Automated)**

When PR is opened:

```bash
# GitHub Action runs:
1. Detect changes (dorny/paths-filter)
2. Build only changed apps (conditional jobs)
3. Generate snapshot version
4. Publish artifacts

# Changesets Action validates:
# - Changeset file exists (enforces changelog entry)
# - Changeset format is valid
# - Version bumps are appropriate
```

### **4. Merge & Release (Automated)**

After PR merge to master:

```bash
# GitHub Action (Changesets Bot):
npx changeset version           # Bumps versions in package.json
                                # Updates CHANGELOG.md files
                                # Deletes consumed changeset files

npx changeset publish           # Creates git tags (api-v2.1.0, etc.)
                                # Triggers deployment workflows

# Deployment workflows:
# Build and deploy only apps with version changes
# Push Docker images with production tags
```

## 📝 Release Notes Strategy

### **Independent Release Notes Per App**

Each app maintains its own CHANGELOG.md with independent version history.

#### **Example: Client Patch Release**

```markdown
# @alacarte/client

## 2.1.3 (2025-01-20)

### Patch Changes

- Fixed authentication timeout issue causing 401 errors in offline mode (#127)
- Improved retry logic for API requests

## 2.1.2 (2025-01-18)

### Patch Changes

- Fixed rating slider UI glitch on Android devices (#125)
```

#### **Example: Coordinated Feature Release**

When a coordinated feature is released, all app CHANGELOGs are updated:

**API CHANGELOG:**
```markdown
## 2.2.0 (2025-02-01)

### Minor Changes

- Added wine item type support with terroir fields (#124)
- New endpoints: GET/POST/PATCH/DELETE /api/wines
```

**Client CHANGELOG:**
```markdown
## 2.2.0 (2025-02-01)

### Minor Changes

- Added wine item type support (#124)
- New wine rating screens with tasting notes
- Updated search filters for wine characteristics
```

**Admin CHANGELOG:**
```markdown
## 2.2.0 (2025-02-01)

### Minor Changes

- Added wine management dashboard (#124)
- CSV import for wine seeding
- Delete impact assessment for wines
```

## 🏗️ CI/CD Pipeline

### **Two-Stage Pipeline**

```
┌─────────────────────────────────────────────────────────┐
│  STAGE 1: PR Commits (Prerelease)                     │
│  • Detect changed apps (dorny/paths-filter)           │
│  • Generate snapshot version (v2.1.0-pr-123.abc1234)   │
│  • Build only changed apps (conditional jobs)          │
│  • Push Docker images to Docker Hub                    │
│  • Comment PR with artifact links                      │
│  • Publish Client APK as GitHub artifact              │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  STAGE 2: Master Merge (Production Release)           │
│  • Changesets bumps versions independently             │
│  • Build apps with version changes                     │
│  • Push production Docker tags                         │
│  • Publish Client APK as GitHub release               │
│  • Create GitHub release with notes per app            │
└─────────────────────────────────────────────────────────┘
```

### **Workflow Files**

```
.github/workflows/
├── pr-snapshot.yml       # Stage 1: Build & publish snapshots on PR commits
├── cleanup-snapshots.yml # Cleanup: Remove old snapshot artifacts
└── release.yml           # Stage 2: Production release from master
```

**Cleanup Workflow Triggers:**
- On PR close (merged or not)
- Daily at 2 AM UTC (safety net)
- Manual trigger (workflow_dispatch)

## 🔍 Change Detection Strategy

### **How GitHub Actions Detects Changes**

Using `dorny/paths-filter@v3` action:

```yaml
- uses: dorny/paths-filter@v3
  id: changes
  with:
    filters: |
      api:
        - 'apps/api/**'
        - '!apps/api/**/*.md'     # Ignore markdown changes
      client:
        - 'apps/client/**'
        - '!apps/client/**/*.md'
      admin:
        - 'apps/admin/**'
        - '!apps/admin/**/*.md'
```

**Output Usage:**
```yaml
build-api:
  needs: detect-changes
  if: needs.detect-changes.outputs.api == 'true'
  # Only runs if API files changed
```

### **CI Build Optimization**

**Before (separate repos):**
- API PR: ~5 min (build API)
- Client PR: ~8 min (build Client)
- Cross-repo change: 2 PRs × 5-8 min = 10-16 min

**After (monorepo with change detection):**
- API-only PR commit: ~5 min (only API builds)
- Client-only PR commit: ~8 min (only Client builds)
- Cross-app PR commit: ~10 min (parallel builds for changed apps)
- Snapshot overhead: +1 min (version generation, Docker push)

### **Build Efficiency Per Commit**

**Per-commit snapshot builds:**
```bash
# Only builds and publishes changed apps
Commit 1: API changes → Build API only (~5 min)
Commit 2: Client changes → Build Client only (~8 min)
Commit 3: All changes → Build all in parallel (~10 min)
```

**Result:** Fast feedback loop with snapshot versions available for manual QA deployment

## ⚠️ Important Notes

### **Docker Hub Token Permissions**

You'll need a Docker Hub token with **DELETE** permissions:

```bash
# In Docker Hub:
1. Go to Account Settings → Security
2. Create new Access Token
3. Ensure "Read, Write, Delete" permissions
4. Add to GitHub Secrets as DOCKERHUB_TOKEN
```

### **Cleanup Order & Dependencies**

```
Docker Hub Cleanup (independent)
         ↓ (can run in parallel)
GitHub Releases Cleanup (sequential - must be first)
         ↓ (releases reference git tags)
Git Tags Cleanup (sequential - after releases)
         ↓ (artifacts may be attached to releases)
Artifacts Cleanup (sequential - safety net)
```

**Why this order matters:**
- **Releases before tags:** Deleting a git tag before its release causes the release to become orphaned
- **Releases before artifacts:** Artifacts attached to releases are auto-deleted when release is deleted
- **Docker parallel:** Docker images are independent and don't reference GitHub entities

### **Failure Handling**

- **Workflow fails if any cleanup job fails** - Ensures visibility of cleanup issues
- **Docker cleanup uses `fail-fast: false`** - One app failure doesn't stop cleanup of other apps
- **Sequential cleanups are strict** - Each step must succeed before proceeding
- **No silent failures** - All errors are surfaced immediately

## 🚀 Migration Checklist

### **Core Setup**
- [x] Install Changesets
- [x] Configure `.changeset/config.json`
- [x] Move existing repos to `apps/` directory structure
- [x] Configure independent versioning (`"fixed": []`)

### **CI/CD Setup**
- [x] Setup GitHub Actions workflows
  - [x] `pr-snapshot.yml` - Build & publish snapshot versions
  - [x] `cleanup-snapshots.yml` - Automated cleanup of old snapshots
  - [x] `release.yml` - Production releases
- [x] Configure Docker Hub credentials in GitHub secrets
- [x] Configure Docker Hub token with delete permissions
- [x] Implement change detection with `dorny/paths-filter`
- [x] Test snapshot build workflow on feature branch
- [x] Test cleanup workflow on closed PR
- [x] Test production release workflow on master

### **Development Workflow**
- [x] Document changeset best practices
- [x] Document manual QA deployment process
- [ ] Train team on changeset workflow (when applicable)
- [ ] Add changeset validation to PR template

### **Future Enhancements (Optional)**
- [ ] Add pre-commit hooks with Husky for changeset validation
- [ ] Setup automated QA deployment (currently manual)
- [ ] Add Renovate Bot for dependency updates
- [ ] Implement commitlint for conventional commits enforcement

## 📚 Resources

**Changesets:**
- [Official Documentation](https://github.com/changesets/changesets)
- [GitHub Action](https://github.com/changesets/action)
- [Independent vs Fixed Versioning](https://github.com/changesets/changesets/blob/main/docs/fixed-packages.md)

**GitHub Actions:**
- [dorny/paths-filter](https://github.com/dorny/paths-filter) - File change detection
- [Conditional Workflows](https://docs.github.com/en/actions/using-jobs/using-conditions-to-control-job-execution)

**Examples:**
- [Vercel's monorepo](https://github.com/vercel/next.js) (uses similar approach)
- [Supabase monorepo](https://github.com/supabase/supabase) (Changesets)

## 📋 Common Issues & Solutions

### Issue: Changeset selected wrong apps

**Problem:** Developer forgot to select all affected apps in changeset

**Solution:**
- Review changeset in PR before merge
- Check which apps changed in PR (use GitHub's "Files changed" tab)
- Verify changeset matches changed apps
- Request changes if mismatch

### Issue: Version numbers drifting

**Problem:** Apps have very different version numbers (e.g., API at 2.5.0, Client at 2.1.3)

**Solution:**
- This is expected with independent versioning
- Version numbers don't need to match
- What matters: semantic versioning is correct per app
- Use CHANGELOG.md to track coordinated releases

### Issue: Forgot to create changeset

**Problem:** PR merged without changeset

**Solution:**
- Create changeset manually after merge
- Run `npx changeset` on master branch
- Commit directly to master (exception)
- Document the change in the changeset
- Consider adding changeset validation to PR checks

### Issue: Workflow runs even with no app changes

**Problem:** PR with only docs/CI changes triggers builds

**Solution:**
- ✅ Fixed: `generate-version` job now has conditional check
- ✅ Only runs if at least one app has changes
- ✅ `no-changes` job provides clear feedback when builds are skipped
- Workflow structure:
  ```yaml
  generate-version:
    needs: detect-changes
    if: |
      needs.detect-changes.outputs.api == 'true' ||
      needs.detect-changes.outputs.client == 'true' ||
      needs.detect-changes.outputs.admin == 'true'
  ```

---

**Last reviewed:** January 2025  
**Next review:** After initial production releases
 > /dev/null; then
  echo "api=true"
else
  echo "api=false"
fi
```

**Release Change Detection Pattern:**
```bash
# Get the version packages commit
VERSION_COMMIT=$(git log -1 --grep="chore: version packages" --format=%H)
CHANGED_FILES=$(git diff-tree --no-commit-id --name-only -r $VERSION_COMMIT)

# Check if CHANGELOG was updated (indicates version bump)
if echo "$CHANGED_FILES" | grep -q "apps/api/CHANGELOG.md"; then
  echo "api_changed=true"
else
  echo "api_changed=false"
fi
```

**Conditional Builds:**
```yaml
build-api:
  needs: detect-changes
  if: needs.detect-changes.outputs.api == 'true'
  # Only runs if API files changed
```

## 📌 Versioning Strategy

### **Independent Versioning with Manual Coordination**

**Approach:**
- Each app versions independently based on its changesets
- Coordinated releases require manually selecting all affected apps
- True semantic versioning per component

**Example Timeline:**
```
v2.1.0 - Coordinated Feature Release (2025-01-15)
├── API: v2.1.0      (selected in changeset)
├── Client: v2.1.0   (selected in changeset)
└── Admin: v2.1.0    (selected in changeset)

v2.1.x - Independent Patch Releases
├── API: v2.1.5      (hotfix, 2025-01-20)
├── Client: v2.1.3   (hotfix, 2025-01-18)
└── Admin: v2.1.1    (hotfix, 2025-01-16)

v2.2.0 - Next Coordinated Feature (2025-02-01)
├── API: v2.2.0      (selected in changeset)
├── Client: v2.2.0   (selected in changeset)
└── Admin: v2.2.0    (selected in changeset)
```

**Benefits:**
- ✅ True semantic versioning per component
- ✅ Hotfixes don't force unnecessary version bumps
- ✅ Clear understanding of what changed per app
- ✅ Flexibility to release independently when needed

**Trade-offs:**
- ⚠️ Requires manual selection of apps in changesets
- ⚠️ Developer must remember to select all apps for coordinated features
- ⚠️ Version numbers may drift between apps over time

## 🎨 Changeset Best Practices

### **When to Select Single App**

Use single-app changesets for:
- **Hotfixes:** Bug fixes that only affect one component
- **Refactoring:** Internal improvements with no external impact
- **Documentation:** Updates to app-specific docs
- **Dependencies:** Updating libraries for one app
- **Performance:** Optimizations isolated to one app

**Example:**
```bash
npx changeset
# Select: client only
# Type: patch
# Summary: "Fixed authentication timeout issue"
```

### **When to Select Multiple Apps**

Use multi-app changesets for:
- **New Features:** Features that span across apps
- **API Changes:** Backend changes requiring frontend updates
- **Breaking Changes:** Changes that affect multiple components
- **Major Releases:** Coordinated version bumps
- **Cross-App Improvements:** Performance or security updates across apps

**Example:**
```bash
npx changeset
# Select: api, client, admin
# Type: minor
# Summary: "Added wine item type support"
```

### **PR Review Checklist**

When reviewing changesets in PRs:

✅ **Correct apps selected?**
- If PR changes multiple apps, changeset should select all affected apps
- If PR changes one app, changeset should select only that app

✅ **Correct version bump type?**
- `major`: Breaking changes
- `minor`: New features (backward compatible)
- `patch`: Bug fixes, refactoring

✅ **Clear summary?**
- Describes what changed
- Will make sense in CHANGELOG.md
- Uses conventional commit style (optional but recommended)

## 🎭 Prerelease Strategy for QA

### **Snapshot Versions**

**Purpose:** Build and publish every PR commit with unique versions for manual QA deployment

**Version Format:**
```
Production:  v2.1.0
Prerelease:  v2.1.0-pr-123.abc1234  (PR number + short commit SHA)
```

**Benefits:**
- ✅ Unique per commit (SHA ensures uniqueness)
- ✅ Traceable to PR and exact commit
- ✅ Doesn't interfere with Changesets production versioning
- ✅ Clearly identifiable as non-production
- ✅ Ready for manual deployment to QA

### **How It Works**

```bash
# PR commit triggers CI
commit: abc1234
branch: feat/add-wine
PR: #123

# CI detects which apps changed
Changed: apps/api, apps/client

# CI generates snapshot version
CURRENT_VERSION="2.1.0"  # from package.json
SNAPSHOT_VERSION="2.1.0-pr-123.abc1234"

# Build only changed apps (conditional GitHub Actions jobs)
if: needs.detect-changes.outputs.api == 'true'
  → docker build -t alacarte-api:2.1.0-pr-123.abc1234 apps/api

if: needs.detect-changes.outputs.client == 'true'
  → flutter build apk (with APP_VERSION=2.1.0-pr-123.abc1234)

# Tag and push Docker images with snapshot version
docker push davidcharbonnier/alacarte-api:2.1.0-pr-123.abc1234
docker push davidcharbonnier/alacarte-api:pr-123-latest

# Comment on PR with available images for manual deployment
```

### **Docker Tag Strategy**

```bash
# Per-commit snapshots (unique, traceable)
alacarte-api:2.1.0-pr-123.abc1234
alacarte-client:2.1.0-pr-123.abc1234
alacarte-admin:2.1.0-pr-123.abc1234

# PR convenience tags (always latest in PR)
alacarte-api:pr-123-latest
alacarte-client:pr-123-latest
alacarte-admin:pr-123-latest

# Production tags (master branch, managed by Changesets)
alacarte-api:2.1.0
alacarte-api:latest
```

### **Manual QA Deployment**

After snapshot images are published, deploy manually:

```bash
# Deploy API to QA
gcloud run deploy alacarte-api-qa \
  --image=davidcharbonnier/alacarte-api:2.1.0-pr-123.abc1234 \
  --region=northamerica-northeast1

# Deploy Admin to QA
gcloud run deploy alacarte-admin-qa \
  --image=davidcharbonnier/alacarte-admin:2.1.0-pr-123.abc1234 \
  --region=northamerica-northeast1

# Download Client APK from GitHub Actions artifacts
# Test locally or distribute to QA team
```

### **Snapshot Lifecycle**

1. **Creation:** Every PR commit generates unique snapshot (only for changed apps)
2. **Publishing:** Docker images pushed to Docker Hub (only changed apps)
3. **Manual Deployment:** QA team deploys as needed
4. **Testing:** QA team tests using deployed versions
5. **Cleanup:** Automated cleanup keeps only active snapshots

### **Automated Cleanup Strategy**

**Retention Policy:**
- ✅ Keep all snapshots from **open PRs** (active development)
- ✅ Keep snapshots from **last merged PR** (rollback capability)
- ❌ Delete all other snapshots (closed/merged PRs older than last merge)

**What Gets Cleaned:**
1. **Docker Hub Tags** - Snapshot image tags (parallel cleanup, independent)
2. **GitHub Releases** - Pre-release entries (must be deleted before git tags)
3. **Git Tags** - Snapshot version tags (deleted after releases)
4. **GitHub Artifacts** - Client APK builds (deleted with releases)

**Cleanup Order (Important!):**
```
Step 1: Docker Hub cleanup (parallel) ─┐
                                        ├─→ Can run independently
Step 2: GitHub Releases cleanup ───────┘
         ↓ (releases reference git tags)
Step 3: Git Tags cleanup
         ↓ (artifacts attached to releases)
Step 4: Artifacts cleanup (if not auto-deleted)
```

**Cleanup Triggers:**
- When a PR is closed (merged or not) - immediate cleanup
- Daily scheduled cleanup at 2 AM UTC (safety net)
- Manual trigger (workflow_dispatch)

**Example Scenario:**
```
Open PRs: #123, #125, #127
Last merged PR: #124

Keep:
✅ All tags/images from PR #123 (open)
✅ All tags/images from PR #125 (open)
✅ All tags/images from PR #127 (open)
✅ All tags/images from PR #124 (last merged - rollback)

Delete:
❌ All tags/images from PR #122 (merged before #124)
❌ All tags/images from PR #120, #121 (old merged PRs)
❌ All tags/images from PR #126 (closed without merge)
```

### **PR Comment Example**

```markdown
## 📦 Snapshot Build Available

**Version:** `v2.1.0-pr-123.abc1234`
**Commit:** abc1234

### Published Images
✅ **API:** `davidcharbonnier/alacarte-api:2.1.0-pr-123.abc1234`
   - Convenience: `davidcharbonnier/alacarte-api:pr-123-latest`

✅ **Client APK:** [Download from artifacts](https://github.com/.../actions/runs/...)

✅ **Admin:** `davidcharbonnier/alacarte-admin:2.1.0-pr-123.abc1234`
   - Convenience: `davidcharbonnier/alacarte-admin:pr-123-latest`
```

## 🔄 Developer Workflow

### **1. Feature Development (Single App)**

```bash
# Create feature branch
git checkout -b fix/client-auth-timeout

# Make changes in apps/client only
# ... edit files ...

# Commit and push
git commit -m "fix: client authentication timeout"
git push

# CI automatically:
# 1. Detects only client changed (dorny/paths-filter)
# 2. Generates snapshot version: v2.1.0-pr-123.abc1234
# 3. Builds only client app
# 4. Uploads Client APK as artifact
# 5. Comments on PR with artifact link

# Create changeset (required before merge)
npx changeset

# Prompts:
# - Which packages changed? (select: client only)
# - What type of change? (select: patch)
# - Summary: "Fixed authentication timeout issue"

# Creates .changeset/random-words.md
git add .changeset/
git commit -m "docs: add changeset"
git push

# Merge PR when ready
```

**Changeset File Example:**
```markdown
---
"@alacarte/client": patch
---

Fixed authentication timeout issue causing 401 errors in offline mode.
```

### **2. Coordinated Feature (Multiple Apps)**

```bash
git checkout -b feat/add-wine-support

# Make changes across apps/api, apps/client, apps/admin
# ... edit files in all three apps ...

# Commit and push
git commit -m "feat: add wine support"
git push

# CI automatically:
# 1. Detects all three apps changed
# 2. Generates snapshot version: v2.1.0-pr-124.def5678
# 3. Builds API, Client, and Admin in parallel
# 4. Pushes Docker images for API and Admin
# 5. Uploads Client APK
# 6. Comments on PR with all artifacts

# Create changeset selecting ALL affected apps
npx changeset

# Prompts:
# - Which packages? (select: api, client, admin)
# - What type? (select: minor for new feature)
# - Summary: "Added wine item type support"

git add .changeset/
git commit -m "docs: add changeset for coordinated release"
git push
```

**Changeset File Example:**
```markdown
---
"@alacarte/api": minor
"@alacarte/client": minor
"@alacarte/admin": minor
---

Added wine item type support across all applications.
Includes wine-specific endpoints, UI screens, and admin management.
```

### **3. CI Validation (Automated)**

When PR is opened:

```bash
# GitHub Action runs:
1. Detect changes (dorny/paths-filter)
2. Build only changed apps (conditional jobs)
3. Generate snapshot version
4. Publish artifacts

# Changesets Action validates:
# - Changeset file exists (enforces changelog entry)
# - Changeset format is valid
# - Version bumps are appropriate
```

### **4. Merge & Release (Automated)**

After PR merge to master:

```bash
# GitHub Action (Changesets Bot):
npx changeset version           # Bumps versions in package.json
                                # Updates CHANGELOG.md files
                                # Deletes consumed changeset files

npx changeset publish           # Creates git tags (api-v2.1.0, etc.)
                                # Triggers deployment workflows

# Deployment workflows:
# Build and deploy only apps with version changes
# Push Docker images with production tags
```

## 📝 Release Notes Strategy

### **Independent Release Notes Per App**

Each app maintains its own CHANGELOG.md with independent version history.

#### **Example: Client Patch Release**

```markdown
# @alacarte/client

## 2.1.3 (2025-01-20)

### Patch Changes

- Fixed authentication timeout issue causing 401 errors in offline mode (#127)
- Improved retry logic for API requests

## 2.1.2 (2025-01-18)

### Patch Changes

- Fixed rating slider UI glitch on Android devices (#125)
```

#### **Example: Coordinated Feature Release**

When a coordinated feature is released, all app CHANGELOGs are updated:

**API CHANGELOG:**
```markdown
## 2.2.0 (2025-02-01)

### Minor Changes

- Added wine item type support with terroir fields (#124)
- New endpoints: GET/POST/PATCH/DELETE /api/wines
```

**Client CHANGELOG:**
```markdown
## 2.2.0 (2025-02-01)

### Minor Changes

- Added wine item type support (#124)
- New wine rating screens with tasting notes
- Updated search filters for wine characteristics
```

**Admin CHANGELOG:**
```markdown
## 2.2.0 (2025-02-01)

### Minor Changes

- Added wine management dashboard (#124)
- CSV import for wine seeding
- Delete impact assessment for wines
```

## 🏗️ CI/CD Pipeline

### **Two-Stage Pipeline**

```
┌─────────────────────────────────────────────────────────┐
│  STAGE 1: PR Commits (Prerelease)                     │
│  • Detect changed apps (dorny/paths-filter)           │
│  • Generate snapshot version (v2.1.0-pr-123.abc1234)   │
│  • Build only changed apps (conditional jobs)          │
│  • Push Docker images to Docker Hub                    │
│  • Comment PR with artifact links                      │
│  • Publish Client APK as GitHub artifact              │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  STAGE 2: Master Merge (Production Release)           │
│  • Changesets bumps versions independently             │
│  • Build apps with version changes                     │
│  • Push production Docker tags                         │
│  • Publish Client APK as GitHub release               │
│  • Create GitHub release with notes per app            │
└─────────────────────────────────────────────────────────┘
```

### **Workflow Files**

```
.github/workflows/
├── pr-snapshot.yml       # Stage 1: Build & publish snapshots on PR commits
├── cleanup-snapshots.yml # Cleanup: Remove old snapshot artifacts
└── release.yml           # Stage 2: Production release from master
```

**Cleanup Workflow Triggers:**
- On PR close (merged or not)
- Daily at 2 AM UTC (safety net)
- Manual trigger (workflow_dispatch)

## 🔍 Change Detection Strategy

### **How GitHub Actions Detects Changes**

Using `dorny/paths-filter@v3` action:

```yaml
- uses: dorny/paths-filter@v3
  id: changes
  with:
    filters: |
      api:
        - 'apps/api/**'
        - '!apps/api/**/*.md'     # Ignore markdown changes
      client:
        - 'apps/client/**'
        - '!apps/client/**/*.md'
      admin:
        - 'apps/admin/**'
        - '!apps/admin/**/*.md'
```

**Output Usage:**
```yaml
build-api:
  needs: detect-changes
  if: needs.detect-changes.outputs.api == 'true'
  # Only runs if API files changed
```

### **CI Build Optimization**

**Before (separate repos):**
- API PR: ~5 min (build API)
- Client PR: ~8 min (build Client)
- Cross-repo change: 2 PRs × 5-8 min = 10-16 min

**After (monorepo with change detection):**
- API-only PR commit: ~5 min (only API builds)
- Client-only PR commit: ~8 min (only Client builds)
- Cross-app PR commit: ~10 min (parallel builds for changed apps)
- Snapshot overhead: +1 min (version generation, Docker push)

### **Build Efficiency Per Commit**

**Per-commit snapshot builds:**
```bash
# Only builds and publishes changed apps
Commit 1: API changes → Build API only (~5 min)
Commit 2: Client changes → Build Client only (~8 min)
Commit 3: All changes → Build all in parallel (~10 min)
```

**Result:** Fast feedback loop with snapshot versions available for manual QA deployment

## ⚠️ Important Notes

### **Docker Hub Token Permissions**

You'll need a Docker Hub token with **DELETE** permissions:

```bash
# In Docker Hub:
1. Go to Account Settings → Security
2. Create new Access Token
3. Ensure "Read, Write, Delete" permissions
4. Add to GitHub Secrets as DOCKERHUB_TOKEN
```

### **Cleanup Order & Dependencies**

```
Docker Hub Cleanup (independent)
         ↓ (can run in parallel)
GitHub Releases Cleanup (sequential - must be first)
         ↓ (releases reference git tags)
Git Tags Cleanup (sequential - after releases)
         ↓ (artifacts may be attached to releases)
Artifacts Cleanup (sequential - safety net)
```

**Why this order matters:**
- **Releases before tags:** Deleting a git tag before its release causes the release to become orphaned
- **Releases before artifacts:** Artifacts attached to releases are auto-deleted when release is deleted
- **Docker parallel:** Docker images are independent and don't reference GitHub entities

### **Failure Handling**

- **Workflow fails if any cleanup job fails** - Ensures visibility of cleanup issues
- **Docker cleanup uses `fail-fast: false`** - One app failure doesn't stop cleanup of other apps
- **Sequential cleanups are strict** - Each step must succeed before proceeding
- **No silent failures** - All errors are surfaced immediately

## 🚀 Migration Checklist

### **Core Setup**
- [x] Install Changesets
- [x] Configure `.changeset/config.json`
- [x] Move existing repos to `apps/` directory structure
- [x] Configure independent versioning (`"fixed": []`)

### **CI/CD Setup**
- [x] Setup GitHub Actions workflows
  - [x] `pr-snapshot.yml` - Build & publish snapshot versions
  - [x] `cleanup-snapshots.yml` - Automated cleanup of old snapshots
  - [x] `release.yml` - Production releases
- [x] Configure Docker Hub credentials in GitHub secrets
- [x] Configure Docker Hub token with delete permissions
- [x] Implement change detection with `dorny/paths-filter`
- [x] Test snapshot build workflow on feature branch
- [x] Test cleanup workflow on closed PR
- [x] Test production release workflow on master

### **Development Workflow**
- [x] Document changeset best practices
- [x] Document manual QA deployment process
- [ ] Train team on changeset workflow (when applicable)
- [ ] Add changeset validation to PR template

### **Future Enhancements (Optional)**
- [ ] Add pre-commit hooks with Husky for changeset validation
- [ ] Setup automated QA deployment (currently manual)
- [ ] Add Renovate Bot for dependency updates
- [ ] Implement commitlint for conventional commits enforcement

## 📚 Resources

**Changesets:**
- [Official Documentation](https://github.com/changesets/changesets)
- [GitHub Action](https://github.com/changesets/action)
- [Independent vs Fixed Versioning](https://github.com/changesets/changesets/blob/main/docs/fixed-packages.md)

**GitHub Actions:**
- [dorny/paths-filter](https://github.com/dorny/paths-filter) - File change detection
- [Conditional Workflows](https://docs.github.com/en/actions/using-jobs/using-conditions-to-control-job-execution)

**Examples:**
- [Vercel's monorepo](https://github.com/vercel/next.js) (uses similar approach)
- [Supabase monorepo](https://github.com/supabase/supabase) (Changesets)

## 📋 Common Issues & Solutions

### Issue: Changeset selected wrong apps

**Problem:** Developer forgot to select all affected apps in changeset

**Solution:**
- Review changeset in PR before merge
- Check which apps changed in PR (use GitHub's "Files changed" tab)
- Verify changeset matches changed apps
- Request changes if mismatch

### Issue: Version numbers drifting

**Problem:** Apps have very different version numbers (e.g., API at 2.5.0, Client at 2.1.3)

**Solution:**
- This is expected with independent versioning
- Version numbers don't need to match
- What matters: semantic versioning is correct per app
- Use CHANGELOG.md to track coordinated releases

### Issue: Forgot to create changeset

**Problem:** PR merged without changeset

**Solution:**
- Create changeset manually after merge
- Run `npx changeset` on master branch
- Commit directly to master (exception)
- Document the change in the changeset
- Consider adding changeset validation to PR checks

### Issue: Workflow runs even with no app changes

**Problem:** PR with only docs/CI changes triggers builds

**Solution:**
- ✅ Fixed: `generate-version` job now has conditional check
- ✅ Only runs if at least one app has changes
- ✅ `no-changes` job provides clear feedback when builds are skipped
- Workflow structure:
  ```yaml
  generate-version:
    needs: detect-changes
    if: |
      needs.detect-changes.outputs.api == 'true' ||
      needs.detect-changes.outputs.client == 'true' ||
      needs.detect-changes.outputs.admin == 'true'
  ```

---

**Last reviewed:** January 2025  
**Next review:** After initial production releases
