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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDxV2ochVKX6KJtvy6gHrDNO_zLorKynVs',
    appId: '1:339395447043:web:5140f556298f85cb4fc136',
    messagingSenderId: '339395447043',
    projectId: 'receipt-app-58d4e',
    authDomain: 'receipt-app-58d4e.firebaseapp.com',
    storageBucket: 'receipt-app-58d4e.firebasestorage.app',
    measurementId: 'G-40LJDCYM81',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCBbfyD1wYXkTFHwH4C33v2ZvPOAvsVSRE',
    appId: '1:339395447043:android:fbd1bced03e8b0d44fc136',
    messagingSenderId: '339395447043',
    projectId: 'receipt-app-58d4e',
    storageBucket: 'receipt-app-58d4e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBm9eFwR7wOPxFqAowCF-3x1oZyuC8Rnxw',
    appId: '1:339395447043:ios:852fd6fc1c07c5ed4fc136',
    messagingSenderId: '339395447043',
    projectId: 'receipt-app-58d4e',
    storageBucket: 'receipt-app-58d4e.firebasestorage.app',
    iosBundleId: 'com.example.receiptLockerFlutter',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDxV2ochVKX6KJtvy6gHrDNO_zLorKynVs',
    appId: '1:339395447043:web:a0cfc6adad2c20504fc136',
    messagingSenderId: '339395447043',
    projectId: 'receipt-app-58d4e',
    authDomain: 'receipt-app-58d4e.firebaseapp.com',
    storageBucket: 'receipt-app-58d4e.firebasestorage.app',
    measurementId: 'G-RZTCTX3ZDB',
  );
}
