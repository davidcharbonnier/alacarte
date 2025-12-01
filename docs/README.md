# À la carte Documentation

Welcome to the centralized documentation for the À la carte platform.

## 🎯 Quick Navigation

### Getting Started
- [Prerequisites](getting-started/prerequisites.md) - System requirements and tools
- [Quick Start](getting-started/quick-start.md) - Get up and running in 5 minutes
- [Local Development](getting-started/local-development.md) - Complete development setup

### Architecture
- [Overview](architecture/overview.md) - System architecture and design principles
- ⭐ [Monorepo Strategy](architecture/monorepo-strategy.md) - release-please, conventional commits, and release management
- [Tech Stack](architecture/tech-stack.md) - Technologies used across the platform
- [Design Resources](architecture/design-resources.md) - Logo and branding assets

### Features (Cross-App)
- [Authentication](features/authentication.md) - Google OAuth, JWT, and user management
- [Privacy Model](features/privacy-model.md) - Privacy-first rating architecture
- [Rating System](features/rating-system.md) - Polymorphic rating system
- [Sharing System](features/sharing-system.md) - Rating sharing and permissions
- [Filtering System](features/filtering-system.md) - Search and filtering
- [Offline Handling](features/offline-handling.md) - Connectivity management
- [Internationalization](features/internationalization.md) - French/English localization

### Guides
- ⭐ [Adding New Item Types](guides/adding-new-item-types.md) - Complete guide for all 3 apps
- ⭐ [Contributing Guide](guides/contributing.md) - Development workflow and conventional commits
- [Backend Checklist](guides/backend-checklist.md) - Quick reference for API
- [Client Checklist](guides/client-checklist.md) - Quick reference for Flutter
- [Admin Checklist](guides/admin-checklist.md) - Quick reference for Next.js

### Component Documentation

#### API (Backend)
- [API Overview](api/README.md) - REST API documentation
- [Endpoints](api/endpoints.md) - API reference
- [Deployment](api/deployment.md) - Docker and Cloud Run
- [Security](api/security.md) - Security improvements

#### Client (Frontend)
- [Client Overview](client/README.md) - Flutter app documentation
- Setup: [Android](client/setup/android-setup.md) | [OAuth](client/setup/android-oauth-setup.md)
- Architecture: [Router](client/architecture/router-architecture.md) | [Form Strategy](client/architecture/form-strategy-pattern.md)
- Features: [Notifications](client/features/notification-system.md) | [Settings](client/features/settings-system.md)

#### Admin (Panel)
- [Admin Overview](admin/README.md) - Admin panel documentation
- [Deployment](admin/deployment.md) - Deployment guide
- [Backend Requirements](admin/backend-requirements.md) - API requirements
- [Phased Implementation](admin/phased-implementation.md) - Development phases

### Operations
- [CI/CD Setup](operations/ci-cd-setup.md) - GitHub Actions and automation
- [GitHub Secrets](operations/github-secrets.md) - Secrets and variables management
- [Workflows](operations/workflows.md) - Workflow documentation

## 📚 Documentation Philosophy

This documentation is organized by **purpose** rather than by app:

- **Getting Started** - For new developers
- **Architecture** - For understanding system design
- **Features** - For cross-app functionality
- **Guides** - For accomplishing specific tasks
- **Component Docs** - For app-specific details
- **Operations** - For deployment and CI/CD

## 🔍 Finding What You Need

**I want to...**
- Add a new item type → [Complete Guide](guides/adding-new-item-types.md)
- Understand authentication → [Authentication](features/authentication.md)
- Set up local development → [Local Development](getting-started/local-development.md)
- Deploy to production → [API Deployment](api/deployment.md) | [Admin Deployment](admin/deployment.md)
- Understand privacy → [Privacy Model](features/privacy-model.md)
- Add a new feature → Check [Features](features/) for existing patterns
- Understand releases → [Monorepo Strategy](architecture/monorepo-strategy.md)

**I'm a...**
- Backend developer → Start with [API Overview](api/README.md)
- Frontend developer → Start with [Client Overview](client/README.md)
- DevOps engineer → Start with [Operations](operations/)
- New team member → Start with [Getting Started](getting-started/)

## 🤝 Contributing

**[Contributing Guide](guides/contributing.md)** - Required reading for contributors!

Covers:
- Development workflow with conventional commits
- Commit message format (enforced by git hooks)
- PR review checklist
- Code style guidelines
- Bug fix process

**Key points:**
- All commits must follow conventional format
- Scope is required: `feat(api):`, `fix(client):`, etc.
- Commit messages drive automated versioning
- See [Monorepo Strategy](architecture/monorepo-strategy.md) for complete details

### Contributing to Documentation

When adding new documentation:
1. Follow the existing structure (purpose over app)
2. Cross-reference related docs
3. Keep app READMEs as quick references
4. Use markdown best practices
5. Update this navigation when adding new docs

## 📄 License

Private - All Rights Reserved
