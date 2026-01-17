# Prerequisites

Before you can run the À la carte project locally, you'll need to install the following tools:

## Required Software

### Node.js
- **Version:** >= 18.x
- **Installation:** [Download Node.js](https://nodejs.org/)
- **Verification:** `node --version`

### Go
- **Version:** >= 1.21
- **Installation:** [Download Go](https://golang.org/dl/)
- **Verification:** `go version`

### Flutter SDK
- **Version:** >= 3.27
- **Installation:** [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Verification:** `flutter --version`

### Docker & Docker Compose
- **Docker:** [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose:** [Install Docker Compose](https://docs.docker.com/compose/install/)
- **Verification:** `docker --version` and `docker compose version`

### MySQL
- **Version:** 8.0+
- **Note:** Docker Compose will run MySQL in a container, so no local installation is required

## Google OAuth Setup

The project uses Google OAuth 2.0 for authentication. You'll need to:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google+ API
4. Create OAuth 2.0 credentials
5. Add authorized redirect URIs:
   - `http://localhost:3000/api/auth/callback/google` (Admin)
   - `http://localhost:3001/api/auth/callback/google` (Client web)
6. Save the Client ID and Client Secret for later use

## Environment Variables

Each application has its own environment configuration:

- **Admin:** Copy `.env.example` to `.env.local` and configure variables
- **API:** Copy `.env.prod.template` to `.env` and configure variables
- **Client:** Copy `.env` from `.env.example` (if available) or create from scratch

See the quick-start guide for detailed setup instructions.

## Next Steps

Once prerequisites are installed:
1. [Quick Start Guide](quick-start.md) - Get running in 5 minutes
2. [Local Development](local-development.md) - Complete development setup
