// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sway/app.dart';
import 'package:sway/data/repositories/spot_repository.dart';
import 'package:sway/data/repositories/user_repository.dart';
import 'package:sway/data/providers/api_provider.dart';
import 'package:sway/blocs/auth/auth_bloc.dart';
import 'package:sway/blocs/spots/spots_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
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
      child: SwayApp(),
    ),
  );
}