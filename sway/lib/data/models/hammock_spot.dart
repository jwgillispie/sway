// lib/data/models/hammock_spot.dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sway/data/models/review.dart';

part 'hammock_spot.g.dart';

@JsonSerializable()
class Coordinates extends Equatable {
  final double latitude;
  final double longitude;

  const Coordinates({required this.latitude, required this.longitude});

  factory Coordinates.fromJson(Map<String, dynamic> json) => 
      _$CoordinatesFromJson(json);
  
  Map<String, dynamic> toJson() => _$CoordinatesToJson(this);
  
  @override
  List<Object> get props => [latitude, longitude];
}

enum TreeType { pine, olive, palm, carob, cypress, other, structure }

@JsonSerializable()
class Amenities extends Equatable {
  final bool restrooms;
  final bool waterSource;
  final bool shade;
  final bool parking;
  final bool foodNearby;
  final bool swimming;

  const Amenities({
    this.restrooms = false,
    this.waterSource = false,
    this.shade = false,
    this.parking = false,
    this.foodNearby = false,
    this.swimming = false,
  });

  factory Amenities.fromJson(Map<String, dynamic> json) => 
      _$AmenitiesFromJson(json);
  
  Map<String, dynamic> toJson() => _$AmenitiesToJson(this);
  
  @override
  List<Object> get props => [
    restrooms, waterSource, shade, parking, foodNearby, swimming
  ];
}

@JsonSerializable()
class Rating extends Equatable {
  final double view;
  final double comfort;
  final double accessibility;
  final double privacy;
  final double overall;

  const Rating({
    this.view = 0,
    this.comfort = 0,
    this.accessibility = 0,
    this.privacy = 0,
    this.overall = 0,
  });

  factory Rating.fromJson(Map<String, dynamic> json) => 
      _$RatingFromJson(json);
  
  Map<String, dynamic> toJson() => _$RatingToJson(this);
  
  @override
  List<Object> get props => [
    view, comfort, accessibility, privacy, overall
  ];
}

@JsonSerializable()
class HammockSpot extends Equatable {
  final String? id;
  final String name;
  final String? description;
  final Coordinates coordinates;
  final List<TreeType> treeTypes;
  final double? distanceBetweenTrees;
  final Amenities amenities;
  final List<String> photos;
  final String creatorId;
  final String creatorUsername;
  final bool isPrivate;
  final bool isVerified;
  final double avgRating;
  final List<Review> reviews;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const HammockSpot({
    this.id,
    required this.name,
    this.description,
    required this.coordinates,
    required this.treeTypes,
    this.distanceBetweenTrees,
    required this.amenities,
    required this.photos,
    required this.creatorId,
    required this.creatorUsername,
    this.isPrivate = false,
    this.isVerified = false,
    this.avgRating = 0,
    this.reviews = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory HammockSpot.fromJson(Map<String, dynamic> json) => 
      _$HammockSpotFromJson(json);
  
  Map<String, dynamic> toJson() => _$HammockSpotToJson(this);
  
  HammockSpot copyWith({
    String? id,
    String? name,
    String? description,
    Coordinates? coordinates,
    List<TreeType>? treeTypes,
    double? distanceBetweenTrees,
    Amenities? amenities,
    List<String>? photos,
    String? creatorId,
    String? creatorUsername,
    bool? isPrivate,
    bool? isVerified,
    double? avgRating,
    List<Review>? reviews,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HammockSpot(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coordinates: coordinates ?? this.coordinates,
      treeTypes: treeTypes ?? this.treeTypes,
      distanceBetweenTrees: distanceBetweenTrees ?? this.distanceBetweenTrees,
      amenities: amenities ?? this.amenities,
      photos: photos ?? this.photos,
      creatorId: creatorId ?? this.creatorId,
      creatorUsername: creatorUsername ?? this.creatorUsername,
      isPrivate: isPrivate ?? this.isPrivate,
      isVerified: isVerified ?? this.isVerified,
      avgRating: avgRating ?? this.avgRating,
      reviews: reviews ?? this.reviews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  List<Object?> get props => [
    id, name, description, coordinates, treeTypes, distanceBetweenTrees,
    amenities, photos, creatorId, creatorUsername, isPrivate, isVerified, 
    avgRating, reviews, createdAt, updatedAt
  ];
}