---
description: "Complete checklist for Flutter CI/CD: accounts, Android/iOS requirements, Firebase, GitHub setup, code-side configuration, and total cost breakdown."
tags:
  - CI/CD
  - Git
  - Template
  - Roadmap
---
# Everything You Need for Flutter CI/CD - Complete Checklist

> *"The hard part of a Flutter mobile pipeline isn't compiling; it's automating the whole thing end-to-end without leaking signing keys and store credentials, and without manual touch."*

## 📑 Table of Contents
1. [Accounts and Memberships](#1-accounts-and-memberships)
2. [Android Requirements](#2-android-requirements)
3. [iOS Requirements](#3-ios-requirements)
4. [Firebase Requirements](#4-firebase-requirements)
5. [GitHub Requirements](#5-github-requirements)
6. [Code-Side Configuration](#6-code-side-configuration)
7. [Optional But Recommended](#7-optional-but-recommended)
8. [Total Cost Breakdown](#8-total-cost-breakdown)

---

## 1. Accounts and Memberships

### ✅ Google Play Console Account
**What:** Google's platform for publishing Android apps  
**Why Needed:** Mandatory for publishing an app on the Play Store  
**Cost:** $25 (one-time, lifetime)  
**How to Get It:**
1. Go to https://play.google.com/console
2. Sign in with your Google account
3. Pay the $25 developer registration fee
4. Fill in your developer profile information
5. Approval can take 1-2 days

**Required Access Levels:**
- Admin access (to publish apps)
- Release management
- Permission to create service accounts

---

### ✅ Apple Developer Program Membership
**What:** Apple's developer program for publishing iOS apps  
**Why Needed:** Mandatory for publishing an app on the App Store and creating certificates  
**Cost:** $99/year (annual subscription)  
**How to Get It:**
1. Go to https://developer.apple.com/programs/
2. Register with an Apple ID
3. Choose a personal or company account (a company account needs a D-U-N-S number)
4. Pay the $99 annual fee
5. Approval can take 24-48 hours

**Required Roles:**
- Account Holder or Admin
- Certificates, Identifiers & Profiles access
- App Store Connect access

---

### ✅ Firebase Account
**What:** Google's mobile app development platform  
**Why Needed:** For test distribution (Firebase App Distribution)  
**Cost:** Free (Spark Plan) — sufficient for App Distribution  
**How to Get It:**
1. Go to https://firebase.google.com/
2. Sign in with your Google account
3. Click "Go to console"
4. Create a new project

**Note:** Features like App Distribution and Analytics are available on the free plan

---

### ✅ GitHub Account
**What:** For the code repository and CI/CD  
**Why Needed:** For code management and GitHub Actions  
**Cost:** 
- Free (sufficient for a public repo)
- Or $4/month (private repo + more Actions minutes)
**How to Get It:**
1. Go to https://github.com/
2. Create a free account

**GitHub Actions Free Limit:**
- Public repo: Unlimited minutes
- Private repo: 2,000 minutes/month (sufficient)

---

### ⭐ Codecov Account (Optional)
**What:** Test coverage reporting  
**Why Needed:** For tracking code coverage (optional but recommended)  
**Cost:** Free (for public repos)  
**How to Get It:**
1. Go to https://codecov.io/
2. Sign in with your GitHub account
3. Connect your repository

---

## 2. Android Requirements

### ✅ Keystore File (.jks)
**What:** Digital certificate for signing your Android app  
**Why Needed:** APK/AAB must be signed to upload to the Play Store  
**How to Create It:**

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -storetype JKS
```

**Information You'll Be Asked For:**
- Keystore password: Choose a strong password
- Key password: Choose a strong password (can be different)
- First and Last Name: Full name or company name
- Organizational Unit: Department name (e.g. Development)
- Organization: Company name
- City/Locality: City
- State/Province: State/province
- Country Code: TR

**WARNING:**
- ⚠️ NEVER lose this file or the passwords!
- ⚠️ If you lose it, you can't update your app
- ⚠️ Back it up somewhere secure (password manager + cloud)
- ⚠️ NEVER commit it to Git

**Store:**
```
keystore.jks
Keystore password: [password]
Key alias: upload
Key password: [password]
```

---

### ✅ Google Play Service Account
**What:** Service account for accessing the Play Store API  
**Why Needed:** For automatic upload from CI/CD  
**How to Create It:**

#### Step 1: Create a Service Account in Google Cloud Console
1. Go to Google Cloud Console: https://console.cloud.google.com/
2. Select the project linked to Play Console (create one if it doesn't exist)
3. IAM & Admin > Service Accounts
4. Click "Create Service Account"
5. Give it a name (e.g. "github-actions-deployer")
6. Click "Create and Continue"
7. Choose the role: "Service Account User"
8. Click "Done"
9. Click on the service account you created
10. Keys tab > Add Key > Create new key
11. Select the JSON format
12. Store the downloaded JSON file somewhere secure

#### Step 2: Link the Service Account in Play Console
1. Go to Play Console: https://play.google.com/console
2. Setup > API access
3. Click the "Link" button (for the new service account)
4. Select and link the service account
5. Click Grant Access
6. Set the permissions:
   - Admin (Releases): View, Create, Edit
   - Release Manager: All permissions

**Store:**
```json
{
  "type": "service_account",
  "project_id": "...",
  "private_key_id": "...",
  "private_key": "...",
  ...
}
```

---

### ✅ Android App Bundle ID
**What:** Your app's unique identifier  
**Why Needed:** To identify the app on the Play Store  
**Format:** com.companyname.appname (e.g. com.onmuhasebe.mobile)  
**Where:** In `android/app/build.gradle`:
```gradle
defaultConfig {
    applicationId "com.onmuhasebe.mobile"
    ...
}
```

---

### ✅ key.properties File (Template)
**What:** Configuration holding the keystore information  
**Why Needed:** For signing during the Android build  
**Location:** `android/key.properties`  
**Content:**
```properties
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=upload
storeFile=../upload-keystore.jks
```

**WARNING:** Add this file to .gitignore!

---

### ✅ android/app/build.gradle Configuration
**What:** Build configuration  
**Why Needed:** For signing release builds  
**What to Do:**

```gradle
// Add to the top of the file
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

### ✅ ProGuard Rules (Optional but Recommended)
**What:** Code obfuscation rules  
**Why Needed:** Security and APK size optimization  
**Location:** `android/app/proguard-rules.pro`  
**Basic Content:**
```proguard
# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
```

---

## 3. iOS Requirements

### ✅ App Store Connect Account Access
**What:** Apple's platform for managing iOS apps  
**Why Needed:** For uploading to the App Store and managing metadata  
**How to Access:**
1. Go to https://appstoreconnect.apple.com/
2. Sign in with your Apple Developer account
3. Create your app under "My Apps"

---

### ✅ iOS Distribution Certificate (.p12)
**What:** Certificate for signing your iOS app  
**Why Needed:** IPA must be signed to upload to the App Store  
**How to Create It:**

#### Step 1: Create a Certificate Signing Request (CSR)
1. Open "Keychain Access" on your Mac
2. Keychain Access > Certificate Assistant > Request a Certificate From a Certificate Authority
3. Enter your email address
4. Select "Saved to disk"
5. Click "Continue" and save the file

#### Step 2: Create the Certificate in Developer Portal
1. Go to https://developer.apple.com/account/resources/certificates
2. Click the "+" button
3. Select "Apple Distribution"
4. Continue
5. Upload the CSR file
6. Click Download (a .cer file will download)

#### Step 3: P12 Export
1. Double-click the downloaded .cer file (it will be added to Keychain)
2. Find it under the "Certificates" category in Keychain Access
3. Right-click the certificate > Export
4. Select the .p12 format
5. Set a strong password (store this!)
6. Export it

**Store:**
```
distribution_certificate.p12
Certificate password: [password]
```

---

### ✅ Provisioning Profile (.mobileprovision)
**What:** Determines which devices your app can run on  
**Why Needed:** Mandatory for iOS build and distribution  
**How to Create It:**

#### Step 1: Create an App ID (If It Doesn't Exist)
1. Go to https://developer.apple.com/account/resources/identifiers
2. Click the "+" button
3. Select "App IDs", Continue
4. Select "App", Continue
5. Enter a description
6. Enter the Bundle ID (e.g. com.onmuhasebe.mobile)
7. Select capabilities (Push Notifications, In-App Purchase, etc.)
8. Continue and Register

#### Step 2: Create the Provisioning Profile
1. Go to https://developer.apple.com/account/resources/profiles
2. Click the "+" button
3. Select "App Store" (for production), Continue
4. Select your App ID, Continue
5. Select your certificate, Continue
6. Enter a profile name (e.g. "AppStore Distribution Profile")
7. Generate
8. Download (a .mobileprovision file will download)

**Store:**
```
distribution_profile.mobileprovision
```

---

### ✅ App Store Connect API Key
**What:** Key for accessing the App Store Connect API  
**Why Needed:** For automatic upload from CI/CD  
**How to Create It:**

1. Go to App Store Connect: https://appstoreconnect.apple.com/
2. Users and Access > Keys tab
3. Under "App Store Connect API" click "+"
4. Enter a name (e.g. "GitHub Actions")
5. Access: select "Admin" or "App Manager"
6. Click Generate
7. Download the API Key (.p8 file — you can only download it once!)
8. Note down the Key ID and Issuer ID

**Store:**
```
AuthKey_XXXXXXXXXX.p8
Key ID: XXXXXXXXXX
Issuer ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

### ✅ Team ID
**What:** Your Apple Developer account's unique ID  
**Why Needed:** For iOS build and provisioning  
**How to Find It:**
1. Go to https://developer.apple.com/account
2. Click the "Membership" tab
3. You'll see the "Team ID" (a 10-character code)

**Store:**
```
Team ID: XXXXXXXXXX
```

---

### ✅ Bundle Identifier
**What:** Your iOS app's unique identifier  
**Why Needed:** To identify the app on the App Store  
**Format:** com.companyname.appname  
**Where:** In `ios/Runner/Info.plist` or in Xcode:
```xml
<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
```

In Xcode: Runner target > Signing & Capabilities > Bundle Identifier

---

### ✅ ExportOptions.plist
**What:** IPA export configuration  
**Why Needed:** Required when generating the IPA with xcodebuild  
**Location:** `ios/Runner/ExportOptions.plist`  
**Content:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.onmuhasebe.mobile</key>
        <string>Your Profile Name</string>
    </dict>
</dict>
</plist>
```

**Replace:**
- `YOUR_TEAM_ID`: Enter your Team ID
- `com.onmuhasebe.mobile`: Enter your Bundle ID
- `Your Profile Name`: Enter your provisioning profile name

---

## 4. Firebase Requirements

### ✅ Firebase Project
**What:** A project created in Firebase  
**Why Needed:** For App Distribution and other Firebase services  
**How to Create It:**
1. Firebase Console: https://console.firebase.google.com/
2. Click "Add project"
3. Enter a project name
4. Enable Google Analytics (optional)
5. Create project

---

### ✅ Firebase Android App
**What:** Android app added to the Firebase project  
**Why Needed:** To use Firebase services  
**How to Add It:**
1. Open your project in Firebase Console
2. Click the Android icon
3. Enter the Android package name (Bundle ID)
4. App nickname (optional)
5. Register app
6. Download the `google-services.json` file
7. Copy it into the `android/app/` folder

**Store:**
```
Firebase Android App ID: 1:xxxxx:android:xxxxx
```

---

### ✅ Firebase iOS App
**What:** iOS app added to the Firebase project  
**Why Needed:** To use Firebase services  
**How to Add It:**
1. Open your project in Firebase Console
2. Click the iOS icon
3. Enter the iOS bundle ID
4. App nickname (optional)
5. Register app
6. Download the `GoogleService-Info.plist` file
7. Add it to the Runner target in Xcode (drag & drop, with "Copy items if needed" checked)

**Store:**
```
Firebase iOS App ID: 1:xxxxx:ios:xxxxx
```

---

### ✅ Firebase Service Account
**What:** Service account for the Firebase Admin SDK  
**Why Needed:** For CI/CD access to Firebase  
**How to Create It:**

1. Firebase Console > Project Settings (⚙️ icon)
2. Service Accounts tab
3. Click "Generate new private key"
4. Download the JSON file and store it somewhere secure

**WARNING:** This file grants full access — keep it secure!

**Store:**
```json
{
  "type": "service_account",
  "project_id": "your-project",
  "private_key_id": "...",
  "private_key": "...",
  ...
}
```

---

### ✅ Firebase App Distribution Tester Groups
**What:** Groups of your test users  
**Why Needed:** For distributing builds  
**How to Create It:**

1. Firebase Console > App Distribution
2. "Testers & Groups" tab
3. Click "Add Group"
4. Give it a group name (e.g. "testers", "qa-team", "beta-users")
5. Add tester emails
6. Create group

**Note:** You'll use this group name in the CI/CD workflow

---

## 5. GitHub Requirements

### ✅ GitHub Repository
**What:** The repository holding your code  
**Why Needed:** For version control and GitHub Actions  
**How to Create It:**
1. Click "New repository" on GitHub
2. Give it a name
3. Choose Public or Private
4. Initialize with README (optional)
5. Create repository

---

### ✅ Enabling GitHub Actions
**What:** Where your CI/CD pipeline runs  
**Why Needed:** For automatic build and deploy  
**How to Enable It:**

It's automatically active on the repository — you just need to add a workflow file:
- Create the `.github/workflows/ci-cd.yml` file

---

### ✅ GitHub Secrets
**What:** Secure storage for sensitive information  
**Why Needed:** For passwords, keys, etc.  
**How to Add Them:**

1. GitHub repository > Settings
2. Secrets and variables > Actions
3. Click "New repository secret"
4. Enter Name and Value
5. Add secret

**Full List of Secrets:**

#### Android Secrets:
```
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_PASSWORD
ANDROID_KEY_ALIAS
GOOGLE_PLAY_SERVICE_ACCOUNT
```

#### iOS Secrets:
```
IOS_CERTIFICATE_BASE64
IOS_CERTIFICATE_PASSWORD
IOS_PROVISION_PROFILE_BASE64
APP_STORE_CONNECT_API_KEY
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_KEY_ID
IOS_TEAM_ID
```

#### Firebase Secrets:
```
FIREBASE_SERVICE_ACCOUNT
FIREBASE_ANDROID_APP_ID
FIREBASE_IOS_APP_ID
```

#### Optional Secrets:
```
CODECOV_TOKEN
SLACK_WEBHOOK
KEYCHAIN_PASSWORD
```

---

### ✅ Base64 Encoding Commands
**What:** Converting binary files into a GitHub Secret  
**Why Needed:** GitHub Secrets only accepts text  
**How to Do It:**

#### Mac/Linux:
```bash
# Android Keystore
base64 -i upload-keystore.jks | pbcopy

# iOS Certificate
base64 -i distribution_certificate.p12 | pbcopy

# iOS Provisioning Profile
base64 -i distribution_profile.mobileprovision | pbcopy
```

#### Windows PowerShell:
```powershell
# Android Keystore
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard

# iOS Certificate
[Convert]::ToBase64String([IO.File]::ReadAllBytes("distribution_certificate.p12")) | Set-Clipboard

# iOS Provisioning Profile
[Convert]::ToBase64String([IO.File]::ReadAllBytes("distribution_profile.mobileprovision")) | Set-Clipboard
```

---

## 6. Code-Side Configuration

### ✅ .gitignore Update
**What:** Files that must not be committed to Git  
**Why Needed:** Security — prevent sensitive information from going into Git  
**What to Add:**

```gitignore
# Android
android/key.properties
android/app/keystore.jks
android/app/upload-keystore.jks

# iOS
ios/Runner/GoogleService-Info.plist
ios/Runner/ExportOptions.plist
*.mobileprovision
*.p12
*.cer

# Firebase
google-services.json

# Secrets
.env
.env.local
*.key
*.pem
```

---

### ✅ pubspec.yaml Version Management
**What:** The app version  
**Why Needed:** The version must be bumped for every release  
**Format:**
```yaml
version: 1.0.0+1
#        └─┬─┘ └┬┘
#          │    └── Build number (integer)
#          └─────── Version name (semantic versioning)
```

**Automatic via CI/CD:**
You can bump it automatically in the workflow using `--build-number=${{ github.run_number }}`

---

### ✅ Flutter Build Configuration
**What:** Build settings  
**Why Needed:** For an optimal build  
**What to Do:**

#### android/app/build.gradle:
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // For modern Android
        targetSdkVersion 34  // Latest API level
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true
    }
    
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            signingConfig signingConfigs.release
        }
    }
}
```

#### ios/Runner.xcodeproj:
In Xcode, Runner > Build Settings:
- Enable Bitcode: NO
- Optimize for Speed: YES
- Strip Debug Symbols: YES (for Release)

---

### ✅ Platform-Specific Configurations
**What:** Platform-specific settings  
**Why Needed:** Store requirements

#### Android:
- `android/app/src/main/AndroidManifest.xml`: Permissions
- `android/app/src/main/res`: Icons, launcher

#### iOS:
- `ios/Runner/Info.plist`: Permissions, configurations
- `ios/Runner/Assets.xcassets`: Icons, launch screens

---

## 7. Optional But Recommended

### ⭐ Crashlytics/Sentry
**What:** Crash reporting  
**Why Recommended:** For tracking errors in production  
**Alternatives:**
- Firebase Crashlytics (free)
- Sentry (has a free tier)

---

### ⭐ Analytics
**What:** Tracking user behavior  
**Why Recommended:** For product development decisions  
**Alternatives:**
- Firebase Analytics (free)
- Mixpanel (free tier)
- Amplitude (free tier)

---

### ⭐ Slack/Discord Webhook
**What:** Build notifications  
**Why Recommended:** For tracking build status  
**How to Set It Up:**

Slack:
1. Slack workspace > Apps > Incoming Webhooks
2. Add to Slack
3. Choose a channel
4. Copy the webhook URL
5. Add it as a GitHub Secret: `SLACK_WEBHOOK`

---

### ⭐ Status Badge
**What:** Build status indicator in the README  
**Why Recommended:** Professional appearance  
**How to Add It:**

In README.md:
```markdown
![CI/CD](https://github.com/username/repo/workflows/Flutter%20CI%2FCD%20Pipeline/badge.svg)
```

---

## 8. Total Cost Breakdown

### Mandatory Costs:
| Item | Cost | Period |
|------|------|--------|
| Google Play Console | $25 | One-time |
| Apple Developer Program | $99 | Annual |
| **TOTAL** | **$124** | **First Year** |
| **TOTAL** | **$99** | **Subsequent Years** |

### Optional (Recommended):
| Item | Cost | Notes |
|------|------|-------|
| Firebase (Spark Plan) | Free | Sufficient for App Distribution |
| GitHub (Public Repo) | Free | Unlimited Actions |
| GitHub (Private Repo) | $4/month | 2000 minutes/month Actions |
| Codecov | Free | For public repos |
| Domain (optional) | ~$10/year | For a website |

### GitHub Actions Usage Estimate:
**Average build times:**
- Test job: ~5 minutes
- Android build: ~15 minutes
- iOS build: ~25 minutes
- **Total:** ~45 minutes per build

**Monthly estimate:**
- 2 builds/day × 30 days = 60 builds
- 60 × 45 minutes = 2,700 minutes
- Private repo limit: 2,000 minutes (free)
- **Result:** You may need the Team plan ($4/month)

---

## 📋 Quick Start Checklist

### 📅 Today's Tasks (2-3 hours):
- [ ] Open a Google Play Console account ($25)
- [ ] Open an Apple Developer account ($99/year)
- [ ] Create a Firebase project
- [ ] Create a GitHub repository
- [ ] Create an Android keystore
- [ ] Store the keystore information somewhere secure

### 📅 Tomorrow's Tasks (3-4 hours):
- [ ] Create the iOS Certificate and Provisioning Profile
- [ ] Get an App Store Connect API key
- [ ] Add the Android and iOS apps to Firebase
- [ ] Download google-services.json and GoogleService-Info.plist
- [ ] Back up all files somewhere secure

### 📅 This Week's Tasks (4-6 hours):
- [ ] Add the GitHub Secrets (all base64s)
- [ ] Add the workflow file
- [ ] Run the first test build
- [ ] Test the Android build
- [ ] Test the iOS build

### 📅 Next Week's Tasks (2-3 hours):
- [ ] Test Firebase Distribution
- [ ] Test upload to the Play Store internal track
- [ ] Test upload to TestFlight
- [ ] Define the production deployment procedure

---

## 🚨 Critical Warnings

### ⚠️ NEVER DO THIS:
1. ❌ Don't commit the keystore file to Git
2. ❌ Don't commit the key.properties file to Git
3. ❌ Don't hardcode passwords in code
4. ❌ Don't add .p12 and .mobileprovision files to Git
5. ❌ Don't make service account JSONs public
6. ❌ Don't print API keys to logs

### ✅ ALWAYS DO THIS:
1. ✅ Add all sensitive files to .gitignore
2. ✅ Back up the keystore and passwords in at least 3 places
3. ✅ Use a password manager (1Password, LastPass, etc.)
4. ✅ Run your first tests on a dev/develop branch
5. ✅ Do internal testing before a production deploy
6. ✅ Track certificate expiry dates

---

## 🎯 Summary: The 10 Most Important Things

1. **Google Play Console account** ($25) ✅
2. **Apple Developer account** ($99/year) ✅
3. **Android Keystore** + passwords ✅
4. **iOS Certificate (.p12)** + password ✅
5. **iOS Provisioning Profile** (.mobileprovision) ✅
6. **App Store Connect API Key** (.p8) ✅
7. **Firebase Service Account** (JSON) ✅
8. **Google Play Service Account** (JSON) ✅
9. **GitHub Secrets** (all of the above, base64-encoded) ✅
10. **.gitignore** (for sensitive files) ✅

---

## 🚫 Anti-Pattern

Common mistakes made when setting up Flutter CI/CD that you must absolutely avoid:

| Anti-pattern | Why it's bad | Do this instead |
|--------------|---------------|------------------|
| Committing keystore/.p12/.mobileprovision files to the repo | The certificate leaks, anyone can sign your app; irreversible. | Add sensitive files to `.gitignore`, store them base64-encoded in GitHub Secrets. |
| Embedding passwords in workflow YAML or in code | Anyone who sees the repo gets the credential; rotation becomes impossible. | Read all credentials from Secrets via `${{ secrets.* }}` references. |
| Keeping the keystore in one place / not backing it up | If you lose it you can never update the app again (Play Store requires matching signature). | Back up in at least 3 separate places: password manager + encrypted cloud + offline. |
| Bumping the build number by hand | Humans forget; a colliding build number gets the upload rejected. | Bump it automatically with `--build-number=${{ github.run_number }}`. |
| Sending the first tests straight to the production track | A broken build reaches real users; hard to pull back. | Try it first on Firebase Distribution / internal track / TestFlight. |
| Printing the API key / service account JSON to logs | If Actions logs leak, the credential is exposed. | Don't echo secrets; use `add-mask` or don't print them at all. |
| Not tracking certificate expiry dates | The pipeline breaks suddenly when the certificate expires, blocking releases. | Put expiry dates on a calendar/alert, renew before they expire. |
| Shipping a release build unsigned or with `minifyEnabled false` | The store rejects it, or the APK bloats and the code stays exposed. | Keep `signingConfig` + `minifyEnabled`/`shrinkResources` + ProGuard active. |
| Skipping the `flutter test` / lint step in CI | Broken code makes it all the way to the store, caught late. | Make the test job a required check before builds. |
| Granting the service account Owner/overly broad permissions | If it leaks, the whole project is exposed. | Least privilege: grant only the Release Manager / App Manager role. |

---

## 📞 Help Resources

### Documentation:
- Flutter: https://docs.flutter.dev/
- GitHub Actions: https://docs.github.com/en/actions
- Firebase: https://firebase.google.com/docs
- Play Console: https://support.google.com/googleplay/android-developer
- App Store Connect: https://developer.apple.com/app-store-connect/

### Community:
- Flutter Discord: https://discord.gg/flutter
- Stack Overflow: `[flutter]` tag
- GitHub Discussions: flutter/flutter

### For Bugs:
- Flutter Issues: https://github.com/flutter/flutter/issues
- GitHub Actions Community: https://github.community/

---


Follow this checklist and you can set up a complete CI/CD infrastructure! Check off each item as you complete it. 🚀

> *"The real work in Flutter CI/CD isn't in the code — it's automating store accounts, signing keys, and service account permissions without leaking them; every manually signed build is technical debt."*
