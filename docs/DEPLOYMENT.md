# 🚀 Build & Deployment - KART

**Scope** : Build process, release, deployment to stores  
**Date** : 18 Mai 2026  
**Version** : 1.0

---

## 📦 Build Configuration

### Android Build

#### Signing configuration

File: `android/app/build.gradle.kts`

```gradle
android {
  compileSdk 34
  
  defaultConfig {
    applicationId = "com.kart.app"
    minSdk = 21
    targetSdk = 34
    versionCode = 1
    versionName = "1.0.0"
  }

  signingConfigs {
    create("release") {
      storeFile = file("path/to/keystore.jks")
      storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
      keyAlias = System.getenv("ANDROID_KEY_ALIAS")
      keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
    }
  }

  buildTypes {
    release {
      signingConfig = signingConfigs.getByName("release")
      minifyEnabled = true
      shrinkResources = true
      proguardFiles(
        getDefaultProguardFile("proguard-android-optimize.txt"),
        "proguard-rules.pro"
      )
    }

    debug {
      signingConfig = signingConfigs.getByName("release")
    }
  }
}
```

#### ProGuard configuration

File: `android/app/proguard-rules.pro`

```proguard
# Keep Flutter engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Dio
-keep class dio.** { *; }
-keep class retrofit.** { *; }

# Keep Google Sign-In
-keep class com.google.android.gms.** { *; }
```

---

### iOS Build

#### Configuration

File: `ios/Podfile`

```ruby
platform :ios, '12.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_root = File.expand_path(File.join(packages_path, 'flutter'))
  load File.join(flutter_root, 'packages', 'flutter_tools', 'bin', 'podhelper')

  flutter_ios_podfile_setup

  pod 'GoogleSignIn'
  pod 'firebase_core'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'FLUTTER_ROOT=\\(flutter_root)',
      ]
    end
  end
end
```

#### Signing setup

```bash
# Configure in Xcode
# 1. Select Runner target
# 2. Go to Signing & Capabilities
# 3. Set Team ID
# 4. Provisioning profile auto-managed by Apple
```

---

## 🏗️ Build Commands

### Debug build

```bash
# Android
flutter build apk --debug

# iOS
flutter build ios --debug

# Web
flutter build web --debug
```

### Release build

```bash
# Android (APK)
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk

# Android (AppBundle)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab

# iOS
flutter build ios --release
# Output: build/ios/iphoneos/Runner.app

# Web
flutter build web --release
# Output: build/web/
```

### Profile build (performance testing)

```bash
flutter build apk --profile
flutter run --profile
```

---

## 📊 Build Optimization

### Size reduction

```bash
# Split APK by ABI (smaller per-device size)
flutter build apk --release --split-per-abi

# Outputs:
# - app-armeabi-v7a-release.apk (~30 MB)
# - app-arm64-v8a-release.apk (~35 MB)
# - app-x86-release.apk (~35 MB)

# vs
# - app-release.apk (~85 MB)
```

### Release optimization

```bash
# Strip debug symbols
flutter build apk --release -v

# Check size breakdown
flutter pub run build_size_analyzer --help
```

---

## 🔧 Flavors (Optional)

For different environments (dev, staging, production):

```bash
# Development build
flutter build apk --flavor dev --release

# Staging build
flutter build apk --flavor staging --release

# Production build
flutter build apk --flavor prod --release
```

Configuration:

File: `android/app/build.gradle.kts`

```gradle
flavorDimensions = listOf("app")

productFlavors {
  create("dev") {
    dimension = "app"
    applicationIdSuffix = ".dev"
    versionNameSuffix = "-dev"
  }
  create("staging") {
    dimension = "app"
    applicationIdSuffix = ".staging"
    versionNameSuffix = "-staging"
  }
  create("prod") {
    dimension = "app"
  }
}
```

---

## 📱 Play Store Deployment

### Prerequisites

1. Google Play Developer account ($25 one-time)
2. App signing key (already configured)
3. App Bundle (AAB format)
4. Screenshots, descriptions, assets

### Step-by-step

#### 1. Build App Bundle

```bash
flutter clean
flutter pub get
flutter build appbundle --release --obfuscate --split-debug-info=./symbols
```

#### 2. Create Play Store listing

- App name
- Short description (80 chars)
- Full description (4000 chars)
- Category, content rating
- Screenshots (up to 8 per language)
- Icon, feature graphic, video

#### 3. Test track release

```bash
# 1. Upload to Internal Testing track first
# 2. Invite testers
# 3. Test for 24 hours
# 4. Get feedback
# 5. Move to Closed Testing (beta)
# 6. Run beta for 1-2 weeks
```

#### 4. Production release

```
Play Console → Your app → Release → Production
→ Create new release → Upload AAB
→ Add release notes
→ Review and rollout
→ Staged rollout (5% → 25% → 100%)
```

### Release notes template

```markdown
## Version 1.0.0 - [Date]

### ✨ New Features
- Digital business card with QR code
- Scan business cards with camera
- Manage contacts
- Subscription plans
- Payment integration

### 🐛 Bug Fixes
- Fixed login error handling

### 🚀 Improvements
- Improved performance
- Better UI animations
- Dark mode support

### 📝 Notes
- Requires Android 5.0+ (API 21)
- First release on Play Store
```

---

## 🍎 App Store Deployment (iOS)

### Prerequisites

1. Apple Developer account ($99/year)
2. App signing certificate
3. Provisioning profile
4. TestFlight (for beta testing)

### Step-by-step

#### 1. Build for iOS

```bash
flutter build ios --release
```

#### 2. Archive in Xcode

```bash
# Option A: Command line
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  archive

# Option B: Open in Xcode
open ios/Runner.xcworkspace
# → Product → Archive
```

#### 3. Upload to TestFlight

```bash
# Xcode → Window → Organizer
# → Archives → Select build
# → Distribute App
# → App Store Connect
# → Upload

# Or use Transporter app
open /Applications/Transporter.app
# → Select build → Upload
```

#### 4. TestFlight beta testing

- Invite testers (up to 10,000)
- Get feedback for 24-48 hours
- Fix critical issues
- Prepare for App Store submission

#### 5. Submit to App Store

```
App Store Connect → Your App → App Store
→ Prepare for submission
→ Add metadata (description, keywords, screenshots)
→ Set pricing
→ Submit for review (24-48 hour wait)
→ If approved → Publish
```

---

## 📊 Version Management

### Versioning scheme

```
versionCode (Android): 1, 2, 3, ...
versionName (iOS): 1.0.0, 1.0.1, 1.1.0, 2.0.0
```

### Semantic versioning

```
MAJOR.MINOR.PATCH

1.0.0 - Initial release
1.0.1 - Patch fix
1.1.0 - Minor feature
2.0.0 - Major breaking change
```

### Bump version

File: `pubspec.yaml`

```yaml
version: 1.0.0+1  # version+buildNumber

# For next release:
version: 1.0.1+2  # patch fix
version: 1.1.0+3  # new features
version: 2.0.0+4  # breaking changes
```

Update in Android:

File: `android/app/build.gradle.kts`

```gradle
defaultConfig {
  versionCode = 2
  versionName = "1.0.1"
}
```

Update in iOS:

File: `ios/Runner/Info.plist`

```xml
<key>CFBundleShortVersionString</key>
<string>1.0.1</string>
<key>CFBundleVersion</key>
<string>2</string>
```

---

## 🔄 CI/CD Pipeline (Recommended)

### GitHub Actions workflow

File: `.github/workflows/build.yml`

```yaml
name: Build

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Upload APK
        uses: actions/upload-artifact@v2
        with:
          name: app-release.apk
          path: build/app/outputs/apk/release/
```

### Firebase App Distribution (for beta testing)

```bash
# Build and distribute to testers
flutter build apk --release

firebase appdistribution:distribute build/app/outputs/apk/release/app-release.apk \
  --app 1:123456789:android:abcdef123456 \
  --groups internal-testers \
  --release-notes "Version 1.0.1 with bug fixes"
```

---

## 📋 Pre-Release Checklist

### Code

- [ ] All tests passing
- [ ] No TODOs in code
- [ ] No debug prints
- [ ] No console errors/warnings
- [ ] Code reviewed
- [ ] No hardcoded secrets

### Features

- [ ] All features working on target devices
- [ ] No crashes on app launch
- [ ] Animations smooth
- [ ] Load times acceptable
- [ ] Error handling working

### Localization

- [ ] Strings in all supported languages
- [ ] Date/time formatting correct
- [ ] RTL languages supported (if needed)

### Store

- [ ] App name final
- [ ] Icon/screenshots correct
- [ ] Description accurate
- [ ] Keywords set
- [ ] Privacy policy link
- [ ] Support contact email
- [ ] Content rating completed

### Version

- [ ] Version bumped
- [ ] Build number bumped
- [ ] Release notes written
- [ ] Changelog updated

---

## 🚨 Post-Release Monitoring

### Track metrics

```
- Crashes (Firebase Crashlytics)
- User feedback (Play Store reviews)
- Performance (Firebase Performance)
- Errors (Sentry or similar)
- Adoption rate
- User retention
```

### Respond quickly to

- Critical crashes
- Negative reviews
- Security issues
- Major bugs

---

## 📊 Deployment Statistics

| Platform | Build Time | Size | Supports |
|----------|------------|------|----------|
| Android APK | ~2-3 min | 35 MB (per-ABI) | API 21+ |
| Android AAB | ~2-3 min | ~85 MB (all ABIs) | Play Store |
| iOS | ~5-10 min | ~80 MB | iOS 12.0+ |
| Web | ~3-5 min | ~20 MB | All browsers |

---

## 🔗 Resources

- [Flutter Build Documentation](https://flutter.dev/docs/deployment)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [iOS Code Signing](https://developer.apple.com/support/code-signing/)
- [Play Store Publishing](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com/)

---

**Dernière mise à jour** : 18 Mai 2026  
**Responsable** : DevOps Team  
**Status** : ✅ Prêt
