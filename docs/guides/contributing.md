# Contributing to A la carte

## 🎯 Overview

This guide covers the development workflow, changeset management, and contribution guidelines for the A la carte monorepo.

## 🔄 Development Workflow

### 1. Create a Feature Branch

```bash
# Create and checkout feature branch
git checkout -b feat/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description
```

**Branch Naming Convention:**
- `feat/` - New features
- `fix/` - Bug fixes
- `refactor/` - Code refactoring
- `docs/` - Documentation changes
- `chore/` - Maintenance tasks

### 2. Make Your Changes

- Edit code in `apps/api`, `apps/client`, or `apps/admin`
- Follow existing code style and patterns
- Add tests if applicable
- Update documentation if needed

### 3. Commit Your Changes

```bash
git add .
git commit -m "feat: add wine support to API"
```

**Commit Message Convention (optional but recommended):**
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code refactoring
- `docs:` - Documentation
- `chore:` - Maintenance

### 4. Create a Changeset

**⚠️ REQUIRED:** Every PR that changes code must include a changeset.

```bash
npx changeset
```

**The CLI will prompt you:**
1. **Which packages changed?** → Select the apps you modified
2. **What type of change?** → Select major, minor, or patch
3. **Summary** → Describe what changed

**Example interaction:**
```bash
$ npx changeset
🦋  Which packages would you like to include?
◉ @alacarte/api
◉ @alacarte/client
◯ @alacarte/admin

🦋  Which packages should have a major bump?
◯ @alacarte/api
◯ @alacarte/client

🦋  Which packages should have a minor bump?
◉ @alacarte/api
◉ @alacarte/client

🦋  Please enter a summary for this change:
Added wine item type support with terroir fields
```

This creates a file in `.changeset/` with a random name:

```markdown
---
"@alacarte/api": minor
"@alacarte/client": minor
---

Added wine item type support with terroir fields
```

**Commit the changeset:**
```bash
git add .changeset/
git commit -m "docs: add changeset"
git push
```

## 📋 Changeset Best Practices

### When to Select Single App

Select **one app only** when the change is isolated:

✅ **Good Examples:**
- Bug fix in client authentication (select: client)
- API performance optimization (select: api)
- Admin UI styling fix (select: admin)
- Refactoring isolated to one app (select: that app)
- Dependency update for one app (select: that app)

**Example changeset:**
```markdown
---
"@alacarte/client": patch
---

Fixed authentication timeout issue in offline mode
```

### When to Select Multiple Apps

Select **multiple apps** when the change spans across them:

✅ **Good Examples:**
- New API endpoint + client UI to use it (select: api, client)
- API response format change + admin update (select: api, admin)
- New feature across all apps (select: api, client, admin)
- Breaking API change + all clients (select: api, client, admin)

**Example changeset:**
```markdown
---
"@alacarte/api": minor
"@alacarte/client": minor
"@alacarte/admin": minor
---

Added wine item type support across all applications
```

### Choosing Version Bump Type

Follow [Semantic Versioning](https://semver.org/):

**Major (x.0.0) - Breaking Changes**
- API endpoint removed or changed incompatibly
- Database schema change requiring migration
- Client feature removal
- Any change that breaks backward compatibility

**Minor (0.x.0) - New Features**
- New API endpoints (backward compatible)
- New client features
- New admin capabilities
- Enhancements that don't break existing functionality

**Patch (0.0.x) - Bug Fixes & Improvements**
- Bug fixes
- Performance improvements
- Refactoring
- Documentation updates
- Dependency updates

### Common Scenarios

#### Scenario 1: Client-Only Bug Fix
```bash
# Changes made to: apps/client/lib/services/auth_service.dart
npx changeset
# Select: client only
# Type: patch
# Summary: "Fixed token refresh logic"
```

#### Scenario 2: New Feature Across API + Client
```bash
# Changes made to:
# - apps/api/controllers/wine_controller.go
# - apps/client/lib/screens/wine_rating_screen.dart
npx changeset
# Select: api, client
# Type: minor
# Summary: "Added wine rating functionality"
```

#### Scenario 3: API Breaking Change
```bash
# Changes made to: apps/api/models/rating.go (removed field)
npx changeset
# Select: api, client, admin (all consumers of the API)
# Type: major
# Summary: "Removed deprecated 'legacy_score' field from rating model"
```

#### Scenario 4: Documentation Only
```markdown
# If ONLY documentation changed (no code changes)
# NO CHANGESET NEEDED
# Just commit and push
git commit -m "docs: update authentication guide"
```

## 🔍 PR Review Checklist

### Before Requesting Review

- [ ] All tests pass locally
- [ ] Code follows existing patterns and style
- [ ] Documentation updated if needed
- [ ] **Changeset created and committed**
- [ ] Commit messages are clear

### For Reviewers

- [ ] **Changeset exists** (required for code changes)
- [ ] **Correct apps selected** in changeset
  - Changed API? → API selected
  - Changed Client? → Client selected
  - Changed Admin? → Admin selected
- [ ] **Correct version bump type**
  - Breaking change? → major
  - New feature? → minor
  - Bug fix? → patch
- [ ] **Clear summary** in changeset
  - Will make sense in CHANGELOG
  - Describes what changed, not how

### Common Review Issues

❌ **Missing Changeset**
```
Comment: "Please add a changeset with `npx changeset`"
```

❌ **Wrong Apps Selected**
```
PR changes: API + Client
Changeset: Only API selected

Comment: "Changeset should include both API and Client"
```

❌ **Wrong Version Type**
```
PR: Removes API endpoint (breaking change)
Changeset: minor bump

Comment: "This is a breaking change, should be major bump"
```

## 🚀 After PR Merge

### What Happens Automatically

1. **Changeset consumed:** PR merge triggers Changesets bot
2. **Versions bumped:** Updates `package.json` in affected apps
3. **CHANGELOG updated:** Adds entry to each app's CHANGELOG.md
4. **Release created:** Creates GitHub release with notes
5. **Deployment triggered:** CI/CD deploys updated apps

### What to Do

**Nothing!** The automation handles everything.

**If something goes wrong:**
- Check GitHub Actions workflow runs
- Check Changesets bot PR (if versions.yml workflow)
- Report issues in #engineering channel (if applicable)

## 📦 Snapshot Builds

Every PR commit automatically creates snapshot versions for testing:

**Version Format:** `2.1.0-pr-123.abc1234`

**What Gets Built:**
- ✅ Only apps that changed (detected automatically)
- ✅ Docker images for API and Admin
- ✅ APK artifact for Client

**How to Use:**

1. **Check PR comments** for snapshot version links
2. **Deploy manually to QA** (if needed):
   ```bash
   gcloud run deploy alacarte-api-qa \
     --image=davidcharbonnier/alacarte-api:pr-123-latest
   ```
3. **Download Client APK** from GitHub Actions artifacts
4. **Test the changes** before merge

**Snapshots are cleaned up automatically** after PR is closed or merged.

## 🐛 Bug Fixes

### Hotfix Workflow

For urgent production bugs:

```bash
# Create hotfix branch from master
git checkout master
git pull
git checkout -b fix/critical-auth-bug

# Make minimal changes to fix the bug
# ... edit code ...

# Create changeset (patch version)
npx changeset
# Select: affected app(s) only
# Type: patch
# Summary: "Fixed critical authentication bug"

# Commit and push
git add .
git commit -m "fix: critical authentication bug"
git push

# Open PR with "HOTFIX" in title
# Example: "HOTFIX: Fix critical authentication bug"

# After review and merge, automated release happens
```

### Regular Bug Fixes

For non-urgent bugs, follow normal workflow:
- Create feature branch
- Fix bug
- Add changeset (patch)
- Normal PR review process

## 🎨 Code Style Guidelines

### General Principles

- Follow existing patterns in the codebase
- Keep code DRY (Don't Repeat Yourself)
- Write self-documenting code
- Add comments for complex logic only
- Prefer readability over cleverness

### Go (API)

- Follow [Effective Go](https://golang.org/doc/effective_go.html)
- Use `gofmt` for formatting
- Use meaningful variable names
- Handle errors explicitly

### Dart/Flutter (Client)

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `dart format` for formatting
- Use Riverpod for state management
- Follow existing widget patterns

### TypeScript/Next.js (Admin)

- Follow [Next.js best practices](https://nextjs.org/docs)
- Use TypeScript strictly (no `any`)
- Use provided UI components
- Follow existing page patterns

## 📚 Documentation

### When to Update Documentation

Update docs when you:
- Add a new feature
- Change existing behavior
- Add a new API endpoint
- Change environment variables
- Update deployment process
- Add or remove dependencies

### Where to Add Documentation

- **General features:** `docs/features/`
- **API-specific:** `docs/api/`
- **Client-specific:** `docs/client/`
- **Admin-specific:** `docs/admin/`
- **Architecture:** `docs/architecture/`
- **Operations:** `docs/operations/`

### Documentation Style

- Use markdown
- Include code examples
- Add screenshots for UI changes
- Keep it concise and actionable
- Link to related documentation

## ❓ Getting Help

### Resources

- **Monorepo Strategy:** [architecture/monorepo-strategy.md](../architecture/monorepo-strategy.md)
- **Adding Item Types:** [adding-new-item-types.md](adding-new-item-types.md)
- **Authentication:** [features/authentication.md](../features/authentication.md)

### Common Questions

**Q: I forgot to create a changeset, what do I do?**
A: Create it after the fact:
```bash
git checkout your-branch
npx changeset
git add .changeset/
git commit -m "docs: add changeset"
git push
```

**Q: I selected the wrong apps in my changeset, how do I fix it?**
A: Delete the changeset file and recreate it:
```bash
rm .changeset/your-changeset-file.md
npx changeset
# Select correct apps
git add .changeset/
git commit -m "docs: fix changeset"
git push
```

**Q: Do I need a changeset for documentation-only changes?**
A: No, only code changes require changesets.

**Q: Should I bump the version in package.json manually?**
A: No, Changesets handles this automatically after PR merge.

**Q: Can I create multiple changesets in one PR?**
A: Yes, but usually one changeset per PR is sufficient. Multiple changesets are useful if you have multiple independent changes in one PR.

---

**Questions?** Open an issue or reach out to the team.
