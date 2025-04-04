// lib/ui/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sway/blocs/auth/auth_bloc.dart';
import 'package:sway/blocs/spots/spots_bloc.dart';
import 'package:sway/config/routes.dart';
import 'package:sway/data/models/user.dart';
import 'package:sway/data/models/hammock_spot.dart';
import 'package:sway/ui/screens/home_screen.dart';
import 'package:sway/ui/widgets/spot_card.dart';
import 'package:sway/ui/widgets/custom_button.dart';
import 'package:sway/ui/widgets/error_view.dart';
import 'package:sway/ui/widgets/loading_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load spots
    context.read<SpotsBloc>().add(LoadSpots());
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _signOut() {
    context.read<AuthBloc>().add(SignOutRequested());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(Routes.settings);
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          // Guest mode
          if (authState is AuthUnauthenticated) {
            return _buildGuestProfile(context);
          }
          
          // Authenticated user
          if (authState is AuthAuthenticated) {
            return _buildUserProfile(context, authState.user);
          }
          
          // Default case
          return Center(
            child: Text('Something went wrong. Please try again.'),
          );
        },
      ),
    );
  }
  
  Widget _buildGuestProfile(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle,
              size: 100,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            SizedBox(height: 24),
            Text(
              'You\'re browsing as a guest',
              style: Theme.of(context).textTheme.displayLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Sign in to create and save your favorite hammock spots',
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            CustomButton(
              label: 'Sign In',
              onPressed: () {
                Navigator.of(context).pushNamed(Routes.login);
              },
            ),
            SizedBox(height: 16),
            CustomButton(
              label: 'Create Account',
              isOutlined: true,
              onPressed: () {
                Navigator.of(context).pushNamed(Routes.register);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserProfile(BuildContext context, User user) {
    return BlocBuilder<SpotsBloc, SpotsState>(
      builder: (context, spotsState) {
        final spots = spotsState is SpotsLoaded ? spotsState.spots : <HammockSpot>[];
        
        // Filter spots created by the user
        final userSpots = spots
            .where((spot) => spot.creatorId == user.id)
            .toList();
        
        // Filter spots favorited by the user
        final favoriteSpots = spots
            .where((spot) => user.favoriteSpots.contains(spot.id))
            .toList();
        
        return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // User avatar and info
                      Row(
                        children: [
                          // Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            ),
                            child: user.profilePhoto != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: CachedNetworkImage(
                                      imageUrl: user.profilePhoto!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.person, size: 40),
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                          ),
                          SizedBox(width: 16),
                          // User info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.username,
                                  style: Theme.of(context).textTheme.displayMedium,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: Theme.of(context).textTheme.displayMedium,
                                ),
                                if (user.isPremium)
                                  Chip(
                                    label: Text('Premium'),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.secondary,
                                    labelStyle: TextStyle(color: Colors.white),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Bio
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.bio!,
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                      
                      // Stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Spots',
                              userSpots.length.toString(),
                              Icons.place,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Favorites',
                              favoriteSpots.length.toString(),
                              Icons.favorite,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Since',
                              _formatDate(user.createdAt),
                              Icons.calendar_today,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Edit profile button
                      CustomButton(
                        label: 'Edit Profile',
                        isOutlined: true,
                        onPressed: () {
                          // TODO: Navigate to edit profile
                        },
                      ),
                      
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(text: 'My Spots'),
                        Tab(text: 'Favorites'),
                      ],
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  pinned: true,
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // My Spots tab
              Builder(
                builder: (context) {
                  return CustomScrollView(
                    slivers: [
                      SliverOverlapInjector(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                      ),
                      if (spotsState is SpotsLoading && !(spotsState is SpotsLoaded))
                        SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (spotsState is SpotsError)
                        SliverFillRemaining(
                          child: ErrorView(
                            message: spotsState.message,
                            onRetry: () {
                              context.read<SpotsBloc>().add(LoadSpots());
                            },
                          ),
                        )
                      else if (userSpots.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_location_alt_outlined,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'You haven\'t added any spots yet',
                                  style: Theme.of(context).textTheme.displayLarge,
                                ),
                                SizedBox(height: 16),
                                CustomButton(
                                  label: 'Add Your First Spot',
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(Routes.addSpot);
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.all(16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: SpotCard(
                                    spot: userSpots[index],
                                    onTap: () {
                                      Navigator.of(context).pushNamed(
                                        Routes.spotDetail,
                                        arguments: {'spotId': userSpots[index].id},
                                      );
                                    },
                                  ),
                                );
                              },
                              childCount: userSpots.length,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              
              // Favorites tab
              Builder(
                builder: (context) {
                  return CustomScrollView(
                    slivers: [
                      SliverOverlapInjector(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                      ),
                      if (spotsState is SpotsLoading && !(spotsState is SpotsLoaded))
                        SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (spotsState is SpotsError)
                        SliverFillRemaining(
                          child: ErrorView(
                            message: spotsState.message,
                            onRetry: () {
                              context.read<SpotsBloc>().add(LoadSpots());
                            },
                          ),
                        )
                      else if (favoriteSpots.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_border_outlined,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No favorite spots yet',
                                  style: Theme.of(context).textTheme.displayLarge,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap the heart icon on any spot you like',
                                  style: Theme.of(context).textTheme.displayLarge,
                                ),
                                SizedBox(height: 16),
                                CustomButton(
                                  label: 'Explore Spots',
                                  onPressed: () {
                                    // Switch to explore tab
                                    (context.findAncestorWidgetOfExactType<HomeScreen>() 
                                      as HomeScreen?)?.switchToTab(1);
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.all(16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: SpotCard(
                                    spot: favoriteSpots[index],
                                    onTap: () {
                                      Navigator.of(context).pushNamed(
                                        Routes.spotDetail,
                                        arguments: {'spotId': favoriteSpots[index].id},
                                      );
                                    },
                                  ),
                                );
                              },
                              childCount: favoriteSpots.length,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference < 30) {
      return '$difference days';
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      return '$months mo';
    } else {
      final years = (difference / 365).floor();
      return '$years yr';
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}