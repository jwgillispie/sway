# lib/ui/screens/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sway/blocs/spots/spots_bloc.dart';
import 'package:sway/config/routes.dart';
import 'package:sway/data/models/hammock_spot.dart';
import 'package:sway/ui/widgets/spot_card.dart';
import 'package:sway/ui/widgets/section_header.dart';
import 'package:sway/ui/widgets/error_view.dart';
import 'package:sway/ui/widgets/loading_view.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SpotsBloc>().add(LoadSpots());
  }
  
  void _refreshSpots() {
    context.read<SpotsBloc>().add(LoadSpots());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshSpots();
          return Future.delayed(Duration(milliseconds: 500));
        },
        child: BlocBuilder<SpotsBloc, SpotsState>(
          builder: (context, state) {
            if (state is SpotsLoading && !(state is SpotsLoaded)) {
              return LoadingView();
            }
            
            if (state is SpotsError) {
              return ErrorView(
                message: state.message,
                onRetry: _refreshSpots,
              );
            }
            
            final spots = state is SpotsLoaded ? state.spots : <HammockSpot>[];
            
            if (spots.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.beach_access_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No hammock spots yet',
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Be the first to add a spot!',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(Routes.addSpot);
                      },
                      icon: Icon(Icons.add),
                      label: Text('Add Spot'),
                    ),
                  ],
                ),
              );
            }
            
            // Sort spots by rating
            final topRatedSpots = List<HammockSpot>.from(spots)
              ..sort((a, b) => b.avgRating.compareTo(a.avgRating));
            
            // Get recent spots (sorted by creation date)
            final recentSpots = List<HammockSpot>.from(spots)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            
            return ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Featured spot
                if (topRatedSpots.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Featured Spot',
                    actionLabel: '',
                    onActionTap: null,
                  ),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: SpotCard(
                      spot: topRatedSpots.first,
                      isFeature: true,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          Routes.spotDetail,
                          arguments: {'spotId': topRatedSpots.first.id},
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 24),
                ],
                
                // Top rated spots
                if (topRatedSpots.length > 1) ...[
                  SectionHeader(
                    title: 'Top Rated',
                    actionLabel: 'See All',
                    onActionTap: () {
                      // TODO: Navigate to filtered list
                    },
                  ),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: topRatedSpots.length > 5 ? 5 : topRatedSpots.length,
                      itemBuilder: (context, index) {
                        // Skip the first one as it's already featured
                        if (index == 0) return SizedBox();
                        
                        return Container(
                          width: 280,
                          margin: EdgeInsets.only(right: 16),
                          child: SpotCard(
                            spot: topRatedSpots[index],
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                Routes.spotDetail,
                                arguments: {'spotId': topRatedSpots[index].id},
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 24),
                ],
                
                // Recent spots
                SectionHeader(
                  title: 'Recently Added',
                  actionLabel: 'See All',
                  onActionTap: () {
                    // TODO: Navigate to filtered list
                  },
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: recentSpots.length > 5 ? 5 : recentSpots.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: SpotCard(
                        spot: recentSpots[index],
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            Routes.spotDetail,
                            arguments: {'spotId': recentSpots[index].id},
                          );
                        },
                      ),
                    );
                  },
                ),
                
                // Categories
                SizedBox(height: 24),
                SectionHeader(
                  title: 'Categories',
                  actionLabel: '',
                  onActionTap: null,
                ),
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildCategoryCard(
                      context, 
                      'Best Views', 
                      Icons.landscape,
                      () {
                        // TODO: Navigate to filtered list by category
                      },
                    ),
                    _buildCategoryCard(
                      context, 
                      'Most Private', 
                      Icons.visibility_off,
                      () {
                        // TODO: Navigate to filtered list by category
                      },
                    ),
                    _buildCategoryCard(
                      context, 
                      'Easy Access', 
                      Icons.directions_walk,
                      () {
                        // TODO: Navigate to filtered list by category
                      },
                    ),
                    _buildCategoryCard(
                      context, 
                      'Near Amenities', 
                      Icons.restaurant,
                      () {
                        // TODO: Navigate to filtered list by category
                      },
                    ),
                  ],
                ),
                
                // Nearby destinations
                SizedBox(height: 24),
                SectionHeader(
                  title: 'Nearby Destinations',
                  actionLabel: 'See Map',
                  onActionTap: () {
                    // Switch to map tab
                    (context.findAncestorWidgetOfExactType<HomeScreen>() 
                      as HomeScreen?)?.switchToMapTab();
                  },
                ),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildDestinationCard(
                        context,
                        'Valletta',
                        '12 spots',
                        'assets/images/valletta.jpg',
                        () {
                          // TODO: Navigate to spots in this area
                        },
                      ),
                      _buildDestinationCard(
                        context,
                        'St. Julian\'s',
                        '8 spots',
                        'assets/images/st_julians.jpg',
                        () {
                          // TODO: Navigate to spots in this area
                        },
                      ),
                      _buildDestinationCard(
                        context,
                        'Gozo',
                        '15 spots',
                        'assets/images/gozo.jpg',
                        () {
                          // TODO: Navigate to spots in this area
                        },
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildCategoryCard(
    BuildContext context, 
    String title, 
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.subtitle1?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDestinationCard(
    BuildContext context,
    String location,
    String spotCount,
    String imagePath,
    VoidCallback onTap,
  ) {
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // We're creating a placeholder since we don't have real images yet
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
              width: 160,
              height: 120,
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              width: 160,
              height: 120,
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    spotCount,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}