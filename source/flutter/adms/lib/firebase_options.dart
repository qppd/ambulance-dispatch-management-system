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
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web — complete
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

  // Windows — uses web config (FlutterFire standard)
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD7LsP4k0h9FfXJzTj8Dt88b9_wkvDcb2Y',
    appId: '1:729212547764:web:d3ee4075d15e91066edde1',
    messagingSenderId: '729212547764',
    projectId: 'adms-929c3',
    authDomain: 'adms-929c3.firebaseapp.com',
    databaseURL: 'https://adms-929c3-default-rtdb.firebaseio.com',
    storageBucket: 'adms-929c3.firebasestorage.app',
    measurementId: 'G-QXR0CY2YTW',
  );

  // Android — register app at Firebase Console → Add app → Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD7LsP4k0h9FfXJzTj8Dt88b9_wkvDcb2Y',
    appId: '1:729212547764:android:YOUR_ANDROID_HASH',
    messagingSenderId: '729212547764',
    projectId: 'adms-929c3',
    databaseURL: 'https://adms-929c3-default-rtdb.firebaseio.com',
    storageBucket: 'adms-929c3.firebasestorage.app',
  );

  // iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD7LsP4k0h9FfXJzTj8Dt88b9_wkvDcb2Y',
    appId: '1:729212547764:ios:YOUR_IOS_HASH',
    messagingSenderId: '729212547764',
    projectId: 'adms-929c3',
    databaseURL: 'https://adms-929c3-default-rtdb.firebaseio.com',
    storageBucket: 'adms-929c3.firebasestorage.app',
    iosBundleId: 'com.example.adms',
  );

  // macOS
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD7LsP4k0h9FfXJzTj8Dt88b9_wkvDcb2Y',
    appId: '1:729212547764:ios:YOUR_IOS_HASH',
    messagingSenderId: '729212547764',
    projectId: 'adms-929c3',
    databaseURL: 'https://adms-929c3-default-rtdb.firebaseio.com',
    storageBucket: 'adms-929c3.firebasestorage.app',
    iosBundleId: 'com.example.adms',
  );
}
