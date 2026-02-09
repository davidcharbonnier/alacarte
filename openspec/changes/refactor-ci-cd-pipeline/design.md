## Context

### Current State

The project currently has a functional CI/CD system with three GitHub Actions workflows:

1. **version.yml** - Triggers on master push, uses versio to generate semantic versions based on conventional commits and creates git tags (api-v*, client-v*, admin-v*)
2. **release.yml** - Triggers on version tags, builds Docker images (API, Admin) and APK (Client), publishes to Docker Hub, and creates GitHub releases
3. **pr-snapshot.yml** - Triggers on PR commits, detects changed apps using git diff, builds only changed apps, publishes to Docker Hub with snapshot versions, and updates PR comments

**Note**: versio has been problematic and will be replaced with semantic-release. Docker Hub will be replaced with GitHub Container Registry (GHCR).

### Existing Infrastructure

- **Versioning**: versio tool with conventional commit support (feat→minor, fix→patch, BREAKING→major) - **TO BE REPLACED**
- **Change Detection**: Git-based detection using `git diff --name-only`
- **Docker Builds**: Multi-stage builds with GitHub Actions caching
- **APK Builds**: Flutter with Java 17, keystore signing, and localization generation
- **PR Comments**: Automated PR comments with build status and artifact links
- **Commitlint**: Enforces conventional commits with scopes: api, client, admin, deps, ci, docs, release

**Planned Changes**:
- Replace versio with semantic-release for automated versioning
- Migrate from Docker Hub to GitHub Container Registry (GHCR)
- Use well-maintained, official GitHub Actions where possible

### Constraints

- **Automated Releases**: Strict Conventional Commits required (enforced by commitlint/husky)
- **Multi-platform**: Client targets mobile and web
- **Private License**: All rights reserved
- **Monorepo Structure**: apps/api, apps/client, apps/admin with independent versioning

## Goals / Non-Goals

**Goals:**

1. **Replace versio with semantic-release**: Use semantic-release for automated versioning based on conventional commits
2. **Migrate to GitHub Container Registry**: Replace Docker Hub with GHCR for better rate limits and integration
3. **Use well-maintained GitHub Actions**: Focus on official and popular community actions
4. **Refine PR versioning**: Change from `{base}-pr-{number}.{sha}` to `pr-{number}.{increment}` format for better predictability
5. **Add test execution**: Run tests for changed applications in PR workflows, fail on test failures
6. **Exclude .md files**: Ensure documentation changes don't trigger builds
7. **Build all apps on PR change**: When any app changes, build all three applications (not just changed ones)
8. **Improve changelog generation**: Generate proper changelogs from conventional commits for GitHub releases

**Non-Goals:**

- Keep versio tooling (replacing with semantic-release)
- Keep Docker Hub (migrating to GHCR)
- Change the master branch release workflow (keep existing tag-based releases)
- Modify the Docker build process (current multi-stage builds are optimal)
- Change the APK build process (current setup with keystore signing is correct)
- Add new deployment targets (current Cloud Run deployment is sufficient)
- Enforce test coverage (open for future consideration)

## Decisions

### 1. Replace Versio with Semantic-Release (Versioning & Changelog Only)

**Decision**: Replace versio with semantic-release for automated versioning and changelog generation on master branch. semantic-release will ONLY create git tags and update changelogs - it will NOT build or publish artifacts.

**Rationale**:
- User reported problems with versio
- semantic-release is more widely used and better maintained
- semantic-release has excellent GitHub Actions integration
- Better support for conventional commits and changelog generation
- Active community and long-term viability
- Clean separation of concerns: semantic-release handles versioning, release.yml handles building/publishing
- Tag-based triggering is simpler and more reliable than direct build integration

**Implementation**:
- Use `semantic-release` npm package with GitHub Actions
- Configure separate semantic-release instances for each app (api, client, admin)
- Use `@semantic-release/git` plugin for tagging (creates api-v*, client-v*, admin-v* tags)
- Use `@semantic-release/changelog` plugin for changelog generation
- Configure commit message parsing for conventional commits with scopes
- **IMPORTANT**: semantic-release will NOT build or publish - it only creates tags and changelogs
- release.yml will trigger on these tags to handle building and publishing

**Workflow Separation**:
```
master push → semantic-release (version.yml)
              ↓
              Creates git tags (api-v*, client-v*, admin-v*)
              Generates CHANGELOG.md files
              ↓
              Tag push → release.yml
                        ↓
                        Builds Docker images and APKs
                        Publishes to GHCR
                        Creates GitHub releases with changelog
```

**Alternatives Considered**:
- Keep versio: User reported issues, less maintained
- Custom versioning script: More maintenance, less features
- Manual versioning: Error-prone, not automated
- semantic-release with build integration: Too complex, harder to debug, monolithic workflow

### 2. Use GitHub Container Registry (GHCR)

**Decision**: Migrate from Docker Hub to GitHub Container Registry for Docker image publishing

**Rationale**:
- Better rate limits (unlimited for public repos, higher for private)
- Better integration with GitHub Actions
- Same authentication as GitHub (no separate Docker Hub credentials)
- Better security with GitHub's access controls
- No additional cost for this project's usage

**Implementation**:
- Use `docker/login-action` with `registry: ghcr.io`
- Update Docker image tags to use `ghcr.io/{owner}/{repo}/{app}:{version}`
- Update deployment scripts to pull from GHCR
- Keep Docker Hub as fallback during migration

**Alternatives Considered**:
- Keep Docker Hub: Rate limits, separate credentials, higher cost
- Use both: Unnecessary complexity

### 3. Use Well-Maintained GitHub Actions

**Decision**: Prioritize official GitHub Actions and popular community actions

**Rationale**:
- Better security and maintenance
- More reliable and tested
- Better documentation and community support
- User's explicit requirement

**Actions to Use**:
- `actions/checkout` - Official checkout action
- `actions/setup-go` - Official Go setup
- `actions/setup-node` - Official Node.js setup
- `subosito/flutter-action` - Popular Flutter action
- `docker/login-action` - Official Docker login
- `docker/build-push-action` - Official Docker build/push
- `semantic-release` - Popular automated versioning
- `actions/upload-artifact` - Official artifact upload
- `actions/download-artifact` - Official artifact download

**Alternatives Considered**:
- Custom scripts: More maintenance, less tested
- Less popular actions: Higher risk of abandonment

### 4. PR Version Format: pr-{number}.{increment}

**Decision**: Use `pr-{number}.{increment}` format for PR versions (e.g., pr-12.1, pr-12.2)

**Rationale**:
- Simpler and more predictable than current `{base}-pr-{number}.{sha}` format
- Easier to reference in PR comments and Docker tags
- Increment counter resets per PR, avoiding version conflicts
- Aligns with user's explicit requirement

**Alternatives Considered**:
- `{base}-pr-{number}.{sha}` (current): Too complex, hard to reference
- `pr-{number}` (no increment): Can't distinguish multiple commits in same PR
- `{number}.{increment}` (no prefix): Ambiguous, could conflict with semantic versions

### 5. Build All Apps on Any PR Change

**Decision**: Build all three applications (API, Client, Admin) when any app changes in a PR

**Rationale**:
- Ensures integration testing across all apps
- User's explicit requirement
- Faster feedback for integration issues
- Snapshot builds are low-cost with Docker caching

**Alternatives Considered**:
- Build only changed apps (current): Faster but misses integration issues
- Build all apps always: Wasteful when only docs change

### 6. Test Execution Before Builds (Parallel)

**Decision**: Run tests for changed applications in parallel before building artifacts, fail workflow on test failures

**Rationale**:
- Prevents publishing broken artifacts
- Enforces quality gates
- User's explicit requirement
- Standard practice in CI/CD
- Parallel execution reduces workflow duration

**Test Commands**:
- API: `go test ./...` in `apps/api`
- Client: `flutter test` in `apps/client` (after `flutter gen-l10n`)
- Admin: `npm test` in `apps/admin`

**Alternatives Considered**:
- Run tests in parallel with builds: Faster but publishes broken artifacts
- Run tests after builds: Wastes build time on broken code
- Run tests sequentially: Slower, no benefit
- Skip tests in PRs: Violates quality requirements

### 7. Exclude .md Files from Change Detection

**Decision**: Filter out .md files when detecting changes using git diff

**Rationale**:
- Documentation changes shouldn't trigger builds
- User's explicit requirement
- Reduces unnecessary CI runs
- Current implementation doesn't exclude .md files

**Implementation**:
```bash
CHANGED_FILES=$(git diff --name-only origin/${BASE_REF}...HEAD | grep -v '\.md$')
```

**Alternatives Considered**:
- Include .md files: Wasteful builds for documentation
- Use .gitignore patterns: Too complex for simple exclusion

### 8. PR Version Increment Strategy for Doc-Only Commits

**Decision**: Skip PR workflow entirely if only .md files changed, otherwise increment version counter

**Rationale**:
- Doc-only commits shouldn't trigger builds (main concern)
- Simple commit counting is more reliable than file extension filtering
- Impact of including doc commits in increment counter is minimal (PR versions are temporary)
- Reduces CI load and storage costs
- Allows pushing doc changes in app folders without rebuilding everything

**Implementation**:
```bash
# Check if any non-.md files changed
CODE_CHANGED=$(git diff --name-only origin/${BASE_REF}...HEAD | grep -v '\.md$')

if [ -z "$CODE_CHANGED" ]; then
  echo "Only documentation changed, skipping build"
  exit 0
fi

# Calculate increment based on all commits (simple and reliable)
INCREMENT=$(git rev-list --count origin/${BASE_REF}...HEAD)
```

**Alternatives Considered**:
- Filter by file extensions: Too complex, error-prone, minimal impact
- Use separate counter: More complex state management
- Use workflow run number: Not tied to actual changes
- Skip workflow entirely: Loses PR visibility for doc changes

### 9. PR Comment Update Strategy

**Decision**: Find and update existing PR comment with "📦 Snapshot Build Available" marker

**Rationale**:
- Current implementation already does this correctly
- Prevents comment spam on multiple commits
- User's explicit requirement to update same comment

**Alternatives Considered**:
- Create new comment each time: Spammy, hard to find latest
- Delete and recreate: Loses comment history

### 10. Changelog Generation for GitHub Releases

**Decision**: Use semantic-release to generate changelogs from conventional commits

**Rationale**:
- Automatic changelog from commit messages
- Aligns with conventional commit format
- Better than manual CHANGELOG.md files (which may not exist)
- semantic-release has built-in changelog support
- Only include feat, fix, and BREAKING commits for relevance

**Implementation**:
- Use `@semantic-release/changelog` plugin
- Configure to include only feat, fix, and BREAKING commits
- Generate CHANGELOG.md in each app directory
- Include changelog in GitHub release notes

**Alternatives Considered**:
- Use existing CHANGELOG.md files: May not exist or be outdated
- Manual changelog: Error-prone, not automated
- Custom git log parsing: Reimplementing semantic-release features

## Risks / Trade-offs

### Risk: Increased CI Time for PRs

**Risk**: Building all apps on any change increases PR workflow duration

**Mitigation**:
- Docker layer caching reduces build times significantly
- Tests run in parallel with builds where possible
- Incremental PR versions don't need full semantic version calculation
- Acceptable trade-off for integration testing

### Risk: Test Failures Block All Builds

**Risk**: If one app's tests fail, no artifacts are published for any app

**Mitigation**:
- This is intentional quality gate
- Developers can fix test failures quickly
- Snapshot builds are for testing, not production
- Encourages test maintenance

### Risk: Semantic-Release Learning Curve

**Risk**: Team unfamiliar with semantic-release may struggle with configuration

**Mitigation**:
- semantic-release has excellent documentation
- Start with simple configuration
- Document configuration in `docs/operations/`
- Provide examples in migration plan

### Risk: GHCR Migration Complexity

**Risk**: Migrating from Docker Hub to GHCR requires updating deployment scripts and documentation

**Mitigation**:
- Keep Docker Hub as fallback during migration
- Update deployment scripts incrementally
- Test thoroughly before removing Docker Hub
- Document migration steps

### Risk: Doc-Only Commit Detection False Positives

**Risk**: Complex file pattern matching may miss code changes or incorrectly classify them

**Mitigation**:
- Start with simple pattern (exclude .md only)
- Monitor and adjust patterns based on real usage
- Use git's built-in pathspec matching for reliability
- Log detected changes for debugging

### Risk: GitHub Actions Rate Limits

**Risk**: Using many GitHub Actions may hit API rate limits

**Mitigation**:
- GitHub Actions have generous limits for this project size
- Use caching to reduce API calls
- Monitor usage and optimize if needed

### Risk: Conventional Commit Enforcement

**Risk**: Developers may not follow conventional commit format

**Mitigation**:
- commitlint already enforces this
- husky Git hooks prevent non-conforming commits
- CI will fail on non-conventional commits
- semantic-release will skip non-conforming commits

### Trade-off: Simplicity vs. Flexibility

**Trade-off**: Building all apps on any change is simpler but less efficient

**Rationale**:
- Integration testing benefits outweigh efficiency concerns
- Docker caching mitigates performance impact
- Simplifies workflow logic and reduces complexity

### Trade-off: Tool Replacement vs. Stability

**Trade-off**: Replacing versio and Docker Hub introduces migration risk

**Rationale**:
- User reported problems with versio
- GHCR provides better rate limits and integration
- Long-term benefits outweigh short-term migration effort
- Can rollback if issues arise

## Migration Plan

### Phase 1: Setup Semantic-Release (Versioning & Changelog Only)

1. Install semantic-release and plugins in each app directory
2. Configure `.releaserc` for each app (api, client, admin)
3. Setup GitHub token as repository secret
4. Configure semantic-release to ONLY create tags and generate changelogs (no builds)
5. Test semantic-release configuration on a feature branch
6. Verify that semantic-release creates correct git tags (api-v*, client-v*, admin-v*)
7. Verify that semantic-release generates CHANGELOG.md files
8. Document semantic-release usage in `docs/operations/`

### Phase 2: Migrate to GHCR

1. Update Docker login action to use `ghcr.io`
2. Update Docker image tags in workflows to use `ghcr.io/{owner}/{repo}/{app}:{version}`
3. Update deployment scripts to pull from GHCR
4. Test GHCR builds on a feature branch
5. Keep Docker Hub as fallback during migration

### Phase 3: Modify PR Workflow

1. Update `pr-snapshot.yml` to exclude .md files from change detection
2. Add logic to skip workflow if only .md files changed
3. Add test execution jobs for changed apps before builds (parallel)
4. Modify version generation to use `pr-{number}.{increment}` format
5. Update build conditions to build all apps when any app changes
6. Update Docker registry to GHCR
7. Test on a feature branch

### Phase 4: Update Release Workflow

1. Replace versio with semantic-release in `release.yml`
2. Configure semantic-release to generate changelogs
3. Ensure changelog includes only relevant commit types (feat, fix, BREAKING)
4. Update Docker registry to GHCR
5. Test by creating a test tag

### Phase 5: Update Actions and Cleanup

1. Replace custom scripts with well-maintained GitHub Actions
2. Remove versio configuration files
3. Remove Docker Hub references (after migration complete)
4. Update documentation in `docs/` to reflect new workflow
5. Verify all workflows work correctly
6. Remove old workflows (version.yml, pr-snapshot.yml) after testing

### Rollback Strategy

- Keep old workflows as backups during migration (rename with .old extension)
- Git revert if issues arise
- Document rollback steps in `docs/operations/`
- Keep Docker Hub as fallback during GHCR migration
- Test rollback procedures before full deployment

## Open Questions

1. **PR Increment Counter Implementation**: How to handle version increments for PR builds?
   - **Answer**: Skip PR workflow entirely if only .md files changed. If code changes exist, calculate increment based on all commits (simple and reliable). File extension filtering is too complex and the impact is minimal since PR versions are temporary.

2. **Test Execution Order**: Should tests run sequentially or in parallel?
   - **Answer**: Run in parallel to reduce workflow duration

3. **Snapshot Image Retention**: Is 30 days sufficient for snapshot Docker images?
   - **Answer**: 30 days for unstable artifacts (PR builds), infinite retention for stable artifacts (releases)

4. **Changelog Format**: Should changelogs include all commit types or only feat/fix/BREAKING?
   - **Answer**: Only include feat, fix, and BREAKING for relevance

5. **Test Coverage**: Should we enforce minimum test coverage?
   - **Answer**: Not yet, open for later consideration
