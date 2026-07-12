// File generated for Firebase multi-platform configuration
// Android + Web support

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Konfigurasi Web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDcsKwGhVESM6y2C-BuQulL63zCXn0gRIY',
    appId: '1:549175691785:web:a17d3268442bf80ad046d8',
    messagingSenderId: '549175691785',
    projectId: 'aplikasi-absensi-707c0',
    authDomain: 'aplikasi-absensi-707c0.firebaseapp.com',
    storageBucket: 'aplikasi-absensi-707c0.firebasestorage.app',
    measurementId: 'G-20FCZRTCYK',
  );

  // Konfigurasi Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBEcap93faocZYkHYCNX36Jy26UYII3P_I',
    appId: '1:549175691785:android:ca11f911b3b79294d046d8',
    messagingSenderId: '549175691785',
    projectId: 'aplikasi-absensi-707c0',
    storageBucket: 'aplikasi-absensi-707c0.firebasestorage.app',
  );

  // Konfigurasi Windows
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDcsKwGhVESM6y2C-BuQulL63zCXn0gRIY',
    appId: '1:549175691785:web:a17d3268442bf80ad046d8',
    messagingSenderId: '549175691785',
    projectId: 'aplikasi-absensi-707c0',
    authDomain: 'aplikasi-absensi-707c0.firebaseapp.com',
    storageBucket: 'aplikasi-absensi-707c0.firebasestorage.app',
  );
}
