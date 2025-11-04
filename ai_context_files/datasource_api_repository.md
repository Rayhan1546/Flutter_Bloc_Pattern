# Data Source, API, and Repository Implementation Guide

This guide provides detailed instructions for implementing the data layer components in Clean Architecture: Data Sources, API integration, and Repository implementations.

## Table of Contents
1. [Overview](#overview)
2. [Data Layer Architecture](#data-layer-architecture)
3. [Setting Up API Data Source](#setting-up-api-data-source)
4. [Creating DTOs](#creating-dtos)
5. [Implementing Repositories](#implementing-repositories)
6. [Error Handling](#error-handling)
7. [Local Data Sources](#local-data-sources)
8. [Best Practices](#best-practices)
9. [Complete Examples](#complete-examples)

## Overview

The data layer is responsible for:
- Fetching data from external sources (API, Database, Cache)
- Converting external data formats (JSON) to domain models
- Implementing repository interfaces defined in the domain layer
- Handling errors and exceptions

**Key Principle**: The data layer depends on the domain layer, but the domain layer does NOT depend on the data layer.

## Data Layer Architecture

```
lib/data/
├── data_sources/
│   ├── remote/                              # Remote API service classes
│   │   ├── api_client/                      # API Client abstraction
│   │   │   ├── api_client.dart              # Abstract API client base class
│   │   │   └── [feature]_api_client.dart    # Concrete API client implementation
│   │   ├── [feature]_api_service.dart       # API service using ApiClient
│   │   └── [another]_api_service.dart
│   ├── api_data_source.dart                 # Main data source facade
│   ├── local_data_source.dart               # Local storage (SharedPreferences, SQLite)
│   └── cache_data_source.dart               # Cache layer
├── dto/
│   └── [feature_name]/
│       └── [entity]_dto.dart                # Data Transfer Objects
├── repositories/
│   └── [feature]_repo_impl.dart             # Repository implementations
├── interceptors/
│   ├── auth_interceptor.dart                # Add auth tokens
│   ├── logging_interceptor.dart             # Log requests/responses
│   └── error_interceptor.dart               # Handle errors globally
└── mappers/                                  # Optional: complex mapping logic
    └── [entity]_mapper.dart
```

**Key Structure**:
- **remote/api_client/**: Contains abstract ApiClient and concrete implementations
- **remote/**: Contains API service classes that use ApiClient for HTTP calls
- **api_data_source.dart**: Acts as a facade that aggregates all remote API services
- Repository implementations use api_data_source, not individual API services

**Architecture Layers**:
1. **ApiClient** (abstract) → Defines HTTP methods (get, post, put, etc.)
2. **Concrete ApiClient** (e.g., GithubApiClient) → Provides base URL and headers
3. **API Services** → Use ApiClient to make HTTP calls
4. **ApiDataSource** → Aggregates all API services
5. **Repositories** → Use ApiDataSource

## Setting Up API Client Abstraction

### Overview of ApiClient Pattern

The **ApiClient abstraction pattern** provides a layer between API services and Dio, allowing centralized HTTP method definitions and easier testing:

1. **ApiClient** (abstract): Defines HTTP methods and requires base URL and headers
2. **Concrete ApiClient**: Implements base URL and default headers for specific APIs
3. **API Services**: Use ApiClient to make HTTP calls
4. **ApiDataSource**: Aggregates multiple API services
5. **Repositories**: Use ApiDataSource

**Benefits**:
- Centralized HTTP method definitions
- Easy to swap between different APIs (dev, staging, prod)
- Better testing with mockable ApiClient
- Consistent header management
- Simplified service implementations

### Step 1: Create Abstract ApiClient

Create the abstract ApiClient base class with all HTTP methods.

**Location**: `lib/data/data_sources/remote/api_client/api_client.dart`

```dart
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

  /// PUT, PATCH, DELETE methods follow similar pattern...
}
```

**Key Points**:
- Abstract class with Dio dependency
- Requires subclasses to implement `baseUrl` and `defaultHeader()`
- All HTTP methods in one place
- Supports authentication toggling
- Handles query parameters and custom headers

### Step 2: Create Concrete ApiClient Implementation

Implement a concrete ApiClient for your specific API.

**Location**: `lib/data/data_sources/remote/api_client/github_api_client.dart`

```dart
import 'package:dio/dio.dart';
import 'package:project_name/data/data_sources/remote/api_client/api_client.dart';

/// GitHub API Client implementation
/// Provides base URL and default headers for GitHub API
class GithubApiClient extends ApiClient {
  GithubApiClient(super.dio);

  @override
  String get baseUrl => 'https://api.github.com';

  @override
  Future<Map<String, String>> defaultHeader() async {
    return {
      'Accept': 'application/vnd.github.v3+json',
      'Content-Type': 'application/json',
    };
  }
}
```

**For authenticated APIs**:

```dart
class AuthApiClient extends ApiClient {
  final AuthService _authService;

  AuthApiClient(super.dio, this._authService);

  @override
  String get baseUrl => 'https://api.myapp.com/v1';

  @override
  Future<Map<String, String>> defaultHeader() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}
```

**Key Points**:
- Extends ApiClient
- Provides specific base URL
- Implements custom headers (with or without auth)
- Can inject additional dependencies (like AuthService)

### Step 3: Create API Service Using ApiClient

Create API services that use ApiClient for HTTP calls. Follow the **abstract interface + implementation pattern** for better testability and dependency inversion.

#### Step 3a: Create Abstract API Service Interface

**Location**: `lib/data/data_sources/remote/github_api_service.dart`

```dart
import 'package:project_name/data/dto/github_repository/github_repository_dto.dart';

/// Abstract API service for GitHub endpoints
/// Defines contracts for all GitHub API operations
abstract class GithubApiService {
  /// Fetches list of repositories from GitHub API
  Future<List<GithubRepositoryDto>> getRepositories();

  /// Fetches a specific repository by ID
  Future<GithubRepositoryDto> getRepositoryById(int repoId);

  /// Searches repositories by query
  Future<List<GithubRepositoryDto>> searchRepositories({
    required String query,
    int? page,
    int? perPage,
  });

  /// Fetches user repositories
  Future<List<GithubRepositoryDto>> getUserRepositories(String username);
}
```

#### Step 3b: Create Concrete API Service Implementation

**Location**: `lib/data/data_sources/remote/github_api_service_impl.dart`

```dart
import 'package:project_name/data/data_sources/remote/api_client/api_client.dart';
import 'package:project_name/data/data_sources/remote/github_api_service.dart';
import 'package:project_name/data/dto/github_repository/github_repository_dto.dart';

/// Implementation of GitHub API service
/// Handles all HTTP requests using ApiClient abstraction
class GithubApiServiceImpl implements GithubApiService {
  final ApiClient _apiClient;

  GithubApiServiceImpl(this._apiClient);

  @override
  Future<List<GithubRepositoryDto>> getRepositories() async {
    final response = await _apiClient.get<List<dynamic>>('repositories');
    return response.map((json) => GithubRepositoryDto.fromJson(json)).toList();
  }

  @override
  Future<GithubRepositoryDto> getRepositoryById(int repoId) async {
    final response = await _apiClient.get<Map<String, dynamic>>('repositories/$repoId');
    return GithubRepositoryDto.fromJson(response);
  }

  @override
  Future<List<GithubRepositoryDto>> searchRepositories({
    required String query,
    int? page,
    int? perPage,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      'search/repositories',
      queryParameters: {
        'q': query,
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
      },
    );
    
    final items = response['items'] as List;
    return items.map((json) => GithubRepositoryDto.fromJson(json)).toList();
  }

  @override
  Future<List<GithubRepositoryDto>> getUserRepositories(String username) async {
    final response = await _apiClient.get<List<dynamic>>('users/$username/repos');
    return response.map((json) => GithubRepositoryDto.fromJson(json)).toList();
  }
}
```

**Key Points**:
- **Abstract interface** defines the contract without implementation
- **Concrete implementation** provides actual HTTP logic using ApiClient
- Uses ApiClient instead of Dio directly
- Endpoints are relative paths (no base URL)
- Generic type parameters for type safety
- Follows dependency inversion principle
- Easy to mock for testing

### Step 4: Register Dependencies

Register ApiClient and services in dependency injection. Follow the **interface + implementation pattern** for API services.

**Location**: `lib/di/di_module.dart`

```dart
class DataModule implements DIModule {
  @override
  Future<void> register() async {
    // Register API clients first
    sl.registerSingleton<ApiClient>(
      GithubApiClient(sl.get<Dio>()),
    );

    // Register API services by interface, instantiate implementation
    sl.registerSingleton<GithubApiService>(
      GithubApiServiceImpl(sl.get<ApiClient>()),
    );

    // Register ApiDataSource
    sl.registerSingleton<ApiDataSource>(
      ApiDataSource(sl.get<GithubApiService>()),
    );

    // Register repositories
    sl.registerSingleton<GithubRepo>(
      GithubRepoImpl(sl.get<ApiDataSource>()),
    );
  }
}
```

**Registration Order**:
1. Dio (in NetworkModule)
2. ApiClient implementations
3. API Services (use ApiClient) - **register interface type, instantiate implementation**
4. ApiDataSource (uses API Services)
5. Repositories (use ApiDataSource)

**Key Points**:
- Register by interface (ApiClient, GithubApiService) for easier testing
- Instantiate concrete implementation (GithubApiServiceImpl) but register as interface type
- Services depend on ApiClient interface, not concrete implementation
- Clear dependency chain following dependency inversion principle
- Easy to swap implementations for testing or different environments

## Setting Up API Data Source with Remote Pattern

### Overview of Remote Pattern

The **remote pattern** separates API service classes from the main data source facade:

1. **Remote API Services** (`data_sources/remote/`): Handle specific API endpoints using ApiClient
2. **ApiDataSource** (`data_sources/api_data_source.dart`): Aggregates multiple API services
3. **Repositories**: Use ApiDataSource, not individual API services

**Benefits**:
- Better separation of concerns
- Easier to test individual API services
- Cleaner organization as app grows
- Repositories don't need to know about multiple API services

### Step 1: Create Remote API Service

Create specific API service classes for each feature in the `remote/` folder.

**Location**: `lib/data/data_sources/remote/[feature]_api_service.dart`

**Example: GitHub API Service**

```dart
// lib/data/data_sources/remote/github_api_service.dart
import 'package:dio/dio.dart';
import 'package:project_name/data/dto/github_repository/github_repository_dto.dart';

/// API service for GitHub endpoints
/// Handles all HTTP requests using Dio abstraction
class GithubApiService {
  final Dio _dio;

  GithubApiService(this._dio);

  /// Fetches list of repositories from GitHub API
  Future<List<GithubRepositoryDto>> getRepositories() async {
    final response = await _dio.get('https://api.github.com/repositories');
    return (response.data as List)
        .map((json) => GithubRepositoryDto.fromJson(json))
        .toList();
  }

  /// Fetches a specific repository by ID
  Future<GithubRepositoryDto> getRepositoryById(int repoId) async {
    final response = await _dio.get('https://api.github.com/repositories/$repoId');
    return GithubRepositoryDto.fromJson(response.data);
  }

  /// Searches repositories by query
  Future<List<GithubRepositoryDto>> searchRepositories({
    required String query,
    int? page,
    int? perPage,
  }) async {
    final response = await _dio.get(
      'https://api.github.com/search/repositories',
      queryParameters: {
        'q': query,
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
      },
    );
    
    final items = response.data['items'] as List;
    return items.map((json) => GithubRepositoryDto.fromJson(json)).toList();
  }
}
```

**Key Points**:
- One API service per feature/domain
- Uses Dio for all HTTP calls
- Returns DTOs, not domain entities
- Handles URL construction and query parameters
- Throws DioException on errors (handled by repository)

### Step 2: Create ApiDataSource Facade

Create a facade that aggregates all API services.

**Location**: `lib/data/data_sources/api_data_source.dart`

```dart
// lib/data/data_sources/api_data_source.dart
import 'package:project_name/data/data_sources/remote/github_api_service.dart';
import 'package:project_name/data/data_sources/remote/user_api_service.dart';
import 'package:project_name/data/dto/github_repository/github_repository_dto.dart';
import 'package:project_name/data/dto/user/user_dto.dart';

/// Main data source that aggregates all API services
/// Acts as a facade for remote API services
class ApiDataSource {
  final GithubApiService _githubApiService;
  final UserApiService _userApiService;

  ApiDataSource(this._githubApiService, this._userApiService);

  // GitHub API methods
  Future<List<GithubRepositoryDto>> getRepositories() async {
    return await _githubApiService.getRepositories();
  }

  Future<GithubRepositoryDto> getRepositoryById(int repoId) async {
    return await _githubApiService.getRepositoryById(repoId);
  }

  Future<List<GithubRepositoryDto>> searchRepositories({
    required String query,
    int? page,
    int? perPage,
  }) async {
    return await _githubApiService.searchRepositories(
      query: query,
      page: page,
      perPage: perPage,
    );
  }

  // User API methods
  Future<UserDto> getCurrentUser() async {
    return await _userApiService.getCurrentUser();
  }

  Future<UserDto> updateUser(UserDto user) async {
    return await _userApiService.updateUser(user);
  }
}
```

**Key Points**:
- Aggregates multiple API services
- Delegates calls to appropriate API service
- Repositories depend on this, not individual services
- Makes it easy to swap API services

### Step 3: Register in Dependency Injection

Register API services before ApiDataSource.

**Location**: `lib/di/di_module.dart`

```dart
/// Data module - registers data sources and repositories
class DataModule implements DIModule {
  @override
  Future<void> register() async {
    // Register remote API services first
    sl.registerSingleton<GithubApiService>(
      GithubApiService(sl.get<Dio>()),
    );
    
    sl.registerSingleton<UserApiService>(
      UserApiService(sl.get<Dio>()),
    );

    // Register ApiDataSource that uses API services
    sl.registerSingleton<ApiDataSource>(
      ApiDataSource(
        sl.get<GithubApiService>(),
        sl.get<UserApiService>(),
      ),
    );

    // Register repositories that use ApiDataSource
    sl.registerSingleton<GithubRepo>(
      GithubRepoImpl(sl.get<ApiDataSource>()),
    );
  }
}
```

**Registration Order**:
1. Dio (in NetworkModule)
2. Remote API services (use Dio)
3. ApiDataSource (uses API services)
4. Repositories (use ApiDataSource)

### Step 4: Configure Dio Client

Create a Dio instance with base configuration.

**Location**: `lib/data/network/dio_client.dart`

```dart
// lib/data/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:project_name/data/interceptors/auth_interceptor.dart';
import 'package:project_name/data/interceptors/logging_interceptor.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.example.com/v1',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    dio.interceptors.addAll([
      AuthInterceptor(),
      LoggingInterceptor(),
    ]);

    return dio;
  }
}
```

### Step 2: Create Auth Interceptor

Handle authentication tokens automatically.

**Location**: `lib/data/interceptors/auth_interceptor.dart`

```dart
// lib/data/interceptors/auth_interceptor.dart
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Get token from secure storage or state management
    final token = _getAuthToken();
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Handle token refresh or logout
      _handleUnauthorized();
    }
    
    super.onError(err, handler);
  }

  String? _getAuthToken() {
    // TODO: Implement token retrieval
    // Example: Get from shared preferences or secure storage
    return null;
  }

  void _handleUnauthorized() {
    // TODO: Implement logout or token refresh logic
  }
}
```

### Step 3: Create Logging Interceptor

Log API requests and responses for debugging.

**Location**: `lib/data/interceptors/logging_interceptor.dart`

```dart
// lib/data/interceptors/logging_interceptor.dart
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('┌───────────────────────────────────────────────');
    _logger.d('│ REQUEST: ${options.method} ${options.uri}');
    _logger.d('│ Headers: ${options.headers}');
    if (options.data != null) {
      _logger.d('│ Body: ${options.data}');
    }
    _logger.d('└───────────────────────────────────────────────');
    
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i('┌───────────────────────────────────────────────');
    _logger.i('│ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
    _logger.i('│ Data: ${response.data}');
    _logger.i('└───────────────────────────────────────────────');
    
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('┌───────────────────────────────────────────────');
    _logger.e('│ ERROR: ${err.response?.statusCode} ${err.requestOptions.uri}');
    _logger.e('│ Message: ${err.message}');
    _logger.e('│ Response: ${err.response?.data}');
    _logger.e('└───────────────────────────────────────────────');
    
    super.onError(err, handler);
  }
}
```

### Step 4: Create API Data Source

Define API endpoints using manual Dio calls.

**Location**: `lib/data/data_sources/api_data_source.dart`

```dart
// lib/data/data_sources/api_data_source.dart
import 'package:dio/dio.dart';
import 'package:project_name/data/dto/user/user_dto.dart';
import 'package:project_name/data/dto/post/post_dto.dart';

class ApiDataSource {
  final Dio _dio;

  ApiDataSource(this._dio);

  // User endpoints
  Future<UserDto> getCurrentUser() async {
    final response = await _dio.get('/users/me');
    return UserDto.fromJson(response.data);
  }

  Future<UserDto> getUserById(String userId) async {
    final response = await _dio.get('/users/$userId');
    return UserDto.fromJson(response.data);
  }

  Future<UserDto> updateUser(String userId, UserDto user) async {
    final response = await _dio.put(
      '/users/$userId',
      data: user.toJson(),
    );
    return UserDto.fromJson(response.data);
  }

  Future<void> deleteUser(String userId) async {
    await _dio.delete('/users/$userId');
  }

  // Post endpoints
  Future<List<PostDto>> getPosts({int? page, int? limit}) async {
    final response = await _dio.get(
      '/posts',
      queryParameters: {
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
    );
    return (response.data as List)
        .map((json) => PostDto.fromJson(json))
        .toList();
  }

  Future<PostDto> getPostById(int postId) async {
    final response = await _dio.get('/posts/$postId');
    return PostDto.fromJson(response.data);
  }

  Future<PostDto> createPost(PostDto post) async {
    final response = await _dio.post(
      '/posts',
      data: post.toJson(),
    );
    return PostDto.fromJson(response.data);
  }

  Future<PostDto> updatePost(int postId, PostDto post) async {
    final response = await _dio.put(
      '/posts/$postId',
      data: post.toJson(),
    );
    return PostDto.fromJson(response.data);
  }

  Future<void> deletePost(int postId) async {
    await _dio.delete('/posts/$postId');
  }

  // Search and filters
  Future<List<PostDto>> searchPosts(String query, String? authorId) async {
    final response = await _dio.get(
      '/posts/search',
      queryParameters: {
        'q': query,
        if (authorId != null) 'author_id': authorId,
      },
    );
    return (response.data as List)
        .map((json) => PostDto.fromJson(json))
        .toList();
  }

  // Upload file
  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/upload', data: formData);
    return response.data as Map<String, dynamic>;
  }
}
```

**Key Points**:
- Manual HTTP calls with Dio
- Path parameters using string interpolation
- Query parameters using `queryParameters` map
- Request body using `data` parameter with `toJson()`
- Response parsing with manual `fromJson()` calls
- File uploads using `FormData` and `MultipartFile`

## Creating DTOs

DTOs (Data Transfer Objects) represent the API response/request format.

### Basic DTO

**Location**: `lib/data/dto/user/user_dto.dart`

```dart
// lib/data/dto/user/user_dto.dart
import 'package:project_name/domain/entities/user/user.dart';

class UserDto {
  final String id;
  final String email;
  final String name;
  final String? profilePictureUrl;
  final String createdAt;
  final String? updatedAt;

  const UserDto({
    required this.id,
    required this.email,
    required this.name,
    this.profilePictureUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      profilePictureUrl: json['profile_picture_url'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
      'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}
```

### DTO with Nested Objects

```dart
// lib/data/dto/post/post_dto.dart
import 'package:project_name/data/dto/user/user_dto.dart';
import 'package:project_name/domain/entities/post/post.dart';

class PostDto {
  final int id;
  final String title;
  final String content;
  final String authorId;
  final UserDto? author; // Nested object
  final String createdAt;
  final String? updatedAt;
  final int likesCount;

  const PostDto({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    this.author,
    required this.createdAt,
    this.updatedAt,
    this.likesCount = 0,
  });

  factory PostDto.fromJson(Map<String, dynamic> json) {
    return PostDto(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      authorId: json['author_id'] as String,
      author: json['author'] != null 
          ? UserDto.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author_id': authorId,
      if (author != null) 'author': author!.toJson(),
      'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      'likes_count': likesCount,
    };
  }
}
```

### DTO Mapping to Domain Entity

Create extension methods for conversion.

```dart
// Extension to convert DTO to Domain Entity
extension UserDtoX on UserDto {
  User toDomain() {
    return User(
      id: id,
      email: email,
      name: name,
      profilePictureUrl: profilePictureUrl,
      createdAt: DateTime.parse(createdAt),
      updatedAt: updatedAt != null ? DateTime.parse(updatedAt!) : null,
    );
  }
}

// Extension to convert Domain Entity to DTO
extension UserX on User {
  UserDto toDto() {
    return UserDto(
      id: id,
      email: email,
      name: name,
      profilePictureUrl: profilePictureUrl,
      createdAt: createdAt.toIso8601String(),
      updatedAt: updatedAt?.toIso8601String(),
    );
  }
}
```

### DTO with Custom Deserialization

For complex API responses:

```dart
// lib/data/dto/api_response_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response_dto.freezed.dart';
part 'api_response_dto.g.dart';

@Freezed(genericArgumentFactories: true)
class ApiResponseDto<T> with _$ApiResponseDto<T> {
  const factory ApiResponseDto({
    required bool success,
    required T data,
    String? message,
    @JsonKey(name: 'error_code') String? errorCode,
  }) = _ApiResponseDto;

  factory ApiResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ApiResponseDtoFromJson(json, fromJsonT);
}

// Usage in API Data Source
@GET('/posts')
Future<ApiResponseDto<List<PostDto>>> getPostsWrapped();
```

### DTO with Enums

```dart
// lib/core/enums/post_status.dart
enum PostStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('published')
  published,
  @JsonValue('archived')
  archived,
}

// In DTO
@freezed
class PostDto with _$PostDto {
  const factory PostDto({
    required int id,
    required String title,
    required PostStatus status, // Enum field
    // ...
  }) = _PostDto;

  factory PostDto.fromJson(Map<String, dynamic> json) => 
      _$PostDtoFromJson(json);
}
```

## Implementing Repositories

Repositories implement the domain interfaces and use data sources.

### Basic Repository Implementation

**Location**: `lib/data/repositories/user_repo_impl.dart`

```dart
// lib/data/repositories/user_repo_impl.dart
import 'package:dio/dio.dart';
import 'package:project_name/core/utils/app_error.dart';
import 'package:project_name/core/utils/result.dart';
import 'package:project_name/data/data_sources/api_data_source.dart';
import 'package:project_name/data/dto/user/user_dto.dart';
import 'package:project_name/domain/entities/user/user.dart';
import 'package:project_name/domain/repositories/user_repo.dart';

class UserRepoImpl implements UserRepo {
  final ApiDataSource _apiDataSource;

  UserRepoImpl(this._apiDataSource);

  @override
  Future<Result<User>> getCurrentUser() async {
    try {
      final userDto = await _apiDataSource.getCurrentUser();
      return Success(userDto.toDomain());
    } on DioException catch (e) {
      return Error(_handleDioError(e));
    } catch (e) {
      return Error(AppError(message: 'Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<User>> updateUser(User user) async {
    try {
      final userDto = await _apiDataSource.updateUser(
        user.id,
        user.toDto(),
      );
      return Success(userDto.toDomain());
    } on DioException catch (e) {
      return Error(_handleDioError(e));
    } catch (e) {
      return Error(AppError(message: 'Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> deleteUser() async {
    try {
      // Assuming you have userId available, perhaps from auth service
      await _apiDataSource.deleteUser('current-user-id');
      return const Success(null);
    } on DioException catch (e) {
      return Error(_handleDioError(e));
    } catch (e) {
      return Error(AppError(message: 'Unexpected error: ${e.toString()}'));
    }
  }

  AppError _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError(
          message: 'Connection timeout. Please check your internet.',
          statusCode: 408,
        );
      case DioExceptionType.badResponse:
        return AppError(
          message: error.response?.data['message'] ?? 'Server error',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return AppError(message: 'Request cancelled');
      case DioExceptionType.connectionError:
        return AppError(message: 'No internet connection');
      default:
        return AppError(message: error.message ?? 'Unknown error');
    }
  }
}
```

### Repository with Multiple Data Sources

Combine API and local storage for offline support.

```dart
// lib/data/repositories/post_repo_impl.dart
import 'package:dio/dio.dart';
import 'package:project_name/core/utils/app_error.dart';
import 'package:project_name/core/utils/result.dart';
import 'package:project_name/data/data_sources/api_data_source.dart';
import 'package:project_name/data/data_sources/local_data_source.dart';
import 'package:project_name/domain/entities/post/post.dart';
import 'package:project_name/domain/repositories/post_repo.dart';

class PostRepoImpl implements PostRepo {
  final ApiDataSource _apiDataSource;
  final LocalDataSource _localDataSource;

  PostRepoImpl(this._apiDataSource, this._localDataSource);

  @override
  Future<Result<List<Post>>> getPosts() async {
    try {
      // Try to fetch from API
      final dtos = await _apiDataSource.getPosts();
      final posts = dtos.map((dto) => dto.toDomain()).toList();
      
      // Cache the results locally
      await _localDataSource.cachePosts(dtos);
      
      return Success(posts);
    } on DioException catch (e) {
      // If API fails, try to get from cache
      try {
        final cachedDtos = await _localDataSource.getCachedPosts();
        if (cachedDtos.isNotEmpty) {
          final posts = cachedDtos.map((dto) => dto.toDomain()).toList();
          return Success(posts);
        }
      } catch (_) {
        // Cache also failed
      }
      
      return Error(AppError(
        message: e.response?.data['message'] ?? 'Failed to fetch posts',
        statusCode: e.response?.statusCode,
      ));
    }
  }

  @override
  Future<Result<Post>> createPost(Post post) async {
    try {
      final dto = await _apiDataSource.createPost(post.toDto());
      return Success(dto.toDomain());
    } on DioException catch (e) {
      return Error(AppError(
        message: e.response?.data['message'] ?? 'Failed to create post',
        statusCode: e.response?.statusCode,
      ));
    }
  }

  @override
  Future<Result<void>> deletePost(int id) async {
    try {
      await _apiDataSource.deletePost(id);
      
      // Also remove from local cache
      await _localDataSource.deletePostFromCache(id);
      
      return const Success(null);
    } on DioException catch (e) {
      return Error(AppError(
        message: e.response?.data['message'] ?? 'Failed to delete post',
        statusCode: e.response?.statusCode,
      ));
    }
  }
}
```

## Error Handling

### Create App Error Model

**Location**: `lib/core/utils/app_error.dart`

```dart
// lib/core/utils/app_error.dart
class AppError {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic originalError;

  AppError({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.originalError,
  });

  bool get isNetworkError => 
      statusCode == null || statusCode == 0 || statusCode == 408;

  bool get isServerError => 
      statusCode != null && statusCode! >= 500;

  bool get isClientError => 
      statusCode != null && statusCode! >= 400 && statusCode! < 500;

  bool get isUnauthorized => statusCode == 401;

  bool get isForbidden => statusCode == 403;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'AppError: $message (code: $statusCode)';
}
```

### Centralized Error Handler

```dart
// lib/data/network/error_handler.dart
import 'package:dio/dio.dart';
import 'package:project_name/core/utils/app_error.dart';

class ErrorHandler {
  static AppError handleError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is AppError) {
      return error;
    } else {
      return AppError(
        message: 'Unexpected error: ${error.toString()}',
        originalError: error,
      );
    }
  }

  static AppError _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError(
          message: 'Connection timeout. Please try again.',
          statusCode: 408,
          originalError: error,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        
        String message = 'Something went wrong';
        if (responseData is Map<String, dynamic>) {
          message = responseData['message'] ?? 
                   responseData['error'] ?? 
                   message;
        }
        
        return AppError(
          message: message,
          statusCode: statusCode,
          errorCode: responseData is Map ? responseData['error_code'] : null,
          originalError: error,
        );

      case DioExceptionType.cancel:
        return AppError(
          message: 'Request cancelled',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return AppError(
          message: 'No internet connection',
          statusCode: 0,
          originalError: error,
        );

      default:
        return AppError(
          message: error.message ?? 'Unknown error occurred',
          originalError: error,
        );
    }
  }
}
```

## Local Data Sources

### Using SharedPreferences

**Location**: `lib/data/data_sources/local_data_source.dart`

```dart
// lib/data/data_sources/local_data_source.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_name/data/dto/post/post_dto.dart';

class LocalDataSource {
  final SharedPreferences _prefs;

  LocalDataSource(this._prefs);

  // Cache posts
  Future<void> cachePosts(List<PostDto> posts) async {
    final jsonList = posts.map((post) => post.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString('cached_posts', jsonString);
  }

  // Get cached posts
  Future<List<PostDto>> getCachedPosts() async {
    final jsonString = _prefs.getString('cached_posts');
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => PostDto.fromJson(json)).toList();
  }

  // Delete post from cache
  Future<void> deletePostFromCache(int postId) async {
    final posts = await getCachedPosts();
    final updatedPosts = posts.where((post) => post.id != postId).toList();
    await cachePosts(updatedPosts);
  }

  // Clear all cache
  Future<void> clearCache() async {
    await _prefs.remove('cached_posts');
  }

  // Save single value
  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }
}
```

### Register SharedPreferences

```dart
// lib/core/service_locator.dart or main.dart
// Register SharedPreferences during app initialization
Future<void> setupDependencies() async {
  final sharedPrefs = await SharedPreferences.getInstance();
  
  // Create data sources
  final localDataSource = LocalDataSource(sharedPrefs);
  
  // Use in repositories
  // final postRepo = PostRepoImpl(apiDataSource, localDataSource);
}
```

## Best Practices

### 1. Always Use DTOs for API Communication

```dart
// ✅ Good - Use DTO
final dto = await _apiDataSource.getUser();
final user = dto.toDomain();

// ❌ Bad - Don't use domain entity directly
final user = await _apiDataSource.getUser(); // Returns User (domain entity)
```

### 2. Handle All Error Types

```dart
// ✅ Good - Comprehensive error handling
try {
  final dto = await _apiDataSource.getUser();
  return Success(dto.toDomain());
} on DioException catch (e) {
  return Error(_handleDioError(e));
} catch (e) {
  return Error(AppError(message: 'Unexpected error: ${e.toString()}'));
}

// ❌ Bad - Generic catch
try {
  final dto = await _apiDataSource.getUser();
  return Success(dto.toDomain());
} catch (e) {
  return Error(AppError(message: e.toString()));
}
```

### 3. Use Proper HTTP Methods

- `GET`: Retrieve data (no body)
- `POST`: Create new resource
- `PUT`: Update entire resource
- `PATCH`: Partial update
- `DELETE`: Remove resource

### 4. Add Request/Response Logging in Development

```dart
// Only in debug mode
if (kDebugMode) {
  dio.interceptors.add(LoggingInterceptor());
}
```

### 5. Cache Strategically

```dart
// Strategy 1: Cache-first, then network
Future<Result<List<Post>>> getPosts() async {
  // Return cached data immediately
  final cachedPosts = await _getCachedPosts();
  
  // Fetch fresh data in background
  _fetchAndCachePosts();
  
  return Success(cachedPosts);
}

// Strategy 2: Network-first, fallback to cache
Future<Result<List<Post>>> getPosts() async {
  try {
    final posts = await _fetchFromNetwork();
    await _cachePosts(posts);
    return Success(posts);
  } catch (e) {
    final cachedPosts = await _getCachedPosts();
    return Success(cachedPosts);
  }
}
```

### 6. Use Proper Status Code Checks

```dart
if (response.statusCode == 200) {
  // Success
} else if (response.statusCode == 401) {
  // Unauthorized - logout user
} else if (response.statusCode == 403) {
  // Forbidden - show permission error
} else if (response.statusCode == 404) {
  // Not found
} else if (response.statusCode! >= 500) {
  // Server error
}
```

### 7. Validate Data Before Mapping

```dart
extension UserDtoX on UserDto {
  User toDomain() {
    // Validate email format
    if (!email.contains('@')) {
      throw Exception('Invalid email format');
    }
    
    return User(
      id: id,
      email: email,
      name: name.trim(), // Clean data
      createdAt: DateTime.parse(createdAt),
    );
  }
}
```

## Complete Examples

### Example 1: Complete User Repository

```dart
class UserRepoImpl implements UserRepo {
  final ApiDataSource _apiDataSource;
  final LocalDataSource _localDataSource;

  UserRepoImpl(this._apiDataSource, this._localDataSource);

  @override
  Future<Result<User>> getCurrentUser() async {
    try {
      final userDto = await _apiDataSource.getCurrentUser();
      final user = userDto.toDomain();
      
      // Cache user locally
      await _localDataSource.saveString('current_user', jsonEncode(userDto.toJson()));
      
      return Success(user);
    } on DioException catch (e) {
      return Error(_handleDioError(e));
    } catch (e) {
      return Error(AppError(message: 'Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<User>> updateUser(User user) async {
    try {
      final userDto = await _apiDataSource.updateUser(user.id, user.toDto());
      
      // Update local cache
      await _localDataSource.saveString('current_user', jsonEncode(userDto.toJson()));
      
      return Success(userDto.toDomain());
    } on DioException catch (e) {
      return Error(_handleDioError(e));
    } catch (e) {
      return Error(AppError(message: 'Unexpected error: ${e.toString()}'));
    }
  }

  AppError _handleDioError(DioException error) {
    return ErrorHandler.handleError(error);
  }
}
```

### Example 2: Pagination Support

```dart
@RestApi()
abstract class ApiDataSource {
  @GET('/posts')
  Future<PaginatedResponseDto<PostDto>> getPostsPaginated(
    @Query('page') int page,
    @Query('limit') int limit,
  );
}

// DTO for paginated response
@freezed
class PaginatedResponseDto<T> with _$PaginatedResponseDto<T> {
  const factory PaginatedResponseDto({
    required List<T> data,
    required int page,
    required int totalPages,
    required int totalItems,
  }) = _PaginatedResponseDto;

  factory PaginatedResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$PaginatedResponseDtoFromJson(json, fromJsonT);
}

// Repository implementation
@override
Future<Result<PaginatedData<Post>>> getPostsPaginated(
  int page,
  int limit,
) async {
  try {
    final response = await _apiDataSource.getPostsPaginated(page, limit);
    
    final paginatedData = PaginatedData<Post>(
      items: response.data.map((dto) => dto.toDomain()).toList(),
      page: response.page,
      totalPages: response.totalPages,
      totalItems: response.totalItems,
    );
    
    return Success(paginatedData);
  } on DioException catch (e) {
    return Error(_handleDioError(e));
  }
}
```

### Example 3: File Upload

```dart
// API Data Source
@POST('/upload')
@MultiPart()
Future<UploadResponseDto> uploadImage(
  @Part(name: 'image') File image,
  @Part(name: 'description') String? description,
);

// Repository
@override
Future<Result<String>> uploadProfilePicture(File image) async {
  try {
    final response = await _apiDataSource.uploadImage(image, 'profile_picture');
    return Success(response.url);
  } on DioException catch (e) {
    return Error(_handleDioError(e));
  }
}
```

---

## Summary Checklist

### Data Source Setup
- [ ] Configure Dio with base URL and timeouts
- [ ] Add auth interceptor for token injection
- [ ] Add logging interceptor for debugging
- [ ] Define API endpoints with manual Dio calls
- [ ] Register data sources in service locator or main.dart

### DTO Creation
- [ ] Create DTO class with fields matching API response
- [ ] Implement manual `fromJson` factory method
- [ ] Implement manual `toJson` method
- [ ] Handle field name mapping (snake_case ↔ camelCase) manually
- [ ] Create `toDomain()` extension for DTO → Entity conversion
- [ ] Create `toDto()` extension for Entity → DTO conversion (if needed)

### Repository Implementation
- [ ] Implement domain repository interface
- [ ] Use constructor injection for data sources
- [ ] Convert DTOs to domain entities at repository boundary
- [ ] Return `Result<T>` for all methods (Success or Error)
- [ ] Handle DioException specifically
- [ ] Add generic exception handling
- [ ] Consider caching strategy
- [ ] Register repository in service locator

### Error Handling
- [ ] Create AppError model
- [ ] Handle network timeouts
- [ ] Handle server errors (5xx)
- [ ] Handle client errors (4xx)
- [ ] Handle connection errors
- [ ] Provide meaningful error messages

**Remember**: The data layer implements the contracts defined by the domain layer. Always convert DTOs to domain entities at the repository boundary.