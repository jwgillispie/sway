// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hammock_spot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Coordinates _$CoordinatesFromJson(Map<String, dynamic> json) => Coordinates(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$CoordinatesToJson(Coordinates instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

Amenities _$AmenitiesFromJson(Map<String, dynamic> json) => Amenities(
      restrooms: json['restrooms'] as bool? ?? false,
      waterSource: json['waterSource'] as bool? ?? false,
      shade: json['shade'] as bool? ?? false,
      parking: json['parking'] as bool? ?? false,
      foodNearby: json['foodNearby'] as bool? ?? false,
      swimming: json['swimming'] as bool? ?? false,
    );

Map<String, dynamic> _$AmenitiesToJson(Amenities instance) => <String, dynamic>{
      'restrooms': instance.restrooms,
      'waterSource': instance.waterSource,
      'shade': instance.shade,
      'parking': instance.parking,
      'foodNearby': instance.foodNearby,
      'swimming': instance.swimming,
    };

Rating _$RatingFromJson(Map<String, dynamic> json) => Rating(
      view: (json['view'] as num?)?.toDouble() ?? 0,
      comfort: (json['comfort'] as num?)?.toDouble() ?? 0,
      accessibility: (json['accessibility'] as num?)?.toDouble() ?? 0,
      privacy: (json['privacy'] as num?)?.toDouble() ?? 0,
      overall: (json['overall'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$RatingToJson(Rating instance) => <String, dynamic>{
      'view': instance.view,
      'comfort': instance.comfort,
      'accessibility': instance.accessibility,
      'privacy': instance.privacy,
      'overall': instance.overall,
    };

HammockSpot _$HammockSpotFromJson(Map<String, dynamic> json) => HammockSpot(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      coordinates:
          Coordinates.fromJson(json['coordinates'] as Map<String, dynamic>),
      treeTypes: (json['treeTypes'] as List<dynamic>)
          .map((e) => $enumDecode(_$TreeTypeEnumMap, e))
          .toList(),
      distanceBetweenTrees: (json['distanceBetweenTrees'] as num?)?.toDouble(),
      amenities: Amenities.fromJson(json['amenities'] as Map<String, dynamic>),
      photos:
          (json['photos'] as List<dynamic>).map((e) => e as String).toList(),
      creatorId: json['creatorId'] as String,
      creatorUsername: json['creatorUsername'] as String,
      isPrivate: json['isPrivate'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$HammockSpotToJson(HammockSpot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'coordinates': instance.coordinates,
      'treeTypes':
          instance.treeTypes.map((e) => _$TreeTypeEnumMap[e]!).toList(),
      'distanceBetweenTrees': instance.distanceBetweenTrees,
      'amenities': instance.amenities,
      'photos': instance.photos,
      'creatorId': instance.creatorId,
      'creatorUsername': instance.creatorUsername,
      'isPrivate': instance.isPrivate,
      'isVerified': instance.isVerified,
      'avgRating': instance.avgRating,
      'reviews': instance.reviews,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$TreeTypeEnumMap = {
  TreeType.pine: 'pine',
  TreeType.olive: 'olive',
  TreeType.palm: 'palm',
  TreeType.carob: 'carob',
  TreeType.cypress: 'cypress',
  TreeType.other: 'other',
  TreeType.structure: 'structure',
};
