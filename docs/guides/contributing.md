# Contributing to À la carte

## 🎯 Overview

This guide covers the development workflow, commit conventions, and contribution guidelines for the À la carte monorepo.

Our monorepo uses automated versioning powered by **versio** and **conventional commits**. There's no manual versioning or changesets required - version bumps happen automatically based on your commit messages.

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

⚠️ **IMPORTANT:** All commits MUST follow the [conventional commit format](#commit-message-convention) with a required scope.

```bash
git add .
git commit -m "feat(api): add wine filtering endpoint"
```

**Commit hooks will automatically validate your message format.** Invalid commits will be rejected.

### 4. Push and Create a Pull Request

```bash
git push origin your-branch-name
```

Open a PR on GitHub. CI will automatically build snapshot versions for testing.

## 📝 Commit Message Convention

We use **conventional commits** with **required scopes** to enable automated versioning.

### Format

```
<type>(<scope>): <subject>
```

### Commit Types

- `feat` - New feature (triggers minor version bump)
- `fix` - Bug fix (triggers patch version bump)
- `docs` - Documentation changes (no version bump)
- `chore` - Maintenance tasks (no version bump)
- `refactor` - Code refactoring (no version bump)
- `style` - Code style changes (no version bump)
- `test` - Adding or updating tests (no version bump)
- `build` - Build system changes (no version bump)
- `ci` - CI configuration changes (no version bump)
- `perf` - Performance improvements (no version bump)

### Required Scopes

Every commit MUST include one of these scopes:

- `api` - Backend API changes
- `client` - Flutter app changes
- `admin` - Admin panel changes
- `deps` - Dependency updates
- `ci` - CI/CD workflow changes
- `docs` - Documentation updates
- `release` - Release-related changes

### Breaking Changes

To indicate a breaking change, add a `BREAKING CHANGE:` footer:

```bash
feat(api): redesign authentication system

BREAKING CHANGE: OAuth flow now requires additional redirect_uri parameter
```

Breaking changes trigger major version bumps.

### Examples

✅ **Good commit messages:**

```bash
feat(api): add wine filtering endpoint
fix(client): resolve authentication timeout issue
docs(admin): update deployment guide
chore(deps): bump dependencies
refactor(api): restructure user controller
```

❌ **Invalid commit messages:**

```bash
# Missing scope
feat: add wine filtering endpoint

# Invalid scope
feat(server): add wine filtering endpoint

# Not sentence case
feat(api): Add wine filtering endpoint
```

## 🚀 Versioning & Releases

Versioning is **fully automated** based on your commit messages.

### How It Works

1. **Commits determine version bumps:**
   - `feat(scope)` → minor bump (0.1.0 → 0.2.0)
   - `fix(scope)` → patch bump (0.1.0 → 0.1.1)
   - `BREAKING CHANGE:` → major bump (0.1.0 → 1.0.0)
   - Other types → no version change

2. **Independent versioning:**
   - Each app (api, client, admin) is versioned independently
   - Only apps with relevant commits get version bumps
   - Apps without changes keep their current version

3. **Automatic tag creation:**
   - When PRs are merged to master, versio creates Git tags
   - Tags follow format: `api-v1.2.3`, `client-v1.2.3`, `admin-v1.2.3`

4. **Release automation:**
   - Tags trigger GitHub Actions workflows
   - Docker images are built and pushed
   - GitHub releases are created automatically

### Example Workflow

```bash
# January 10 - Merge PR with feat(api): add wine filtering endpoint
# Result:
# - api-v1.1.0 (minor bump from feat)
# - client-v1.0.0 (no change)
# - admin-v1.0.0 (no change)

# January 12 - Merge PR with fix(client): fix authentication bug
# Result:
# - api-v1.1.0 (no change)
# - client-v1.0.1 (patch bump from fix)
# - admin-v1.0.0 (no change)
```

## 📦 Snapshot Builds

Every PR commit automatically creates snapshot versions for testing:

**Version Format:** `{version}-pr-{pr_number}.{commit_sha}`
**Example:** `1.1.0-pr-123.abc1234`

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

# Commit with conventional format
git add .
git commit -m "fix(client): resolve critical authentication bug"

git push origin fix/critical-auth-bug

# Open PR with "HOTFIX" in title
# Example: "HOTFIX: Fix critical authentication bug"

# After review and merge, automated release happens
```

### Regular Bug Fixes

For non-urgent bugs, follow normal workflow:

- Create feature branch
- Fix bug
- Commit with `fix(scope)` format
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

## 🔍 PR Review Checklist

### Before Requesting Review

- [ ] All tests pass locally
- [ ] Code follows existing patterns and style
- [ ] Documentation updated if needed
- [ ] **Commit messages follow conventional format with required scopes**
- [ ] **Breaking changes clearly documented in commit body**

### For Reviewers

- [ ] **Commit messages follow conventional format**
- [ ] **Appropriate scope used** (api, client, admin, etc.)
- [ ] **Correct commit type** (feat for features, fix for bugs)
- [ ] **Breaking changes properly indicated**
- [ ] **Clear subject line** in sentence case

## ❓ Getting Help

### Resources

- **Monorepo Strategy:** [architecture/monorepo-strategy.md](../architecture/monorepo-strategy.md)
- **Adding Item Types:** [adding-new-item-types.md](adding-new-item-types.md)
- **Authentication:** [features/authentication.md](../features/authentication.md)

### Common Questions

**Q: What happened to changesets?**
A: We've moved to automated versioning with versio. No manual changesets needed!

**Q: My commit was rejected - what do I do?**
A: Fix the commit message to follow the conventional format with required scope:

```bash
git commit -m "feat(api): add wine filtering endpoint"
```

**Q: Do I need to bump versions manually?**
A: No, versio handles all versioning automatically based on your commits.

**Q: How do I indicate a breaking change?**
A: Add a `BREAKING CHANGE:` footer to your commit:

```bash
feat(api): redesign authentication system

BREAKING CHANGE: OAuth flow now requires additional redirect_uri parameter
```

---

**Questions?** Open an issue or reach out to the team.
