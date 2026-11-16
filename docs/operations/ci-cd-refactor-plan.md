## Why

The current CI/CD system lacks intelligent change detection, independent app versioning, and automated PR workflows. This limits development velocity and creates manual overhead for releases and PR reviews. A complete rebuild is needed to support modern monorepo practices with automated versioning, artifact publishing, and PR-based development workflows.

## What Changes

- **BREAKING**: Complete rewrite of GitHub Actions CI/CD workflows from scratch
- Implement intelligent change detection based on file paths (apps/client, apps/admin, apps/api) excluding .md files
- Add independent versioning per application (api, client, admin) with automatic semantic version bumps based on conventional commits
- Build and publish Docker images for API and Admin applications
- Build and publish APK for Client application
- Create GitHub releases for each application version with auto-generated changelogs
- Implement PR workflow that triggers on every commit with development versions (pr-{number}.{increment})
- Run tests for changed applications in PR workflows
- Build and publish all applications when any app changes in a PR
- Update PR comments with download links (APK) and pull commands (Docker images) on each commit
- Replace or augment versio tooling as needed for the new workflow

## Capabilities

### New Capabilities
- `automated-ci-cd-pipeline`: Complete CI/CD system for monorepo with intelligent change detection, independent app versioning, automated builds (Docker images and APK), artifact publishing (GitHub releases and Docker Hub), PR-based development workflows with incremental versioning, automated PR comments with build/download links, and test execution for changed applications

### Modified Capabilities
- None (this is a complete rewrite of CI/CD infrastructure)

## Impact

- **CI/CD Workflows**: Complete replacement of existing GitHub Actions workflows
- **Version Management**: New versioning strategy replacing or augmenting current versio setup
- **Release Process**: Automated GitHub releases replacing manual release process
- **Development Workflow**: New PR-based development workflow with automated builds and comments
- **Tooling**: Potential replacement or augmentation of versio and related tools
- **Developer Experience**: Improved visibility into build status and artifact availability through PR comments
- **Deployment Artifacts**: Consistent, versioned Docker images and APKs available for each release
