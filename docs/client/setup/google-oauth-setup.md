# Google OAuth Setup Guide

Complete guide for setting up Google OAuth authentication for À la carte across all platforms.

## 🎯 Overview

À la carte uses Google OAuth 2.0 for authentication across web and mobile platforms. The architecture uses:
- **Frontend platforms** (Web, Android) authenticate with Google
- **Backend API** validates Google tokens and issues application JWT tokens
- **Single OAuth flow** with cross-platform compatibility

## 🔧 Google Cloud Console Setup

### **Step 1: Create Google Cloud Project**

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create new project or select existing project
3. Enable **Google+ API** and **OAuth2 API**

### **Step 2: Configure OAuth Consent Screen**

1. Navigate to **APIs & Services** → **OAuth consent screen**
2. Choose **External** user type (for public app)
3. **App Information:**
   - **App name**: À la carte
   - **User support email**: your-email@example.com
   - **App logo**: Upload your app icon
   - **App domain**: Your production domain
   - **Privacy policy**: Link to your privacy policy

4. **Scopes:**
   - Add `userinfo.email` scope
   - Add `userinfo.profile` scope
   - These are the **only scopes required**

5. **Test Users** (for development):
   - Add your Gmail address
   - Add test user emails for development

### **Step 3: Create OAuth 2.0 Client IDs**

#### **Web Application Client**
1. Click **Create Credentials** → **OAuth 2.0 Client ID**
2. **Application type**: Web application
3. **Name**: "À la carte Web App"
4. **Authorized JavaScript origins**:
   ```
   http://localhost:3000                    # Development
   https://yourdomain.com                   # Production
   ```
5. **Authorized redirect URIs**:
   ```
   http://localhost:3000/auth/callback      # Development
   https://yourdomain.com/auth/callback     # Production
   ```
6. **Save and copy the Client ID** (format: `123456789-abc...@apps.googleusercontent.com`)

#### **Android Application Client**
1. Click **Create Credentials** → **OAuth 2.0 Client ID**
2. **Application type**: Android
3. **Name**: "À la carte Android App"
4. **Package name**: `com.alacarte.alc_client`
5. **SHA-1 certificate fingerprint**: 
   ```bash
   # Get your debug SHA-1 fingerprint
   keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android
   
   # Look for: SHA1: AA:BB:CC:DD:EE:FF...
   ```
6. **Save the Android Client ID**

### **Step 4: Get Release SHA-1 (For Production)**
```bash
# For production releases, you'll also need the release keystore SHA-1
keytool -list -v -alias your-release-alias -keystore path/to/release.keystore
```

## 🛠️ Backend Configuration

### **Environment Variables**
```bash
# In your Cloud Run environment variables
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-web-client-secret

# Example:
GOOGLE_CLIENT_ID=123456789-abcdefghijk.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-abc123def456ghi789
```

### **Validation Architecture**
The backend validates all tokens (from web and Android) against the **web client ID**:

```go
// Backend accepts tokens with web client audience
if tokenInfo.Audience != clientID {
    return nil, fmt.Errorf("token audience mismatch")
}
```

This works because Android uses `serverClientId` to generate tokens with web client audience.

## 📱 Frontend Configuration

### **App Configuration**
```dart
// lib/config/app_config.dart
class AppConfig {
  // Use your web client ID for both development and production
  static const String googleWebClientId = 'your-web-client-id.apps.googleusercontent.com';
}
```

### **Google Sign-In Service**
```dart
// lib/services/auth_service.dart
static final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  // Use web client ID as serverClientId for backend compatibility
  serverClientId: AppConfig.googleWebClientId,
);
```

### **Dependencies**
```yaml
# pubspec.yaml
dependencies:
  google_sign_in: ^6.2.1
```

## 🚀 Authentication Flow

### **Complete OAuth Flow**
```
1. User taps "Continue with Google" in app
2. Google shows native sign-in UI (Android) or web popup (Web)
3. User authenticates with Google account
4. Google returns ID token + access token to app
5. App sends tokens to backend: POST /auth/google
6. Backend validates token with Google's tokeninfo API
7. Backend extracts complete profile data from JWT payload
8. Backend creates/updates user with Google profile data
9. Backend returns application JWT token
10. App stores JWT and navigates to main interface
```

### **Cross-Platform Token Flow**
```
Android App (uses Android client for UI, web client for backend)
    ↓ Google OAuth with serverClientId
    ↓ Tokens have web client audience
    ↓ Sends to backend
Backend (validates against web client)
    ✅ Validates successfully

Web App (uses web client directly)
    ↓ Google OAuth 
    ↓ Tokens have web client audience
    ↓ Sends to backend  
Backend (validates against web client)
    ✅ Validates successfully
```

## 🔧 Development Setup

### **Prerequisites**
1. **Google Cloud Console** project with OAuth clients configured
2. **Android Development**: SHA-1 certificate fingerprint added to Android client
3. **Backend Deployed**: Cloud Run with Google OAuth environment variables
4. **Frontend Dependencies**: `google_sign_in` package installed

### **Local Development**
```bash
# 1. Clone and setup backend (if not already deployed)
cd rest-api
go mod tidy
go run main.go
# Should show: "🔐 Google OAuth enabled"

# 2. Setup frontend
cd client
flutter pub get
flutter run -d linux    # For web testing
flutter run -d android  # For Android testing
```

### **Testing OAuth Flow**
1. **Android**: Native Google sign-in dialog
2. **Web**: Google OAuth redirect/popup
3. **Backend**: Validates tokens and returns user profile
4. **Success**: Navigate to profile setup or main app

## 🔍 Troubleshooting

### **Common Issues**

#### **Android: ApiException: 10**
- **Cause**: Android client not configured in Google Console
- **Solution**: Add Android client with correct package name + SHA-1

#### **Web: OAuth Error**  
- **Cause**: Authorized origins not configured
- **Solution**: Add your domain to authorized JavaScript origins

#### **Backend: Token audience mismatch**
- **Cause**: Web client ID mismatch between frontend and backend
- **Solution**: Ensure same client ID in app_config.dart and backend environment

#### **Backend: Invalid token**
- **Cause**: Google OAuth consent screen not published or scopes missing
- **Solution**: Publish consent screen and verify email/profile scopes

### **Debug Information**

#### **Backend Logs**
```bash
# Successful OAuth
🔐 Google OAuth enabled
   • OAuth endpoint: /auth/google
   • Token validation: Google API servers
   • Client ID: your-web-client-id.apps.googleusercontent.com

# Failed authentication
{"error": "Invalid Google ID token or missing profile data", "details": "..."}
```

#### **Frontend Debugging**
```dart
// Check Google Sign-In status
print('Signed in: ${await GoogleSignIn().isSignedIn()}');
print('Current user: ${GoogleSignIn().currentUser?.email}');
```

## 📈 Production Deployment

### **Backend (Cloud Run)**
- **✅ Deployed**: Production Google OAuth validation
- **✅ Environment**: Google Client ID and secret configured
- **✅ Database**: MySQL with complete OAuth user schema
- **✅ Security**: Real token validation with fail-fast architecture

### **Frontend Deployment**

#### **Web Application**
```bash
# Build for production
flutter build web --release

# Deploy to your hosting platform
# Ensure authorized origins include your production domain
```

#### **Android Application**
```bash
# Build release APK
flutter build apk --release

# Or build app bundle for Google Play
flutter build appbundle --release

# Note: Update Android client SHA-1 with release keystore fingerprint
```

## 🔒 Security Considerations

### **What's Safe to Expose**
- ✅ **Google Web Client ID**: Safe to embed in frontend code
- ✅ **Package Names**: Public in app stores anyway
- ✅ **OAuth Scopes**: Publicly visible in consent screen

### **What Must Stay Secret**
- ❌ **Google Client Secret**: Only in backend environment variables
- ❌ **JWT Signing Key**: Backend-only secret for token generation
- ❌ **Database Credentials**: Secure backend environment only

### **Security Benefits**
- **Multi-layer validation**: Google validation + audience verification
- **Short-lived tokens**: Google tokens expire automatically
- **Fail-fast architecture**: Invalid tokens rejected immediately
- **Privacy-first model**: User data protection built-in

## 🎯 Next Steps

### **For New Developers**
1. **Google Console**: Set up OAuth clients following this guide
2. **Environment Setup**: Configure client IDs in app_config.dart
3. **Test Authentication**: Verify OAuth flow on your platform
4. **Profile Completion**: Test display name setup workflow

### **For Production Deployment**
1. **Update Client IDs**: Replace placeholder IDs with production values
2. **Configure Domains**: Add production domains to authorized origins
3. **Release Certificates**: Add production SHA-1 to Android client
4. **Monitor**: Set up OAuth success/failure monitoring

The Google OAuth implementation provides enterprise-grade authentication security while maintaining a seamless user experience across all platforms.

---

**Google OAuth 2.0 Implementation**  
*Secure, scalable, cross-platform authentication*
