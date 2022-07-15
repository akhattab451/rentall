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
    apiKey: 'AIzaSyBvX6nQXQlviOjjft7dCGX0bXrOYL0-pug',
    appId: '1:518118589601:android:1daa58ab5552cd05ad9ce0',
    messagingSenderId: '518118589601',
    projectId: 'rentall-0451',
    storageBucket: 'rentall-0451.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC_OsYe5Cib63WPNpcWMognjNWoWYbzte4',
    appId: '1:518118589601:ios:024cc106f9900cbfad9ce0',
    messagingSenderId: '518118589601',
    projectId: 'rentall-0451',
    storageBucket: 'rentall-0451.appspot.com',
    iosClientId:
        '518118589601-c70epua8u44uqvj4oo905j9r39fh4kjd.apps.googleusercontent.com',
    iosBundleId: 'com.example.rentall',
  );
}
