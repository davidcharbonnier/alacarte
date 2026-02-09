## ADDED Requirements

### Requirement: Change detection by file path
The CI/CD system SHALL detect which applications have changed based on file path patterns, excluding documentation files (.md).

#### Scenario: Detect API changes
- **WHEN** files are modified in the `apps/api/` directory
- **THEN** the system SHALL mark the API application as changed

#### Scenario: Detect Client changes
- **WHEN** files are modified in the `apps/client/` directory
- **THEN** the system SHALL mark the Client application as changed

#### Scenario: Detect Admin changes
- **WHEN** files are modified in the `apps/admin/` directory
- **THEN** the system SHALL mark the Admin application as changed

#### Scenario: Exclude documentation files
- **WHEN** only .md files are modified in any application directory
- **THEN** the system SHALL NOT mark any application as changed

#### Scenario: Detect multiple app changes
- **WHEN** files are modified in both `apps/api/` and `apps/client/` directories
- **THEN** the system SHALL mark both API and Client applications as changed

### Requirement: Independent semantic versioning
The CI/CD system SHALL maintain independent semantic versions for each application (api, client, admin) and automatically bump versions based on conventional commits.

#### Scenario: Bump minor version for feat commits
- **WHEN** a commit with type `feat(api)` is merged to master
- **THEN** the system SHALL increment the API application's minor version (e.g., 0.1.0 → 0.2.0)

#### Scenario: Bump patch version for fix commits
- **WHEN** a commit with type `fix(client)` is merged to master
- **THEN** the system SHALL increment the Client application's patch version (e.g., 0.1.0 → 0.1.1)

#### Scenario: Bump major version for breaking changes
- **WHEN** a commit includes `BREAKING CHANGE:` in the body
- **THEN** the system SHALL increment the affected application's major version (e.g., 0.1.0 → 1.0.0)

#### Scenario: No version bump for other commit types
- **WHEN** a commit with type `docs` or `chore` is merged
- **THEN** the system SHALL NOT increment any application version

#### Scenario: Independent versioning per app
- **WHEN** commits affect different applications (e.g., `feat(api)` and `fix(client)`)
- **THEN** the system SHALL increment each affected application's version independently

### Requirement: Docker image builds
The CI/CD system SHALL build Docker images for API and Admin applications with proper caching and optimization.

#### Scenario: Build API Docker image
- **WHEN** the API application has changed
- **THEN** the system SHALL build a Docker image for the API application

#### Scenario: Build Admin Docker image
- **WHEN** the Admin application has changed
- **THEN** the system SHALL build a Docker image for the Admin application

#### Scenario: Use Docker layer caching
- **WHEN** building Docker images
- **THEN** the system SHALL use Docker layer caching to optimize build times

#### Scenario: Tag Docker images with version
- **WHEN** building a Docker image for version 0.2.1
- **THEN** the system SHALL tag the image with both version (0.2.1) and latest tags

### Requirement: APK builds
The CI/CD system SHALL build APK files for the Client application.

#### Scenario: Build Client APK
- **WHEN** the Client application has changed
- **THEN** the system SHALL build an APK file for the Client application

#### Scenario: Generate localization before build
- **WHEN** building the Client APK
- **THEN** the system SHALL run `flutter gen-l10n` before the build command

#### Scenario: Name APK with version
- **WHEN** building an APK for version 0.1.2
- **THEN** the system SHALL name the APK file to include the version (e.g., alacarte-client-0.1.2.apk)

### Requirement: Artifact publishing
The CI/CD system SHALL publish Docker images to Docker Hub and create GitHub releases with versioned artifacts.

#### Scenario: Publish Docker image to Docker Hub
- **WHEN** a Docker image build completes successfully
- **THEN** the system SHALL publish the image to Docker Hub

#### Scenario: Create GitHub release
- **WHEN** a new application version is released
- **THEN** the system SHALL create a GitHub release for that application version

#### Scenario: Include APK in GitHub release
- **WHEN** creating a GitHub release for the Client application
- **THEN** the system SHALL attach the APK file as a release asset

#### Scenario: Generate changelog for release
- **WHEN** creating a GitHub release
- **THEN** the system SHALL generate a changelog from conventional commits since the previous version

### Requirement: PR workflow with development versions
The CI/CD system SHALL trigger on every PR commit with development versions named pr-{number}.{increment} and build all applications when any app changes.

#### Scenario: Trigger on PR commit
- **WHEN** a commit is pushed to a pull request
- **THEN** the system SHALL trigger the PR workflow

#### Scenario: Generate development version
- **WHEN** the PR workflow runs for PR #12 for the first time
- **THEN** the system SHALL use version pr-12.1

#### Scenario: Increment development version on subsequent commits
- **WHEN** a second commit is pushed to PR #12
- **THEN** the system SHALL use version pr-12.2

#### Scenario: Build all apps when any app changes
- **WHEN** files are modified in any application directory in a PR
- **THEN** the system SHALL build all three applications (API, Client, Admin)

#### Scenario: Tag development artifacts with PR version
- **WHEN** building artifacts for PR #12, commit 3
- **THEN** the system SHALL tag artifacts with version pr-12.3

### Requirement: PR commenting with build links
The CI/CD system SHALL comment on PRs with build status, APK download links, and Docker image pull commands, updating the comment on each commit.

#### Scenario: Create initial PR comment
- **WHEN** the PR workflow completes for the first time
- **THEN** the system SHALL create a comment on the PR with build status and artifact links

#### Scenario: Update existing PR comment
- **WHEN** the PR workflow completes on a subsequent commit
- **THEN** the system SHALL update the existing PR comment with new build status and artifact links

#### Scenario: Include APK download link
- **WHEN** creating or updating a PR comment
- **THEN** the system SHALL include a direct download link to the Client APK

#### Scenario: Include Docker pull commands
- **WHEN** creating or updating a PR comment
- **THEN** the system SHALL include Docker pull commands for API and Admin images

#### Scenario: Show build status in comment
- **WHEN** creating or updating a PR comment
- **THEN** the system SHALL display the build status (success/failure) for each application

### Requirement: Test execution for changed applications
The CI/CD system SHALL run tests for applications that have changed in PR workflows.

#### Scenario: Run tests for changed API
- **WHEN** the API application has changed in a PR
- **THEN** the system SHALL run `go test ./...` in the `apps/api` directory

#### Scenario: Run tests for changed Client
- **WHEN** the Client application has changed in a PR
- **THEN** the system SHALL run `flutter test` in the `apps/client` directory

#### Scenario: Run tests for changed Admin
- **WHEN** the Admin application has changed in a PR
- **THEN** the system SHALL run `npm test` in the `apps/admin` directory

#### Scenario: Fail workflow on test failure
- **WHEN** any test fails
- **THEN** the system SHALL fail the PR workflow and prevent artifact publishing

#### Scenario: Skip tests for unchanged apps
- **WHEN** an application has not changed in a PR
- **THEN** the system SHALL skip running tests for that application
