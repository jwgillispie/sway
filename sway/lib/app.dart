// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sway/blocs/auth/auth_bloc.dart';
import 'package:sway/config/routes.dart';
import 'package:sway/config/theme.dart';
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
      initialRoute: Routes.splash,
      routes: Routes.routes,
      home: BlocBuilder<AuthBloc, AuthState>(
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
    );
  }
}