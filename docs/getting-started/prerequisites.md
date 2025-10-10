# Prerequisites

## System Requirements

### Required Tools
- **Node.js:** >= 18.0.0
- **Go:** >= 1.21
- **Flutter SDK:** >= 3.27
- **Docker & Docker Compose:** Latest stable
- **MySQL:** 8.0+ (or via Docker)

### Development Tools
- **VS Code** or your preferred IDE
- **Postman** or curl for API testing
- **Git** for version control

### Cloud Accounts (for deployment)
- Google Cloud account (for Cloud Run, Cloud SQL)
- Docker Hub account (for container registry)
- GitHub account (for CI/CD)

### Google OAuth Setup
- Google Cloud Console project
- OAuth 2.0 credentials (Web + Android clients)
- See [Authentication](/docs/features/authentication.md) for complete setup

## Installation

### Node.js & npm
```bash
# Install via nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18
```

### Go
```bash
# Download from https://golang.org/dl/
# Or via package manager:
brew install go  # macOS
sudo apt install golang-go  # Linux
```

### Flutter
```bash
# Download from https://docs.flutter.dev/get-started/install
# Add to PATH and run:
flutter doctor
```

### Docker
```bash
# Install Docker Desktop
# Download from https://www.docker.com/products/docker-desktop

# Verify installation
docker --version
docker-compose --version
```

## Next Steps

Once prerequisites are installed:
1. [Quick Start Guide](quick-start.md) - Get running in 5 minutes
2. [Local Development](local-development.md) - Complete development setup
