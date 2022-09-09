// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars
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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    // ignore: missing_enum_constant_in_switch
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
    }

    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4rs4qPk9SaGKPAtgUt130FTYEX_wvyJY',
    appId: '1:79250125102:android:4a6a815945d471953dcabf',
    messagingSenderId: '79250125102',
    projectId: 'myst-a7305',
    storageBucket: 'myst-a7305.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD8uJYHpVucJWqdBT7HtjRNg-82SqJlw1Q',
    appId: '1:79250125102:ios:1d180121f0bf761b3dcabf',
    messagingSenderId: '79250125102',
    projectId: 'myst-a7305',
    storageBucket: 'myst-a7305.appspot.com',
    iosClientId:
        '79250125102-gc75numl6u84rfqgagirvkcids4eqid5.apps.googleusercontent.com',
    iosBundleId: 'com.example.myst_',
  );
}
