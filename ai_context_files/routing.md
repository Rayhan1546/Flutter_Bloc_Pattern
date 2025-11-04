# Routing and Navigation Guide

This document explains the routing and navigation patterns used in your Flutter project, focusing on GoRouter implementation and navigation best practices.

## Overview

Your project uses **GoRouter** for navigation with:
- ✅ **Declarative routing** with route definitions
- ✅ **Type-safe navigation** with route names and paths
- ✅ **Nested navigation** support
- ✅ **Deep linking** capabilities
- ✅ **Route guards** and redirection
- ✅ **BlocProvider integration** for state management

## Overview

This project uses **go_router** for declarative routing with these characteristics:

- **Part files**: Route names and paths separated into part files
- **Type-safe**: Named routes with constants
- **Clean separation**: Paths and names organized separately
- **Centralized**: Single router configuration

## Project Structure

```
lib/presentation/navigation/
├── app_navigation.dart    # Main router configuration
├── route_name.dart        # Route name constants (part file)
└── route_path.dart        # Route path constants (part file)
```

## Implementation

### Main Router Configuration

**Location**: `lib/presentation/navigation/app_navigation.dart`

```dart
import 'package:go_router/go_router.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/view/github_repo_screen.dart';

part 'route_name.dart';
part 'route_path.dart';

class AppNavigation {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: _RoutePath.home,
      routes: [
        GoRoute(
          path: _RoutePath.home,
          name: _RouteName.home,
          builder: (context, state) => GithubRepoScreen(),
        ),
        GoRoute(
          path: _RoutePath.repositories,
          name: _RouteName.repositories,
          builder: (context, state) => GithubRepoScreen(),
        ),
      ],
    );
  }
}
```

### Route Names (Part File)

**Location**: `lib/presentation/navigation/route_name.dart`

```dart
part of 'app_navigation.dart';

class _RouteName {
  static const String home = '/';
  static const String repositories = 'repositories';
}
```

**Purpose**: 
- Constants for route names
- Used for named navigation
- Type-safe route references

### Route Paths (Part File)

**Location**: `lib/presentation/navigation/route_path.dart`

```dart
part of 'app_navigation.dart';

class _RoutePath {
  static const String home = '/';
  static const String repositories = '/repositories';
}
```

**Purpose**:
- Constants for route paths
- URL-like strings
- Initial location configuration

### Using Router in Main App

**Location**: `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:junie_ai_test/di/register_modules.dart';
import 'package:junie_ai_test/presentation/navigation/app_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register dependencies
  await registerModules();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'My App',
      routerConfig: AppNavigation.createRouter(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
    );
  }
}
```

## Adding New Routes

Follow this pattern when adding new routes:

### Step 1: Add Route Path

In `route_path.dart`:

```dart
part of 'app_navigation.dart';

class _RoutePath {
  static const String home = '/';
  static const String repositories = '/repositories';
  
  // Add new path
  static const String profile = '/profile';
  static const String settings = '/settings';
}
```

### Step 2: Add Route Name

In `route_name.dart`:

```dart
part of 'app_navigation.dart';

class _RouteName {
  static const String home = '/';
  static const String repositories = 'repositories';
  
  // Add new name
  static const String profile = 'profile';
  static const String settings = 'settings';
}
```

### Step 3: Register Route

In `app_navigation.dart`:

```dart
class AppNavigation {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: _RoutePath.home,
      routes: [
        GoRoute(
          path: _RoutePath.home,
          name: _RouteName.home,
          builder: (context, state) => GithubRepoScreen(),
        ),
        GoRoute(
          path: _RoutePath.repositories,
          name: _RouteName.repositories,
          builder: (context, state) => GithubRepoScreen(),
        ),
        // Add new route
        GoRoute(
          path: _RoutePath.profile,
          name: _RouteName.profile,
          builder: (context, state) => ProfileScreen(),
        ),
        GoRoute(
          path: _RoutePath.settings,
          name: _RouteName.settings,
          builder: (context, state) => SettingsScreen(),
        ),
      ],
    );
  }
}
```

## Navigation Patterns

### Pattern 1: Navigate by Path

```dart
// Using context.go (replaces current route)
context.go('/repositories');

// Using context.push (adds to stack)
context.push('/profile');
```

### Pattern 2: Navigate by Name

```dart
// Using named routes (type-safe)
context.goNamed(_RouteName.repositories);
context.pushNamed(_RouteName.profile);
```

**Note**: Named routes need to be accessible. If using private classes (_RouteName), navigate by path or make the class public.

### Pattern 3: Navigate with Parameters

#### Path Parameters

```dart
// Define route with parameter
GoRoute(
  path: '/user/:id',
  name: 'user-detail',
  builder: (context, state) {
    final userId = state.pathParameters['id']!;
    return UserDetailScreen(userId: userId);
  },
),

// Navigate with parameter
context.go('/user/123');
context.goNamed('user-detail', pathParameters: {'id': '123'});
```

#### Query Parameters

```dart
// Navigate with query parameters
context.go('/search?query=flutter');

// Access in builder
GoRoute(
  path: '/search',
  builder: (context, state) {
    final query = state.uri.queryParameters['query'] ?? '';
    return SearchScreen(query: query);
  },
),
```

#### Extra Data (Object Passing)

```dart
// Pass complex object
context.push('/detail', extra: myObject);

// Access in builder
GoRoute(
  path: '/detail',
  builder: (context, state) {
    final data = state.extra as MyObject;
    return DetailScreen(data: data);
  },
),
```

### Pattern 4: Pop/Go Back

```dart
// Pop current route
context.pop();

// Pop with result
context.pop(result);

// Check if can pop
if (context.canPop()) {
  context.pop();
} else {
  context.go('/');
}
```

### Pattern 5: Replace Route

```dart
// Replace current route
context.pushReplacement('/home');

// Replace with named route
context.pushReplacementNamed('home');
```

## Advanced Patterns

### Nested Routes

```dart
GoRoute(
  path: '/home',
  builder: (context, state) => HomeScreen(),
  routes: [
    // Child route: /home/profile
    GoRoute(
      path: 'profile',
      builder: (context, state) => ProfileScreen(),
    ),
    // Child route: /home/settings
    GoRoute(
      path: 'settings',
      builder: (context, state) => SettingsScreen(),
    ),
  ],
),
```

### Route Guards (Authentication)

```dart
class AppNavigation {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: _RoutePath.home,
      redirect: (context, state) {
        // Check authentication status
        final isAuthenticated = checkAuth();
        final isAuthRoute = state.matchedLocation == '/login';
        
        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }
        
        if (isAuthenticated && isAuthRoute) {
          return '/';
        }
        
        return null; // No redirect
      },
      routes: [
        // Routes definition
      ],
    );
  }
}
```

### Error Handling

```dart
GoRouter(
  initialLocation: _RoutePath.home,
  errorBuilder: (context, state) => ErrorScreen(
    error: state.error,
  ),
  routes: [
    // Routes
  ],
)
```

### ShellRoute (Persistent Bottom Navigation)

```dart
GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithBottomNav(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => HomeScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => SearchScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => ProfileScreen(),
        ),
      ],
    ),
  ],
)
```

## Best Practices

### 1. Use Part Files for Organization

✅ **Good**:
```dart
// app_navigation.dart
part 'route_name.dart';
part 'route_path.dart';

// Separate concerns
```

❌ **Bad**:
```dart
// Everything in one file
class AppNavigation {
  static const String homePath = '/';
  static const String homeName = 'home';
  // ...
}
```

### 2. Use Constants for Routes

✅ **Good**:
```dart
class _RoutePath {
  static const String home = '/';
  static const String profile = '/profile';
}

// Usage
context.go(_RoutePath.profile);
```

❌ **Bad**:
```dart
// Magic strings
context.go('/profile'); // Typo-prone
```

### 3. Consistent Naming Convention

```dart
// Path: URL-like with leading slash
static const String userDetail = '/user/:id';

// Name: Simple identifier
static const String userDetail = 'user-detail';
```

### 4. Use Private Classes for Internal Constants

```dart
// Private class (not exported from module)
class _RoutePath {
  static const String home = '/';
}

// Or public if needed elsewhere
class RoutePath {
  static const String home = '/';
}
```

### 5. Organize Routes by Feature

For larger apps:

```
lib/presentation/navigation/
├── app_navigation.dart
├── routes/
│   ├── auth_routes.dart       # Authentication routes
│   ├── home_routes.dart       # Home feature routes
│   └── profile_routes.dart    # Profile feature routes
├── route_name.dart
└── route_path.dart
```

### 6. Handle Deep Links

```dart
GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final productId = state.pathParameters['id']!;
        return ProductScreen(productId: productId);
      },
    ),
  ],
)

// Deep link: myapp://product/123
```

### 7. Navigate After Async Operations

```dart
Future<void> login() async {
  final success = await authService.login();
  
  if (success && mounted) {
    context.go('/home');
  }
}
```

### 8. Use context.go vs context.push Appropriately

**Use `context.go`**:
- Replace navigation stack
- Navigate to root level
- After logout

```dart
context.go('/login'); // Replace stack
```

**Use `context.push`**:
- Add to navigation stack
- Allow back navigation
- Details/modal screens

```dart
context.push('/detail'); // Add to stack
```

## Example: Complete Feature Routing

### Step-by-Step: Add User Feature

**1. Update route_path.dart**:
```dart
part of 'app_navigation.dart';

class _RoutePath {
  static const String home = '/';
  static const String repositories = '/repositories';
  
  // User feature
  static const String users = '/users';
  static const String userDetail = '/users/:id';
  static const String userEdit = '/users/:id/edit';
}
```

**2. Update route_name.dart**:
```dart
part of 'app_navigation.dart';

class _RouteName {
  static const String home = '/';
  static const String repositories = 'repositories';
  
  // User feature
  static const String users = 'users';
  static const String userDetail = 'user-detail';
  static const String userEdit = 'user-edit';
}
```

**3. Update app_navigation.dart**:
```dart
class AppNavigation {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: _RoutePath.home,
      routes: [
        // Existing routes...
        
        // User routes
        GoRoute(
          path: _RoutePath.users,
          name: _RouteName.users,
          builder: (context, state) => UsersScreen(),
        ),
        GoRoute(
          path: _RoutePath.userDetail,
          name: _RouteName.userDetail,
          builder: (context, state) {
            final userId = state.pathParameters['id']!;
            return UserDetailScreen(userId: userId);
          },
        ),
        GoRoute(
          path: _RoutePath.userEdit,
          name: _RouteName.userEdit,
          builder: (context, state) {
            final userId = state.pathParameters['id']!;
            return UserEditScreen(userId: userId);
          },
        ),
      ],
    );
  }
}
```

**4. Navigate in app**:
```dart
// In UsersScreen
GestureDetector(
  onTap: () => context.go('/users/${user.id}'),
  child: UserCard(user: user),
)

// Or using path constants
GestureDetector(
  onTap: () => context.go(_RoutePath.userDetail.replaceAll(':id', user.id)),
  child: UserCard(user: user),
)
```

## Summary

**Key Takeaways**:

1. **Part files** organize route names and paths separately
2. **Constants** prevent typos and provide type safety
3. **Static factory** creates router configuration
4. **go_router** provides declarative routing
5. **context.go** vs **context.push** for different navigation needs
6. **Path parameters** for dynamic routes
7. **Query parameters** for optional data
8. **Extra data** for complex object passing

**Pattern Benefits**:
- ✅ Clean separation of concerns
- ✅ Easy to maintain and update
- ✅ Type-safe with constants
- ✅ Centralized configuration
- ✅ No code generation required

---

**Remember**: Consistent routing patterns make navigation predictable and maintainable. Use part files to keep route definitions organized and accessible.
