// lib/data/repositories/spot_repository.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sway/config/constants.dart';
import 'package:sway/data/models/hammock_spot.dart';
import 'package:sway/data/models/review.dart';
import 'package:sway/data/providers/api_provider.dart';
import 'package:sway/data/providers/firebase_provider.dart';

class SpotRepository {
  final ApiProvider _apiProvider;
  final FirebaseProvider _firebaseProvider = FirebaseProvider();
  
  SpotRepository({required ApiProvider apiProvider}) : _apiProvider = apiProvider;
  
  // Fetch spots
  Future<List<HammockSpot>> getSpots({
    double? lat,
    double? lng,
    double? radius,
    String? treeType,
    double? minRating,
    List<String>? hasAmenity,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (lat != null) queryParams['lat'] = lat.toString();
      if (lng != null) queryParams['lng'] = lng.toString();
      if (radius != null) queryParams['radius'] = radius.toString();
      if (treeType != null) queryParams['tree_type'] = treeType;
      if (minRating != null) queryParams['min_rating'] = minRating.toString();
      if (hasAmenity != null && hasAmenity.isNotEmpty) {
        queryParams['has_amenity'] = hasAmenity.join(',');
      }
      
      final response = await _apiProvider.get(
        ApiConstants.spots,
        queryParameters: queryParams,
      );
      
      return (response.data as List)
          .map((json) => HammockSpot.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get spots: $e');
    }
  }
  
  // Get spot by ID
  Future<HammockSpot> getSpotById(String spotId) async {
    try {
      final response = await _apiProvider.get('${ApiConstants.spots}/$spotId');
      return HammockSpot.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get spot: $e');
    }
  }
  
  // Create new spot
  Future<HammockSpot> createSpot({
    required String name,
    required String description,
    required Coordinates coordinates,
    required List<TreeType> treeTypes,
    double? distanceBetweenTrees,
    required Amenities amenities,
    required bool isPrivate,
    required List<File> photos,
  }) async {
    try {
      // First upload photos
      final photoUrls = await _uploadSpotPhotos(photos);
      
      // Create spot data
      final spotData = {
        'name': name,
        'description': description,
        'coordinates': coordinates.toJson(),
        'tree_types': treeTypes.map((t) => t.toString().split('.').last).toList(),
        'distance_between_trees': distanceBetweenTrees,
        'amenities': amenities.toJson(),
        'photos': photoUrls,
        'is_private': isPrivate,
      };
      
      // Create spot in API
      final response = await _apiProvider.post(
        ApiConstants.spots,
        data: spotData,
      );
      
      return HammockSpot.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create spot: $e');
    }
  }
  
  // Update spot
  Future<HammockSpot> updateSpot({
    required String spotId,
    String? name,
    String? description,
    Coordinates? coordinates,
    List<TreeType>? treeTypes,
    double? distanceBetweenTrees,
    Amenities? amenities,
    bool? isPrivate,
    List<File>? newPhotos,
    List<String>? photoUrlsToKeep,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      // Add fields that need to be updated
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (coordinates != null) updateData['coordinates'] = coordinates.toJson();
      if (treeTypes != null) {
        updateData['tree_types'] = treeTypes.map((t) => t.toString().split('.').last).toList();
      }
      if (distanceBetweenTrees != null) updateData['distance_between_trees'] = distanceBetweenTrees;
      if (amenities != null) updateData['amenities'] = amenities.toJson();
      if (isPrivate != null) updateData['is_private'] = isPrivate;
      
      // Handle photos if provided
      if (newPhotos != null || photoUrlsToKeep != null) {
        final List<String> finalPhotoUrls = photoUrlsToKeep ?? [];
        
        // Upload new photos if any
        if (newPhotos != null && newPhotos.isNotEmpty) {
          final newPhotoUrls = await _uploadSpotPhotos(newPhotos);
          finalPhotoUrls.addAll(newPhotoUrls);
        }
        
        updateData['photos'] = finalPhotoUrls;
      }
      
      // Update spot in API
      final response = await _apiProvider.put(
        '${ApiConstants.spots}/$spotId',
        data: updateData,
      );
      
      return HammockSpot.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update spot: $e');
    }
  }
  
  // Delete spot
  Future<void> deleteSpot(String spotId) async {
    try {
      await _apiProvider.delete('${ApiConstants.spots}/$spotId');
    } catch (e) {
      throw Exception('Failed to delete spot: $e');
    }
  }
  
  // Add review to spot
  Future<Review> addReview({
    required String spotId,
    required Rating rating,
    String? comment,
    List<File>? photos,
  }) async {
    try {
      // Upload photos if any
      List<String> photoUrls = [];
      if (photos != null && photos.isNotEmpty) {
        photoUrls = await _uploadReviewPhotos(spotId, photos);
      }
      
      // Create review data
      final reviewData = {
        'spot_id': spotId,
        'rating': rating.toJson(),
        'comment': comment,
        'photos': photoUrls,
      };
      
      // Create review in API
      final response = await _apiProvider.post(
        '${ApiConstants.reviews}/$spotId',
        data: reviewData,
      );
      
      return Review.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }
  
  // Update review
  Future<Review> updateReview({
    required String reviewId,
    required Rating rating,
    String? comment,
    List<File>? newPhotos,
    List<String>? photoUrlsToKeep,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'rating': rating.toJson(),
      };
      
      if (comment != null) updateData['comment'] = comment;
      
      // Handle photos if provided
      if (newPhotos != null || photoUrlsToKeep != null) {
        final List<String> finalPhotoUrls = photoUrlsToKeep ?? [];
        
        // Upload new photos if any
        if (newPhotos != null && newPhotos.isNotEmpty) {
          final review = await getReviewById(reviewId);
          final newPhotoUrls = await _uploadReviewPhotos(review.spotId, newPhotos);
          finalPhotoUrls.addAll(newPhotoUrls);
        }
        
        updateData['photos'] = finalPhotoUrls;
      }
      
      // Update review in API
      final response = await _apiProvider.put(
        '${ApiConstants.reviews}/$reviewId',
        data: updateData,
      );
      
      return Review.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }
  
  // Delete review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _apiProvider.delete('${ApiConstants.reviews}/$reviewId');
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }
  
  // Get review by ID
  Future<Review> getReviewById(String reviewId) async {
    try {
      final response = await _apiProvider.get('${ApiConstants.reviews}/$reviewId');
      return Review.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get review: $e');
    }
  }
  
  // Helper methods
  Future<List<String>> _uploadSpotPhotos(List<File> photos) async {
    final photoUrls = <String>[];
    
    for (final photo in photos) {
      final url = await _firebaseProvider.uploadFile(
        photo,
        'spot_photos',
      );
      photoUrls.add(url);
    }
    
    return photoUrls;
  }
  
  Future<List<String>> _uploadReviewPhotos(String spotId, List<File> photos) async {
    final photoUrls = <String>[];
    
    for (final photo in photos) {
      final url = await _firebaseProvider.uploadFile(
        photo,
        'review_photos/$spotId',
      );
      photoUrls.add(url);
    }
    
    return photoUrls;
  }
}