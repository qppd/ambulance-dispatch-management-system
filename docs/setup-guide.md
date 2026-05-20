# Setup Guide

## Prerequisites

| Dependency | Version | Purpose |
|------------|---------|---------|
| Flutter SDK | ≥3.9 | Cross‑platform UI framework |
| Dart SDK | ≥3.9 | Language runtime (bundled with Flutter) |
| Node.js | ≥20 | Firebase Cloud Functions |
| Firebase CLI | latest | Deploy functions & rules |
| Git | any | Version control |
| IDE | any | VS Code or Android Studio recommended |

## Firebase Setup

### 1. Create a Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project (or use existing)
3. Register the app for each platform (Android, iOS, Web)

### 2. Enable Services

| Service | Configuration |
|---------|---------------|
| **Authentication** | Enable **Email/Password** sign‑in provider |
| **Realtime Database** | Create database, start in **test mode** (lock down with `database.rules.json` later) |
| **Cloud Messaging** | Enable FCM (no additional config needed for the app) |
| **Analytics** | Enable (auto‑collects basic events) |

### 3. Generate Firebase Options

```bash
# Install Firebase CLI if not already
npm install -g firebase-tools

# Login
firebase login

# Initialize Flutter Firebase
cd source/flutter/adms
flutterfire configure --project=your-project-id
```

This generates `lib/firebase_options.dart`. If not available, use the template:

```bash
cp lib/firebase_options_template.dart lib/firebase_options.dart
# Edit with your Firebase project credentials
```

## Flutter Setup

```bash
# 1. Navigate to Flutter project
cd ambulance-dispatch-management-system/source/flutter/adms

# 2. Install dependencies
flutter pub get

# 3. Create .env file (optional, for API keys)
echo "MAPBOX_ACCESS_TOKEN=your_token_here" > .env

# 4. Verify compilation
flutter analyze

# 5. Run the app
flutter run
```

### Platform‑Specific Setup

#### Android

1. Update `android/app/build.gradle`:
   - `minSdkVersion` must be ≥ 23 (for Firebase)
   - `compileSdkVersion` should be 34+

2. Place `google-services.json` (from Firebase console → Android app) in `android/app/`

#### iOS

1. Place `GoogleService-Info.plist` in `ios/Runner/` via Xcode
2. Ensure `ios/Podfile` has `platform :ios, '13.0'` or higher

#### Web

```bash
flutter run -d chrome
```

Firebase FCM topic subscriptions are **not supported on web** — the app gracefully skips topic operations when running in a browser.

## Cloud Functions Setup

```bash
# 1. Navigate to functions directory
cd ambulance-dispatch-management-system/functions

# 2. Install dependencies
npm install

# 3. Set Firebase project
firebase use your-project-id

# 4. Deploy functions
npm run deploy

# 5. Or test locally
npm run serve
```

## Firebase Database Rules

Deploy the security rules to lock down your database:

```bash
cd source/flutter/adms
firebase deploy --only database
```

The rules enforce role‑based access at every node:
- Citizens can only create incidents (not read others' without a linked index)
- Municipal admins can read/manage their municipality's data
- Super admins have full access
- `auditLog` writes are blocked from client — only Cloud Functions can write

## Environment Variables

| Variable | File | Required | Purpose |
|----------|------|----------|---------|
| Firebase project ID | `firebase_options.dart` | Yes | Firebase project identifier |
| `MAPBOX_ACCESS_TOKEN` | `.env` | No | Map tile styling (optional, OSM works without) |

## Verification Checklist

After setup, verify everything works:

- [ ] `flutter analyze` passes with **0 errors**
- [ ] `flutter pub get` resolves all dependencies
- [ ] `npm install` in `functions/` succeeds
- [ ] Firebase project has Auth, RTDB, Messaging, Analytics enabled
- [ ] Cloud Functions deploy without errors
- [ ] App can be launched on at least one target platform
- [ ] Login with test credentials works
- [ ] Citizen can report an incident
- [ ] Admin dashboard shows the incident
- [ ] Driver receives push notification on dispatch