// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyDsLHb9ioF9kXYzszBX_ve6lfvaIawy7zg',
    appId: '1:19193586262:web:1479f1f95a835f42eb51f7',
    messagingSenderId: '19193586262',
    projectId: 'proje1-d2f6c',
    authDomain: 'proje1-d2f6c.firebaseapp.com',
    storageBucket: 'proje1-d2f6c.appspot.com',
    measurementId: 'G-MQYDZC5S49',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBpGOF44mHUQONeBRXQe_7TYsk0XlrGMvY',
    appId: '1:19193586262:android:8ee3dd5269f0c5eceb51f7',
    messagingSenderId: '19193586262',
    projectId: 'proje1-d2f6c',
    storageBucket: 'proje1-d2f6c.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBeG0TLZnRCRKhhlFOkctaEhtu7Fxta-iU',
    appId: '1:19193586262:ios:55c67f0db920e86beb51f7',
    messagingSenderId: '19193586262',
    projectId: 'proje1-d2f6c',
    storageBucket: 'proje1-d2f6c.appspot.com',
    iosBundleId: 'com.example.proje1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBeG0TLZnRCRKhhlFOkctaEhtu7Fxta-iU',
    appId: '1:19193586262:ios:55c67f0db920e86beb51f7',
    messagingSenderId: '19193586262',
    projectId: 'proje1-d2f6c',
    storageBucket: 'proje1-d2f6c.appspot.com',
    iosBundleId: 'com.example.proje1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDsLHb9ioF9kXYzszBX_ve6lfvaIawy7zg',
    appId: '1:19193586262:web:1f31f458cc42b5f8eb51f7',
    messagingSenderId: '19193586262',
    projectId: 'proje1-d2f6c',
    authDomain: 'proje1-d2f6c.firebaseapp.com',
    storageBucket: 'proje1-d2f6c.appspot.com',
    measurementId: 'G-TF9PV87LGN',
  );
}