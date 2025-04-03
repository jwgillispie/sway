// lib/data/models/user.dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends Equatable {
  final String id;
  final String email;
  final String username;
  final String? profilePhoto;
  final String? bio;
  final List<String> favoriteSpots;
  final List<String> createdSpots;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.username,
    this.profilePhoto,
    this.bio,
    this.favoriteSpots = const [],
    this.createdSpots = const [],
    this.isPremium = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? email,
    String? username,
    String? profilePhoto,
    String? bio,
    List<String>? favoriteSpots,
    List<String>? createdSpots,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      bio: bio ?? this.bio,
      favoriteSpots: favoriteSpots ?? this.favoriteSpots,
      createdSpots: createdSpots ?? this.createdSpots,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id, 
    email, 
    username, 
    profilePhoto, 
    bio, 
    favoriteSpots, 
    createdSpots, 
    isPremium, 
    createdAt, 
    updatedAt
  ];
}