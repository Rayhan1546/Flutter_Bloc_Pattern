# Clean Architecture Best Practices for Flutter - Junie AI Test Project

This document consolidates best practices, common pitfalls, and guidelines for implementing Clean Architecture in your Flutter project based on the current codebase structure.

## Table of Contents
1. [Core Architecture Overview](#core-architecture-overview)
2. [Project Structure](#project-structure)
3. [Layer-Specific Best Practices](#layer-specific-best-practices)
4. [State Management Patterns](#state-management-patterns)
5. [Dependency Injection Pattern](#dependency-injection-pattern)
6. [Error Handling Patterns](#error-handling-patterns)
7. [Code Quality Guidelines](#code-quality-guidelines)
8. [Testing Best Practices](#testing-best-practices)
9. [Common Patterns Used](#common-patterns-used)

## Core Architecture Overview

Your project follows **Clean Architecture** with the following key principles:

### The Dependency Rule
```
Presentation → Domain ← Data
    ↓           ↑
    └───────────┘
         ✗ Never this direction
```

- **Domain Layer**: No dependencies on outer layers - pure business logic
- **Data Layer**: Depends on domain (interfaces only) - API calls and data mapping
- **Presentation Layer**: Depends on domain (use cases only) - UI and state management
- **Core Layer**: Shared utilities - Result types, AsyncState, AppError

### Key Architectural Decisions

1. **Custom Service Locator** instead of get_it/injectable
2. **Flutter Bloc** for state management with custom AsyncState
3. **GoRouter** for navigation
4. **Dio** for HTTP client with custom ApiClient abstraction
5. **Custom Result<T>** type instead of Either from dartz
6. **Module-based DI registration** organized by architectural layer

## Project Structure

```
lib/
├── core/                    # Shared utilities and state management
│   ├── state/
│   │   └── async_state.dart # AsyncState<T> for UI state management
│   └── utils/
│       ├── result.dart      # Result<T> for error handling
│       └── app_error.dart   # AppError for consistent error types
├── data/                    # Data layer
│   ├── data_sources/        # API clients and services
│   │   └── remote/
│   │       ├── api_client/  # Abstract ApiClient base class
│   │       └── api_service/ # API service interfaces and implementations
│   ├── dto/                 # Data Transfer Objects
│   └── repositories/        # Repository implementations
├── domain/                  # Business logic layer
│   ├── entities/           # Domain entities (immutable)
│   ├── repositories/       # Repository interfaces
│   └── use_cases/          # Use cases (one per operation)
├── di/                     # Dependency injection
│   ├── service_locator.dart    # Custom ServiceLocator implementation
│   ├── di_module.dart          # DIModule interface and implementations
│   └── register_modules.dart     # Module registration orchestration
└── presentation/           # UI layer
    ├── common/             # Shared UI components
    ├── feature/            # Feature-specific UI
    │   └── [feature_name]/
    │       ├── components/ # Reusable UI components
    │       ├── cubit/      # State management
    │       ├── view/       # Screens/pages
    │       └── widgets/    # Feature-specific widgets
    └── navigation/         # GoRouter configuration
```

## Layer-Specific Best Practices

### Domain Layer Best Practices

#### 1. Keep Domain Pure (No External Dependencies)

✅ **Good** - Pure Dart only:
```dart
// lib/domain/entities/github_repository/github_repository.dart
class GithubRepo {
  final int id;
  final String name;
  final String fullName;
  
  const GithubRepo({
    required this.id,
    required this.name,
    required this.fullName,
  });
  
  @override
  bool operator ==(Object other) { ... }
  
  @override
  int get hashCode => ...;
}
```

❌ **Bad** - External dependencies:
```dart
import 'package:flutter/material.dart'; // ❌ Never in domain
import 'package:dio/dio.dart'; // ❌ Never in domain
```

**Allowed in Domain**:
- `dart:core` and standard Dart libraries
- Other domain layer files
- Core utility files (Result, AppError)

#### 2. One Use Case = One Responsibility

✅ **Good** - Single responsibility:
```dart
class GetRepositoriesUseCase {
  final GithubRepository _githubRepo;
  
  GetRepositoriesUseCase(this._githubRepo);
  
  Future<Result<List<GithubRepo>>> call() async {
    return await _githubRepo.getRepositories();
  }
}
```

#### 3. Repository Interfaces Must Be Abstract

✅ **Good**:
```dart
abstract class GithubRepository {
  Future<Result<List<GithubRepo>>> getRepositories();
}
```

### Data Layer Best Practices

#### 1. DTO Pattern with Extension Methods

✅ **Good** - DTO to Domain conversion:
```dart
// lib/data/dto/github_repository/github_repository_dto.dart
class GithubRepositoryDto {
  final int id;
  final String name;
  
  const GithubRepositoryDto({required this.id, required this.name});
  
  factory GithubRepositoryDto.fromJson(Map<String, dynamic> json) {
    return GithubRepositoryDto(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

// Extension for domain conversion
extension GithubRepositoryDtoX on GithubRepositoryDto {
  GithubRepo toDomain() {
    return GithubRepo(
      id: id,
      name: name,
    );
  }
}
```

#### 2. Abstract ApiClient Pattern

✅ **Good** - Your current implementation:
```dart
// lib/data/data_sources/remote/api_client/api_client.dart
abstract class ApiClient {
  final Dio _dio;
  ApiClient(this._dio);
  
  String get baseUrl;
  Future<Map<String, String>> defaultHeader();
  
  Future<T> get<T>(String endpoint, {Map<String, dynamic>? queryParameters});
  Future<T> post<T>(String endpoint, {Map<String, dynamic>? data});
  // ... other HTTP methods
}

// Implementation for specific API
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

### Presentation Layer Best Practices

#### 1. Feature-Based Organization

✅ **Good** - Your current structure:
```
lib/presentation/feature/github_repository/
├── components/          # Reusable UI components
├── cubit/              # State management (Cubit + State)
├── view/               # Main screens
└── widgets/            # Feature-specific widgets
```

#### 2. BlocProvider Pattern

✅ **Good** - Screen-level BlocProvider:
```dart
class GithubRepoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl.get<GithubRepoCubit>()..loadRepositories(),
      child: Scaffold(...),
    );
  }
}
```

## State Management Patterns

### AsyncState<T> Pattern

Your project uses a custom `AsyncState<T>` instead of traditional Bloc states:

```dart
// lib/core/state/async_state.dart
sealed class AsyncState<T> {}

class AsyncInitial<T> extends AsyncState<T> {}
class AsyncLoading<T> extends AsyncState<T> {}
class AsyncSuccess<T> extends AsyncState<T> {
  final T data;
  AsyncSuccess(this.data);
}
class AsyncError<T> extends AsyncState<T> {
  final String message;
  AsyncError(this.message);
}
```

### Cubit State Pattern

✅ **Good** - Your current pattern:
```dart
// lib/presentation/feature/github_repository/cubit/github_repo_state.dart
class GithubRepoState {
  final AsyncState<List<GithubRepo>> repositoriesState;
  
  const GithubRepoState({required this.repositoriesState});
  
  factory GithubRepoState.initial() {
    return GithubRepoState(repositoriesState: AsyncInitial());
  }
  
  GithubRepoState copyWith({
    AsyncState<List<GithubRepo>>? repositoriesState,
  }) {
    return GithubRepoState(
      repositoriesState: repositoriesState ?? this.repositoriesState,
    );
  }
}
```

## Dependency Injection Pattern

### Custom Service Locator

Your project uses a custom ServiceLocator instead of external packages:

```dart
// lib/di/service_locator.dart
class ServiceLocator {
  final Map<Type, dynamic> _services = {};
  final Map<Type, dynamic Function()> _factories = {};
  
  void registerSingleton<T>(T instance) { ... }
  void registerFactory<T>(T Function() factory) { ... }
  T get<T>() { ... }
}

// Global instance
final sl = ServiceLocator();
```

### Module-Based Registration

✅ **Good** - Your current pattern:
```dart
// Registration order matters - dependencies first
Future<void> registerModules() async {
  final modules = <DIModule>[
    NetworkModule(),      // Dio, network config
    DataModule(),         // Repositories, API services
    DomainModule(),       // Use cases
    PresentationModule(), // Cubits/Blocs
  ];
  
  for (final module in modules) {
    await module.register();
  }
}
```

## Error Handling Patterns

### Result<T> Pattern

Your project uses a custom Result<T> instead of Either:

```dart
// lib/core/utils/result.dart
sealed class Result<T> {}
class Success<T> extends Result<T> {
  final T data;
  Success(this.data);
}
class Error<T> extends Result<T> {
  final AppError error;
  Error(this.error);
}
```

### Use Case Error Handling

✅ **Good** - Your current pattern:
```dart
Future<Result<List<GithubRepo>>> call() async {
  return await _githubRepo.getRepositories();
}
```

### Cubit Error Handling

✅ **Good** - Your current pattern:
```dart
Future<void> loadRepositories() async {
  emit(state.copyWith(repositoriesState: AsyncLoading()));
  
  final result = await _getRepositoriesUseCase();
  
  switch (result) {
    case Success(:final data):
      emit(state.copyWith(repositoriesState: AsyncSuccess(data)));
    case Error(:final error):
      emit(state.copyWith(repositoriesState: AsyncError(error.message)));
  }
}
```

### UI Component Patterns

#### AsyncState Switch Expression Pattern

✅ **Good** - Your current pattern in `github_repo_list.dart`:
```dart
class GithubRepoList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GithubRepoCubit, GithubRepoState>(
      builder: (context, state) {
        return switch (state.repositoriesState) {
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
          
          AsyncError(:final message) => ErrorRetryWidget(
            error: message,
            onTapRetry: () => cubit.loadRepositories(),
          ),
          
          AsyncSuccess<List<GithubRepo>>(:final data) when data.isEmpty =>
            const Center(child: Text("No Repository to show")),
          
          AsyncSuccess<List<GithubRepo>>(:final data) => ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final repository = data[index];
              return RepositoryItem(repository: repository);
            },
          ),
          
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}
```

#### Repository Item Widget Pattern

✅ **Good** - Your current pattern in `repository_item.dart`:
```dart
class RepositoryItem extends StatelessWidget {
  final GithubRepo repository;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(repository.owner.avatarUrl),
          radius: 24,
        ),
        title: Text(repository.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(repository.fullName, style: TextStyle(color: Colors.grey[600])),
            if (repository.description != null) ...[
              Text(repository.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            Row(
              children: [
                Icon(repository.private ? Icons.lock : Icons.public, size: 14),
                Text(repository.private ? 'Private' : 'Public'),
                if (repository.fork) ...[
                  Icon(Icons.fork_right, size: 14),
                  Text('Fork'),
                ],
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
```

## Code Quality Guidelines

### Naming Conventions

- **Files**: `snake_case.dart` (e.g., `github_repository.dart`)
- **Classes**: `PascalCase` (e.g., `GithubRepoCubit`)
- **Variables/Functions**: `camelCase` (e.g., `loadRepositories()`)
- **Constants**: `UPPER_SNAKE_CASE` (e.g., `BASE_URL`)

### File Organization

✅ **Good** - One class per file, named after the class:
```
github_repository.dart        # GithubRepo entity
github_repository_dto.dart   # GithubRepositoryDto
github_repository_impl.dart # GithubRepositoryImpl
```

### Extension Methods

✅ **Good** - Use for DTO to Domain conversion:
```dart
extension GithubRepositoryDtoX on GithubRepositoryDto {
  GithubRepo toDomain() {
    return GithubRepo(...);
  }
}
```

## Testing Best Practices

### Unit Testing Pattern

```dart
// Test use cases
void main() {
  late GetRepositoriesUseCase useCase;
  late MockGithubRepository mockRepository;
  
  setUp(() {
    mockRepository = MockGithubRepository();
    useCase = GetRepositoriesUseCase(mockRepository);
  });
  
  test('should return repositories when successful', () async {
    // Arrange
    final mockRepos = [GithubRepo(...)];
    when(mockRepository.getRepositories())
        .thenAnswer((_) async => Success(mockRepos));
    
    // Act
    final result = await useCase();
    
    // Assert
    expect(result, isA<Success<List<GithubRepo>>>());
    expect((result as Success).data, mockRepos);
  });
}
```

## Common Patterns Used

### 1. Repository Pattern
- Abstract repository interfaces in domain
- Concrete implementations in data layer
- Constructor injection of dependencies

### 2. Use Case Pattern
- One use case per business operation
- Simple `call()` method
- Returns `Result<T>` for error handling

### 3. Cubit Pattern
- State classes with `copyWith()` methods
- `AsyncState<T>` for UI state management
- Factory constructor for initial state

### 4. DTO Pattern
- Separate DTOs from domain entities
- Extension methods for conversion
- JSON serialization with `fromJson()`

### 5. Service Locator Pattern
- Custom implementation without external packages
- Module-based registration
- Singleton and factory registration support

This architecture provides:
- ✅ **Testability**: Each layer can be tested in isolation
- ✅ **Maintainability**: Clear separation of concerns
- ✅ **Scalability**: Easy to add new features following patterns
- ✅ **Flexibility**: Easy to swap implementations
- ✅ **Type Safety**: Strong typing throughout the codebase