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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId: '1:123456789012:web:abcdef1234567890abcdef',
    messagingSenderId: '123456789012',
    projectId: 'steps-tracker-app',
    authDomain: 'steps-tracker-app.firebaseapp.com',
    storageBucket: 'steps-tracker-app.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAW7_hdiCYkKNOpqYtMcwgtn91vseUYkuc',
    appId: '1:1961490031:android:caa803ff7ffb24b676bf9a',
    messagingSenderId: '1961490031',
    projectId: 'steps-tracker-1760794907',
    storageBucket: 'steps-tracker-1760794907.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA5I5vESoFSTHy_M-I79ttfj5fP7o6jHkk',
    appId: '1:1961490031:ios:3d0ff12bc8ee295276bf9a',
    messagingSenderId: '1961490031',
    projectId: 'steps-tracker-1760794907',
    storageBucket: 'steps-tracker-1760794907.firebasestorage.app',
    iosBundleId: 'com.example.stepsTracker',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA5I5vESoFSTHy_M-I79ttfj5fP7o6jHkk',
    appId: '1:1961490031:ios:3d0ff12bc8ee295276bf9a',
    messagingSenderId: '1961490031',
    projectId: 'steps-tracker-1760794907',
    storageBucket: 'steps-tracker-1760794907.firebasestorage.app',
    iosBundleId: 'com.example.stepsTracker',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId: '1:123456789012:web:abcdef1234567890abcdef',
    messagingSenderId: '123456789012',
    projectId: 'steps-tracker-app',
    authDomain: 'steps-tracker-app.firebaseapp.com',
    storageBucket: 'steps-tracker-app.appspot.com',
  );
}
