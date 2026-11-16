# Production Deployment Guide - Admin Panel

**Last Updated:** October 2025  
**Status:** Production-Ready

---

## Quick Deployment Checklist

### Prerequisites

- [ ] Docker Hub account with `davidcharbonnier/alacarte-admin` repository
- [ ] Google Cloud Project with Cloud Run enabled
- [ ] Backend API deployed and accessible
- [ ] Google OAuth Web Client configured

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

**Important:** Must use the exact Cloud Run URL. No server-side redirect URI is needed — the SPA uses Google Identity Services (`@react-oauth/google`) and sends the `id_token` to the backend, which verifies it and issues its own JWT (stored in `sessionStorage`).

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

# Create PR → Builds pre-release image
# Merge to master → Builds production image with version tag
```

**Images created:**
- `davidcharbonnier/alacarte-admin:latest`
- `davidcharbonnier/alacarte-admin:0.1.0` (semantic version)

### Method 2: Manual Docker Build

```bash
# Build production image
docker build -t davidcharbonnier/alacarte-admin:latest --target prod .

# Push to Docker Hub
docker push davidcharbonnier/alacarte-admin:latest

# Deploy to Cloud Run
gcloud run deploy alacarte-admin \
  --image davidcharbonnier/alacarte-admin:latest \
  --platform managed \
  --region northamerica-northeast1 \
  --allow-unauthenticated \
  --set-env-vars "VITE_API_URL=https://backend.run.app,VITE_GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com"
```

---

## Post-Deployment

### Verify Deployment

1. **Access admin panel:** `https://alacarte-admin-xxx.northamerica-northeast1.run.app`
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

- ✅ HTTPS enforced (Cloud Run automatic)
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
3. Verify Cloud Run → Cloud Run networking allows traffic

### OAuth Redirect Mismatch

**Symptom:** Google OAuth error after clicking sign in  
**Solution:**
1. Add exact Cloud Run URL to Google OAuth authorized JavaScript origins
2. Verify `GOOGLE_CLIENT_ID` matches the OAuth client used by the client app

---

## Monitoring

### Check Logs

```bash
# View admin panel logs
gcloud run services logs read alacarte-admin \
  --region northamerica-northeast1 \
  --limit 50

# Follow logs in real-time
gcloud run services logs tail alacarte-admin \
  --region northamerica-northeast1
```

### Key Log Patterns

**Successful login:**
```
POST /api/auth/callback/google → 302
GET / → 200
```

**Failed admin check:**
```
Admin access required - user is not an administrator
Error: AccessDenied
```

**Backend unreachable:**
```
Authentication failed: [network error]
Error: ServiceUnavailable
```

---

## Admin Panel is Production-Ready! ✅

All authentication, authorization, and error handling is complete and tested.
