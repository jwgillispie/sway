// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sway/blocs/auth/auth_bloc.dart';
import 'package:sway/config/routes.dart';
import 'package:sway/config/theme.dart';
import 'package:sway/screens/landing/landing_page.dart';
import 'package:sway/ui/screens/splash_screen.dart';
import 'package:sway/ui/screens/auth/login_screen.dart';
import 'package:sway/ui/screens/home_screen.dart';

class SwayApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sway',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: kIsWeb ? null : Routes.splash,
      routes: Routes.routes,
      // For web, use the landing page as the initial screen
      home: kIsWeb ? LandingPage() : BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial) {
            return SplashScreen();
          }
          
          if (state is AuthAuthenticated) {
            return HomeScreen();
          }
          
          return LoginScreen();
        },
      ),
      // Custom page route generator for named routes
      onGenerateRoute: (settings) {
        // Let the Routes class handle generating routes
        return Routes.generateRoute(settings);
      },
    );
  }
}