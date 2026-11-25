# Prerequisites

Before you can run the À la carte project locally, you'll need to install the following tools:

## Required Software

### Node.js
- **Version:** >= 20.x
- **Installation:** [Download Node.js](https://nodejs.org/)
- **Verification:** `node --version`

### Go
- **Version:** >= 1.25 (go.mod requires 1.25.0)
- **Installation:** [Download Go](https://golang.org/dl/)
- **Verification:** `go version`

### Flutter SDK
- **Version:** >= 3.32 (Dart ^3.8.1)
- **Installation:** [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Verification:** `flutter --version`

### Docker & Docker Compose
- **Docker:** [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose:** [Install Docker Compose](https://docs.docker.com/compose/install/) (v2.20 or newer: the root `docker-compose.yml` uses a top-level `include:`)
- **Verification:** `docker --version` and `docker compose version`

### Postgres
- **Version:** 16+
- **Note:** Docker Compose will run Postgres in a container, so no local installation is required

## Google OAuth Setup

The project uses Google OAuth 2.0 for authentication. You'll need to:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Create OAuth 2.0 credentials (Web application type)
4. Add authorized JavaScript origins (no redirect URIs — the apps use the Google Identity Services token flow):
   - `http://localhost:3000` (Admin)
5. Save the Client ID for later use (no client secret needed — tokens are verified by the backend, not exchanged)

## Environment Variables

Each application has its own environment configuration:

- **Admin:** Copy `.env.example` to `.env` (Docker) or `.env.local` (bare Vite) and configure variables
- **API:** Copy `.env.example` to `.env` and configure variables
- **Client:** Copy `.env` from `.env.example` (if available) or create from scratch

See the quick-start guide for detailed setup instructions.

## Next Steps

Once prerequisites are installed:
1. [Quick Start Guide](quick-start.md) - Get running in 5 minutes
2. [Local Development](local-development.md) - Complete development setup
