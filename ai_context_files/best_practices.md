# Clean Architecture Best Practices for Flutter

This document consolidates best practices, common pitfalls, and guidelines for implementing Clean Architecture in Flutter projects.

## Table of Contents
1. [Core Principles](#core-principles)
2. [Layer-Specific Best Practices](#layer-specific-best-practices)
3. [Common Pitfalls and Solutions](#common-pitfalls-and-solutions)
4. [Code Quality Guidelines](#code-quality-guidelines)
5. [Testing Best Practices](#testing-best-practices)
6. [Performance Considerations](#performance-considerations)
7. [Quick Reference Checklists](#quick-reference-checklists)

## Core Principles

### The Dependency Rule

**Golden Rule**: Source code dependencies must point only inward.

```
Presentation → Domain ← Data
    ↓           ↑
    └───────────┘
         ✗ Never this direction
```

- **Domain Layer**: No dependencies on outer layers
- **Data Layer**: Depends on domain (interfaces only)
- **Presentation Layer**: Depends on domain (use cases only)

### Independence

Each layer should be:
- **Testable**: Can be tested in isolation
- **Replaceable**: Can swap implementations without affecting other layers
- **Independent**: Changes in one layer don't force changes in others

### Clear Responsibilities

| Layer | Responsibility | What it Contains |
|-------|---------------|------------------|
| **Domain** | Business logic | Entities, Use Cases, Repository Interfaces |
| **Data** | Data access | DTOs, Repository Implementations, Data Sources |
| **Presentation** | UI & State | Pages, Widgets, Cubits/Blocs, States |
| **Core** | Shared utilities | Constants, Extensions, Utils |

## Layer-Specific Best Practices

### Domain Layer Best Practices

#### 1. Keep Domain Pure

✅ **Good**:
```dart
// lib/domain/entities/user/user.dart
// Pure Dart only - no external dependencies

class User {
  final String id;
  final String name;

  const User({
    required this.id,
    required this.name,
  });

  User copyWith({
    String? id,
    String? name,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
```

❌ **Bad**:
```dart
// lib/domain/entities/user/user.dart
import 'package:flutter/material.dart'; // ❌ Flutter dependency
import 'package:dio/dio.dart'; // ❌ External package

class User {
  final String id;
  final String name;
}
```

**Allowed Dependencies in Domain**:
- `dart:core` (default Dart libraries)
- `dartz` (for functional programming - Either, optional)
- Other domain layer files

#### 2. One Use Case = One Responsibility

✅ **Good**:
```dart
// Separate use cases for each operation
class GetUserUseCase {
  Future<Either<AppError, User>> call() { ... }
}

class UpdateUserUseCase {
  Future<Either<AppError, User>> call(User user) { ... }
}

class DeleteUserUseCase {
  Future<Either<AppError, void>> call(String userId) { ... }
}
```

❌ **Bad**:
```dart
// God use case - too many responsibilities
class UserUseCase {
  Future<User> getUser() { ... }
  Future<User> updateUser(User user) { ... }
  Future<void> deleteUser(String userId) { ... }
  Future<List<User>> searchUsers(String query) { ... }
}
```

#### 3. Use Either for Error Handling

✅ **Good**:
```dart
abstract class UserRepo {
  Future<Either<AppError, User>> getUser();
  Future<Either<AppError, User>> updateUser(User user);
}
```

❌ **Bad**:
```dart
abstract class UserRepo {
  Future<User?> getUser(); // Loses error context
  Future<User> updateUser(User user); // Can't handle errors
}
```

#### 4. Repository Interfaces Should Be Abstract

✅ **Good**:
```dart
abstract class UserRepo {
  Future<Either<AppError, User>> getUser();
  Future<Either<AppError, User>> updateUser(User user);
}
```

❌ **Bad**:
```dart
class UserRepo {
  Future<Either<AppError, User>> getUser() {
    throw UnimplementedError();
  }
}
```

#### 5. Entities Should Be Immutable

✅ **Good**:
```dart
class User {
  final String id;
  final String name;

  const User({
    required this.id,
    required this.name,
  });

  // Create copyWith method for updates
  User copyWith({
    String? id,
    String? name,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}

// To update, create a new instance
final updatedUser = user.copyWith(name: 'New Name');
```

❌ **Bad**:
```dart
class User {
  String id;
  String name; // Mutable

  User({required this.id, required this.name});
}

// Mutating state
user.name = 'New Name'; // ❌ Side effects
```

### Data Layer Best Practices

#### 1. Always Use DTOs for API Communication

✅ **Good**:
```dart
class UserRepoImpl implements UserRepo {
  final ApiDataSource _apiDataSource;

  UserRepoImpl(this._apiDataSource);

  @override
  Future<Either<AppError, User>> getUser() async {
    final dto = await _apiDataSource.getUser(); // Returns UserDto
    return Right(dto.toDomain()); // Convert to domain entity
  }
}
```

❌ **Bad**:
```dart
class UserRepoImpl implements UserRepo {
  final ApiDataSource _apiDataSource;

  UserRepoImpl(this._apiDataSource);

  @override
  Future<Either<AppError, User>> getUser() async {
    final user = await _apiDataSource.getUser(); // Returns User (domain entity)
    return Right(user); // ❌ No separation
  }
}
```

#### 2. Map DTOs to Entities at Repository Boundary

✅ **Good**:
```dart
// DTO in data layer
extension UserDtoX on UserDto {
  User toDomain() {
    return User(
      id: id,
      name: name,
      createdAt: DateTime.parse(createdAt), // Convert types
    );
  }
}

// Repository
final dto = await _apiDataSource.getUser();
return Right(dto.toDomain()); // Convert at boundary
```

❌ **Bad**:
```dart
// Mixing DTOs and Entities
final dto = await _apiDataSource.getUser();
return Right(dto); // ❌ Returning DTO instead of entity
```

#### 3. Handle All Error Types

✅ **Good**:
```dart
@override
Future<Either<AppError, User>> getUser() async {
  try {
    final dto = await _apiDataSource.getUser();
    return Right(dto.toDomain());
  } on DioException catch (e) {
    return Left(_handleDioError(e)); // Specific error handling
  } on SocketException catch (e) {
    return Left(AppError(message: 'No internet connection'));
  } catch (e) {
    return Left(AppError(message: 'Unexpected error: ${e.toString()}'));
  }
}
```

❌ **Bad**:
```dart
@override
Future<Either<AppError, User>> getUser() async {
  try {
    final dto = await _apiDataSource.getUser();
    return Right(dto.toDomain());
  } catch (e) {
    return Left(AppError(message: e.toString())); // Generic error
  }
}
```

#### 4. Use Dependency Injection

✅ **Good**:
```dart
class UserRepoImpl implements UserRepo {
  final ApiDataSource _apiDataSource;
  
  UserRepoImpl(this._apiDataSource); // Injected via constructor
}

// Manual registration in service locator or main.dart
final apiDataSource = ApiDataSource(dio);
final userRepo = UserRepoImpl(apiDataSource);
```

❌ **Bad**:
```dart
class UserRepoImpl implements UserRepo {
  final ApiDataSource _apiDataSource = ApiDataSource(); // ❌ Direct instantiation
}
```

#### 5. Repository Should Not Contain Business Logic

✅ **Good**:
```dart
@override
Future<Either<AppError, User>> getUser() async {
  try {
    final dto = await _apiDataSource.getUser();
    return Right(dto.toDomain()); // Simple mapping
  } catch (e) {
    return Left(AppError(message: e.toString()));
  }
}
```

❌ **Bad**:
```dart
@override
Future<Either<AppError, User>> getUser() async {
  try {
    final dto = await _apiDataSource.getUser();
    final user = dto.toDomain();
    
    // ❌ Business logic in repository
    if (user.age < 18) {
      return Left(AppError(message: 'User must be 18+'));
    }
    
    return Right(user);
  } catch (e) {
    return Left(AppError(message: e.toString()));
  }
}
```

### Presentation Layer Best Practices

#### 1. Inject Use Cases, Not Repositories

✅ **Good**:
```dart
class ProfileCubit extends Cubit<ProfileState> {
  final GetUserUseCase _getUserUseCase;
  final UpdateUserUseCase _updateUserUseCase;

  ProfileCubit(
    this._getUserUseCase,
    this._updateUserUseCase,
  ) : super(const ProfileState.initial());
}

// Manual instantiation example
final cubit = ProfileCubit(
  GetUserUseCase(userRepo),
  UpdateUserUseCase(userRepo),
);
```

❌ **Bad**:
```dart
class ProfileCubit extends Cubit<ProfileState> {
  final UserRepo _userRepo; // ❌ Injecting repository directly

  ProfileCubit(this._userRepo) : super(const ProfileState.initial());
}
```

#### 2. No Business Logic in Cubit/Bloc

✅ **Good**:
```dart
class ProfileCubit extends Cubit<ProfileState> {
  final GetUserUseCase _getUserUseCase;

  ProfileCubit(this._getUserUseCase) : super(const ProfileState.initial());

  Future<void> loadUser() async {
    emit(const ProfileState.loading());
    
    final result = await _getUserUseCase(); // Use case handles logic
    
    result.fold(
      (error) => emit(ProfileState.error(error.message)),
      (user) => emit(ProfileState.loaded(user)),
    );
  }
}
```

❌ **Bad**:
```dart
class ProfileCubit extends Cubit<ProfileState> {
  final Dio _dio; // ❌ Direct API dependency

  ProfileCubit(this._dio) : super(const ProfileState.initial());

  Future<void> loadUser() async {
    emit(const ProfileState.loading());
    
    try {
      // ❌ Business logic in Cubit
      final response = await _dio.get('/user');
      final json = response.data;
      final user = User.fromJson(json);
      
      // ❌ Validation in Cubit
      if (user.age < 18) {
        emit(const ProfileState.error('User must be 18+'));
        return;
      }
      
      emit(ProfileState.loaded(user));
    } catch (e) {
      emit(ProfileState.error(e.toString()));
    }
  }
}
```

#### 3. Use Sealed Classes for State Management

✅ **Good**:
```dart
// Base state class
sealed class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final User user;
  const ProfileLoaded(this.user);
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
}

// Usage with pattern matching
Widget build(BuildContext context, ProfileState state) {
  return switch (state) {
    ProfileInitial() => const SizedBox(),
    ProfileLoading() => const CircularProgressIndicator(),
    ProfileLoaded(:final user) => UserProfile(user: user),
    ProfileError(:final message) => ErrorWidget(message: message),
  };
}
```

❌ **Bad**:
```dart
class ProfileState {
  final bool isLoading;
  final User? user;
  final String? error;

  ProfileState({
    this.isLoading = false,
    this.user,
    this.error,
  });
}

// Usage - error prone
if (state.isLoading) {
  return const CircularProgressIndicator();
} else if (state.error != null) {
  return ErrorWidget(message: state.error!);
} else if (state.user != null) {
  return UserProfile(user: state.user!);
}
```

#### 4. Handle All State Cases

✅ **Good**:
```dart
BlocBuilder<ProfileCubit, ProfileState>(
  builder: (context, state) {
    return state.when(
      initial: () => const SizedBox(),
      loading: () => const CircularProgressIndicator(),
      loaded: (user) => UserProfile(user: user),
      error: (message) => ErrorWidget(message: message),
    ); // All cases handled
  },
)
```

❌ **Bad**:
```dart
BlocBuilder<ProfileCubit, ProfileState>(
  builder: (context, state) {
    return state.whenOrNull(
      loaded: (user) => UserProfile(user: user),
      error: (message) => ErrorWidget(message: message),
    ) ?? const SizedBox(); // ❌ Missing initial and loading states
  },
)
```

#### 5. Use BlocProvider with Clean Dependency Injection

✅ **Good**:
```dart
class ProfilePage extends StatelessWidget {
  final ProfileCubit cubit;

  const ProfilePage({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => cubit..loadUser(),
      child: const ProfileView(),
    );
  }
}

// Or with constructor injection pattern
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get dependencies from a service locator pattern
    final userRepo = ServiceLocator.get<UserRepo>();
    final getUserUseCase = GetUserUseCase(userRepo);
    
    return BlocProvider(
      create: (context) => ProfileCubit(getUserUseCase)..loadUser(),
      child: const ProfileView(),
    );
  }
}
```

❌ **Bad**:
```dart
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileCubit(
        GetUserUseCase(UserRepoImpl(ApiDataSource())), // ❌ Deep nesting, hard to test
      )..loadUser(),
      child: const ProfileView(),
    );
  }
}
```

## Common Pitfalls and Solutions

### Pitfall 1: Domain Layer Depends on Data Layer

❌ **Problem**:
```dart
// lib/domain/entities/user/user.dart
import 'package:myapp/data/dto/user_dto.dart'; // ❌ Wrong direction

class User {
  // ...
}
```

✅ **Solution**:
```dart
// lib/domain/entities/user/user.dart
// No imports from data layer

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
  }) = _User;
}
```

**Rule**: Domain should never import from data or presentation layers.

### Pitfall 2: Business Logic in Presentation Layer

❌ **Problem**:
```dart
class UserCubit extends Cubit<UserState> {
  final Dio _dio;

  Future<void> loadUser() async {
    final response = await _dio.get('/user'); // ❌ Direct API call
    final user = User.fromJson(response.data);
    
    // ❌ Business validation in Cubit
    if (user.email.isEmpty) {
      emit(UserState.error('Email is required'));
      return;
    }
    
    emit(UserState.loaded(user));
  }
}
```

✅ **Solution**:
```dart
// Use case handles business logic
class GetUserUseCase implements NoParamUseCase<User> {
  final UserRepo _userRepo;

  GetUserUseCase(this._userRepo);

  @override
  Future<Either<AppError, User>> call() async {
    final result = await _userRepo.getUser();
    
    return result.fold(
      (error) => Left(error),
      (user) {
        // Business validation in use case
        if (user.email.isEmpty) {
          return Left(AppError(message: 'Email is required'));
        }
        return Right(user);
      },
    );
  }
}

// Cubit just calls use case
class UserCubit extends Cubit<UserState> {
  final GetUserUseCase _getUserUseCase;

  UserCubit(this._getUserUseCase) : super(const UserState.initial());

  Future<void> loadUser() async {
    emit(const UserState.loading());
    
    final result = await _getUserUseCase();
    
    result.fold(
      (error) => emit(UserState.error(error.message)),
      (user) => emit(UserState.loaded(user)),
    );
  }
}
```

### Pitfall 3: Entities and DTOs Mixed

❌ **Problem**:
```dart
// lib/domain/entities/user.dart
class UserDto { // ❌ DTO in domain layer
  final String id;
  final String userName;
}
```

✅ **Solution**:
```dart
// lib/domain/entities/user/user.dart
class User {
  final String id;
  final String name;

  const User({
    required this.id,
    required this.name,
  });

  User copyWith({String? id, String? name}) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}

// lib/data/dto/user/user_dto.dart
class UserDto {
  final String id;
  final String userName;

  const UserDto({
    required this.id,
    required this.userName,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      userName: json['user_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
    };
  }
}

// Mapping
extension UserDtoX on UserDto {
  User toDomain() => User(id: id, name: userName);
}
```

### Pitfall 4: Not Handling Errors Properly

❌ **Problem**:
```dart
Future<void> loadUser() async {
  final user = await getUser(); // What if it fails?
  emit(UserState.loaded(user));
}
```

✅ **Solution**:
```dart
Future<void> loadUser() async {
  emit(const UserState.loading());
  
  final result = await _getUserUseCase();
  
  result.fold(
    (error) => emit(UserState.error(error.message)),
    (user) => emit(UserState.loaded(user)),
  );
}
```

### Pitfall 5: Incomplete Manual Implementations

❌ **Problem**:
- Forgot to implement `copyWith` method for entities
- Missing `fromJson` or `toJson` in DTOs
- No equality operators for value objects

✅ **Solution**:
```dart
// Complete entity implementation
class User {
  final String id;
  final String name;

  const User({required this.id, required this.name});

  // Don't forget copyWith for immutability
  User copyWith({String? id, String? name}) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  // Implement equality for value comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

// Complete DTO implementation
class UserDto {
  final String id;
  final String name;

  const UserDto({required this.id, required this.name});

  // Don't forget JSON serialization
  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
```

### Pitfall 6: Not Using Proper Folder Structure

❌ **Problem**:
```
lib/
├── models/
│   ├── user.dart          # Mixed entities and DTOs
│   └── post.dart
├── services/
│   └── api_service.dart   # Mixed concerns
└── screens/
    └── home_screen.dart
```

✅ **Solution**:
```
lib/
├── core/
│   └── utils/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── use_cases/
├── data/
│   ├── dto/
│   ├── data_sources/
│   └── repositories/
└── presentation/
    └── [features]/
```

### Pitfall 7: Creating God Classes

❌ **Problem**:
```dart
class UserManager {
  // ❌ Too many responsibilities
  Future<User> getUser() { ... }
  Future<User> updateUser(User user) { ... }
  Future<void> deleteUser() { ... }
  Future<List<User>> searchUsers(String query) { ... }
  Future<void> sendEmail(String email) { ... }
  Future<bool> validateUser(User user) { ... }
}
```

✅ **Solution**:
```dart
// Separate use cases
class GetUserUseCase { ... }
class UpdateUserUseCase { ... }
class DeleteUserUseCase { ... }
class SearchUsersUseCase { ... }

// Email is separate feature
class SendEmailUseCase { ... }

// Validation in entity or use case
```

## Code Quality Guidelines

### 1. Naming Conventions

| Component | Convention | Example |
|-----------|-----------|---------|
| Entity | Singular, PascalCase | `User`, `Post`, `Comment` |
| DTO | Entity + Dto suffix | `UserDto`, `PostDto` |
| Repository Interface | Entity + Repo | `UserRepo`, `PostRepo` |
| Repository Implementation | Interface + Impl | `UserRepoImpl`, `PostRepoImpl` |
| Use Case | Verb + Entity + UseCase | `GetUserUseCase`, `CreatePostUseCase` |
| State | Feature + State | `ProfileState`, `PostsState` |
| Cubit/Bloc | Feature + Cubit/Bloc | `ProfileCubit`, `PostsBloc` |
| Page | Feature + Page | `ProfilePage`, `PostsPage` |

### 2. File Organization

```
feature_name/
├── domain/
│   ├── entities/
│   │   └── feature_name/
│   │       └── entity.dart
│   ├── repositories/
│   │   └── feature_repo.dart
│   └── use_cases/
│       ├── get_feature_use_case.dart
│       └── create_feature_use_case.dart
├── data/
│   ├── dto/
│   │   └── feature_name/
│   │       └── entity_dto.dart
│   ├── data_sources/
│   │   └── api_data_source.dart
│   └── repositories/
│       └── feature_repo_impl.dart
└── presentation/
    └── feature_name/
        ├── feature_page.dart
        ├── cubit/
        │   ├── feature_cubit.dart
        │   └── feature_state.dart
        └── widgets/
            └── custom_widget.dart
```

### 3. Documentation

Add documentation to:
- Public APIs
- Complex business logic
- Repository interfaces
- Use cases

```dart
/// Repository for managing user data.
///
/// Provides methods to fetch, update, and delete user information.
abstract class UserRepo {
  /// Fetches the current authenticated user.
  ///
  /// Returns [Right(User)] on success.
  /// Returns [Left(AppError)] on failure.
  Future<Either<AppError, User>> getCurrentUser();

  /// Updates the user profile.
  ///
  /// [user] The updated user data.
  /// Returns the updated [User] on success.
  Future<Either<AppError, User>> updateUser(User user);
}
```

### 4. Error Messages

Provide meaningful error messages:

✅ **Good**:
```dart
return Left(AppError(
  message: 'Failed to fetch user profile. Please check your connection.',
  statusCode: 408,
));
```

❌ **Bad**:
```dart
return Left(AppError(message: 'Error')); // Not helpful
```

## Testing Best Practices

### 1. Test Each Layer Independently

```dart
// Domain layer test - no dependencies
test('GetUserUseCase returns user on success', () async {
  // Arrange
  final mockRepo = MockUserRepo();
  when(mockRepo.getUser()).thenAnswer(
    (_) async => Right(testUser),
  );
  
  final useCase = GetUserUseCase(mockRepo);
  
  // Act
  final result = await useCase();
  
  // Assert
  expect(result, Right(testUser));
});

// Data layer test - mock API
test('UserRepoImpl returns user from API', () async {
  // Arrange
  final mockApi = MockApiDataSource();
  when(mockApi.getUser()).thenAnswer(
    (_) async => testUserDto,
  );
  
  final repo = UserRepoImpl(mockApi);
  
  // Act
  final result = await repo.getUser();
  
  // Assert
  expect(result, Right(testUser));
});

// Presentation layer test - mock use case
blocTest<ProfileCubit, ProfileState>(
  'emits [loading, loaded] when loadUser succeeds',
  build: () {
    when(mockGetUserUseCase()).thenAnswer(
      (_) async => Right(testUser),
    );
    return ProfileCubit(mockGetUserUseCase);
  },
  act: (cubit) => cubit.loadUser(),
  expect: () => [
    const ProfileState.loading(),
    ProfileState.loaded(testUser),
  ],
);
```

### 2. Use Mocks for External Dependencies

```dart
// Mock repository
class MockUserRepo extends Mock implements UserRepo {}

// Mock data source
class MockApiDataSource extends Mock implements ApiDataSource {}

// Mock use case
class MockGetUserUseCase extends Mock implements GetUserUseCase {}
```

### 3. Test Error Cases

```dart
test('GetUserUseCase returns error on failure', () async {
  // Arrange
  final mockRepo = MockUserRepo();
  when(mockRepo.getUser()).thenAnswer(
    (_) async => Left(AppError(message: 'Network error')),
  );
  
  final useCase = GetUserUseCase(mockRepo);
  
  // Act
  final result = await useCase();
  
  // Assert
  expect(result.isLeft(), true);
});
```

## Performance Considerations

### 1. Lazy Loading

```dart
// Manual singleton pattern for expensive operations
class UserRepoImpl implements UserRepo {
  static UserRepoImpl? _instance;
  
  UserRepoImpl._();
  
  factory UserRepoImpl(ApiDataSource apiDataSource) {
    _instance ??= UserRepoImpl._();
    return _instance!;
  }
  
  // Or use a service locator with lazy initialization
}

// Factory pattern for lightweight objects
class GetUserUseCase implements NoParamUseCase<User> {
  final UserRepo _userRepo;
  
  GetUserUseCase(this._userRepo); // Create new instance each time
}
```

### 2. Caching Strategy

```dart
// Network-first with cache fallback
@override
Future<Either<AppError, List<Post>>> getPosts() async {
  try {
    final posts = await _apiDataSource.getPosts();
    await _cacheDataSource.cachePosts(posts);
    return Right(posts.map((dto) => dto.toDomain()).toList());
  } catch (e) {
    // Fallback to cache
    final cachedPosts = await _cacheDataSource.getCachedPosts();
    if (cachedPosts.isNotEmpty) {
      return Right(cachedPosts.map((dto) => dto.toDomain()).toList());
    }
    return Left(AppError(message: e.toString()));
  }
}
```

### 3. Pagination

```dart
// Domain entity
class PaginatedData<T> {
  final List<T> items;
  final int page;
  final int totalPages;
  final bool hasMore;

  const PaginatedData({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.hasMore,
  });

  PaginatedData<T> copyWith({
    List<T>? items,
    int? page,
    int? totalPages,
    bool? hasMore,
  }) {
    return PaginatedData<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// Use case
class GetPostsUseCase {
  final PostRepo _postRepo;

  GetPostsUseCase(this._postRepo);

  Future<Either<AppError, PaginatedData<Post>>> call(int page) {
    return _postRepo.getPostsPaginated(page, limit: 20);
  }
}
```

## Quick Reference Checklists

### Creating a New Feature

- [ ] Define entity in `domain/entities/` with copyWith and equality methods
- [ ] Create repository interface in `domain/repositories/`
- [ ] Create use cases in `domain/use_cases/`
- [ ] Ensure no Flutter/external dependencies in domain
- [ ] Create DTO in `data/dto/` with manual fromJson/toJson methods
- [ ] Create toDomain() extension for DTO mapping
- [ ] Implement repository in `data/repositories/`
- [ ] Register dependencies manually in service locator
- [ ] Create sealed state classes in `presentation/[feature]/cubit/`
- [ ] Create cubit in `presentation/[feature]/cubit/`
- [ ] Create page in `presentation/[feature]/`
- [ ] Add tests for all layers

### Code Review Checklist

- [ ] Domain layer has no Flutter/external dependencies
- [ ] DTOs are only in data layer
- [ ] Entities are only in domain layer
- [ ] Entities have copyWith, equality operators, and hashCode
- [ ] DTOs have manual fromJson and toJson methods
- [ ] All async operations return `Either<AppError, T>`
- [ ] Error handling covers all cases
- [ ] State management uses sealed classes with pattern matching
- [ ] Cubit/Bloc only calls use cases
- [ ] No business logic in presentation layer
- [ ] Dependencies injected via constructors
- [ ] All state cases handled in UI
- [ ] Tests written for critical paths

### Dependency Injection Checklist

- [ ] All repositories implement interfaces
- [ ] All use cases have constructor injection
- [ ] All cubits/blocs have constructor injection
- [ ] Data sources registered in service locator
- [ ] Manual dependency registration in service locator or main.dart
- [ ] Dependencies properly scoped (singleton vs factory)
- [ ] No circular dependencies

### Before Committing

- [ ] Run `flutter analyze` - no errors
- [ ] Run `flutter test` - all tests pass
- [ ] Format code: `flutter format .`
- [ ] Remove debug prints
- [ ] Check for unused imports
- [ ] Verify all entities have copyWith and equality methods
- [ ] Verify all DTOs have fromJson/toJson methods
- [ ] Update documentation if needed

---

## Summary

**Key Takeaways**:

1. **Separation of Concerns**: Each layer has clear responsibilities
2. **Dependency Rule**: Dependencies point inward (toward domain)
3. **Testability**: Each layer can be tested independently
4. **Use Cases**: Encapsulate business operations
5. **DTOs vs Entities**: Map at repository boundaries with manual implementations
6. **Either for Errors**: Explicit error handling
7. **Constructor Injection**: Pass dependencies through constructors
8. **Immutability**: Implement copyWith methods and const constructors
9. **State Management**: Use sealed classes with pattern matching
10. **Manual Implementation**: Write fromJson/toJson, equality operators, and hashCode

**Remember**: Clean Architecture is about making your code maintainable, testable, and scalable. Manual implementations give you full control and understanding of your codebase. Start simple and refine as you go!