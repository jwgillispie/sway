// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      profilePhoto: json['profilePhoto'] as String?,
      bio: json['bio'] as String?,
      favoriteSpots: (json['favoriteSpots'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdSpots: (json['createdSpots'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isPremium: json['isPremium'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'username': instance.username,
      'profilePhoto': instance.profilePhoto,
      'bio': instance.bio,
      'favoriteSpots': instance.favoriteSpots,
      'createdSpots': instance.createdSpots,
      'isPremium': instance.isPremium,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
