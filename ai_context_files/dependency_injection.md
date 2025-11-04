# Dependency Injection - Custom Service Locator Pattern

This document explains the custom Service Locator pattern used in your Flutter project, replacing external DI packages like get_it or injectable with a clean, manual implementation.

## Overview

Your project uses a **custom Service Locator** pattern that provides:
- ✅ **No external dependencies** - Pure Dart implementation
- ✅ **Simple and lightweight** - Minimal overhead
- ✅ **Type-safe** - Compile-time type checking
- ✅ **Testable** - Easy to mock and reset
- ✅ **Module-based** - Organized by architectural layers

## Architecture

### Service Locator Class

```dart
// lib/di/service_locator.dart
class ServiceLocator {
  final Map<Type, dynamic> _services = {};
  final Map<Type, dynamic Function()> _factories = {};

  void registerSingleton<T>(T instance) {
    _services[T] = instance;
  }

  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  T get<T>() {
    // Check singletons first
    if (_services.containsKey(T)) {
      return _services[T] as T;
    }
    
    // Check factories
    if (_factories.containsKey(T)) {
      return _factories[T]!();
    }
    
    throw Exception('Service not found for type $T');
  }

  bool contains<T>() {
    return _services.containsKey(T) || _factories.containsKey(T);
  }

  void reset() {
    _services.clear();
    _factories.clear();
  }
}

// Global instance
final sl = ServiceLocator();
```

### Key Features

1. **Singleton Registration**: Objects registered once and reused
2. **Factory Registration**: New instance created each time
3. **Type Safety**: Generic methods ensure compile-time type checking
4. **Reset Capability**: Clear all registrations for testing
5. **Existence Check**: Verify if a service is registered

## Module-Based Registration

### DIModule Interface

```dart
// lib/di/di_module.dart
abstract class DIModule {
  Future<void> register();
}
```

### Network Module

```dart
class NetworkModule extends DIModule {
  @override
  Future<void> register() async {
    // Dio configuration
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 30);
    
    // Add interceptors
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
    ));
    
    // Register Dio as singleton
    sl.registerSingleton<Dio>(dio);
  }
}
```

### Data Module

```dart
class DataModule extends DIModule {
  @override
  Future<void> register() async {
    // API Clients
    sl.registerFactory<GithubApiClient>(() => 
      GithubApiClient(sl.get<Dio>())
    );
    
    // Repositories
    sl.registerFactory<GithubRepository>(() => 
      GithubRepositoryImpl(sl.get<GithubApiClient>())
    );
  }
}
```

### Domain Module

```dart
class DomainModule extends DIModule {
  @override
  Future<void> register() async {
    // Use Cases
    sl.registerFactory<GetRepositoriesUseCase>(() => 
      GetRepositoriesUseCase(sl.get<GithubRepository>())
    );
  }
}
```

### Presentation Module

```dart
class PresentationModule extends DIModule {
  @override
  Future<void> register() async {
    // Cubits/Blocs as factories (new instance each time)
    sl.registerFactory<GithubRepoCubit>(() => 
      GithubRepoCubit(sl.get<GetRepositoriesUseCase>())
    );
  }
}
```

### Registration Order

```dart
// lib/di/register_modules.dart
Future<void> registerModules() async {
  final modules = <DIModule>[
    NetworkModule(),      // Dio, network configuration
    DataModule(),         // API clients, repositories
    DomainModule(),       // Use cases
    PresentationModule(), // Cubits/Blocs
  ];
  
  for (final module in modules) {
    await module.register();
  }
}
```

## Usage Patterns

### In Widgets

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register all modules
  await registerModules();
  
  runApp(const MyApp());
}
```

### In Screens

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

### In Use Cases

```dart
class GetRepositoriesUseCase {
  final GithubRepository _githubRepo;
  
  GetRepositoriesUseCase(this._githubRepo);
  
  Future<Result<List<GithubRepo>>> call() async {
    return await _githubRepo.getRepositories();
  }
}
```

## Testing with Service Locator

### Reset Between Tests

```dart
void main() {
  setUp(() async {
    // Clear all registrations
    sl.reset();
    
    // Register test modules
    await registerTestModules();
  });
  
  tearDown(() {
    sl.reset();
  });
}
```

### Mock Registration

```dart
// Register mock instead of real implementation
sl.registerSingleton<GithubRepository>(
  MockGithubRepository()
);

// Or register factory that returns mock
sl.registerFactory<GithubRepository>(
  () => MockGithubRepository()
);
```

## Best Practices

### 1. Registration Order Matters

```dart
// ✅ Correct order - dependencies first
final modules = [
  NetworkModule(),      // Dio
  DataModule(),         // Needs Dio
  DomainModule(),       // Needs repositories
  PresentationModule(), // Needs use cases
];

// ❌ Wrong order - will fail
final modules = [
  PresentationModule(), // Needs use cases that aren't registered yet
  DomainModule(),
  DataModule(),
  NetworkModule(),
];
```

### 2. Choose Singleton vs Factory Wisely

```dart
// ✅ Singleton - shared state, expensive to create
sl.registerSingleton<Dio>(Dio());
sl.registerSingleton<UserRepository>(UserRepositoryImpl());

// ✅ Factory - no shared state, lightweight
sl.registerFactory<GetUserUseCase>(() => GetUserUseCase(sl.get()));
sl.registerFactory<ProfileCubit>(() => ProfileCubit(sl.get()));
```

### 3. Constructor Injection Pattern

```dart
// ✅ Good - Constructor injection
class GithubRepoCubit extends Cubit<GithubRepoState> {
  final GetRepositoriesUseCase _getRepositoriesUseCase;
  
  GithubRepoCubit(this._getRepositoriesUseCase) 
    : super(GithubRepoState.initial());
}

// ❌ Bad - Direct service locator usage
class GithubRepoCubit extends Cubit<GithubRepoState> {
  GithubRepoCubit() : super(GithubRepoState.initial());
  
  void loadData() {
    final useCase = sl.get<GetRepositoriesUseCase>();
    // ...
  }
}
```

### 4. Error Handling

```dart
// ✅ Good - Handle missing services
try {
  final cubit = sl.get<GithubRepoCubit>();
} catch (e) {
  // Handle service not found error
  debugPrint('Service not found: $e');
}

// ✅ Good - Check before getting
if (sl.contains<GithubRepoCubit>()) {
  final cubit = sl.get<GithubRepoCubit>();
}
```

### 5. Module Organization

```dart
// ✅ Good - Separate modules by layer
- NetworkModule: Dio, HTTP clients
- DataModule: Repositories, API services
- DomainModule: Use cases
- PresentationModule: Cubits/Blocs

// ❌ Bad - Mixed concerns
class MixedModule extends DIModule {
  @override
  Future<void> register() async {
    sl.registerSingleton(Dio()); // Network
    sl.registerFactory(UserRepositoryImpl()); // Data
    sl.registerFactory(GetUserUseCase()); // Domain
    sl.registerFactory(ProfileCubit()); // Presentation
  }
}
```

## Comparison with External Packages

| Feature | Custom Service Locator | get_it | injectable |
|---------|---------------------|--------|------------|
| External Dependencies | ❌ None | ✅ Required | ✅ Required |
| Setup Complexity | 🟢 Simple | 🟡 Medium | 🔴 Complex |
| Code Generation | ❌ None | ❌ None | ✅ Required |
| Type Safety | ✅ Compile-time | ✅ Compile-time | ✅ Compile-time |
| Testability | ✅ Easy | ✅ Easy | ✅ Easy |
| Performance | 🟢 Fast | 🟡 Medium | 🔴 Slower (code gen) |
| Learning Curve | 🟢 Low | 🟡 Medium | 🔴 High |

## Migration from get_it

If you're migrating from get_it, here's the mapping:

```dart
// get_it syntax
GetIt.I.registerSingleton<Dio>(Dio());
GetIt.I.registerFactory<UserCubit>(() => UserCubit());
final dio = GetIt.I.get<Dio>();

// Custom Service Locator syntax
sl.registerSingleton<Dio>(Dio());
sl.registerFactory<UserCubit>(() => UserCubit());
final dio = sl.get<Dio>();
```

## Common Patterns

### Repository Pattern with DI

```dart
// Domain interface (no DI knowledge)
abstract class GithubRepository {
  Future<Result<List<GithubRepo>>> getRepositories();
}

// Data implementation (uses DI)
class GithubRepositoryImpl implements GithubRepository {
  final GithubApiClient _apiClient;
  
  GithubRepositoryImpl(this._apiClient);
  
  @override
  Future<Result<List<GithubRepo>>> getRepositories() async {
    try {
      final response = await _apiClient.get('/repositories');
      final dtos = (response as List)
          .map((json) => GithubRepositoryDto.fromJson(json))
          .toList();
      final repos = dtos.map((dto) => dto.toDomain()).toList();
      return Success(repos);
    } catch (e) {
      return Error(AppError(message: e.toString()));
    }
  }
}
```

### Use Case Pattern with DI

```dart
class GetRepositoriesUseCase {
  final GithubRepository _githubRepo;
  
  GetRepositoriesUseCase(this._githubRepo);
  
  Future<Result<List<GithubRepo>>> call() async {
    return await _githubRepo.getRepositories();
  }
}
```

### Cubit Pattern with DI

```dart
class GithubRepoCubit extends Cubit<GithubRepoState> {
  final GetRepositoriesUseCase _getRepositoriesUseCase;
  
  GithubRepoCubit(this._getRepositoriesUseCase) 
    : super(GithubRepoState.initial());
  
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
}
```

## Troubleshooting

### Service Not Found Error

```dart
// Error: Exception: Service not found for type GithubRepoCubit

// Solution: Check registration order
await registerModules(); // Make sure this is called

// Solution: Verify registration
print(sl.contains<GithubRepoCubit>()); // Should print: true
```

### Circular Dependency Error

```dart
// Problem: A needs B, B needs A
class A {
  final B b;
  A(this.b);
}

class B {
  final A a;
  B(this.a);
}

// Solution: Use factory pattern or refactor
sl.registerFactory<A>(() => A(sl.get<B>()));
sl.registerFactory<B>(() => B(sl.get<A>())); // ❌ Circular

// Better: Refactor to avoid circular dependencies
```

### Testing Issues

```dart
// Problem: Tests interfere with each other

// Solution: Reset between tests
setUp(() {
  sl.reset();
  registerTestModules();
});

tearDown(() {
  sl.reset();
});
```

## Advanced Patterns

### Conditional Registration

```dart
class EnvironmentModule extends DIModule {
  @override
  Future<void> register() async {
    if (kDebugMode) {
      // Debug-specific services
      sl.registerFactory<Logger>(() => DebugLogger());
    } else {
      // Production services
      sl.registerFactory<Logger>(() => ProductionLogger());
    }
  }
}
```

### Scoped Dependencies

```dart
class UserSessionModule extends DIModule {
  @override
  Future<void> register() async {
    // Register user-specific services
    sl.registerSingleton<UserSession>(UserSession());
    
    // Register services that depend on user session
    sl.registerFactory<UserService>(() => 
      UserService(sl.get<UserSession>())
    );
  }
  
  void unregister() {
    // Remove user-specific services
    sl._services.remove(UserSession);
    sl._services.remove(UserService);
  }
}
```

## Summary

Your custom Service Locator provides:
- **Simplicity**: No external dependencies or code generation
- **Performance**: Direct object access with minimal overhead
- **Flexibility**: Easy to extend and customize
- **Testability**: Simple to mock and reset
- **Maintainability**: Clear module organization

This approach aligns with your clean architecture by keeping dependencies minimal while providing the flexibility needed for scalable applications.
