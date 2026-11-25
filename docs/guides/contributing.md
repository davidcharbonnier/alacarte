# Contributing to À la carte

## 🎯 Overview

This guide covers the development workflow, commit conventions, and contribution guidelines for the À la carte monorepo.

Our monorepo uses automated versioning powered by **semantic-release** and **conventional commits**. There's no manual versioning or changesets: version bumps are derived from your commit messages by `version.yml` (see the known caveats in [ci-cd-setup.md](/docs/operations/ci-cd-setup.md)).

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

⚠️ **IMPORTANT:** All commits MUST follow the [conventional commit format](/docs/guides/contributing.md#-commit-message-convention) with a required scope.

```bash
git add .
git commit -m "feat(api): add wine filtering endpoint"
```

**The commit-msg hook validates your message format only if you enable it** (`git config core.hooksPath .husky`, with `commitlint` available to `npx`; see [Monorepo Strategy](/docs/architecture/monorepo-strategy.md#commitlint---commit-message-validation)). CI does not check commit messages. Always use a scope (commitlint requires one).

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
- `docs` - Documentation changes (patch bump with an `api`/`client` scope)
- `chore` - Maintenance tasks (patch bump with an `api`/`client` scope)
- `revert` - Revert a previous commit
- `refactor` - Code refactoring (patch bump with an `api`/`client` scope)
- `style` - Code style changes (never releases)
- `test` - Adding or updating tests (patch bump with an `api`/`client` scope)
- `build` - Build system changes (patch bump with an `api`/`client` scope)
- `ci` - CI configuration changes (patch bump with an `api`/`client` scope)
- `perf` - Performance improvements (patch bump, both apps, whatever the scope)

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

# Not lower case (commitlint enforces subject-case: lower-case)
feat(api): Add wine filtering endpoint
```

## 🚀 Versioning & Releases

Versioning is driven by your commit messages and automated by `version.yml` (see the known caveats in [ci-cd-setup.md](/docs/operations/ci-cd-setup.md)).

### How It Works

1. **Commits determine version bumps:**
   - `feat(scope)` → minor bump (0.1.0 → 0.2.0)
   - `fix(scope)` → patch bump (0.1.0 → 0.1.1)
   - `BREAKING CHANGE:` → major bump (0.1.0 → 1.0.0)
   - `docs`, `chore`, `refactor`, `test`, `build`, `ci` → patch bump with an `api`/`client` scope; with another scope these types do not release, and `style` never does
   - Scope does not limit `feat`/`fix`/`perf`/breaking changes: they release **both api and client** whatever the scope, because commits matching no `.releaserc` rule fall back to semantic-release's default rules (`@semantic-release/commit-analyzer`). This is from reading the configs: the repo's tags do not confirm it (`api-v2.3.0` has no `client-v2.3.0`), so treat the client bump as expected, not proven

2. **Independent versioning:**
   - api and client are versioned independently and released by `version.yml`, which is meant to be automatic (see the known caveats in [ci-cd-setup.md](/docs/operations/ci-cd-setup.md)); admin tags are pushed manually: `admin-vX.Y.Z`
   - An app is only skipped when no commit since its last tag is releasable for it (see the scope note above)

3. **Automatic tag creation:**
   - When PRs are merged to master, semantic-release is meant to create Git tags (see the known caveats in [ci-cd-setup.md](/docs/operations/ci-cd-setup.md))
   - Tags follow format: `api-v1.2.3`, `client-v1.2.3` (and `admin-v1.2.3`, pushed by hand)

4. **Release automation:**
   - `version.yml` dispatches the release workflow (admin: push an `admin-v*` tag)
   - Docker images are built and pushed
   - GitHub releases are created by `release.yml` for tag-push runs (see the known caveats in [ci-cd-setup.md](/docs/operations/ci-cd-setup.md))

### Example Workflow

```bash
# January 10 - Merge PR with feat(api): add wine filtering endpoint
# Result:
# - api-v1.1.0 (minor bump from feat)
# - client-v1.1.0 (expected to also be minor: feat should release both apps whatever the scope)
# - admin-v1.0.0 (no change: admin is never auto-released)

# January 12 - Merge PR with fix(client): fix authentication bug
# Result:
# - api-v1.1.1 (expected to also be patch: fix should release both apps whatever the scope)
# - client-v1.1.1 (patch bump from fix)
# - admin-v1.0.0 (no change)
```

## 📦 Snapshot Builds

Every PR commit automatically creates snapshot versions for testing:

**Version Format:** `pr-{pr_number}.{increment}`
**Example:** `pr-123.5`

**What Gets Built:**

- ✅ All apps are built whenever any non-`.md` file changes (docs-only PRs skip the build)
- ✅ Docker image for API
- ✅ Static `dist/` bundle for Admin
- ✅ APK artifact for Client

**How to Use:**

1. **Check PR comments** for snapshot version links
2. **Deploy manually to QA** (if needed):
   ```bash
   docker pull ghcr.io/{owner}/{repo}-api:pr-123.5
   ```
3. **Download Client APK** from GitHub Actions artifacts
4. **Test the changes** before merge

**Snapshots are not pruned automatically** — delete old `pr-*` image tags by hand if needed.

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

# After review and merge, version.yml is meant to release it (see the caveats in ci-cd-setup.md)
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

### TypeScript/React (Admin)

- Follow [React best practices](https://react.dev/learn)
- Use TypeScript strictly (no `any`)
- Use MUI v6 components and theme tokens from `src/theme.ts` (no Tailwind)
- Follow existing route/page patterns (TanStack Router file-based routes)

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
- [ ] **Clear subject line** in lower case (commitlint `subject-case`)

## ❓ Getting Help

### Resources

- **Monorepo Strategy:** [architecture/monorepo-strategy.md](../architecture/monorepo-strategy.md)
- **Adding Item Types:** [adding-new-item-types.md](adding-new-item-types.md)
- **Authentication:** [features/authentication.md](../features/authentication.md)

### Common Questions

**Q: What happened to changesets?**
A: We've moved to automated versioning with semantic-release. No manual changesets needed!

**Q: My commit was rejected - what do I do?**
A: Fix the commit message to follow the conventional format with required scope:

```bash
git commit -m "feat(api): add wine filtering endpoint"
```

**Q: Do I need to bump versions manually?**
A: No, versions are derived from your commits by semantic-release (see the known caveats in [ci-cd-setup.md](/docs/operations/ci-cd-setup.md)).

**Q: How do I indicate a breaking change?**
A: Add a `BREAKING CHANGE:` footer to your commit:

```bash
feat(api): redesign authentication system

BREAKING CHANGE: OAuth flow now requires additional redirect_uri parameter
```

---

**Questions?** Open an issue or reach out to the team.
