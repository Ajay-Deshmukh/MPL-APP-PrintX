import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    } else {
      return android;
    }
  } 

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDCRZX50snmKd9QLz_fXqAbBdmXoUSwof0",
    authDomain: "printx-dfd40.firebaseapp.com",
    projectId: "printx-dfd40",
    storageBucket: "printx-dfd40.firebasestorage.app",
    messagingSenderId: "922512712015",
    appId: "1:922512712015:web:cc1c18e6f5ed693127a53a",
    measurementId: "G-NK06ZX0HYH"
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyC76vbD2SeubllnV0_9sB13AwyBcuI8kx8",
    appId: "1:922512712015:android:9e8cd49f9665b47f27a53a",
    messagingSenderId: "922512712015",
    projectId: "printx-dfd40",
    storageBucket: "printx-dfd40.firebasestorage.app",
  );
}
