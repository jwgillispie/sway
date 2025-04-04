//lib/blocs/spots/spots_bloc.dart
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sway/data/models/hammock_spot.dart';
import 'package:sway/data/models/review.dart';
import 'package:sway/data/repositories/spot_repository.dart';

// Events
abstract class SpotsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSpots extends SpotsEvent {
  final double? lat;
  final double? lng;
  final double? radius;
  final String? treeType;
  final double? minRating;
  final List<String>? hasAmenity;
  
  LoadSpots({
    this.lat,
    this.lng,
    this.radius,
    this.treeType,
    this.minRating,
    this.hasAmenity,
  });
  
  @override
  List<Object?> get props => [lat, lng, radius, treeType, minRating, hasAmenity];
}

class LoadSpotDetails extends SpotsEvent {
  final String spotId;
  
  LoadSpotDetails(this.spotId);
  
  @override
  List<Object> get props => [spotId];
}

class CreateSpot extends SpotsEvent {
  final String name;
  final String description;
  final Coordinates coordinates;
  final List<TreeType> treeTypes;
  final double? distanceBetweenTrees;
  final Amenities amenities;
  final bool isPrivate;
  final List<File> photos;
  
  CreateSpot({
    required this.name,
    required this.description,
    required this.coordinates,
    required this.treeTypes,
    this.distanceBetweenTrees,
    required this.amenities,
    required this.isPrivate,
    required this.photos,
  });
  
  @override
  List<Object?> get props => [
    name, description, coordinates, treeTypes, distanceBetweenTrees,
    amenities, isPrivate, photos,
  ];
}

class UpdateSpot extends SpotsEvent {
  final String spotId;
  final String? name;
  final String? description;
  final Coordinates? coordinates;
  final List<TreeType>? treeTypes;
  final double? distanceBetweenTrees;
  final Amenities? amenities;
  final bool? isPrivate;
  final List<File>? newPhotos;
  final List<String>? photoUrlsToKeep;
  
  UpdateSpot({
    required this.spotId,
    this.name,
    this.description,
    this.coordinates,
    this.treeTypes,
    this.distanceBetweenTrees,
    this.amenities,
    this.isPrivate,
    this.newPhotos,
    this.photoUrlsToKeep,
  });
  
  @override
  List<Object?> get props => [
    spotId, name, description, coordinates, treeTypes, distanceBetweenTrees,
    amenities, isPrivate, newPhotos, photoUrlsToKeep,
  ];
}

class DeleteSpot extends SpotsEvent {
  final String spotId;
  
  DeleteSpot(this.spotId);
  
  @override
  List<Object> get props => [spotId];
}

class AddReview extends SpotsEvent {
  final String spotId;
  final Rating rating;
  final String? comment;
  final List<File>? photos;
  
  AddReview({
    required this.spotId,
    required this.rating,
    this.comment,
    this.photos,
  });
  
  @override
  List<Object?> get props => [spotId, rating, comment, photos];
}

// States
abstract class SpotsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SpotsInitial extends SpotsState {}

class SpotsLoading extends SpotsState {}

class SpotsLoaded extends SpotsState {
  final List<HammockSpot> spots;
  
  SpotsLoaded(this.spots);
  
  @override
  List<Object> get props => [spots];
}

class SpotDetailsLoaded extends SpotsState {
  final HammockSpot spot;
  
  SpotDetailsLoaded(this.spot);
  
  @override
  List<Object> get props => [spot];
}

class SpotCreated extends SpotsState {
  final HammockSpot spot;
  
  SpotCreated(this.spot);
  
  @override
  List<Object> get props => [spot];
}

class SpotUpdated extends SpotsState {
  final HammockSpot spot;
  
  SpotUpdated(this.spot);
  
  @override
  List<Object> get props => [spot];
}

class SpotDeleted extends SpotsState {
  final String spotId;
  
  SpotDeleted(this.spotId);
  
  @override
  List<Object> get props => [spotId];
}

class ReviewAdded extends SpotsState {
  final Review review;
  final HammockSpot updatedSpot;
  
  ReviewAdded(this.review, this.updatedSpot);
  
  @override
  List<Object> get props => [review, updatedSpot];
}

class SpotsError extends SpotsState {
  final String message;
  
  SpotsError(this.message);
  
  @override
  List<Object> get props => [message];
}

// BLoC
class SpotsBloc extends Bloc<SpotsEvent, SpotsState> {
  final SpotRepository spotRepository;
  
  SpotsBloc({required this.spotRepository}) : super(SpotsInitial()) {
    on<LoadSpots>(_onLoadSpots);
    on<LoadSpotDetails>(_onLoadSpotDetails);
    on<CreateSpot>(_onCreateSpot);
    on<UpdateSpot>(_onUpdateSpot);
    on<DeleteSpot>(_onDeleteSpot);
    on<AddReview>(_onAddReview);
  }
  
  Future<void> _onLoadSpots(LoadSpots event, Emitter<SpotsState> emit) async {
    emit(SpotsLoading());
    
    try {
      final spots = await spotRepository.getSpots(
        lat: event.lat,
        lng: event.lng,
        radius: event.radius,
        treeType: event.treeType,
        minRating: event.minRating,
        hasAmenity: event.hasAmenity,
      );
      
      emit(SpotsLoaded(spots));
    } catch (e) {
      emit(SpotsError(e.toString()));
    }
  }
  
  Future<void> _onLoadSpotDetails(LoadSpotDetails event, Emitter<SpotsState> emit) async {
    emit(SpotsLoading());
    
    try {
      final spot = await spotRepository.getSpotById(event.spotId);
      emit(SpotDetailsLoaded(spot));
    } catch (e) {
      emit(SpotsError(e.toString()));
    }
  }
  
  Future<void> _onCreateSpot(CreateSpot event, Emitter<SpotsState> emit) async {
    emit(SpotsLoading());
    
    try {
      final spot = await spotRepository.createSpot(
        name: event.name,
        description: event.description,
        coordinates: event.coordinates,
        treeTypes: event.treeTypes,
        distanceBetweenTrees: event.distanceBetweenTrees,
        amenities: event.amenities,
        isPrivate: event.isPrivate,
        photos: event.photos,
      );
      
      emit(SpotCreated(spot));
    } catch (e) {
      emit(SpotsError(e.toString()));
    }
  }
  
  Future<void> _onUpdateSpot(UpdateSpot event, Emitter<SpotsState> emit) async {
    emit(SpotsLoading());
    
    try {
      final spot = await spotRepository.updateSpot(
        spotId: event.spotId,
        name: event.name,
        description: event.description,
        coordinates: event.coordinates,
        treeTypes: event.treeTypes,
        distanceBetweenTrees: event.distanceBetweenTrees,
        amenities: event.amenities,
        isPrivate: event.isPrivate,
        newPhotos: event.newPhotos,
        photoUrlsToKeep: event.photoUrlsToKeep,
      );
      
      emit(SpotUpdated(spot));
    } catch (e) {
      emit(SpotsError(e.toString()));
    }
  }
  
  Future<void> _onDeleteSpot(DeleteSpot event, Emitter<SpotsState> emit) async {
    emit(SpotsLoading());
    
    try {
      await spotRepository.deleteSpot(event.spotId);
      emit(SpotDeleted(event.spotId));
    } catch (e) {
      emit(SpotsError(e.toString()));
    }
  }
  
  Future<void> _onAddReview(AddReview event, Emitter<SpotsState> emit) async {
    emit(SpotsLoading());
    
    try {
      final review = await spotRepository.addReview(
        spotId: event.spotId,
        rating: event.rating,
        comment: event.comment,
        photos: event.photos,
      );
      
      // Reload the spot to get updated ratings
      final updatedSpot = await spotRepository.getSpotById(event.spotId);
      
      emit(ReviewAdded(review, updatedSpot));
    } catch (e) {
      emit(SpotsError(e.toString()));
    }
  }
}