// ============================================================================
// Firebase Configuration Template
// ============================================================================
// PROJECT: adms-929c3
//
// The values below that are already filled (projectId, databaseURL,
// authDomain, storageBucket) are derived from your Firebase project.
//
// YOU STILL NEED to fill in from Firebase Console:
//   Go to: https://console.firebase.google.com/project/adms-929c3/settings/general
//   Scroll to "Your apps" section.
//
//   For each platform app you've registered, you'll find:
//     - apiKey      → "Web API key" / "API key"
//     - appId       → "App ID"  (format: 1:PROJECT_NUMBER:platform:HASH)
//     - messagingSenderId → "Project number" (same for all platforms)
//     - measurementId → "Measurement ID" (Web only, starts with G-)
//
// RECOMMENDED: Run FlutterFire CLI to auto-generate firebase_options.dart:
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=adms-929c3
//
// IMPORTANT: Copy this file to 'firebase_options.dart' (same directory),
// fill in your values, and NEVER commit firebase_options.dart to git.
// ============================================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ============================================================================
  // WEB CONFIGURATION
  // Get from: Firebase Console → Project Settings → Your apps → Web app
  // ============================================================================
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD7LsP4k0h9FfXJzTj8Dt88b9_wkvDcb2Y',
    appId: '1:729212547764:web:d3ee4075d15e91066edde1',
    messagingSenderId: '729212547764',
    projectId: 'adms-929c3',
    authDomain: 'adms-929c3.firebaseapp.com',
    databaseURL: 'https://adms-929c3-default-rtdb.firebaseio.com',
    storageBucket: 'adms-929c3.firebasestorage.app',
    measurementId: 'G-QXR0CY2YTW',
  );

  // ============================================================================
  // ANDROID CONFIGURATION
  // Get from: Firebase Console → Project Settings → Your apps → Android app
  // ============================================================================
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',                 // ← fill this
    appId: 'YOUR_ANDROID_APP_ID',                   // ← fill this (1:...:android:...)
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',  // ← same as web (project number)
    projectId: 'adms-929c3',
    databaseURL: 'https://adms-929c3-default-rtdb.firebaseio.com',
    storageBucket: 'adms-929c3.firebasestorage.app',
  );

  // ============================================================================
  // iOS CONFIGURATION
  // Get from: Firebase Console → Project Settings → Your apps → iOS app
  // ============================================================================
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',                     // ← fill this
    appId: 'YOUR_IOS_APP_ID',                       // ← fill this (1:...:ios:...)
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',  // ← same as web (project number)
    projectId: 'adms-929c3',
    databaseURL: 'https://adms-929c3-default-rtdb.firebaseio.com',
    storageBucket: 'adms-929c3.firebasestorage.app',
    iosBundleId: 'com.example.adms',               // ← update if different
  );

  // ============================================================================
  // macOS CONFIGURATION
  // Get from: Firebase Console → Project Settings → Your apps → macOS app
  // ============================================================================
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',                   // ← fill this
    appId: 'YOUR_MACOS_APP_ID',                     // ← fill this (1:...:ios:...)
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',  // ← same as web (project number)
    projectId: 'adms-929c3',
    databaseURL: 'https://adms-929c3-default-rtdb.firebaseio.com',
    storageBucket: 'adms-929c3.firebasestorage.app',
    iosBundleId: 'com.example.adms',               // ← update if different
  );

  // ============================================================================
  // WINDOWS CONFIGURATION
  // Get from: Firebase Console → Project Settings → Your apps → Web app
  // (Windows uses same config as Web for FlutterFire)
  // ============================================================================
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_WINDOWS_API_KEY',                 // ← fill this (same as web)
    appId: 'YOUR_WINDOWS_APP_ID',                   // ← fill this (1:...:web:...)
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',  // ← same as web (project number)
    projectId: 'adms-929c3',
    databaseURL: 'https://adms-929c3-default-rtdb.firebaseio.com',
    storageBucket: 'adms-929c3.firebasestorage.app',
  );
}
