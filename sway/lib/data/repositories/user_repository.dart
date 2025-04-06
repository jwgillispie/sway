// lib/data/repositories/user_repository.dart
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sway/config/constants.dart';
import 'package:sway/data/models/user.dart';
import 'package:sway/data/providers/api_provider.dart';
import 'package:sway/data/providers/firebase_provider.dart';

class UserRepository {
  final ApiProvider _apiProvider;
  final FirebaseProvider _firebaseProvider = FirebaseProvider();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  UserRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  // Authentication methods
  Future<bool> isSignedIn() async {
    final token = await _secureStorage.read(key: StorageKeys.authToken);
    return token != null;
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      print('Attempting to sign in with Firebase');
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

      print('Got Firebase ID token, saving to secure storage');
      // Store token in secure storage
      await _secureStorage.write(key: StorageKeys.authToken, value: idToken);

      // Store user ID in secure storage
      await _secureStorage.write(
        key: StorageKeys.userId,
        value: credentials.user?.uid,
      );

      print('Fetching user profile from API');
      // Fetch user profile from API
      await _fetchAndStoreUserProfile();
    } catch (e) {
      print('Error during sign in: $e');
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
      print('Creating user with Firebase');
      // Create user with Firebase
      final credentials =
          await _firebaseProvider.createUserWithEmailAndPassword(
        email,
        password,
      );

      print('Updating Firebase profile with username');
      // Update display name
      await _firebaseProvider.updateProfile(displayName: username);

      // Get ID token
      final idToken = await credentials.user?.getIdToken();

      if (idToken == null) {
        throw Exception('Failed to get authentication token');
      }

      print('Got Firebase ID token, saving to secure storage');
      // Store token in secure storage
      await _secureStorage.write(key: StorageKeys.authToken, value: idToken);

      // Store user ID in secure storage
      await _secureStorage.write(
        key: StorageKeys.userId,
        value: credentials.user?.uid,
      );

      // Create user profile in API
      print('Creating user profile with API');
      await _createUserProfile(username: username);
    } catch (e) {
      print('Error during sign up: $e');
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
    print('Getting current user profile');
    final userJson = await _secureStorage.read(key: StorageKeys.userProfile);

    if (userJson != null) {
      print('Found user profile in secure storage');
      // Properly cast the map to Map<String, dynamic>
      final Map<String, dynamic> userData =
          Map<String, dynamic>.from(jsonDecode(userJson) as Map);
      return User.fromJson(userData);
    }

    print('User profile not in storage, fetching from API');
    // If not in storage, fetch from API
    return await _fetchAndStoreUserProfile();
  }

  Future<User> _fetchAndStoreUserProfile() async {
    try {
      print('Fetching user profile from API endpoint: ${ApiConstants.users}/me');
      final response = await _apiProvider.get('${ApiConstants.users}/me');
      print('Response received: ${response.statusCode}');
      
      final user = User.fromJson(response.data);

      // Store user profile in secure storage
      await _secureStorage.write(
        key: StorageKeys.userProfile,
        value: jsonEncode(user.toJson()),
      );

      return user;
    } catch (e) {
      print('Error fetching user profile: $e');
      rethrow;
    }
  }

  Future<void> _createUserProfile({required String username}) async {
    try {
      final userId = await _secureStorage.read(key: StorageKeys.userId);
      
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Firebase user not found');
      }

      // Create user profile in API
      print('Creating user profile with API endpoint: ${ApiConstants.users}');
      final userData = {
        'firebase_uid': userId,
        'username': username,
        'email': firebaseUser.email ?? '',
      };

      final response = await _apiProvider.post(ApiConstants.users, data: userData);
      print('User profile creation response: ${response.statusCode}');

      // Fetch and store user profile
      await _fetchAndStoreUserProfile();
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
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
    print('Adding favorite spot: $spotId');
    await _apiProvider.post('${ApiConstants.users}/favorites/$spotId');

    // Refresh user profile
    await _fetchAndStoreUserProfile();
  }

  Future<void> removeFavoriteSpot(String spotId) async {
    print('Removing favorite spot: $spotId');
    await _apiProvider.delete('${ApiConstants.users}/favorites/$spotId');

    // Refresh user profile
    await _fetchAndStoreUserProfile();
  }
}