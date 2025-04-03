// lib/config/routes.dart
import 'package:flutter/material.dart';
import 'package:sway/ui/screens/splash_screen.dart';
import 'package:sway/ui/screens/auth/login_screen.dart';
import 'package:sway/ui/screens/auth/register_screen.dart';
import 'package:sway/ui/screens/home_screen.dart';
import 'package:sway/ui/screens/map_screen.dart';
import 'package:sway/ui/screens/spot_detail_screen.dart';
import 'package:sway/ui/screens/add_spot_screen.dart';
import 'package:sway/ui/screens/profile_screen.dart';
import 'package:sway/ui/screens/settings_screen.dart';

class Routes {
  // Route names
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String map = '/map';
  static const String spotDetail = '/spot-detail';
  static const String addSpot = '/add-spot';
  static const String profile = '/profile';
  static const String settings = '/settings';
  
  // Route map
  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => SplashScreen(),
    login: (context) => LoginScreen(),
    register: (context) => RegisterScreen(),
    home: (context) => HomeScreen(),
    map: (context) => MapScreen(),
    spotDetail: (context) => SpotDetailScreen(),
    addSpot: (context) => AddSpotScreen(),
    profile: (context) => ProfileScreen(),
    settings: (context) => SettingsScreen(),
  };
  
  // Route generator for dynamic routes with parameters
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case spotDetail:
        final args = settings.arguments as Map<String, dynamic>;
        final spotId = args['spotId'] as String;
        return MaterialPageRoute(
          builder: (context) => SpotDetailScreen(spotId: spotId),
        );
        
      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}