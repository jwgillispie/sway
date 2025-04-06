// lib/config/constants.dart
class ApiConstants {
static const String baseUrl = 'http://localhost:8000'; // For web or iOS simulator

  static const String apiVersion = '/v1';
  static const String baseApiUrl = baseUrl + apiVersion;
  
  static const int connectTimeout = 15000; // 15 seconds
  static const int receiveTimeout = 15000; // 15 seconds
  
  // Endpoints
  static const String spots = '/spots';
  static const String users = '/users';
  static const String reviews = '/reviews';
  static const String auth = '/auth';
}

class StorageKeys {
  static const String authToken = 'auth_token';
  static const String userId = 'user_id';
  static const String userProfile = 'user_profile';
  static const String appSettings = 'app_settings';
  static const String recentSearches = 'recent_searches';
}

class MapConstants {
  static const double defaultZoom = 13.0;
  static const double defaultSearchRadius = 5000.0; // 5 km
  static const int maxVisibleSpots = 100;
  
  // Default Malta center coordinates
  static const double defaultLatitude = 35.9375;
  static const double defaultLongitude = 14.3754;
}

class UiConstants {
  static const double bottomSheetPeekHeight = 80.0;
  static const double bottomSheetBorderRadius = 24.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double inputBorderRadius = 8.0;
  
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
}

class FeatureFlags {
  static const bool enableOfflineMode = true;
  static const bool enableDarkMode = true;
  static const bool enablePushNotifications = false;
  static const bool enableAnalytics = true;
}