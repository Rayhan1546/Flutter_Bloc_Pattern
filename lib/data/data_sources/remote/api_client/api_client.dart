import 'dart:convert';
import 'package:dio/dio.dart';

/// Abstract API Client that provides HTTP methods
/// Subclasses must provide baseUrl and defaultHeader implementation
abstract class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  /// Base URL for API endpoints
  String get baseUrl;

  /// Default headers for requests
  Future<Map<String, String>> defaultHeader();

  /// GET request
  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool isAuthenticationRequired = true,
  }) async {
    final url = Uri.parse('$baseUrl/$endpoint').replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );

    final options = Options(
      headers: isAuthenticationRequired ? await defaultHeader() : null,
    );

    final response = await _dio.getUri(url, options: options);
    return response.data as T;
  }

  /// POST request
  Future<T> post<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String> headers = const {},
    bool isAuthenticationRequired = true,
  }) async {
    final url = '$baseUrl/$endpoint';
    
    final mergedHeaders = isAuthenticationRequired
        ? {...await defaultHeader(), ...headers}
        : headers;

    final options = Options(headers: mergedHeaders);

    final response = await _dio.post(
      url,
      data: jsonEncode(data),
      options: options,
    );

    return response.data as T;
  }

  /// POST multipart request for file uploads
  Future<T> postMultipart<T>(
    String endpoint, {
    required Map<String, String> fields,
    String? filePath,
    String fileFieldName = 'file',
    Map<String, String> headers = const {},
    bool isAuthenticationRequired = true,
  }) async {
    final url = '$baseUrl/$endpoint';

    final mergedHeaders = isAuthenticationRequired
        ? {...await defaultHeader(), ...headers}
        : headers;

    // Remove Content-Type as Dio will set it automatically for multipart
    mergedHeaders.remove('Content-Type');

    final formData = FormData.fromMap(fields);

    if (filePath != null && filePath.isNotEmpty) {
      formData.files.add(
        MapEntry(
          fileFieldName,
          await MultipartFile.fromFile(filePath),
        ),
      );
    }

    final options = Options(headers: mergedHeaders);

    final response = await _dio.post(
      url,
      data: formData,
      options: options,
    );

    return response.data as T;
  }

  /// PUT request
  Future<T> put<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String> headers = const {},
    bool isAuthenticationRequired = true,
  }) async {
    final url = '$baseUrl/$endpoint';

    final mergedHeaders = isAuthenticationRequired
        ? {...await defaultHeader(), ...headers}
        : headers;

    final options = Options(headers: mergedHeaders);

    final response = await _dio.put(
      url,
      data: jsonEncode(data),
      options: options,
    );

    return response.data as T;
  }

  /// PATCH request
  Future<T> patch<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String> headers = const {},
    bool isAuthenticationRequired = true,
  }) async {
    final url = '$baseUrl/$endpoint';

    final mergedHeaders = isAuthenticationRequired
        ? {...await defaultHeader(), ...headers}
        : headers;

    final options = Options(headers: mergedHeaders);

    final response = await _dio.patch(
      url,
      data: jsonEncode(data),
      options: options,
    );

    return response.data as T;
  }

  /// DELETE request
  Future<T> delete<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String> headers = const {},
    bool isAuthenticationRequired = true,
  }) async {
    final url = '$baseUrl/$endpoint';

    final mergedHeaders = isAuthenticationRequired
        ? {...await defaultHeader(), ...headers}
        : headers;

    final options = Options(headers: mergedHeaders);

    final response = await _dio.delete(
      url,
      data: data != null ? jsonEncode(data) : null,
      options: options,
    );

    return response.data as T;
  }
}
