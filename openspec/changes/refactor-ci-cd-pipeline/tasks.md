# Tasks: Refactor CI/CD Pipeline

## 1. DevOps: Setup Semantic-Release

- [ ] 1.1 Install semantic-release and plugins in apps/api (npm install -D semantic-release @semantic-release/git @semantic-release/changelog)
- [ ] 1.2 Install semantic-release and plugins in apps/client (npm install -D semantic-release @semantic-release/git @semantic-release/changelog)
- [ ] 1.3 Install semantic-release and plugins in apps/admin (npm install -D semantic-release @semantic-release/git @semantic-release/changelog)
- [ ] 1.4 Create .releaserc configuration file in apps/api with tag format (api-v${version})
- [ ] 1.5 Create .releaserc configuration file in apps/client with tag format (client-v${version})
- [ ] 1.6 Create .releaserc configuration file in apps/admin with tag format (admin-v${version})
- [ ] 1.7 Configure semantic-release plugins in each .releaserc (@semantic-release/git, @semantic-release/changelog)
- [ ] 1.8 Add GITHUB_TOKEN secret to repository (if not already present) **[manual]**
- [ ] 1.9 Create new version.yml workflow that runs semantic-release on master push
- [ ] 1.10 Configure version.yml to run semantic-release for each app in separate jobs
- [ ] 1.11 Test semantic-release on a feature branch with conventional commits
- [ ] 1.12 Verify semantic-release creates correct git tags (api-v*, client-v*, admin-v*)
- [ ] 1.13 Verify semantic-release generates CHANGELOG.md files in each app directory
- [ ] 1.14 Document semantic-release configuration in docs/operations/ci-cd.md

## 2. DevOps: Migrate to GitHub Container Registry

- [ ] 2.1 Update Docker login action in .github/workflows/release.yml to use ghcr.io
- [ ] 2.2 Update Docker image tags in release.yml to use ghcr.io/{owner}/{repo}/{app}:{version}
- [ ] 2.3 Update Docker image tags in .github/workflows/pr-snapshot.yml to use ghcr.io
- [ ] 2.4 Update deployment scripts to pull Docker images from ghcr.io **[manual]**
- [ ] 2.5 Test GHCR builds on a feature branch **[manual]**
- [ ] 2.6 Verify Docker images are successfully pushed to GHCR **[manual]**

## 3. DevOps: Modify PR Workflow

- [ ] 3.1 Update pr-snapshot.yml to exclude .md files from change detection (grep -v '.md$')
- [ ] 3.2 Add logic to skip workflow if only .md files changed (exit 0)
- [ ] 3.3 Add test execution job for API (go test ./...) before builds
- [ ] 3.4 Add test execution job for Client (flutter gen-l10n && flutter test) before builds
- [ ] 3.5 Add test execution job for Admin (npm test) before builds
- [ ] 3.6 Configure test jobs to run in parallel
- [ ] 3.7 Add workflow failure if any test fails
- [ ] 3.8 Update version generation to use pr-{number}.{increment} format
- [ ] 3.9 Implement increment counter using git rev-list --count
- [ ] 3.10 Update build conditions to build all apps when any app changes
- [ ] 3.11 Update Docker registry references to ghcr.io in pr-snapshot.yml
- [ ] 3.12 Update PR comment template to include ghcr.io pull commands
- [ ] 3.13 Test modified pr-snapshot.yml on a feature branch **[manual]**
- [ ] 3.14 Verify workflow skips when only .md files changed **[manual]**
- [ ] 3.15 Verify workflow builds all apps when any app changes **[manual]**
- [ ] 3.16 Verify tests run in parallel and fail on test failures **[manual]**

## 4. DevOps: Update Release Workflow

- [ ] 4.1 Update release.yml to trigger on semantic-release tags (api-v*, client-v*, admin-v*)
- [ ] 4.2 Remove versio references from release.yml
- [ ] 4.3 Configure release.yml to extract version from git tag
- [ ] 4.4 Update release.yml to generate changelog from git log (feat, fix, BREAKING only)
- [ ] 4.5 Update release.yml to include changelog in GitHub release notes
- [ ] 4.6 Update Docker registry references to ghcr.io in release.yml
- [ ] 4.7 Test release.yml by creating a test tag manually **[manual]**
- [ ] 4.8 Verify GitHub release is created with correct changelog **[manual]**
- [ ] 4.9 Verify Docker images are pushed to ghcr.io **[manual]**
- [ ] 4.10 Verify APK is attached to GitHub release **[manual]**

## 5. DevOps: Update Actions and Cleanup

- [ ] 5.1 Replace any custom scripts with well-maintained GitHub Actions
- [ ] 5.2 Review and update all GitHub Actions to use official or popular community actions
- [ ] 5.3 Remove versio configuration files (.versio.toml, versio.yml, etc.)
- [ ] 5.4 Remove Docker Hub references from all workflows
- [ ] 5.5 Update docs/operations/ci-cd.md with new workflow documentation
- [ ] 5.6 Update AGENTS.md with new CI/CD commands and processes
- [ ] 5.7 Update README.md with new CI/CD information
- [ ] 5.8 Verify all workflows work correctly end-to-end **[manual]**
- [ ] 5.9 Test complete CI/CD pipeline on a feature branch **[manual]**

## 6. Backend: Verify API Tests

- [ ] 6.1 Verify existing API tests work correctly (go test ./...)
- [ ] 6.2 Ensure API tests are properly configured for CI/CD execution
- [ ] 6.3 Run API tests locally to confirm they pass

## 7. Frontend: Verify Client Tests

- [ ] 7.1 Verify existing Client tests work correctly (flutter test)
- [ ] 7.2 Ensure flutter gen-l10n is run before tests in CI/CD
- [ ] 7.3 Run Client tests locally to confirm they pass

## 8. Frontend: Verify Admin Tests

- [ ] 8.1 Verify existing Admin tests work correctly (npm test)
- [ ] 8.2 Ensure Admin tests are properly configured for CI/CD execution
- [ ] 8.3 Run Admin tests locally to confirm they pass

## 9. Documentation: Update Project Documentation

- [ ] 9.1 Create docs/operations/ci-cd.md with comprehensive CI/CD documentation
- [ ] 9.2 Document semantic-release configuration and usage
- [ ] 9.3 Document GHCR migration and usage
- [ ] 9.4 Document PR workflow and versioning strategy
- [ ] 9.5 Document release workflow and changelog generation
- [ ] 9.6 Document troubleshooting steps for common CI/CD issues
- [ ] 9.7 Update AGENTS.md with new CI/CD commands and processes
- [ ] 9.8 Update README.md with new CI/CD information

## 10. Testing: End-to-End CI/CD Validation **[manual]**

- [ ] 10.1 Create feature branch for testing
- [ ] 10.2 Make conventional commits affecting different apps (feat, fix)
- [ ] 10.3 Verify version.yml runs semantic-release and creates tags
- [ ] 10.4 Verify release.yml builds and publishes artifacts on tags
- [ ] 10.5 Create pull request with code changes
- [ ] 10.6 Verify pr-snapshot.yml runs tests in parallel
- [ ] 10.7 Verify pr-snapshot.yml builds all apps
- [ ] 10.8 Verify PR comment is created/updated with correct links
- [ ] 10.9 Test doc-only commit (verify workflow skips)
- [ ] 10.10 Test test failure (verify workflow fails and doesn't publish)
- [ ] 10.11 Merge feature branch to master
- [ ] 10.12 Verify complete CI/CD pipeline runs successfully
- [ ] 10.13 Verify all artifacts are published to ghcr.io
- [ ] 10.14 Verify GitHub releases are created with changelogs
