// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sway/app.dart';
import 'package:sway/data/repositories/spot_repository.dart';
import 'package:sway/data/repositories/user_repository.dart';
import 'package:sway/data/providers/api_provider.dart';
import 'package:sway/blocs/auth/auth_bloc.dart';
import 'package:sway/blocs/spots/spots_bloc.dart';
import 'package:sway/web/landing_page.dart';
import 'package:sway/config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase using configuration
    await FirebaseConfig.initialize();
    print("Firebase initialized successfully");
    
    // Initialize API provider
    final apiProvider = ApiProvider();
    
    // Initialize repositories
    final spotRepository = SpotRepository(apiProvider: apiProvider);
    final userRepository = UserRepository(apiProvider: apiProvider);
    
    runApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(userRepository: userRepository),
          ),
          BlocProvider<SpotsBloc>(
            create: (context) => SpotsBloc(spotRepository: spotRepository),
          ),
        ],
        child: kIsWeb ? WebApp(userRepository: userRepository) : SwayApp(),
      ),
    );
  } catch (e) {
    print("Error in app initialization: $e");
    // Display error startup screen or handle error appropriately
    runApp(ErrorApp(error: e.toString()));
  }
}

class WebApp extends StatelessWidget {
  final UserRepository userRepository;
  
  const WebApp({Key? key, required this.userRepository}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sway - Find Perfect Hammock Spots',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LandingPage(),
    );
  }
}

// Simple error app to display if initialization fails
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 64),
                SizedBox(height: 16),
                Text(
                  'Error Starting App',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'An error occurred while starting the application:',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  error,
                  style: TextStyle(fontFamily: 'monospace', color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}