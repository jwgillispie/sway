// lib/data/repositories/user_repository.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sway/config/constants.dart';
import 'package:sway/data/models/user.dart';
import 'package:sway/data/providers/api_provider.dart';
import 'package:sway/data/providers/firebase_provider.dart';
import 'dart:convert';

class UserRepository {
  final ApiProvider _apiProvider;
  final FirebaseProvider _firebaseProvider = FirebaseProvider();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  UserRepository({required ApiProvider apiProvider}) : _apiProvider = apiProvider;
  
  // Authentication methods
  Future<bool> isSignedIn() async {
    final token = await _secureStorage.read(key: StorageKeys.authToken);
    return token != null;
  }
  
  Future<void> signIn({required String email, required String password}) async {
    try {
      // Sign in with Firebase
      final credentials = await _firebaseProvider.signInWithEmailAndPassword(
        email,
        password,
      );
      
      // Get ID token
      final idToken = await credentials.user?.getIdToken();
      
      if (idToken == null) {
        throw Exception('Failed to get authentication token');
      }
      
      // Store token in secure storage
      await _secureStorage.write(key: StorageKeys.authToken, value: idToken);
      
      // Store user ID in secure storage
      await _secureStorage.write(
        key: StorageKeys.userId,
        value: credentials.user?.uid,
      );
      
      // Fetch user profile from API
      await _fetchAndStoreUserProfile();
    } catch (e) {
      // Clean up in case of error
      await _secureStorage.delete(key: StorageKeys.authToken);
      await _secureStorage.delete(key: StorageKeys.userId);
      throw e;
    }
  }
  
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Create user with Firebase
      final credentials = await _firebaseProvider.createUserWithEmailAndPassword(
        email,
        password,
      );
      
      // Update display name
      await _firebaseProvider.updateProfile(displayName: username);
      
      // Get ID token
      final idToken = await credentials.user?.getIdToken();
      
      if (idToken == null) {
        throw Exception('Failed to get authentication token');
      }
      
      // Store token in secure storage
      await _secureStorage.write(key: StorageKeys.authToken, value: idToken);
      
      // Store user ID in secure storage
      await _secureStorage.write(
        key: StorageKeys.userId,
        value: credentials.user?.uid,
      );
      
      // Create user profile in API
      await _createUserProfile(username: username);
    } catch (e) {
      // Clean up in case of error
      await _secureStorage.delete(key: StorageKeys.authToken);
      await _secureStorage.delete(key: StorageKeys.userId);
      throw e;
    }
  }
  
  Future<void> signOut() async {
    await _firebaseProvider.signOut();
    await _secureStorage.delete(key: StorageKeys.authToken);
    await _secureStorage.delete(key: StorageKeys.userId);
    await _secureStorage.delete(key: StorageKeys.userProfile);
  }
  
  // User profile methods
Future<User> getCurrentUser() async {
  final userJson = await _secureStorage.read(key: StorageKeys.userProfile);
  
  if (userJson != null) {
    // Fix: Properly cast the map to Map<String, dynamic>
    final Map<String, dynamic> userData = Map<String, dynamic>.from(
      jsonDecode(userJson) as Map
    );
    return User.fromJson(userData);
  }
  
  // If not in storage, fetch from API
  return await _fetchAndStoreUserProfile();
}
  
  Future<User> _fetchAndStoreUserProfile() async {
    final response = await _apiProvider.get('${ApiConstants.users}/me');
    final user = User.fromJson(response.data);
    
    // Store user profile in secure storage
    await _secureStorage.write(
      key: StorageKeys.userProfile,
      value: jsonEncode(user.toJson()),
    );
    
    return user;
  }
  
  Future<void> _createUserProfile({required String username}) async {
    final userId = await _secureStorage.read(key: StorageKeys.userId);
    
    if (userId == null) {
      throw Exception('User ID not found');
    }
    
    // Create user profile in API
    final userData = {
      'firebase_uid': userId,
      'username': username,
      'email': firebase_auth.FirebaseAuth.instance.currentUser?.email,
    };
    
    await _apiProvider.post(ApiConstants.users, data: userData);
    
    // Fetch and store user profile
    await _fetchAndStoreUserProfile();
  }
  
  Future<User> updateUserProfile({
    String? username,
    String? bio,
    File? profilePhoto,
  }) async {
    final updates = <String, dynamic>{};
    
    if (username != null) updates['username'] = username;
    if (bio != null) updates['bio'] = bio;
    
    // If profile photo is provided, upload it first
    if (profilePhoto != null) {
      final photoUrl = await _firebaseProvider.uploadFile(
        profilePhoto,
        'profile_photos',
      );
      updates['profile_photo'] = photoUrl;
      
      // Update Firebase profile photo as well
      await _firebaseProvider.updateProfile(photoURL: photoUrl);
    }
    
    // Update profile in API
    await _apiProvider.put('${ApiConstants.users}/me', data: updates);
    
    // Fetch and return updated user
    return await _fetchAndStoreUserProfile();
  }
  
  Future<void> toggleFavoriteSpot(String spotId) async {
    await _apiProvider.post('${ApiConstants.users}/favorites/$spotId');
    
    // Refresh user profile
    await _fetchAndStoreUserProfile();
  }
  
  Future<void> removeFavoriteSpot(String spotId) async {
    await _apiProvider.delete('${ApiConstants.users}/favorites/$spotId');
    
    // Refresh user profile
    await _fetchAndStoreUserProfile();
  }
}

// Helper method to handle JSON

T jsonDecode<T>(String source) {
  return json.decode(source) as T;
}

String jsonEncode(Object object) {
  return json.encode(object);
}