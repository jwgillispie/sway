// lib/config/firebase_config.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:js' as js;
import 'dart:convert';

class FirebaseConfig {
  // Load web options from environment variables
  static FirebaseOptions get webOptions {
    return FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
      measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '',
    );
  }

  // Initialize Firebase for both web and mobile platforms
  static Future<void> initialize() async {
    try {
      // Make sure dotenv is loaded before initializing Firebase
      await dotenv.load(fileName: ".env");
      
      // Initialize Firebase Core
      await Firebase.initializeApp(
        options: kIsWeb ? webOptions : webOptions, // Replace with mobile options for mobile
      );
      
      print("Firebase initialized successfully for ${kIsWeb ? 'web' : 'mobile'}");
      
      // In a web environment, we need to also initialize Firebase in JS
      if (kIsWeb) {
        await _initializeFirebaseJS();
      }
    } catch (e) {
      print("Error initializing Firebase: $e");
      rethrow;
    }
  }
  
  // Initialize Firebase in JavaScript for web environment
  static Future<void> _initializeFirebaseJS() async {
    if (kIsWeb) {
      try {
        final config = {
          'apiKey': dotenv.env['FIREBASE_API_KEY'],
          'authDomain': dotenv.env['FIREBASE_AUTH_DOMAIN'],
          'projectId': dotenv.env['FIREBASE_PROJECT_ID'],
          'storageBucket': dotenv.env['FIREBASE_STORAGE_BUCKET'],
          'messagingSenderId': dotenv.env['FIREBASE_MESSAGING_SENDER_ID'],
          'appId': dotenv.env['FIREBASE_APP_ID'],
          'measurementId': dotenv.env['FIREBASE_MEASUREMENT_ID'],
        };
        
        // Call the function we defined in index.html
        js.context.callMethod('initializeFirebase', [config]);
      } catch (e) {
        print('Error initializing Firebase JS: $e');
      }
    }
  }
}