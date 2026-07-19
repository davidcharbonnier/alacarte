# À la carte Documentation

Welcome to the centralized documentation for the À la carte platform.

## 🎯 Quick Navigation

### Getting Started
- [Prerequisites](getting-started/prerequisites.md) - System requirements and tools
- [Quick Start](getting-started/quick-start.md) - Get up and running in 5 minutes
- [Local Development](getting-started/local-development.md) - Complete development setup

### Architecture
- ⭐ [Monorepo Strategy](architecture/monorepo-strategy.md) - release-please, conventional commits, and release management

### Features (Cross-App)
- [Authentication](features/authentication.md) - Google OAuth, JWT, and user management
- [Privacy Model](features/privacy-model.md) - Privacy-first rating architecture
- [Rating System](features/rating-system.md) - Polymorphic rating system
- [Sharing System](features/sharing-system.md) - Rating sharing and permissions
- [Filtering System](features/filtering-system.md) - Search and filtering
- [Image Upload](features/image-upload.md) - File storage and image handling
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
- [Authentication System](api/authentication-system.md) - OAuth and JWT implementation
- [Endpoints](api/endpoints.md) - API reference
- [Security](api/security.md) - Security improvements
- [Privacy Model](api/privacy-model.md) - API privacy implementation

#### Client (Frontend)
- [Authentication System](client/authentication-system.md) - OAuth and token management
- [Privacy Model](client/privacy-model.md) - Client privacy implementation
- [Cache Management](client/cache-management.md) - Data caching strategies

##### Setup
- [Android Setup](client/setup/android-setup.md) - Android development setup
- [Android OAuth Setup](client/setup/android-oauth-setup.md) - Android OAuth configuration
- [Google OAuth Setup](client/setup/google-oauth-setup.md) - Cross-platform OAuth

##### Architecture
- [Router Architecture](client/architecture/router-architecture.md) - Navigation and routing
- [Form Strategy Pattern](client/architecture/form-strategy-pattern.md) - Form handling patterns
- [Strategy Pattern Refactoring](client/architecture/strategy-pattern-refactoring-summary.md) - Refactoring summary

##### Features
- [Notification System](client/features/notification-system.md) - Push notifications
- [Settings System](client/features/settings-system.md) - User preferences

#### Admin (Panel)
- [Authentication System](admin/authentication-system.md) - Admin OAuth and session management
- [Design System](admin/design-system.md) - UI components and styling
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
- Deploy to production → [Admin Deployment](admin/deployment.md)
- Understand privacy → [Privacy Model](features/privacy-model.md)
- Add a new feature → Check [Features](features/) for existing patterns
- Understand releases → [Monorepo Strategy](architecture/monorepo-strategy.md)
- Set up image upload → [Image Upload](features/image-upload.md)
- Implement caching → [Cache Management](client/cache-management.md)

**I'm a...**
- Backend developer → Start with [API Overview](api/README.md)
- Frontend developer → Start with [Client Authentication](client/authentication-system.md)
- DevOps engineer → Start with [Operations](operations/)
- New team member → Start with [Getting Started](getting-started/)
- Admin panel developer → Start with [Admin Authentication](admin/authentication-system.md)

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
