import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static Future<void> init() async {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBF2gvEN0b5ciQZ3pbHXWoXBA592_kOMc0",
          authDomain: "restaurnt-c9e7c.firebaseapp.com",
          projectId: "restaurnt-c9e7c",
          storageBucket: "restaurnt-c9e7c.firebasestorage.app",
          messagingSenderId: "436706061799",
          appId: "1:436706061799:web:1027798dd9769bfbc26142",
          measurementId: "G-6T5LJGPJNH",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  }

  static void enableFirebaseEmulator() {
    if (kDebugMode) {
      try {
        FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
        FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
        FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
      } catch (e) {
        // Ignore emulator errors in web
      }
    }
  }
} 