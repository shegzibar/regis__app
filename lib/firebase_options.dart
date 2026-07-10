// File generated manually from Firebase console config.
// To regenerate using FlutterFire CLI:
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=cxsupportforya

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
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform. '
          'You can reconfigure this by running flutterfire configure again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Web configuration (cxsupport app)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAbnYB0ms5nx1_yZbyfw2Z2CPa5iS7R2k4',
    appId: '1:257435547697:web:f5d533e4379c85f6f8bd10',
    messagingSenderId: '257435547697',
    projectId: 'cxsupportforya',
    authDomain: 'cxsupportforya.firebaseapp.com',
    storageBucket: 'cxsupportforya.firebasestorage.app',
    measurementId: 'G-TKN8G2710M',
  );

  /// Android configuration (com.example.gaming_hub)
  /// If you have a google-services.json, run flutterfire configure to get
  /// the exact android appId.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbnYB0ms5nx1_yZbyfw2Z2CPa5iS7R2k4',
    appId: '1:257435547697:android:f5d533e4379c85f6f8bd10',
    messagingSenderId: '257435547697',
    projectId: 'cxsupportforya',
    storageBucket: 'cxsupportforya.firebasestorage.app',
  );
}
