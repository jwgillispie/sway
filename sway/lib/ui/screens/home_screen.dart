// lib/ui/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sway/blocs/auth/auth_bloc.dart';
import 'package:sway/config/routes.dart';
import 'package:sway/ui/screens/explore_screens.dart';
import 'package:sway/ui/screens/map_screen.dart';
import 'package:sway/ui/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// This extension allows external screens to control the tab
extension HomeScreenExtension on HomeScreen {
  void switchToTab(int index) {
    // Find the current state and call its method
    final state = _HomeScreenState.instance;
    if (state != null) {
      state.switchToTab(index);
    }
  }
  
  void switchToMapTab() {
    switchToTab(0);
  }
}

class _HomeScreenState extends State<HomeScreen> {
  // Add a static instance to access from extension
  static _HomeScreenState? instance;
  
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    MapScreen(),
    ExploreScreen(),
    ProfileScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    instance = this;
  }
  
  @override
  void dispose() {
    if (instance == this) {
      instance = null;
    }
    super.dispose();
  }
  
  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed(Routes.addSpot);
              },
              child: Icon(Icons.add),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            )
          : null,
    );
  }
}