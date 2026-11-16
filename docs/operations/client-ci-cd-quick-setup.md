# Quick Setup Guide - Android CI/CD

## 🚀 Quick Start Checklist

### **Step 1: Local Development Setup** ✅

Create `.env` file in project root:
```bash
# .env
API_BASE_URL=https://alacarte-api-414358220433.northamerica-northeast1.run.app
GOOGLE_CLIENT_ID=414358220433-utddgtujirv58gt6g33kb7jei3shih27.apps.googleusercontent.com
APP_VERSION=1.0.0-dev
```

Test locally:
```bash
flutter pub get
flutter run
```

### **Step 2: Generate Release Keystore** 🔑

```bash
cd alacarte-client
keytool -genkey -v -keystore android/app/release-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias release

# When prompted:
# - Enter keystore password (save this!)
# - Re-enter password
# - Enter your details (name, organization, etc.)
```

### **Step 3: Encode Keystore for GitHub** 📦

```bash
base64 -i android/app/release-keystore.jks | tr -d '\n'
# Copy the entire output
```

### **Step 4: Configure GitHub Variables** ⚙️

Go to: **Repository → Settings → Secrets and Variables → Actions**

#### **Variables Tab**:
```
DEVELOPMENT_API_URL = https://alacarte-api-414358220433.northamerica-northeast1.run.app
DEVELOPMENT_GOOGLE_CLIENT_ID = 414358220433-utddgtujirv58gt6g33kb7jei3shih27.apps.googleusercontent.com
PRODUCTION_API_URL = [your production URL]
PRODUCTION_GOOGLE_CLIENT_ID = [your production OAuth client ID]
```

#### **Secrets Tab**:
```
KEYSTORE_BASE64 = [paste the base64 output from Step 3]
KEYSTORE_PASSWORD = [the password you entered in Step 2]
KEY_PASSWORD = [same as KEYSTORE_PASSWORD]
KEY_ALIAS = release
```

### **Step 5: Configure Google OAuth** 🔐

#### **Development OAuth Client (for debug builds)**:
- **Package name**: `com.alacarte.alc_client.debug`
- **SHA-1**: Run and copy output:
  ```bash
  keytool -list -v -alias androiddebugkey \
    -keystore ~/.android/debug.keystore \
    -storepass android -keypass android
  ```

#### **Production OAuth Client (for release builds)**:
- **Package name**: `com.alacarte.alc_client`
- **SHA-1**: Run and copy output:
  ```bash
  keytool -list -v -alias release \
    -keystore android/app/release-keystore.jks \
    -storepass [your password]
  ```

### **Step 6: Test the Pipeline** 🧪

```bash
# Create test branch
git checkout -b feat/test-ci-cd
echo "test" >> README.md
git add README.md
git commit -m "feat: test Android CI/CD pipeline"
git push origin feat/test-ci-cd

# Open PR on GitHub
# Wait for workflow to complete (~5 minutes)
# Download APK from pre-release
# Install and test on Android device
```

## ✅ Verification Checklist

- [ ] `.env` file created with all required variables
- [ ] `flutter run` works locally
- [ ] Release keystore generated
- [ ] Keystore base64 encoded
- [ ] All GitHub Variables configured
- [ ] All GitHub Secrets configured
- [ ] Debug OAuth client configured with debug SHA-1
- [ ] Production OAuth client configured with release SHA-1
- [ ] Test PR created and APK built successfully
- [ ] APK downloaded and tested on device
- [ ] OAuth login works in test APK

## 🎯 Common Issues

### **"Environment variable not set"**
→ Add missing variable to GitHub repository settings

### **"ApiException error 10" on Android**
→ Check package name matches OAuth client (`com.alacarte.alc_client.debug` for debug)
→ Verify SHA-1 is added to Google OAuth client

### **"Keystore not found"**
→ Verify KEYSTORE_BASE64 secret is set correctly
→ Ensure no newlines in base64 encoding

### **"Build failed - version solving"**
→ Check Flutter version in workflow matches your requirements (3.27+)

## 📋 Time Estimate

- **Local setup**: 5 minutes
- **Keystore generation**: 5 minutes
- **GitHub configuration**: 10 minutes
- **Google OAuth setup**: 10 minutes
- **Testing**: 10 minutes

**Total**: ~40 minutes for complete setup

## 🔗 Related Documentation

- [Full CI/CD Documentation](client-ci-cd-pipeline.md)
- [Android Setup Guide](../client/setup/android-setup.md)
- [Authentication System](../features/authentication.md)
