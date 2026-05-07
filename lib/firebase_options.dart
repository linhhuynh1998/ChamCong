import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
        throw UnsupportedError('DefaultFirebaseOptions has not been configured for macos.');
      case TargetPlatform.windows:
        throw UnsupportedError('DefaultFirebaseOptions has not been configured for windows.');
      case TargetPlatform.linux:
        throw UnsupportedError('DefaultFirebaseOptions has not been configured for linux.');
      default:
        throw UnsupportedError('DefaultFirebaseOptions.currentPlatform is not supported on this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDc1tArVeUsvsC-zA2krfj0VA3hx5gh5XU',
    appId: '1:282200495325:android:3e569acadd1f41e958f734',
    messagingSenderId: '282200495325',
    projectId: 'cham-cong-2c8e3',
    storageBucket: 'cham-cong-2c8e3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA64aRCjNasVqA30pJPVTtQ52BIHIKE2bE',
    appId: '1:282200495325:ios:4fd5f6ab1c726ad958f734',
    messagingSenderId: '282200495325',
    projectId: 'cham-cong-2c8e3',
    storageBucket: 'cham-cong-2c8e3.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
  );
}
