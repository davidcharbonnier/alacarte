# Android OAuth Setup Guide

Complete guide for configuring Google OAuth specifically for Android development and deployment.

## 🎯 Android OAuth Architecture

À la carte uses a **hybrid OAuth approach** for Android:
- **Android Client**: For native Google sign-in UI experience
- **Web Client ID as serverClientId**: For backend token validation compatibility
- **Single Backend Validation**: Backend only needs to know about web client ID

## 🔧 Android Development Setup

### **Step 1: Get Your SHA-1 Certificate Fingerprint**

#### **Debug Certificate (Development)**
```bash
# Navigate to your Flutter project
cd apps/client

# Get debug SHA-1 fingerprint
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android

# Look for output like:
# Certificate fingerprints:
#   SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
#   SHA256: 11:22:33:44:55:66...

# COPY THE SHA-1 VALUE - you'll need it for Google Console
```

#### **Release Certificate (Production)**
```bash
# When you have a release keystore for Google Play
keytool -list -v -alias your-release-alias -keystore path/to/your-release.keystore

# You'll need to provide the password for your release keystore
# Copy the SHA-1 fingerprint for production configuration
```

### **Step 2: Google Cloud Console Configuration**

#### **Create Android OAuth Client**
1. Go to [Google Cloud Console Credentials](https://console.cloud.google.com/apis/credentials)
2. Click **"+ CREATE CREDENTIALS"** → **"OAuth 2.0 Client ID"**
3. **Application type**: Select **"Android"**
4. **Configuration**:
   - **Name**: "À la carte Android App"
   - **Package name**: `com.alacarte.alc_client` (from your build.gradle.kts)
   - **SHA-1 certificate fingerprint**: Paste your debug SHA-1 from Step 1

5. Click **"CREATE"**
6. **Note**: You'll also need your existing web client ID for serverClientId configuration

### **Step 3: Flutter Configuration**

Your Flutter app reads the client ID from `apps/client/.env` (exposed as `AppConfig.googleWebClientId`):

```dart
// apps/client/.env (read via dotenv; AppConfig.googleWebClientId returns it)
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com

// lib/services/auth_service.dart (google_sign_in ^7.2.0)
await GoogleSignIn.instance.initialize(
  serverClientId: AppConfig.googleWebClientId, // Uses web client ID for backend
);
```

See [Client Authentication System](/docs/client/authentication-system.md) for the full v7 flow.

**How this works:**
- Android app authenticates using the **Android client** (native UI)
- But tokens are generated with **web client audience** (backend compatibility)
- Backend validates tokens against **web client ID** (unchanged)

## 📱 Android App Configuration

### **Package Name Verification**
Your Android app uses package name: `com.alacarte.alc_client`

**Verify in your project:**
```kotlin
// android/app/build.gradle.kts
android {
    namespace = "com.alacarte.alc_client"        // ✅ Correct
    defaultConfig {
        applicationId = "com.alacarte.alc_client" // ✅ Correct
    }
}
```

### **Permissions**
The app manifest declares `INTERNET` and `ACCESS_NETWORK_STATE` itself (see [android-setup.md](/docs/client/setup/android-setup.md)).

## 🚀 Testing Android OAuth

### **Development Testing**
```bash
# Build and run on Android device/emulator
flutter run -d android

# Expected flow:
# 1. App shows "Continue with Google" button
# 2. Tap button → Native Google sign-in dialog appears
# 3. Select Google account → Permission consent screen
# 4. Accept permissions → App receives tokens
# 5. Tokens sent to backend → JWT returned
# 6. Navigate to profile setup or main app
```

### **Debug OAuth Issues**

#### **Check Google Sign-In Status**
In debug builds `auth_service.dart` prints each step (`🔐 Starting Google authentication...`, `✅ Got both tokens...`); check the `flutter run` console for the step that fails.

#### **Common Android Issues**

**ApiException: 10 (Developer Error)**
- **Cause**: Android client not configured or SHA-1 mismatch
- **Solution**: Verify package name and SHA-1 in Google Console
- **Debug**: Check SHA-1 fingerprint matches exactly

**ApiException: 12 (Cancelled)**
- **Cause**: User cancelled sign-in or app not approved
- **Solution**: Normal user behavior, handle gracefully

**ApiException: 7 (Network Error)**
- **Cause**: No internet connection during sign-in
- **Solution**: Check connectivity, retry when online

## 🔧 Production Deployment

### **Release Keystore Setup**
For Google Play deployment, you need a release keystore:

```bash
# Create release keystore (if you don't have one)
keytool -genkey -v -keystore ~/alacarte-release.keystore -alias alacarte -keyalg RSA -keysize 2048 -validity 10000

# Get release SHA-1
keytool -list -v -alias alacarte -keystore ~/alacarte-release.keystore
```

### **Update Google Console for Production**
1. **Edit your Android OAuth client**
2. **Add production SHA-1**: Release keystore fingerprint
3. **Keep debug SHA-1**: For continued development
4. **Final configuration**:
   - **Package name**: `com.alacarte.alc_client`
   - **SHA-1 fingerprints**: Both debug AND release

### **Build Production APK**
```bash
# Build release version
flutter build apk --release

# Or build app bundle for Google Play
flutter build appbundle --release
```

## 🔍 Architecture Benefits

### **Single Backend Configuration**
```bash
# Backend only needs web client ID
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com

# No need for multiple client IDs or complex validation logic
```

### **Cross-Platform Consistency**
```
Web App → Uses web client directly → Backend validates ✅
Android App → Uses serverClientId → Backend validates ✅ 
iOS App (future) → Uses serverClientId → Backend validates ✅
```

### **Security Properties**
- **✅ Native Platform Experience**: Real Google sign-in UI per platform
- **✅ Backend Compatibility**: All tokens work with same validation logic
- **✅ Client ID Safety**: Safe to embed web client ID in app package
- **✅ Audience Verification**: Backend ensures tokens intended for your app

## 📊 Verification Checklist

### **Google Cloud Console**
- [ ] OAuth consent screen configured and published
- [ ] Web application client created
- [ ] Android application client created with correct package name
- [ ] SHA-1 certificate fingerprint(s) added
- [ ] Test users added for development

### **Android App**
- [ ] `google_sign_in` dependency added
- [ ] Package name matches Google Console (`com.alacarte.alc_client`)
- [ ] `apps/client/.env` contains the correct web client ID
- [ ] AuthService uses serverClientId configuration

### **Backend**
- [ ] Google web client ID configured in environment
- [ ] OAuth endpoint responds correctly: `/auth/google`
- [ ] Token validation working with Google API
- [ ] Complete profile data extraction implemented

### **Testing**
- [ ] Android OAuth flow works without ApiException: 10
- [ ] Backend receives and validates tokens successfully
- [ ] User profile created with complete Google data (name, email, avatar)
- [ ] Profile completion flow works correctly
- [ ] JWT tokens work for authenticated API access

## 🚨 Security Reminders

### **Safe Practices**
- ✅ **Client ID embedding**: Safe to include web client ID in app
- ✅ **Package verification**: Google validates package name + SHA-1
- ✅ **Token audience**: Backend verifies tokens intended for your app
- ✅ **Expiration**: All tokens expire automatically

### **Never Expose**
- ❌ **Google Client Secret**: Backend environment only
- ❌ **JWT Signing Secret**: Backend environment only  
- ❌ **User passwords**: OAuth eliminates password handling
- ❌ **Database credentials**: Backend environment only

The Android OAuth setup provides native authentication experience while maintaining backend security and cross-platform compatibility.

---

**Android + Google OAuth 2.0**  
*Native mobile authentication for À la carte*
