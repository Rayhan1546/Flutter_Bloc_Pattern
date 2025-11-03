# Dependency Injection Guide - Custom Service Locator Pattern

This guide explains the custom dependency injection pattern used in this project without external DI packages.

## Table of Contents
1. [Overview](#overview)
2. [Service Locator Pattern](#service-locator-pattern)
3. [Module-Based Registration](#module-based-registration)
4. [Registration Patterns](#registration-patterns)
5. [Usage Examples](#usage-examples)
6. [Best Practices](#best-practices)

## Overview

This project uses a **custom Service Locator pattern** instead of external DI packages like `get_it` or `injectable`. This provides:

- **Full control** over dependency lifecycle
- **No code generation** required
- **Simple and lightweight** implementation
- **Easy to understand** and maintain
- **Modular organization** by layer

## Service Locator Pattern

### Implementation

**Location**: `lib/di/service_locator.dart`

```dart
/// Service Locator for Dependency Injection
/// This is a simple implementation without external DI packages
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  
  factory ServiceLocator() => _instance;
  
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};
  final Map<Type, dynamic Function()> _factories = {};

  /// Register a singleton instance
  void registerSingleton<T>(T instance) {
    _services[T] = instance;
  }

  /// Register a factory function
  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  /// Get a registered service
  T get<T>() {
    // Check if singleton exists
    if (_services.containsKey(T)) {
      return _services[T] as T;
    }

    // Check if factory exists
    if (_factories.containsKey(T)) {
      return _factories[T]!() as T;
    }

    throw Exception('Service of type $T is not registered');
  }

  /// Check if a service is registered
  bool isRegistered<T>() {
    return _services.containsKey(T) || _factories.containsKey(T);
  }

  /// Reset all services (useful for testing)
  void reset() {
    _services.clear();
    _factories.clear();
  }
}
```

### Key Features

- **Singleton Pattern**: Single instance across the app
- **Type-safe**: Uses Dart generics for type safety
- **Two registration types**:
  - `registerSingleton<T>()`: One instance shared everywhere
  - `registerFactory<T>()`: New instance each time
- **Simple retrieval**: `get<T>()` to fetch dependencies
- **Test support**: `reset()` method for cleaning between tests

## Module-Based Registration

Dependencies are organized into modules by architectural layer.

### DIModule Interface

**Location**: `lib/di/di_module.dart`

```dart
/// Base module interface for dependency registration
abstract class DIModule {
  Future<void> register();
}
```

### Global Service Locator Instance

```dart
/// Global service locator instance
final sl = ServiceLocator();
```

### Module Registration Order

**Location**: `lib/di/register_modules.dart`

```dart
/// Registers all dependency injection modules
/// 
/// Modules are registered in order:
/// 1. NetworkModule - Core network dependencies (Dio)
/// 2. DataModule - Data sources and repositories
/// 3. DomainModule - Use cases
/// 4. PresentationModule - Cubits/Blocs
Future<void> registerModules() async {
  final modules = <DIModule>[
    NetworkModule(),
    DataModule(),
    DomainModule(),
    PresentationModule(),
  ];

  for (final module in modules) {
    await module.register();
  }
}
```

**Important**: Modules must be registered in dependency order to ensure dependencies are available when needed.

## Registration Patterns

### Network Module

Registers core network dependencies like Dio.

```dart
/// Network module - registers Dio and network-related dependencies
class NetworkModule implements DIModule {
  @override
  Future<void> register() async {
    // Register Dio as singleton
    sl.registerSingleton<Dio>(
      Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ),
    );
  }
}
```

**Pattern**: Network clients are singletons since they're expensive to create and should be reused.

### Data Module

Registers data sources and repository implementations.

```dart
/// Data module - registers data sources and repositories
class DataModule implements DIModule {
  @override
  Future<void> register() async {
    // Register ApiDataSource as singleton
    sl.registerSingleton<ApiDataSource>(
      ApiDataSource(sl.get<Dio>())
    );

    // Register GithubRepo implementation as singleton
    sl.registerSingleton<GithubRepo>(
      GithubRepoImpl(sl.get<ApiDataSource>())
    );
  }
}
```

**Pattern**: 
- Data sources are singletons (shared across app)
- Repositories registered by interface type, not implementation
- Constructor injection using `sl.get<T>()`

### Domain Module

Registers use cases.

```dart
/// Domain module - registers use cases
class DomainModule implements DIModule {
  @override
  Future<void> register() async {
    // Register GetRepositoriesUseCase as singleton
    sl.registerSingleton<GetRepositoriesUseCase>(
      GetRepositoriesUseCase(sl.get<GithubRepo>()),
    );
  }
}
```

**Pattern**: Use cases can be singletons if they're stateless.

### Presentation Module

Registers Cubits/Blocs.

```dart
/// Presentation module - registers cubits/blocs as factories
class PresentationModule implements DIModule {
  @override
  Future<void> register() async {
    // Register GithubRepoCubit as factory (new instance each time)
    sl.registerFactory<GithubRepoCubit>(
      () => GithubRepoCubit(sl.get<GetRepositoriesUseCase>()),
    );
  }
}
```

**Pattern**: Cubits/Blocs are factories (new instance for each screen/widget) to prevent state sharing between screens.

## Usage Examples

### App Initialization

**Location**: `lib/main.dart`

```dart
import 'package:junie_ai_test/di/register_modules.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register all dependencies
  await registerModules();
  
  runApp(const MyApp());
}
```

### Using Dependencies in Widgets

**Pattern 1: BlocProvider with Factory**

```dart
class GithubRepoScreen extends StatelessWidget {
  const GithubRepoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl.get<GithubRepoCubit>()..loadRepositories(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Repositories')),
        body: const GithubRepoView(),
      ),
    );
  }
}
```

**Pattern 2: Direct Usage in Cubit**

```dart
class GithubRepoCubit extends Cubit<GithubRepoState> {
  final GetRepositoriesUseCase _getRepositoriesUseCase;

  // Dependency injected via constructor
  GithubRepoCubit(this._getRepositoriesUseCase)
    : super(const GithubRepoInitial());

  Future<void> loadRepositories() async {
    emit(const GithubRepoLoading());
    final result = await _getRepositoriesUseCase();
    result.fold(
      (error) => emit(GithubRepoError(error.message)),
      (repos) => emit(GithubRepoLoaded(
        repositories: repos,
        filteredRepositories: repos,
      )),
    );
  }
}
```

### Testing with Service Locator

```dart
void main() {
  late MockGetRepositoriesUseCase mockUseCase;
  late GithubRepoCubit cubit;

  setUp(() {
    // Reset service locator before each test
    sl.reset();
    
    // Register mock dependencies
    mockUseCase = MockGetRepositoriesUseCase();
    sl.registerSingleton<GetRepositoriesUseCase>(mockUseCase);
    
    // Create cubit with mocked dependency
    cubit = sl.get<GithubRepoCubit>();
  });

  tearDown(() {
    cubit.close();
    sl.reset();
  });

  test('loadRepositories emits loaded state on success', () async {
    // Test implementation
  });
}
```

## Best Practices

### 1. Register by Interface, Not Implementation

✅ **Good**:
```dart
// Register repository by interface
sl.registerSingleton<GithubRepo>(
  GithubRepoImpl(sl.get<ApiDataSource>())
);

// Retrieve by interface
final repo = sl.get<GithubRepo>();
```

❌ **Bad**:
```dart
// Register by implementation
sl.registerSingleton<GithubRepoImpl>(
  GithubRepoImpl(sl.get<ApiDataSource>())
);

// Tightly coupled to implementation
final repo = sl.get<GithubRepoImpl>();
```

### 2. Choose Correct Registration Type

**Singleton**: Use for stateless services
- Network clients (Dio)
- Data sources
- Repositories
- Stateless use cases

```dart
sl.registerSingleton<ApiDataSource>(ApiDataSource(dio));
```

**Factory**: Use for stateful components
- Cubits/Blocs (have state)
- Components that should be recreated

```dart
sl.registerFactory<GithubRepoCubit>(
  () => GithubRepoCubit(sl.get<GetRepositoriesUseCase>())
);
```

### 3. Respect Dependency Order

Register modules in correct order:

```dart
1. NetworkModule    // No dependencies
2. DataModule       // Depends on NetworkModule
3. DomainModule     // Depends on DataModule
4. PresentationModule // Depends on DomainModule
```

### 4. Use Constructor Injection

✅ **Good**:
```dart
class GithubRepoCubit extends Cubit<GithubRepoState> {
  final GetRepositoriesUseCase _useCase;

  GithubRepoCubit(this._useCase) : super(const GithubRepoInitial());
}
```

❌ **Bad**:
```dart
class GithubRepoCubit extends Cubit<GithubRepoState> {
  late final GetRepositoriesUseCase _useCase;

  GithubRepoCubit() : super(const GithubRepoInitial()) {
    _useCase = sl.get<GetRepositoriesUseCase>(); // Service locator inside class
  }
}
```

### 5. Reset Service Locator in Tests

```dart
setUp(() {
  sl.reset(); // Clean slate for each test
  // Register test dependencies
});

tearDown(() {
  sl.reset(); // Clean up after test
});
```

### 6. Organize by Modules

Create separate module files when needed:

```
lib/di/
├── service_locator.dart      # Core service locator
├── di_module.dart            # All modules in one file
├── register_modules.dart     # Module registration
```

For larger projects, split into separate files:

```
lib/di/
├── service_locator.dart
├── modules/
│   ├── network_module.dart
│   ├── data_module.dart
│   ├── domain_module.dart
│   └── presentation_module.dart
└── register_modules.dart
```

## Adding New Features

When adding a new feature, follow this pattern:

### Step 1: Create Dependencies

```dart
// 1. Create repository implementation
class UserRepoImpl implements UserRepo {
  final ApiDataSource _apiDataSource;
  UserRepoImpl(this._apiDataSource);
  // Implementation
}

// 2. Create use case
class GetUserUseCase {
  final UserRepo _userRepo;
  GetUserUseCase(this._userRepo);
  // Implementation
}

// 3. Create cubit
class UserCubit extends Cubit<UserState> {
  final GetUserUseCase _getUserUseCase;
  UserCubit(this._getUserUseCase) : super(const UserInitial());
  // Implementation
}
```

### Step 2: Register in Modules

```dart
// In DataModule
class DataModule implements DIModule {
  @override
  Future<void> register() async {
    // ... existing registrations
    
    // Add new repository
    sl.registerSingleton<UserRepo>(
      UserRepoImpl(sl.get<ApiDataSource>())
    );
  }
}

// In DomainModule
class DomainModule implements DIModule {
  @override
  Future<void> register() async {
    // ... existing registrations
    
    // Add new use case
    sl.registerSingleton<GetUserUseCase>(
      GetUserUseCase(sl.get<UserRepo>())
    );
  }
}

// In PresentationModule
class PresentationModule implements DIModule {
  @override
  Future<void> register() async {
    // ... existing registrations
    
    // Add new cubit
    sl.registerFactory<UserCubit>(
      () => UserCubit(sl.get<GetUserUseCase>())
    );
  }
}
```

### Step 3: Use in Widget

```dart
class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl.get<UserCubit>()..loadUser(),
      child: const UserView(),
    );
  }
}
```

## Comparison with Injectable/Get_it

### This Approach (Custom Service Locator)

**Pros**:
- ✅ No code generation
- ✅ Simple and transparent
- ✅ Full control over lifecycle
- ✅ Easy to debug
- ✅ No external dependencies

**Cons**:
- ⚠️ Manual registration required
- ⚠️ No compile-time dependency checking
- ⚠️ More boilerplate for large projects

### Injectable/Get_it Approach

**Pros**:
- ✅ Automatic registration with annotations
- ✅ Less boilerplate
- ✅ Environment-based registration

**Cons**:
- ❌ Requires code generation
- ❌ Build runner overhead
- ❌ Less transparent (generated code)
- ❌ External dependencies

## Summary

**Key Takeaways**:

1. **Custom service locator** eliminates code generation
2. **Module-based organization** keeps dependencies organized by layer
3. **Singleton vs Factory**: Choose based on statefulness
4. **Register by interface**: Enables easy testing and swapping implementations
5. **Constructor injection**: Dependencies passed explicitly
6. **Order matters**: Register in dependency order
7. **Reset in tests**: Clean slate for each test

**When to Use This Pattern**:
- ✅ Small to medium projects
- ✅ Want to avoid code generation
- ✅ Prefer simple, understandable code
- ✅ Full control over DI lifecycle

**When to Consider Injectable/Get_it**:
- Large projects with many dependencies
- Team prefers annotations over manual registration
- Want compile-time dependency validation

---

**Remember**: Dependency injection is about decoupling components, not about the tool. This custom pattern achieves the same goals as external packages while maintaining simplicity and transparency.
