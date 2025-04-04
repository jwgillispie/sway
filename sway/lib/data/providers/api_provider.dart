// lib/data/providers/api_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sway/config/constants.dart';

class ApiProvider {
  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiProvider() {
    _dio.options.baseUrl = ApiConstants.baseApiUrl;
    _dio.options.connectTimeout =
        Duration(milliseconds: ApiConstants.connectTimeout);
    _dio.options.receiveTimeout =
        Duration(milliseconds: ApiConstants.receiveTimeout);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add interceptor for authentication
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get token from secure storage
          final token = await _secureStorage.read(key: StorageKeys.authToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Handle 401 unauthorized errors
          if (e.response?.statusCode == 401) {
            // TODO: Implement token refresh or logout logic
          }
          return handler.next(e);
        },
      ),
    );
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Upload files
  Future<Response> upload(
    String path, {
    required FormData formData,
    void Function(int, int)? onSendProgress,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: options ?? Options(contentType: 'multipart/form-data'),
      );
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Download files
  Future<Response> download(
    String path,
    String savePath, {
    void Function(int, int)? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.download(
        path,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Error handling
  Object? _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception(
              'Connection timeout. Please check your internet connection and try again.');

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          String errorMessage = 'Server error occurred';

          // Try to extract error message from response
          try {
            if (error.response?.data != null) {
              if (error.response!.data is Map &&
                  error.response!.data['message'] != null) {
                errorMessage = error.response!.data['message'];
              } else if (error.response!.data is String) {
                errorMessage = error.response!.data;
              }
            }
          } catch (_) {
            // If we can't extract a message, use a generic one based on status code
            errorMessage = _getErrorMessageFromStatusCode(statusCode);
          }

          return Exception('$errorMessage (Status code: $statusCode)');

        case DioExceptionType.cancel:
          return Exception('Request was cancelled');

        case DioExceptionType.connectionError:
          return Exception(
              'Connection error. Please check your internet connection and try again.');
        case DioExceptionType.unknown:
          if (error.error is Exception) {
            return error.error as Exception; // Cast to Exception type
          }
          return Exception('An unexpected error occurred: ${error.error}');
          return Exception('An unexpected error occurred: ${error.error}');

        default:
          return Exception('Network error occurred');
      }
    }

    return Exception('Unexpected error occurred: $error');
  }

  String _getErrorMessageFromStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please log in again.';
      case 403:
        return 'Forbidden. You do not have permission to access this resource.';
      case 404:
        return 'Resource not found.';
      case 408:
        return 'Request timeout. Please try again.';
      case 409:
        return 'Conflict occurred. The resource might already exist.';
      case 422:
        return 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 502:
        return 'Bad gateway. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      case 504:
        return 'Gateway timeout. Please try again later.';
      default:
        return 'Server error occurred';
    }
  }

  // Token management methods
  Future<void> setToken(String token) async {
    await _secureStorage.write(key: StorageKeys.authToken, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: StorageKeys.authToken);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: StorageKeys.authToken);
  }

  // Add custom headers to a single request
  Options addCustomHeaders(Map<String, dynamic> headers, {Options? options}) {
    options = options ?? Options();
    options.headers = {...options.headers ?? {}, ...headers};
    return options;
  }
}
