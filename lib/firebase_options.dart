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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Values from google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCxgfqtumyISrpWNXjUuKV6iFq77rMGtuo',
    appId: '1:986823005108:android:e0530fe96e24e4af83d8e1',
    messagingSenderId: '986823005108',
    projectId: 'decormate-61eb2',
    storageBucket: 'decormate-61eb2.firebasestorage.app',
  );

  // Web config — get appId from Firebase Console > Project Settings > Your apps > Web app
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDZhT0Vp6SyE7cMsS-kDsirqcrPD141QBI',
    appId: '1:986823005108:web:fe4da92f41edb39883d8e1',
    messagingSenderId: '986823005108',
    projectId: 'decormate-61eb2',
    storageBucket: 'decormate-61eb2.firebasestorage.app',
    authDomain: 'decormate-61eb2.firebaseapp.com',
    measurementId: 'G-RKXMNP3FW1',
  );

  // Placeholder — fill in if you add iOS support
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '986823005108',
    projectId: 'decormate-61eb2',
    storageBucket: 'decormate-61eb2.firebasestorage.app',
    iosBundleId: 'com.example.decormateAndroid',
  );
}
