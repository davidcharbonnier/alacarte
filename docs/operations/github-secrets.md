# GitHub Secrets and Variables Configuration

This document lists all required secrets and variables for the CI/CD workflows.

## 📋 Repository Secrets

Navigate to: `Settings` → `Secrets and variables` → `Actions` → `Secrets`

### Required Secrets (Repository Level)

#### Docker Hub

1. **`DOCKERHUB_USERNAME`**
   - Your Docker Hub username
   - Example: `davidcharbonnier`
   - Used by: All workflows that build Docker images

2. **`DOCKERHUB_TOKEN`**
   - Docker Hub Access Token with **Read, Write, Delete** permissions
   - How to create:
     1. Go to [Docker Hub Security](https://hub.docker.com/settings/security)
     2. Click "New Access Token"
     3. Name: `alacarte-github-actions`
     4. Permissions: **Read, Write, Delete** (Delete required for cleanup)
     5. Copy token immediately (shown only once)
   - Used by: All workflows that build Docker images

#### Android Signing (Client App)

3. **`CLIENT_KEYSTORE_BASE64`**
   - Base64-encoded Android release keystore file
   - How to create:
     ```bash
     base64 -i release-keystore.jks | tr -d '\n' > keystore.txt
     # Copy content of keystore.txt
     ```
   - Used by: Production release builds of Flutter client

4. **`CLIENT_KEYSTORE_PASSWORD`**
   - Password for the keystore file
   - Used by: Production release builds of Flutter client

5. **`CLIENT_KEY_ALIAS`**
   - Alias of the key in the keystore
   - Example: `release` or `alacarte`
   - Used by: Production release builds of Flutter client

6. **`CLIENT_KEY_PASSWORD`**
   - Password for the specific key (often same as keystore password)
   - Used by: Production release builds of Flutter client

7. **`GITHUB_TOKEN`**
   - ✅ Automatically provided by GitHub Actions
   - No setup needed

---

## 📝 Environment Variables

Navigate to: `Settings` → `Environments`

You need to create **two environments**: `dev` and `prod`

### Environment: `dev` (for PR snapshots)

Variables to add:

1. **`CLIENT_API_BASE_URL`**
   - Development API URL for Flutter client
   - Example: `https://alacarte-api-dev-123456.run.app`
   - Or: `http://10.0.2.2:8080` (for Android emulator)
   - Used by: PR snapshot builds of Flutter client

2. **`CLIENT_GOOGLE_CLIENT_ID`**
   - Development Google OAuth Client ID for Flutter client
   - Format: `xxxxx-yyyyy.apps.googleusercontent.com`
   - Get from: Google Cloud Console → APIs & Services → Credentials
   - Used by: PR snapshot builds of Flutter client

3. **`ADMIN_NEXT_PUBLIC_API_URL`**
   - Development API URL for Admin panel
   - Example: `https://alacarte-api-dev-123456.run.app`
   - Used by: PR snapshot builds of Admin panel

### Environment: `prod` (for production releases)

Variables to add:

1. **`CLIENT_API_BASE_URL`**
   - Production API URL for Flutter client
   - Example: `https://alacarte-api-prod-123456.run.app`
   - Used by: Production release builds of Flutter client

2. **`CLIENT_GOOGLE_CLIENT_ID`**
   - Production Google OAuth Client ID for Flutter client
   - Format: `xxxxx-yyyyy.apps.googleusercontent.com`
   - Get from: Google Cloud Console → APIs & Services → Credentials
   - ⚠️ Must be different from dev client ID
   - Used by: Production release builds of Flutter client

3. **`ADMIN_NEXT_PUBLIC_API_URL`**
   - Production API URL for Admin panel
   - Example: `https://alacarte-api-prod-123456.run.app`
   - Used by: Production release builds of Admin panel

---

## 📊 Summary Table

### Secrets (Repository Level)
| Secret Name | Type | Description |
|-------------|------|-------------|
| `DOCKERHUB_USERNAME` | String | Docker Hub username |
| `DOCKERHUB_TOKEN` | Token | Docker Hub access token (Read/Write/Delete) |
| `CLIENT_KEYSTORE_BASE64` | Base64 | Android release keystore (base64 encoded) |
| `CLIENT_KEYSTORE_PASSWORD` | String | Keystore password |
| `CLIENT_KEY_ALIAS` | String | Key alias in keystore |
| `CLIENT_KEY_PASSWORD` | String | Key password |
| `GITHUB_TOKEN` | Auto | Provided automatically by GitHub |

### Variables (Environment Level)

#### Dev Environment
| Variable Name | Description | Example |
|---------------|-------------|---------|
| `CLIENT_API_BASE_URL` | Dev API URL for client | `https://api-dev.example.com` |
| `CLIENT_GOOGLE_CLIENT_ID` | Dev Google OAuth client ID | `123-abc.apps.googleusercontent.com` |
| `ADMIN_NEXT_PUBLIC_API_URL` | Dev API URL for admin | `https://api-dev.example.com` |

#### Prod Environment
| Variable Name | Description | Example |
|---------------|-------------|---------|
| `CLIENT_API_BASE_URL` | Prod API URL for client | `https://api.example.com` |
| `CLIENT_GOOGLE_CLIENT_ID` | Prod Google OAuth client ID | `456-xyz.apps.googleusercontent.com` |
| `ADMIN_NEXT_PUBLIC_API_URL` | Prod API URL for admin | `https://api.example.com` |

---

## ✅ Setup Checklist

- [ ] **Repository Secrets**
  - [ ] `DOCKERHUB_USERNAME` added
  - [ ] `DOCKERHUB_TOKEN` added (with Delete permissions)
  - [ ] `CLIENT_KEYSTORE_BASE64` added (base64 encoded keystore)
  - [ ] `CLIENT_KEYSTORE_PASSWORD` added
  - [ ] `CLIENT_KEY_ALIAS` added
  - [ ] `CLIENT_KEY_PASSWORD` added

- [ ] **Dev Environment Created**
  - [ ] `CLIENT_API_BASE_URL` added
  - [ ] `CLIENT_GOOGLE_CLIENT_ID` added
  - [ ] `ADMIN_NEXT_PUBLIC_API_URL` added

- [ ] **Prod Environment Created**
  - [ ] `CLIENT_API_BASE_URL` added
  - [ ] `CLIENT_GOOGLE_CLIENT_ID` added
  - [ ] `ADMIN_NEXT_PUBLIC_API_URL` added

---

## 🔍 Verification

After setting up all secrets and variables, verify by:

1. **Check Repository Secrets:**
   - Settings → Secrets and variables → Actions → Secrets
   - Should see: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `CLIENT_KEYSTORE_BASE64`, `CLIENT_KEYSTORE_PASSWORD`, `CLIENT_KEY_ALIAS`, `CLIENT_KEY_PASSWORD`

2. **Check Dev Environment:**
   - Settings → Environments → dev → Environment variables
   - Should see: `CLIENT_API_BASE_URL`, `CLIENT_GOOGLE_CLIENT_ID`, `ADMIN_NEXT_PUBLIC_API_URL`

3. **Check Prod Environment:**
   - Settings → Environments → prod → Environment variables
   - Should see: `CLIENT_API_BASE_URL`, `CLIENT_GOOGLE_CLIENT_ID`, `ADMIN_NEXT_PUBLIC_API_URL`

---

## 📝 Notes

- **Client variables are prefixed with `CLIENT_`** to avoid conflicts
- **Admin variables are prefixed with `ADMIN_`** to avoid conflicts
- **API app doesn't need any variables** (no build-time configuration needed)
- **Environment separation** ensures dev builds use dev services, prod builds use prod services
- **Google OAuth requires separate client IDs** for dev and prod environments

---

## 🔄 Future Apps

When adding new apps (e.g., Wine, Beer), follow this pattern:

**Dev Environment:**
- `NEWAPP_VAR_NAME` = dev value

**Prod Environment:**
- `NEWAPP_VAR_NAME` = prod value

This maintains consistency and prevents naming conflicts across all applications.

---

**Last Updated:** January 2025
