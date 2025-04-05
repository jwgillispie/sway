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
  
  // Initialize Firebase using configuration
  await FirebaseConfig.initialize();
  
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
}

class WebApp extends StatelessWidget {
  final UserRepository userRepository;
  
  const WebApp({Key? key, required this.userRepository}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sway - Find Perfect Hammock Spots',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LandingPage(),
    );
  }
}