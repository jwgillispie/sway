// lib/ui/screens/spot_detail_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sway/blocs/spots/spots_bloc.dart';
import 'package:sway/blocs/auth/auth_bloc.dart';
import 'package:sway/config/routes.dart';
import 'package:sway/data/models/hammock_spot.dart';
import 'package:sway/data/models/review.dart';
import 'package:sway/data/repositories/user_repository.dart';
import 'package:sway/ui/widgets/custom_button.dart';
import 'package:sway/ui/widgets/error_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class SpotDetailScreen extends StatefulWidget {
  final String spotId;

  const SpotDetailScreen({Key? key, required this.spotId}) : super(key: key);

  @override
  _SpotDetailScreenState createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends State<SpotDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load spot details
    context.read<SpotsBloc>().add(LoadSpotDetails(widget.spotId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleFavorite(String spotId) {
    final userRepository = context.read<UserRepository>();

    if (_isFavorite) {
      userRepository.removeFavoriteSpot(spotId);
    } else {
      userRepository.toggleFavoriteSpot(spotId);
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _openMap(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open map')),
      );
    }
  }

  void _shareSpot(HammockSpot spot) {
    final text =
        'Check out this hammock spot: ${spot.name} - Coordinates: ${spot.coordinates.latitude}, ${spot.coordinates.longitude}';
    Share.share(text);
  }

  void _openPhotoGallery(
      BuildContext context, List<String> photos, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PhotoGalleryScreen(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SpotsBloc, SpotsState>(
        builder: (context, state) {
          if (state is SpotsLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (state is SpotsError) {
            return ErrorView(
              message: state.message,
              onRetry: () {
                context.read<SpotsBloc>().add(LoadSpotDetails(widget.spotId));
              },
            );
          }

          if (state is SpotDetailsLoaded) {
            final spot = state.spot;

            // Check if spot is in user's favorites
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                if (authState is AuthAuthenticated) {
                  _isFavorite = authState.user.favoriteSpots.contains(spot.id);
                }
                return SizedBox.shrink();
              },
            );

            return CustomScrollView(
              slivers: [
                // App bar with image
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: spot.photos.isNotEmpty
                        ? Stack(
                            children: [
                              Positioned.fill(
                                child: GestureDetector(
                                  onTap: () {
                                    _openPhotoGallery(context, spot.photos, 0);
                                  },
                                  child: CachedNetworkImage(
                                    imageUrl: spot.photos.first,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.2),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.2),
                                      child: Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 48,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Gradient overlay for better text visibility
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                      stops: [0.6, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border),
                      onPressed: () {
                        if (spot.id != null) {
                          _toggleFavorite(spot.id!);
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () => _shareSpot(spot),
                    ),
                  ],
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and rating
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                spot.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  spot.avgRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '(${spot.reviews.length})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Author and date
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withOpacity(0.7),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Added by ${spot.creatorUsername}',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.7),
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withOpacity(0.7),
                            ),
                            SizedBox(width: 4),
                            Text(
                              _formatDate(spot.createdAt),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Description
                        if (spot.description != null &&
                            spot.description!.isNotEmpty) ...[
                          Text(
                            'Description',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            spot.description!,
                            style: TextStyle(
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 16),
                        ],

                        // Tree types
                        Text(
                          'Tree Types',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: spot.treeTypes.map((treeType) {
                            return Chip(
                              label: Text(
                                treeType
                                    .toString()
                                    .split('.')
                                    .last
                                    .capitalize(),
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                            );
                          }).toList(),
                        ),

                        if (spot.distanceBetweenTrees != null) ...[
                          SizedBox(height: 8),
                          Text(
                            'Distance between trees: ${spot.distanceBetweenTrees} meters',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],

                        SizedBox(height: 16),

                        // Amenities
                        Text(
                          'Amenities',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        SizedBox(height: 8),
                        _buildAmenitiesGrid(spot.amenities),

                        SizedBox(height: 16),

                        // Photos
                        if (spot.photos.length > 1) ...[
                          Text(
                            'Photos',
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: spot.photos.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    _openPhotoGallery(
                                        context, spot.photos, index);
                                  },
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    margin: EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: spot.photos[index],
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Icon(
                                          Icons.image_not_supported_outlined,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 16),
                        ],

                        // Location
                        Text(
                          'Location',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Latitude: ${spot.coordinates.latitude.toStringAsFixed(6)}\nLongitude: ${spot.coordinates.longitude.toStringAsFixed(6)}',
                                style: TextStyle(
                                  height: 1.5,
                                ),
                              ),
                            ),
                            CustomButton(
                              label: 'Open Map',
                              icon: Icons.map_outlined,
                              onPressed: () => _openMap(
                                spot.coordinates.latitude,
                                spot.coordinates.longitude,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 24),

                        // Tabs for reviews and related spots
                        TabBar(
                          controller: _tabController,
                          tabs: [
                            Tab(text: 'Reviews (${spot.reviews.length})'),
                            Tab(text: 'Similar Spots'),
                          ],
                          indicatorColor: Theme.of(context).colorScheme.primary,
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor:
                              Theme.of(context).colorScheme.onBackground,
                        ),

                        SizedBox(
                          height: 500, // Fixed height for tab content
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Reviews tab
                              _buildReviewsTab(context, spot),

                              // Similar spots tab
                              Center(
                                child: Text('Coming soon'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Default case
          return Center(
            child: Text('Something went wrong'),
          );
        },
      ),
      floatingActionButton: BlocBuilder<SpotsBloc, SpotsState>(
        builder: (context, state) {
          if (state is SpotDetailsLoaded) {
            return FloatingActionButton.extended(
              onPressed: () {
                _showAddReviewSheet(context, state.spot);
              },
              icon: Icon(Icons.rate_review_outlined),
              label: Text('Review'),
            );
          }
          return SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAmenitiesGrid(Amenities amenities) {
    final items = [
      {
        'icon': Icons.wc_outlined,
        'label': 'Restrooms',
        'value': amenities.restrooms
      },
      {
        'icon': Icons.water_drop_outlined,
        'label': 'Water Source',
        'value': amenities.waterSource
      },
      {
        'icon': Icons.wb_shade_outlined,
        'label': 'Shade',
        'value': amenities.shade
      },
      {
        'icon': Icons.local_parking_outlined,
        'label': 'Parking',
        'value': amenities.parking
      },
      {
        'icon': Icons.restaurant_outlined,
        'label': 'Food Nearby',
        'value': amenities.foodNearby
      },
      {
        'icon': Icons.pool_outlined,
        'label': 'Swimming',
        'value': amenities.swimming
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isAvailable = item['value'] as bool;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isAvailable
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item['icon'] as IconData,
                color: isAvailable
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                size: 24,
              ),
              SizedBox(height: 4),
              Text(
                item['label'] as String,
                style: TextStyle(
                  color: isAvailable
                      ? Theme.of(context).colorScheme.onBackground
                      : Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab(BuildContext context, HammockSpot spot) {
    if (spot.reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to leave a review!',
              style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 16),
      itemCount: spot.reviews.length,
      itemBuilder: (context, index) {
        final review = spot.reviews[index];
        return _buildReviewCard(context, review);
      },
    );
  }

  Widget _buildReviewCard(BuildContext context, Review review) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    review.username.substring(0, 1).toUpperCase(),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onBackground
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      review.rating.overall.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Detailed ratings
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildRatingItem(context, 'View', review.rating.view),
                  _buildRatingItem(context, 'Comfort', review.rating.comfort),
                  _buildRatingItem(
                      context, 'Access', review.rating.accessibility),
                  _buildRatingItem(context, 'Privacy', review.rating.privacy),
                ],
              ),
            ),

            // Comment
            if (review.comment != null && review.comment!.isNotEmpty)
              Text(review.comment!),

            // Photos
            if (review.photos.isNotEmpty) ...[
              SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.photos.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        _openPhotoGallery(context, review.photos, index);
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: review.photos[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.image_not_supported_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingItem(BuildContext context, String label, double value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
          ),
        ),
        SizedBox(width: 4),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showAddReviewSheet(BuildContext context, HammockSpot spot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddReviewSheet(
        spotId: spot.id ?? '',
        onReviewAdded: () {
          context.read<SpotsBloc>().add(LoadSpotDetails(spot.id ?? ''));
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? "s" : ""} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? "s" : ""} ago';
    }
  }
}

class _PhotoGalleryScreen extends StatelessWidget {
  final List<String> photos;
  final int initialIndex;

  const _PhotoGalleryScreen({
    Key? key,
    required this.photos,
    required this.initialIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(photos[index]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        itemCount: photos.length,
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(),
        ),
        backgroundDecoration: BoxDecoration(color: Colors.black),
        pageController: PageController(initialPage: initialIndex),
      ),
    );
  }
}

class _AddReviewSheet extends StatefulWidget {
  final String spotId;
  final VoidCallback onReviewAdded;

  const _AddReviewSheet({
    Key? key,
    required this.spotId,
    required this.onReviewAdded,
  }) : super(key: key);

  @override
  _AddReviewSheetState createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends State<_AddReviewSheet> {
  final TextEditingController _commentController = TextEditingController();
  double _viewRating = 3.0;
  double _comfortRating = 3.0;
  double _accessRating = 3.0;
  double _privacyRating = 3.0;
  List<File> _photos = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _pickImages() async {
    // Implement image picking using image_picker package
    // This is a placeholder for the actual implementation

    // final picker = ImagePicker();
    // final pickedFiles = await picker.pickMultiImage();

    // if (pickedFiles.isNotEmpty) {
    //   setState(() {
    //     _photos.addAll(pickedFiles.map((file) => File(file.path)).toList());
    //   });
    // }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _submitReview() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final rating = Rating(
        view: _viewRating,
        comfort: _comfortRating,
        accessibility: _accessRating,
        privacy: _privacyRating,
        overall:
            (_viewRating + _comfortRating + _accessRating + _privacyRating) / 4,
      );

      context.read<SpotsBloc>().add(
            AddReview(
              spotId: widget.spotId,
              rating: rating,
              comment: _commentController.text.trim().isNotEmpty
                  ? _commentController.text.trim()
                  : null,
              photos: _photos.isNotEmpty ? _photos : null,
            ),
          );

      widget.onReviewAdded();
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle and title
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Write a Review',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ],
            ),
          ),

          // Review content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating categories
                  _buildRatingSection(
                    context,
                    'View',
                    'How was the scenery and surroundings?',
                    _viewRating,
                    (rating) {
                      setState(() {
                        _viewRating = rating;
                      });
                    },
                  ),

                  _buildRatingSection(
                    context,
                    'Comfort',
                    'How comfortable was hanging your hammock?',
                    _comfortRating,
                    (rating) {
                      setState(() {
                        _comfortRating = rating;
                      });
                    },
                  ),

                  _buildRatingSection(
                    context,
                    'Accessibility',
                    'How easy was it to get to this spot?',
                    _accessRating,
                    (rating) {
                      setState(() {
                        _accessRating = rating;
                      });
                    },
                  ),

                  _buildRatingSection(
                    context,
                    'Privacy',
                    'How private and peaceful was this spot?',
                    _privacyRating,
                    (rating) {
                      setState(() {
                        _privacyRating = rating;
                      });
                    },
                  ),

                  SizedBox(height: 16),

                  // Comment
                  Text(
                    'Comment (Optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Share your experience with this spot...',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Photo upload
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Photos (Optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickImages,
                        icon: Icon(Icons.add_photo_alternate_outlined),
                        label: Text('Add Photos'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Selected photos
                  if (_photos.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photos.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                margin: EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.5),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _photos[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(index),
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 32,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add photos to your review',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 24),

                  // Overall rating summary
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Overall Rating',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          ((_viewRating +
                                      _comfortRating +
                                      _accessRating +
                                      _privacyRating) /
                                  4)
                              .toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 8),
                        RatingBar.builder(
                          initialRating: (_viewRating +
                                  _comfortRating +
                                  _accessRating +
                                  _privacyRating) /
                              4,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 28,
                          ignoreGestures: true,
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (_) {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Submit button
          Padding(
            padding: EdgeInsets.all(16),
            child: CustomButton(
              label: 'Submit Review',
              isLoading: _isSubmitting,
              onPressed: _submitReview,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(
    BuildContext context,
    String title,
    String description,
    double value,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8),
          RatingBar.builder(
            initialRating: value,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemSize: 28,
            itemBuilder: (context, _) => Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: onChanged,
          ),
        ],
      ),
    );
  }
}

// Extension for capitalizing strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
