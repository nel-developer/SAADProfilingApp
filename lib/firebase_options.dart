import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // initialize
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
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.linux:
        return linux;
      default:
        break;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBqIt5CBrO0iuryOr10rkuYRWkKASIzhvM',
    appId: '1:221749572081:android:d042f1132c35d1b34c1450',
    messagingSenderId: '221749572081',
    projectId: 'da-saad-profiling',
    storageBucket: 'da-saad-profiling.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCj8eI2MH-cyEYfhc0yl-UMZKtGE13Mxn4',
    appId: '1:221749572081:ios:26ce19781a849d9b4c1450',
    messagingSenderId: '221749572081',
    projectId: 'da-saad-profiling',
    storageBucket: 'da-saad-profiling.firebasestorage.app',
    iosBundleId: 'com.example.daProject1',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBqIt5CBrO0iuryOr10rkuYRWkKASIzhvM',
    appId: '1:221749572081:web:YOUR_WEB_APP_ID',
    messagingSenderId: '221749572081',
    projectId: 'da-saad-profiling',
    storageBucket: 'da-saad-profiling.firebasestorage.app',
    authDomain: 'da-saad-profiling.firebaseapp.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBqIt5CBrO0iuryOr10rkuYRWkKASIzhvM',
    appId: '1:221749572081:windows:YOUR_WINDOWS_APP_ID',
    messagingSenderId: '221749572081',
    projectId: 'da-saad-profiling',
    storageBucket: 'da-saad-profiling.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBqIt5CBrO0iuryOr10rkuYRWkKASIzhvM',
    appId: '1:221749572081:macos:YOUR_MACOS_APP_ID',
    messagingSenderId: '221749572081',
    projectId: 'da-saad-profiling',
    storageBucket: 'da-saad-profiling.firebasestorage.app',
    iosClientId: 'YOUR_MACOS_CLIENT_ID',
    iosBundleId: 'YOUR_MACOS_BUNDLE_ID',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyBqIt5CBrO0iuryOr10rkuYRWkKASIzhvM',
    appId: '1:221749572081:linux:YOUR_LINUX_APP_ID',
    messagingSenderId: '221749572081',
    projectId: 'da-saad-profiling',
    storageBucket: 'da-saad-profiling.firebasestorage.app',
  );
}
