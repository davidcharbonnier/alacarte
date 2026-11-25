# GitHub Secrets and Variables Configuration

This document lists all required secrets and variables for the CI/CD workflows.

## 📋 Repository Secrets

Navigate to: `Settings` → `Secrets and variables` → `Actions` → `Secrets`

### Required Secrets (Repository Level)

#### Android Signing (Client App)

1. **`CLIENT_KEYSTORE_BASE64`**
   - Base64-encoded Android release keystore file
   - Create the keystore with `keytool` first: see [Release Keystore Setup](/docs/client/setup/android-oauth-setup.md#release-keystore-setup)
   - How to encode it:
     ```bash
     base64 -i release-keystore.jks | tr -d '\n' > keystore.txt
     # Copy content of keystore.txt
     ```
   - Used by: Production release builds of Flutter client

2. **`CLIENT_KEYSTORE_PASSWORD`**
   - Password for the keystore file
   - Used by: Production release builds of Flutter client

3. **`CLIENT_KEY_ALIAS`**
   - Alias of the key in the keystore
   - Example: `release` or `alacarte`
   - Used by: Production release builds of Flutter client

4. **`CLIENT_KEY_PASSWORD`**
   - Password for the specific key (often same as keystore password)
   - Used by: Production release builds of Flutter client

5. **`GITHUB_TOKEN`**
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

3. **`ADMIN_VITE_API_URL`**
   - Development API URL for Admin SPA
   - Example: `https://alacarte-api-dev-123456.run.app`
   - Used by: PR snapshot builds of Admin SPA (baked into the bundle as `VITE_API_URL`)

4. **`ADMIN_VITE_GOOGLE_CLIENT_ID`**
   - Development Google OAuth Web Client ID for Admin SPA
   - Used by: PR snapshot builds of Admin SPA (baked into the bundle as `VITE_GOOGLE_CLIENT_ID`)

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

3. **`ADMIN_VITE_API_URL`**
   - Production API URL for Admin SPA
   - Example: `https://alacarte-api-prod-123456.run.app`
   - Used by: Production release builds of Admin SPA (baked into the bundle as `VITE_API_URL`)

4. **`ADMIN_VITE_GOOGLE_CLIENT_ID`**
   - Production Google OAuth Web Client ID for Admin SPA
   - Used by: Production release builds of Admin SPA (baked into the bundle as `VITE_GOOGLE_CLIENT_ID`)

---

## 📊 Summary Table

### Secrets (Repository Level)
| Secret Name | Type | Description |
|-------------|------|-------------|
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
| `ADMIN_VITE_API_URL` | Dev API URL for admin | `https://api-dev.example.com` |
| `ADMIN_VITE_GOOGLE_CLIENT_ID` | Dev Google OAuth web client ID for admin | `123-abc.apps.googleusercontent.com` |

#### Prod Environment
| Variable Name | Description | Example |
|---------------|-------------|---------|
| `CLIENT_API_BASE_URL` | Prod API URL for client | `https://api.example.com` |
| `CLIENT_GOOGLE_CLIENT_ID` | Prod Google OAuth client ID | `456-xyz.apps.googleusercontent.com` |
| `ADMIN_VITE_API_URL` | Prod API URL for admin | `https://api.example.com` |
| `ADMIN_VITE_GOOGLE_CLIENT_ID` | Prod Google OAuth web client ID for admin | `456-xyz.apps.googleusercontent.com` |

---

## ✅ Setup Checklist

- [ ] **Repository Secrets**
  - [ ] `CLIENT_KEYSTORE_BASE64` added (base64 encoded keystore)
  - [ ] `CLIENT_KEYSTORE_PASSWORD` added
  - [ ] `CLIENT_KEY_ALIAS` added
  - [ ] `CLIENT_KEY_PASSWORD` added

- [ ] **Dev Environment Created**
  - [ ] `CLIENT_API_BASE_URL` added
  - [ ] `CLIENT_GOOGLE_CLIENT_ID` added
  - [ ] `ADMIN_VITE_API_URL` added
  - [ ] `ADMIN_VITE_GOOGLE_CLIENT_ID` added

- [ ] **Prod Environment Created**
  - [ ] `CLIENT_API_BASE_URL` added
  - [ ] `CLIENT_GOOGLE_CLIENT_ID` added
  - [ ] `ADMIN_VITE_API_URL` added
  - [ ] `ADMIN_VITE_GOOGLE_CLIENT_ID` added

---

## 🔍 Verification

After setting up all secrets and variables, verify by:

1. **Check Repository Secrets:**
   - Settings → Secrets and variables → Actions → Secrets
   - Should see: `CLIENT_KEYSTORE_BASE64`, `CLIENT_KEYSTORE_PASSWORD`, `CLIENT_KEY_ALIAS`, `CLIENT_KEY_PASSWORD`

2. **Check Dev Environment:**
   - Settings → Environments → dev → Environment variables
   - Should see: `CLIENT_API_BASE_URL`, `CLIENT_GOOGLE_CLIENT_ID`, `ADMIN_VITE_API_URL`, `ADMIN_VITE_GOOGLE_CLIENT_ID`

3. **Check Prod Environment:**
   - Settings → Environments → prod → Environment variables
   - Should see: `CLIENT_API_BASE_URL`, `CLIENT_GOOGLE_CLIENT_ID`, `ADMIN_VITE_API_URL`, `ADMIN_VITE_GOOGLE_CLIENT_ID`

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
