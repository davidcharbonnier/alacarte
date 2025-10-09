# Android Build Setup and Development Guide

## Overview

This guide covers the complete setup process for building and running the A la carte Flutter app on Android devices. The setup includes configuration for local development with network API access, Android-specific permissions, and troubleshooting common build issues.

## Prerequisites

### Required Software
- **Flutter SDK**: Official stable channel installation (not package manager versions)
- **Android Studio**: Latest version with Android SDK
- **Android SDK**: API level 36 (Android 15)
- **Android NDK**: Version 27.0.12077973
- **Java JDK**: Version 17 or higher

### Hardware Requirements
- **Development machine**: Linux/macOS/Windows with network connectivity
- **Android device**: API level 24+ with wireless debugging enabled
- **Local network**: Both development machine and Android device on same network

## Build Configuration

### Android Gradle Configuration

#### 1. Project-Level Build Configuration
**File**: `android/settings.gradle.kts`
```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}
```

#### 2. App-Level Build Configuration  
**File**: `android/app/build.gradle.kts`
```kotlin
android {
    namespace = "com.alacarte.alc_client"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.alacarte.alc_client"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    implementation("androidx.multidex:multidx:2.0.1")
}
```

#### 3. Gradle Properties
**File**: `android/gradle.properties`
```properties
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true
kotlin.incremental=true
org.gradle.caching=true
android.defaults.buildfeatures.buildconfig=true
android.nonTransitiveRClass=false
```

### Android Permissions and Security

#### 1. Application Manifest
**File**: `android/app/src/main/AndroidManifest.xml`
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Required permissions for A la carte app -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <application
        android:label="À la carte"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:networkSecurityConfig="@xml/network_security_config">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:orientation="portrait"
            android:screenOrientation="portrait"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme" />
              
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

#### 2. Network Security Configuration
**File**: `android/app/src/main/res/xml/network_security_config.xml`
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <!-- Allow localhost for development -->
        <domain includeSubdomains="false">localhost</domain>
        <domain includeSubdomains="false">127.0.0.1</domain>
        <domain includeSubdomains="false">10.0.2.2</domain>  <!-- Android emulator host -->
        <!-- Local network ranges for device testing -->
        <domain includeSubdomains="false">192.168.0.0/24</domain>
        <domain includeSubdomains="false">192.168.1.0/24</domain>
    </domain-config>
</network-security-config>
```

### Flutter App Configuration

#### 1. Widget Binding Initialization
**File**: `lib/main.dart`
```dart
void main() {
  // Ensure Flutter binding is initialized first
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize rateable item types before running the app
  initializeRateableItemTypes();
  
  // Start connectivity monitoring after binding is initialized
  ApiService.startConnectivityMonitoring();
  
  runApp(const ProviderScope(child: MyApp()));
}
```

#### 2. Network API Configuration
**File**: `lib/config/app_config.dart`
```dart
class AppConfig {
  // API Configuration for local development
  static const String baseUrl = isDevelopment 
      ? 'http://192.168.0.22:8080'  // Replace with your computer's IP
      : 'https://your-production-api.com';
}
```

## Development Setup Process

### Step 1: Flutter Installation
```bash
# Remove package manager Flutter if installed
sudo pacman -R flutter  # For Arch Linux
# or equivalent for other package managers

# Install official Flutter
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.35.6-stable.tar.xz
tar xf flutter_linux_3.35.6-stable.tar.xz
export PATH="$PWD/flutter/bin:$PATH"

# Verify installation
flutter doctor -v
```

### Step 2: Android SDK Setup
```bash
# Ensure Android SDK is properly configured
flutter config --android-sdk /opt/android-sdk
flutter doctor --android-licenses

# Verify Android setup
flutter doctor -v
```

### Step 3: Project Configuration
```bash
# Navigate to project
cd /path/to/client

# Clean previous builds
flutter clean
rm -rf .dart_tool
rm -rf android/.gradle
rm -rf android/app/build
rm -rf android/build
rm -rf build

# Regenerate dependencies
flutter pub get
```

### Step 4: Network Configuration
1. **Find your computer's IP address**:
   ```bash
   ip addr show | grep "inet 192.168"
   # or
   hostname -I
   ```

2. **Update API configuration** in `lib/config/app_config.dart`

3. **Ensure backend accepts network connections**:
   ```bash
   # Backend should bind to all interfaces
   cd ../rest-api
   go run main.go  # Should start on :8080, not localhost:8080
   ```

4. **Test network connectivity**:
   ```bash
   # From development machine
   curl http://192.168.0.22:8080/api/health
   
   # From Android device browser
   # Navigate to: http://192.168.0.22:8080/api/health
   ```

### Step 5: Build and Deploy
```bash
# Build APK
flutter build apk --debug

# Or build and install directly
flutter run -d android
```

## Common Issues and Solutions

### Build Issues

#### 1. Kotlin Compiler Session File Error
**Error**: `java.nio.file.NoSuchFileException: .../kotlin-compiler-*.salive`

**Cause**: Package manager Flutter installations often have compatibility issues

**Solution**: 
- Install official Flutter from flutter.dev
- Switch to stable channel
- Clean all build artifacts

#### 2. NDK Version Mismatch
**Error**: Plugin requires NDK version X.Y.Z

**Solution**: Update `ndkVersion` in `android/app/build.gradle.kts` to match plugin requirements

#### 3. Widget Binding Not Initialized
**Error**: `Binding has not yet been initialized`

**Solution**: Add `WidgetsFlutterBinding.ensureInitialized()` at start of `main()` function

#### 4. Gradle Daemon Compatibility
**Error**: Incompatible daemon could not be reused

**Solution**:
```bash
cd android
./gradlew --stop
rm -rf ~/.gradle/daemon
./gradlew clean --no-daemon
```

### Network Connectivity Issues

#### 1. App Shows Offline Mode
**Cause**: Android device cannot reach API on localhost

**Solution**: Update API base URL to use network IP address instead of localhost

#### 2. Network Security Policy Blocks HTTP
**Cause**: Android blocks cleartext HTTP traffic by default

**Solution**: Add network security configuration allowing local development domains

#### 3. Backend Not Accessible from Network
**Cause**: Backend only listening on localhost interface

**Solution**: Configure backend to bind to all interfaces (`:8080` instead of `localhost:8080`)

### UI and Layout Issues

#### 1. RenderFlex Overflow Errors
**Cause**: Text content exceeds available container width

**Solution**: Use `Expanded` widgets and `TextOverflow.ellipsis` for responsive text

#### 2. Dialog Title Overflow
**Cause**: Long localized text in dialog titles

**Solution**: Wrap dialog title text in `Expanded` with overflow handling

## Development Workflow

### Daily Development Process
1. **Start backend API**:
   ```bash
   cd ../rest-api && go run main.go
   ```

2. **Start Flutter app**:
   ```bash
   flutter run -d android
   ```

3. **Hot reload for changes**:
   ```bash
   # In Flutter terminal, press 'r'
   r
   ```

### Testing Network Changes
1. **Update API configuration** in `app_config.dart`
2. **Hot reload** or restart app
3. **Verify connectivity** in app (should show online status)
4. **Test API functionality** (authentication, rating operations)

### Building for Distribution
```bash
# Debug build for testing
flutter build apk --debug

# Release build for distribution (future)
flutter build apk --release
```

## Performance Considerations

### Memory Management
- **Gradle heap**: 4GB allocation prevents out-of-memory errors
- **Kotlin incremental compilation**: Faster rebuild times
- **Gradle caching**: Improved build performance

### Network Optimization
- **Local network development**: Faster API response times than localhost tunneling
- **Connectivity monitoring**: Efficient network state detection
- **Offline-first architecture**: Graceful degradation when network unavailable

## Security Notes

### Development vs Production
- **Development**: Allows HTTP cleartext for local API testing
- **Production**: Should use HTTPS with proper certificates
- **Network security config**: Restricts cleartext to development domains only

### Permissions Rationale
- **INTERNET**: Required for API communication with backend
- **ACCESS_NETWORK_STATE**: Required for connectivity monitoring and offline handling

## Next Steps

### For Production Deployment
1. **Update network security configuration** to use HTTPS only
2. **Configure proper signing** for release builds
3. **Update API endpoints** to production URLs
4. **Test on multiple Android versions** and screen sizes

### For Enhanced Development
1. **Set up Android emulator** for testing without physical device
2. **Configure CI/CD pipeline** for automated builds
3. **Add instrumentation tests** for Android-specific functionality
4. **Optimize build times** with Gradle build cache

## Troubleshooting Commands

### Clean Build Environment
```bash
# Complete clean
flutter clean
cd android && ./gradlew clean && cd ..
rm -rf .dart_tool android/.gradle build

# Regenerate
flutter pub get
flutter build apk --debug
```

### Debug Network Issues
```bash
# Check device connectivity
adb shell ping 192.168.0.22

# Monitor app logs
flutter logs

# Check API health from device
# Use device browser: http://192.168.0.22:8080/api/health
```

### Gradle Debug
```bash
# Verbose Gradle output
cd android
./gradlew assembleDebug --info --stacktrace

# Check Gradle daemon status
./gradlew --status
```

This guide provides complete coverage for setting up Android development for the A la carte Flutter app, including all the configurations and solutions developed during our build session.
