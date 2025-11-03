# Feature Creation Guide - Clean Architecture

This guide provides step-by-step instructions for creating a new feature following Clean Architecture principles in Flutter.

## Table of Contents
1. [Overview](#overview)
2. [Layer Structure](#layer-structure)
3. [Step-by-Step Feature Creation](#step-by-step-feature-creation)
4. [Complete Example](#complete-example)
5. [Checklist](#checklist)

## Overview

When creating a new feature, follow the **Dependency Rule**: dependencies must point inward.
- **Domain Layer** (innermost): Pure business logic, no dependencies on outer layers
- **Data Layer**: Implements domain interfaces, handles external data
- **Presentation Layer** (outermost): UI and state management, depends on domain

**Flow**: UI → Use Case → Repository Interface → Repository Implementation → Data Source

## Layer Structure

```
lib/
├── core/                    # Shared utilities
│   ├── enums/
│   ├── extensions/
│   └── utils/
│       └── app_error.dart
├── domain/                  # Business logic (pure Dart)
│   ├── entities/           # Business models
│   │   └── [feature_name]/
│   │       └── [entity].dart
│   ├── repositories/       # Abstract contracts
│   │   └── [feature]_repo.dart
│   └── use_cases/          # Business operations
│       └── [action]_use_case.dart
├── data/                    # Implementation details
│   ├── dto/                # Data Transfer Objects
│   │   └── [feature_name]/
│   │       └── [entity]_dto.dart
│   ├── data_sources/       # API/Local storage
│   │   └── api_data_source.dart
│   └── repositories/       # Repository implementations
│       └── [feature]_repo_impl.dart
└── presentation/           # UI layer
    └── [feature_name]/
        ├── [feature]_page.dart
        ├── cubit/
        │   ├── [feature]_cubit.dart
        │   └── [feature]_state.dart
        └── widgets/
            └── [custom_widgets].dart
```

## Step-by-Step Feature Creation

### Step 1: Define Domain Entity

Create the business model in the domain layer. This represents your core business object.

**Location**: `lib/domain/entities/[feature_name]/[entity].dart`

```dart
// lib/domain/entities/post/post.dart
class Post {
  final int id;
  final String title;
  final String content;
  final String authorId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.createdAt,
    this.updatedAt,
  });

  Post copyWith({
    int? id,
    String? title,
    String? content,
    String? authorId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Post &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          content == other.content &&
          authorId == other.authorId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      content.hashCode ^
      authorId.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
}
```

**Key Points**:
- Use immutable fields (final)
- Implement copyWith for updates
- Add equality operators and hashCode
- No Flutter dependencies
- Pure Dart only

### Step 2: Define Repository Interface

Create an abstract repository interface in the domain layer.

**Location**: `lib/domain/repositories/[feature]_repo.dart`

```dart
// lib/domain/repositories/post_repo.dart
import 'package:dartz/dartz.dart';
import 'package:project_name/domain/entities/post/post.dart';
import 'package:project_name/utils/app_error.dart';

abstract class PostRepo {
  Future<Either<AppError, List<Post>>> getPosts();
  Future<Either<AppError, Post>> getPostById(int id);
  Future<Either<AppError, Post>> createPost(Post post);
  Future<Either<AppError, Post>> updatePost(Post post);
  Future<Either<AppError, void>> deletePost(int id);
}
```

**Key Points**:
- Use `Either<AppError, T>` for error handling
- Define all operations for this feature
- Abstract class (no implementation)
- Only use domain entities, never DTOs

### Step 3: Create Use Cases

Create individual use cases for each business operation.

**Location**: `lib/domain/use_cases/[action]_use_case.dart`

**Use Case Base Classes** (if not already created):
```dart
// lib/domain/utils/use_case.dart
import 'package:dartz/dartz.dart';
import 'package:project_name/utils/app_error.dart';

abstract class UseCase<T, S> {
  Future<Either<AppError, T>> call(S param);
}

abstract class NoParamUseCase<T> {
  Future<Either<AppError, T>> call();
}
```

**Example - Get Posts Use Case**:
```dart
// lib/domain/use_cases/get_posts_use_case.dart
import 'package:dartz/dartz.dart';
import 'package:project_name/domain/entities/post/post.dart';
import 'package:project_name/domain/repositories/post_repo.dart';
import 'package:project_name/domain/utils/use_case.dart';
import 'package:project_name/utils/app_error.dart';

class GetPostsUseCase implements NoParamUseCase<List<Post>> {
  final PostRepo _postRepo;

  GetPostsUseCase(this._postRepo);

  @override
  Future<Either<AppError, List<Post>>> call() {
    return _postRepo.getPosts();
  }
}
```

**Example - Create Post Use Case (with parameters)**:
```dart
// lib/domain/use_cases/create_post_use_case.dart
import 'package:dartz/dartz.dart';
import 'package:project_name/domain/entities/post/post.dart';
import 'package:project_name/domain/repositories/post_repo.dart';
import 'package:project_name/domain/utils/use_case.dart';
import 'package:project_name/utils/app_error.dart';

class CreatePostUseCase implements UseCase<Post, CreatePostParams> {
  final PostRepo _postRepo;

  CreatePostUseCase(this._postRepo);

  @override
  Future<Either<AppError, Post>> call(CreatePostParams params) {
    final post = Post(
      id: 0, // Will be set by backend
      title: params.title,
      content: params.content,
      authorId: params.authorId,
      createdAt: DateTime.now(),
    );
    
    return _postRepo.createPost(post);
  }
}

class CreatePostParams {
  final String title;
  final String content;
  final String authorId;

  const CreatePostParams({
    required this.title,
    required this.content,
    required this.authorId,
  });
}
```

**Key Points**:
- One use case = one business operation
- Inject repository through constructor
- Use `NoParamUseCase<T>` or `UseCase<T, Params>` based on need
- Keep business logic in use cases

### Step 4: Create DTO (Data Transfer Object)

Create DTOs in the data layer for API/database communication.

**Location**: `lib/data/dto/[feature_name]/[entity]_dto.dart`

```dart
// lib/data/dto/post/post_dto.dart
import 'package:project_name/domain/entities/post/post.dart';

class PostDto {
  final int id;
  final String title;
  final String content;
  final String authorId;
  final String createdAt;
  final String? updatedAt;

  const PostDto({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.createdAt,
    this.updatedAt,
  });

  factory PostDto.fromJson(Map<String, dynamic> json) {
    return PostDto(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      authorId: json['author_id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author_id': authorId,
      'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}

// Extension to convert DTO to Domain Entity
extension PostDtoX on PostDto {
  Post toDomain() {
    return Post(
      id: id,
      title: title,
      content: content,
      authorId: authorId,
      createdAt: DateTime.parse(createdAt),
      updatedAt: updatedAt != null ? DateTime.parse(updatedAt!) : null,
    );
  }
}

// Extension to convert Domain Entity to DTO
extension PostX on Post {
  PostDto toDto() {
    return PostDto(
      id: id,
      title: title,
      content: content,
      authorId: authorId,
      createdAt: createdAt.toIso8601String(),
      updatedAt: updatedAt?.toIso8601String(),
    );
  }
}
```

**Key Points**:
- Manual fromJson factory for deserialization
- Manual toJson method for serialization
- Handle field name mapping (snake_case ↔ camelCase) manually
- Create `toDomain()` extension to convert DTO → Entity
- Create `toDto()` extension to convert Entity → DTO
- Handle type conversions (e.g., String → DateTime)

### Step 5: Implement Repository

Implement the repository interface in the data layer.

**Location**: `lib/data/repositories/[feature]_repo_impl.dart`

```dart
// lib/data/repositories/post_repo_impl.dart
import 'package:dartz/dartz.dart';
import 'package:project_name/data/data_sources/api_data_source.dart';
import 'package:project_name/data/dto/post/post_dto.dart';
import 'package:project_name/domain/entities/post/post.dart';
import 'package:project_name/domain/repositories/post_repo.dart';
import 'package:project_name/utils/app_error.dart';

class PostRepoImpl implements PostRepo {
  final ApiDataSource _apiDataSource;

  PostRepoImpl(this._apiDataSource);

  @override
  Future<Either<AppError, List<Post>>> getPosts() async {
    try {
      final dtos = await _apiDataSource.getPosts();
      final posts = dtos.map((dto) => dto.toDomain()).toList();
      return Right(posts);
    } on DioException catch (e) {
      return Left(AppError(
        message: e.response?.data['message'] ?? 'Failed to fetch posts',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(AppError(message: 'Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, Post>> getPostById(int id) async {
    try {
      final dto = await _apiDataSource.getPostById(id);
      return Right(dto.toDomain());
    } on DioException catch (e) {
      return Left(AppError(
        message: e.response?.data['message'] ?? 'Failed to fetch post',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(AppError(message: 'Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, Post>> createPost(Post post) async {
    try {
      final dto = await _apiDataSource.createPost(post.toDto());
      return Right(dto.toDomain());
    } on DioException catch (e) {
      return Left(AppError(
        message: e.response?.data['message'] ?? 'Failed to create post',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(AppError(message: 'Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, Post>> updatePost(Post post) async {
    try {
      final dto = await _apiDataSource.updatePost(post.id, post.toDto());
      return Right(dto.toDomain());
    } catch (e) {
      return Left(AppError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> deletePost(int id) async {
    try {
      await _apiDataSource.deletePost(id);
      return const Right(null);
    } catch (e) {
      return Left(AppError(message: e.toString()));
    }
  }
}
```

**Key Points**:
- Use `@Injectable(as: InterfaceName)` to bind implementation to interface
- Convert DTOs to entities before returning
- Wrap all operations in try-catch
- Return `Either<AppError, T>` for all methods
- Handle different exception types (DioException, etc.)

### Step 6: Define State

Create state classes using sealed classes for the presentation layer.

**Location**: `lib/presentation/[feature_name]/cubit/[feature]_state.dart`

```dart
// lib/presentation/posts/cubit/posts_state.dart
import 'package:project_name/domain/entities/post/post.dart';

sealed class PostsState {
  const PostsState();
}

class PostsInitial extends PostsState {
  const PostsInitial();
}

class PostsLoading extends PostsState {
  const PostsLoading();
}

class PostsLoaded extends PostsState {
  final List<Post> posts;
  const PostsLoaded(this.posts);
}

class PostsError extends PostsState {
  final String message;
  const PostsError(this.message);
}
```

**For features with multiple operations**:
```dart
// lib/presentation/posts/cubit/posts_state.dart
import 'package:project_name/domain/entities/post/post.dart';

sealed class PostsState {
  const PostsState();
}

class PostsInitial extends PostsState {
  const PostsInitial();
}

// Loading states
class PostsLoading extends PostsState {
  const PostsLoading();
}

class PostsCreating extends PostsState {
  const PostsCreating();
}

class PostsUpdating extends PostsState {
  const PostsUpdating();
}

class PostsDeleting extends PostsState {
  const PostsDeleting();
}

// Success states
class PostsLoaded extends PostsState {
  final List<Post> posts;
  const PostsLoaded(this.posts);
}

class PostsCreated extends PostsState {
  final Post post;
  const PostsCreated(this.post);
}

class PostsUpdated extends PostsState {
  final Post post;
  const PostsUpdated(this.post);
}

class PostsDeleted extends PostsState {
  const PostsDeleted();
}

// Error state
class PostsError extends PostsState {
  final String message;
  const PostsError(this.message);
}
```

**Key Points**:
- Use sealed classes for exhaustive pattern matching
- Define clear states: initial, loading, success, error
- Include data in success states
- Use specific loading states for different operations if needed

### Step 7: Create Cubit/Bloc

Create state management logic using Cubit.

**Location**: `lib/presentation/[feature_name]/cubit/[feature]_cubit.dart`

```dart
// lib/presentation/posts/cubit/posts_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_name/domain/use_cases/get_posts_use_case.dart';
import 'package:project_name/domain/use_cases/create_post_use_case.dart';
import 'package:project_name/domain/use_cases/delete_post_use_case.dart';
import 'package:project_name/presentation/posts/cubit/posts_state.dart';

class PostsCubit extends Cubit<PostsState> {
  final GetPostsUseCase _getPostsUseCase;
  final CreatePostUseCase _createPostUseCase;
  final DeletePostUseCase _deletePostUseCase;

  PostsCubit(
    this._getPostsUseCase,
    this._createPostUseCase,
    this._deletePostUseCase,
  ) : super(const PostsInitial());

  Future<void> loadPosts() async {
    emit(const PostsLoading());
    
    final result = await _getPostsUseCase();
    
    result.fold(
      (error) => emit(PostsError(error.message)),
      (posts) => emit(PostsLoaded(posts)),
    );
  }

  Future<void> createPost({
    required String title,
    required String content,
    required String authorId,
  }) async {
    emit(const PostsCreating());
    
    final params = CreatePostParams(
      title: title,
      content: content,
      authorId: authorId,
    );
    
    final result = await _createPostUseCase(params);
    
    result.fold(
      (error) => emit(PostsError(error.message)),
      (post) {
        emit(PostsCreated(post));
        loadPosts(); // Refresh list
      },
    );
  }

  Future<void> deletePost(int postId) async {
    emit(const PostsDeleting());
    
    final result = await _deletePostUseCase(postId);
    
    result.fold(
      (error) => emit(PostsError(error.message)),
      (_) {
        emit(const PostsDeleted());
        loadPosts(); // Refresh list
      },
    );
  }
}
```

**Key Points**:
- Inject use cases through constructor
- Call use cases, don't implement business logic here
- Use `fold` to handle Either results
- Emit appropriate sealed class states

### Step 8: Create UI Page

Create the UI page with BLoC integration.

**Location**: `lib/presentation/[feature_name]/[feature]_page.dart`

```dart
// lib/presentation/posts/posts_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_name/presentation/posts/cubit/posts_cubit.dart';
import 'package:project_name/presentation/posts/cubit/posts_state.dart';
import 'package:project_name/presentation/posts/widgets/post_item.dart';

class PostsPage extends StatelessWidget {
  final PostsCubit cubit;

  const PostsPage({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => cubit..loadPosts(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Posts'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateDialog(context),
            ),
          ],
        ),
        body: BlocConsumer<PostsCubit, PostsState>(
          listener: (context, state) {
            switch (state) {
              case PostsCreated(:final post):
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post created successfully')),
                );
              case PostsDeleted():
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted successfully')),
                );
              case PostsError(:final message):
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $message'),
                    backgroundColor: Colors.red,
                  ),
                );
              default:
                break;
            }
          },
          builder: (context, state) {
            return switch (state) {
              PostsInitial() => const SizedBox(),
              PostsLoading() || PostsCreating() || PostsUpdating() || PostsDeleting() => 
                const Center(child: CircularProgressIndicator()),
              PostsLoaded(:final posts) => posts.isEmpty
                ? const Center(child: Text('No posts found'))
                : ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return PostItem(
                        post: posts[index],
                        onDelete: () {
                          context.read<PostsCubit>().deletePost(posts[index].id);
                        },
                      );
                    },
                  ),
              PostsCreated() || PostsUpdated() || PostsDeleted() => 
                const Center(child: CircularProgressIndicator()),
              PostsError(:final message) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $message'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<PostsCubit>().loadPosts();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            };
          },
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<PostsCubit>().createPost(
                    title: titleController.text,
                    content: contentController.text,
                    authorId: 'current-user-id', // Get from auth
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
```

**Key Points**:
- Use `BlocProvider` to provide Cubit
- Pass Cubit via constructor for dependency injection
- Call initial data loading in provider creation
- Use `BlocBuilder` for UI updates
- Use `BlocListener` for side effects (snackbars, navigation)
- Use `BlocConsumer` when you need both
- Use pattern matching with `switch` to handle all sealed class states exhaustively

### Step 9: Verify Manual Implementations

Review your manual implementations:

```bash
# Run static analysis
flutter analyze

# Run tests
flutter test

# Format code
flutter format .
```

**Checklist**:
- [ ] All entities have `copyWith`, equality operators, and `hashCode`
- [ ] All DTOs have manual `fromJson` and `toJson` methods
- [ ] All sealed state classes are defined with subclasses
- [ ] No code generation annotations remain (`@freezed`, `@injectable`, etc.)
- [ ] All dependencies use constructor injection

### Step 10: Register Dependencies Manually

Create a simple service locator or use manual instantiation:

**Option 1: Simple Service Locator**:
```dart
// lib/core/service_locator.dart
import 'package:dio/dio.dart';
import 'package:project_name/data/data_sources/api_data_source.dart';
import 'package:project_name/data/repositories/post_repo_impl.dart';
import 'package:project_name/domain/repositories/post_repo.dart';
import 'package:project_name/domain/use_cases/get_posts_use_case.dart';
import 'package:project_name/domain/use_cases/create_post_use_case.dart';
import 'package:project_name/domain/use_cases/delete_post_use_case.dart';
import 'package:project_name/presentation/posts/cubit/posts_cubit.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Singletons
  late final Dio _dio;
  late final ApiDataSource _apiDataSource;
  late final PostRepo _postRepo;

  void init() {
    _dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    _apiDataSource = ApiDataSource(_dio);
    _postRepo = PostRepoImpl(_apiDataSource);
  }

  // Factories
  PostsCubit createPostsCubit() {
    return PostsCubit(
      GetPostsUseCase(_postRepo),
      CreatePostUseCase(_postRepo),
      DeletePostUseCase(_postRepo),
    );
  }
}

// Initialize in main.dart
void main() {
  ServiceLocator().init();
  runApp(const MyApp());
}
```

**Option 2: Direct Constructor Injection**:
```dart
// Pass dependencies directly when creating widgets
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create dependencies
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final apiDataSource = ApiDataSource(dio);
    final postRepo = PostRepoImpl(apiDataSource);
    
    final postsCubit = PostsCubit(
      GetPostsUseCase(postRepo),
      CreatePostUseCase(postRepo),
      DeletePostUseCase(postRepo),
    );

    return MaterialApp(
      home: PostsPage(cubit: postsCubit),
    );
  }
}
```

## Complete Example

See a complete feature implementation:

**Domain Layer**:
- ✅ `lib/domain/entities/post/post.dart`
- ✅ `lib/domain/repositories/post_repo.dart`
- ✅ `lib/domain/use_cases/get_posts_use_case.dart`
- ✅ `lib/domain/use_cases/create_post_use_case.dart`

**Data Layer**:
- ✅ `lib/data/dto/post/post_dto.dart`
- ✅ `lib/data/repositories/post_repo_impl.dart`

**Presentation Layer**:
- ✅ `lib/presentation/posts/cubit/posts_state.dart`
- ✅ `lib/presentation/posts/cubit/posts_cubit.dart`
- ✅ `lib/presentation/posts/posts_page.dart`

## Checklist

Use this checklist when creating a new feature:

### Domain Layer
- [ ] Create entity in `domain/entities/[feature_name]/`
- [ ] Implement `copyWith` method for immutability
- [ ] Implement equality operators (`==` and `hashCode`)
- [ ] Define repository interface in `domain/repositories/`
- [ ] Create use case(s) in `domain/use_cases/`
- [ ] Ensure no Flutter/external dependencies
- [ ] Use constructor injection for dependencies

### Data Layer
- [ ] Create DTO in `data/dto/[feature_name]/`
- [ ] Implement manual `fromJson` factory method
- [ ] Implement manual `toJson` method
- [ ] Create `toDomain()` extension
- [ ] Create `toDto()` extension (if needed)
- [ ] Implement repository in `data/repositories/`
- [ ] Use constructor injection for data sources
- [ ] Handle errors with Either
- [ ] Add data source methods if needed

### Presentation Layer
- [ ] Define sealed state class in `presentation/[feature]/cubit/[feature]_state.dart`
- [ ] Create state subclasses for each state (Initial, Loading, Loaded, Error, etc.)
- [ ] Create Cubit in `presentation/[feature]/cubit/[feature]_cubit.dart`
- [ ] Use constructor injection for use cases (not repositories)
- [ ] Create page in `presentation/[feature]/[feature]_page.dart`
- [ ] Use BlocProvider to provide Cubit
- [ ] Handle all state cases in UI with pattern matching
- [ ] Add error handling and loading states

### Manual Implementation Verification
- [ ] Run `flutter analyze` - no errors
- [ ] Verify all entities have complete implementations
- [ ] Verify all DTOs have JSON methods
- [ ] Verify all states use sealed classes
- [ ] Register dependencies in service locator or use constructor injection

### Testing
- [ ] Test use cases
- [ ] Test repository implementations
- [ ] Test Cubit logic
- [ ] Run app and verify feature works

## Tips

1. **Start with Domain**: Always start with entities and repository interfaces
2. **One Use Case, One Responsibility**: Don't create god use cases
3. **Keep Domain Pure**: No Flutter imports in domain layer
4. **Map at Boundaries**: Convert DTO ↔ Entity at repository level
5. **Error Handling**: Always use Either for operations that can fail
6. **Manual Implementations**: Implement copyWith, equality operators, fromJson/toJson manually
7. **State Management**: Use sealed classes with pattern matching
8. **Constructor Injection**: Pass all dependencies through constructors

## Common Mistakes to Avoid

1. ❌ Importing data layer in domain layer
2. ❌ Putting business logic in Cubit/Bloc
3. ❌ Using DTOs in domain layer
4. ❌ Injecting repositories directly into Cubit (use use cases)
5. ❌ Not handling all state cases in UI
6. ❌ Forgetting to implement copyWith or equality operators
7. ❌ Missing fromJson or toJson in DTOs
8. ❌ Not using Either for error handling
9. ❌ Using mutable fields in entities
10. ❌ Not using sealed classes for states

---

**Remember**: Clean Architecture is about separation of concerns. Each layer has its responsibility, and dependencies always point inward.