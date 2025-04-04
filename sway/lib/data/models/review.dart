// lib/data/models/review.dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sway/data/models/hammock_spot.dart';

part 'review.g.dart';

@JsonSerializable()
class Review extends Equatable {
  final String? id;
  final String spotId;
  final String userId;
  final String username;
  final Rating rating;
  final String? comment;
  final List<String> photos;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Review({
    this.id,
    required this.spotId,
    required this.userId,
    required this.username,
    required this.rating,
    this.comment,
    this.photos = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
  
  Map<String, dynamic> toJson() => _$ReviewToJson(this);

  Review copyWith({
    String? id,
    String? spotId,
    String? userId,
    String? username,
    Rating? rating,
    String? comment,
    List<String>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id ?? this.id,
      spotId: spotId ?? this.spotId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  List<Object?> get props => [
    id, spotId, userId, username, rating, comment, photos, createdAt, updatedAt
  ];
}