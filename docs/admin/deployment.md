# Production Deployment Guide - Admin Panel

**Last Updated:** November 2026  
**Status:** Production-Ready

---

## Quick Deployment Checklist

### Prerequisites

- [ ] Static hosting account (Netlify, Cloudflare Pages, Firebase Hosting, …) for the admin SPA
- [ ] Backend API deployed and accessible
- [ ] Google OAuth Web Client configured with the admin origin

---

## Environment Variables

### Required Variables

```bash
# API Configuration (baked into bundle at build time)
VITE_API_URL=https://alacarte-api-xxx.northamerica-northeast1.run.app

# Google OAuth Web Client ID (baked into bundle at build time)
VITE_GOOGLE_CLIENT_ID=<your-google-client-id>
```

---

## Google OAuth Setup

### Add Authorized Redirect URIs

In Google Cloud Console → APIs & Services → Credentials:

**Production:**
- Authorized JavaScript origins: `https://alacarte-admin-xxx.northamerica-northeast1.run.app`

**Important:** Must use the exact deployed domain (your static-host URL). No server-side redirect URI is needed — the SPA uses Google Identity Services (`@react-oauth/google`) and sends the `id_token` to the backend, which verifies it and issues its own JWT (stored in `sessionStorage`).

---

## Deployment Methods

### Method 1: GitHub Actions (Recommended)

The CI/CD pipeline automatically builds and publishes Docker images:

**For production releases:**
```bash
# Create feature branch
git checkout -b feat/admin-enhancements
git commit -m "feat: add user management"
git push

# Create PR → CI builds the dist/ artifact with VITE_* vars from GitHub vars
# (ADMIN_VITE_API_URL, ADMIN_VITE_GOOGLE_CLIENT_ID)
# Merge to master → release workflow produces a dist/ artifact per version tag
```

**Artifacts created:**
- `admin-dist-{version}` (static bundle, e.g. `admin-dist-0.1.0`)

### Method 2: Manual Static Build

```bash
cd apps/admin

# VITE_* values are baked into the bundle at build time — set them before building
export VITE_API_URL=https://alacarte-api-xxx.northamerica-northeast1.run.app
export VITE_GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com

npm ci --ignore-scripts
npm run build

# Upload dist/ to any static host (Netlify, Cloudflare Pages, Firebase Hosting, …)
```

No runtime env vars exist for the admin SPA — changing `VITE_*` requires a rebuild.
```

---

## Post-Deployment

### Verify Deployment

1. **Access admin panel:** your static-host URL (e.g. `https://admin.example.com`)
2. **Click "Sign in with Google"**
3. **Authenticate with admin account**
4. **Should redirect to dashboard**

### Test Error Handling

**Test with non-admin account:**
- Should see "Access Denied" error
- Clear message explaining admin privileges required

**Test with backend stopped:**
- Should see "Service Unavailable" error
- Message explaining connection issue

### Set Initial Admin

The first admin is configured via environment variable:

```bash
# In backend .env
INITIAL_ADMIN_EMAIL=your-admin@gmail.com
```

This user can login immediately and promote other users to admin via the UI.

---

## Security Considerations

### Production Security

- ✅ HTTPS enforced (automatic on Cloud Run and all major static hosts)
- ✅ Backend verifies Google `id_token` before issuing its own JWT
- ✅ Admin verification at login
- ✅ Backend JWT validation on all API calls
- ✅ JWT held in `sessionStorage` (cleared when the tab closes)
- ✅ No tech stack info disclosed
- ✅ X-Powered-By header disabled

### Secrets Management

The admin SPA needs no secrets — both env vars are public build-time values (backend keeps `GOOGLE_CLIENT_SECRET` in Secret Manager; see the API deployment guide).

**Never commit to git:**
- `.env.local`
- `.env.production`
- Any file containing secrets

---

## Troubleshooting

### Access Denied for Admin User

**Symptom:** Known admin sees access denied  
**Solution:**
1. Check `INITIAL_ADMIN_EMAIL` in backend matches Google account email
2. Or set `is_admin = true` in database

### Backend Connection Failed

**Symptom:** Service Unavailable error  
**Solution:**
1. Verify `API_URL` is correct
2. Check backend is deployed and running
3. Verify the API service allows traffic from the admin origin

### OAuth Redirect Mismatch

**Symptom:** Google OAuth error after clicking sign in  
**Solution:**
1. Add the exact deployed admin URL to Google OAuth authorized JavaScript origins
2. Verify `GOOGLE_CLIENT_ID` matches the OAuth client used by the client app

---

## Monitoring

### Check Logs

The admin SPA is a static bundle — no server logs exist for it. Debug via the browser console (see Key Log Patterns below) and the API's Cloud Run logs for backend-side auth events.

### Key Log Patterns

The admin SPA is a static bundle — it produces no server logs. Watch browser console output:

**Successful login:**
```
POST /auth/google → 200 (JWT stored in sessionStorage)
GET /api/auth/check-admin → 200 {"is_admin": true}
```

**Failed admin check:**
```
GET /api/auth/check-admin → 200 {"is_admin": false}
```

**Backend unreachable:**
```
Axios network error → redirect to /login
```

Backend-side auth logs are in the API service's Cloud Run logs.

---

## Admin Panel Status

All authentication, authorization, and error handling is complete.
