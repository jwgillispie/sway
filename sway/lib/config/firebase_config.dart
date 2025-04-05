// lib/config/firebase_config.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FirebaseConfig {
  // Web configuration
  static FirebaseOptions? get webOptions {
    if (!kIsWeb) return null;
    
    // Replace these with your actual Firebase configuration values
    return const FirebaseOptions(
      apiKey: "AIzaSyAEKCkw5Asj4kzqB9Z80jFgUC57vq0fx84",
      authDomain: "sway-6f710.firebaseapp.com",
      projectId: "sway-6f710",
      storageBucket: "sway-6f710.firebasestorage.app",
      messagingSenderId: "402376838376",
      appId: "1:402376838376:web:f28f9177351787edf3cd5d",
      measurementId: "G-1DXXE39K8R",
    );
  }


  // Initialize Firebase for both web and mobile platforms
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: webOptions,
    );
  }
}