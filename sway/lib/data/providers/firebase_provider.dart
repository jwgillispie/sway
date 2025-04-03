// lib/data/providers/firebase_provider.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class FirebaseProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Auth methods
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }
  
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }
  
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }
  
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }
  
  // Storage methods
  Future<String> uploadFile(File file, String folderPath) async {
    try {
      final fileName = path.basename(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final destination = '$folderPath/$timestamp-$fileName';
      
      final ref = _storage.ref().child(destination);
      final uploadTask = ref.putFile(file);
      
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadURL = await snapshot.ref.getDownloadURL();
      
      return downloadURL;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }
  
  Future<void> deleteFile(String fileURL) async {
    try {
      final ref = _storage.refFromURL(fileURL);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }
  
  // Error handling
  Exception _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return Exception('User not found. Please check your email or sign up.');
        case 'wrong-password':
          return Exception('Incorrect password. Please try again.');
        case 'email-already-in-use':
          return Exception('Email already in use. Please use a different email or sign in.');
        case 'weak-password':
          return Exception('Password is too weak. Please use a stronger password.');
        case 'invalid-email':
          return Exception('Invalid email format. Please check your email.');
        case 'user-disabled':
          return Exception('This account has been disabled. Please contact support.');
        default:
          return Exception('Authentication error: ${error.message}');
      }
    }
    
    return Exception('Unexpected authentication error: $error');
  }
}