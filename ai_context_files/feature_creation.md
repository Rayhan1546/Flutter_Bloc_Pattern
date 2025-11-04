# Feature Creation Guide

This guide explains how to create new features following your project's Clean Architecture patterns and coding style.

## Overview

Your project follows a **Clean Architecture** pattern with clear separation between layers:
- **Domain Layer**: Business logic, entities, and use cases
- **Data Layer**: API clients, DTOs, and repository implementations  
- **Presentation Layer**: UI components, state management (Cubits), and screens
- **Core Layer**: Shared utilities, error handling, and state patterns

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

## Key UI Component Patterns

### 1. AsyncState Switch Expression Benefits

Your switch expression pattern provides:
- **Exhaustive handling**: All states must be handled
- **Type safety**: Pattern matching with type inference
- **Clean separation**: Each state has its own UI branch
- **Empty state handling**: Built-in support for empty data scenarios

### 2. Component Architecture Benefits

- **Separation of concerns**: List logic separate from item rendering
- **Reusability**: Components can be used in multiple contexts
- **Testability**: Each component can be tested in isolation
- **Maintainability**: Changes to list logic don't affect item rendering

### 3. Error Handling Pattern

The `ErrorRetryWidget` provides:
- **Consistent error display**: Same error UI across features
- **Retry functionality**: Built-in retry mechanism
- **User-friendly messages**: Clear error communication

### 4. Empty State Pattern

Built-in handling for empty data:
```dart
AsyncSuccess<List<Post>>(:final data) when data.isEmpty =>
  const Center(child: Text("No posts to show")),
```

This ensures users see helpful messages when there's no data to display.

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
import 'package:project_name/core/utils/result.dart';
import 'package:project_name/domain/entities/post/post.dart';

abstract class PostRepo {
  Future<Result<List<Post>>> getPosts();
  Future<Result<Post>> getPostById(int id);
  Future<Result<Post>> createPost(Post post);
  Future<Result<Post>> updatePost(Post post);
  Future<Result<void>> deletePost(int id);
}
```

**Key Points**:
- Use `Result<T>` for error handling (Success or Error)
- Define all operations for this feature
- Abstract class (no implementation)
- Only use domain entities, never DTOs

### Step 3: Create Use Cases

Create individual use cases for each business operation.

**Location**: `lib/domain/use_cases/[action]_use_case.dart`

**Use Case Base Classes** (if not already created):
```dart
// lib/domain/utils/use_case.dart
import 'package:project_name/core/utils/result.dart';

abstract class UseCase<T, S> {
  Future<Result<T>> call(S param);
}

abstract class NoParamUseCase<T> {
  Future<Result<T>> call();
}
```

**Example - Get Posts Use Case**:
```dart
// lib/domain/use_cases/get_posts_use_case.dart
import 'package:project_name/core/utils/result.dart';
import 'package:project_name/domain/entities/post/post.dart';
import 'package:project_name/domain/repositories/post_repo.dart';
import 'package:project_name/domain/utils/use_case.dart';

class GetPostsUseCase implements NoParamUseCase<List<Post>> {
  final PostRepo _postRepo;

  GetPostsUseCase(this._postRepo);

  @override
  Future<Result<List<Post>>> call() {
    return _postRepo.getPosts();
  }
}
```

**Example - Create Post Use Case (with parameters)**:
```dart
// lib/domain/use_cases/create_post_use_case.dart
import 'package:project_name/core/utils/result.dart';
import 'package:project_name/domain/entities/post/post.dart';
import 'package:project_name/domain/repositories/post_repo.dart';
import 'package:project_name/domain/utils/use_case.dart';

class CreatePostUseCase implements UseCase<Post, CreatePostParams> {
  final PostRepo _postRepo;

  CreatePostUseCase(this._postRepo);

  @override
  Future<Result<Post>> call(CreatePostParams params) {
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
import 'package:dio/dio.dart';
import 'package:project_name/core/utils/app_error.dart';
import 'package:project_name/core/utils/result.dart';
import 'package:project_name/data/data_sources/api_data_source.dart';
import 'package:project_name/data/dto/post/post_dto.dart';
import 'package:project_name/domain/entities/post/post.dart';
import 'package:project_name/domain/repositories/post_repo.dart';

class PostRepoImpl implements PostRepo {
  final ApiDataSource _apiDataSource;

  PostRepoImpl(this._apiDataSource);

  @override
  Future<Result<List<Post>>> getPosts() async {
    try {
      final dtos = await _apiDataSource.getPosts();
      final posts = dtos.map((dto) => dto.toDomain()).toList();
      return Success(posts);
    } on DioException catch (e) {
      return Error(AppError(
        message: e.response?.data['message'] ?? 'Failed to fetch posts',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Error(AppError(message: 'Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Post>> getPostById(int id) async {
    try {
      final dto = await _apiDataSource.getPostById(id);
      return Success(dto.toDomain());
    } on DioException catch (e) {
      return Error(AppError(
        message: e.response?.data['message'] ?? 'Failed to fetch post',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Error(AppError(message: 'Unexpected error: ${e.toString()}'));
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
    } catch (e) {
      return Error(AppError(message: 'Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Post>> updatePost(Post post) async {
    try {
      final dto = await _apiDataSource.updatePost(post.id, post.toDto());
      return Success(dto.toDomain());
    } catch (e) {
      return Error(AppError(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deletePost(int id) async {
    try {
      await _apiDataSource.deletePost(id);
      return const Success(null);
    } catch (e) {
      return Error(AppError(message: e.toString()));
    }
  }
}
```

**Key Points**:
- Use constructor injection for dependencies
- Convert DTOs to entities before returning
- Wrap all operations in try-catch
- Return `Result<T>` for all methods (Success or Error)
- Handle different exception types (DioException, etc.)

### Step 6: Define State with Switch Expressions

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

### Step 7: Create Cubit/Bloc with Pattern Matching

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
    
    switch (result) {
      case Success(:final data):
        emit(PostsLoaded(data));
      case Error(:final error):
        emit(PostsError(error.message));
    }
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
    
    switch (result) {
      case Success(:final data):
        emit(PostsCreated(data));
        loadPosts(); // Refresh list
      case Error(:final error):
        emit(PostsError(error.message));
    }
  }

  Future<void> deletePost(int postId) async {
    emit(const PostsDeleting());
    
    final result = await _deletePostUseCase(postId);
    
    switch (result) {
      case Success():
        emit(const PostsDeleted());
        loadPosts(); // Refresh list
      case Error(:final error):
        emit(PostsError(error.message));
    }
  }
}
```

**Key Points**:
- Inject use cases through constructor
- Call use cases, don't implement business logic here
- Use pattern matching (switch) to handle Result types
- Emit appropriate sealed class states

### Step 8: Create UI Components with Switch Expressions

Create reusable UI components using modern Dart switch expressions for state handling.

#### Main List Component with AsyncState Switch Pattern

**Location**: `lib/presentation/[feature_name]/components/[feature]_list_component.dart`

```dart
// lib/presentation/posts/components/post_list_component.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_name/core/state/async_state.dart';
import 'package:project_name/domain/entities/post/post.dart';
import 'package:project_name/presentation/posts/cubit/posts_cubit.dart';
import 'package:project_name/presentation/posts/cubit/posts_state.dart';
import 'package:project_name/presentation/common/widgets/error_retry_widget.dart';
import 'package:project_name/presentation/posts/widgets/post_item_widget.dart';

class PostListComponent extends StatelessWidget {
  const PostListComponent({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PostsCubit>();

    return BlocBuilder<PostsCubit, PostsState>(
      builder: (context, state) {
        return switch (state.postsState) {
          // Loading state
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
          
          // Error state with retry
          AsyncError(:final message) => ErrorRetryWidget(
            error: message,
            onTapRetry: () => cubit.loadPosts(),
          ),
          
          // Empty data state
          AsyncSuccess<List<Post>>(:final data) when data.isEmpty =>
            const Center(child: Text("No posts to show")),
          
          // Success state with data
          AsyncSuccess<List<Post>>(:final data) => ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final post = data[index];
              return PostItemWidget(post: post);
            },
          ),
          
          // Default fallback
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}
```

#### Individual Item Widget

**Location**: `lib/presentation/[feature_name]/widgets/[feature]_item_widget.dart`

```dart
// lib/presentation/posts/widgets/post_item_widget.dart
import 'package:flutter/material.dart';
import 'package:project_name/domain/entities/post/post.dart';

class PostItemWidget extends StatelessWidget {
  final Post post;

  const PostItemWidget({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(post.authorAvatarUrl),
          radius: 24,
        ),
        title: Text(
          post.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'By ${post.authorName} • ${post.createdAtFormatted}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (post.content.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.favorite, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${post.likesCount}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(width: 12),
                Icon(Icons.comment, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${post.commentsCount}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          // Navigate to post detail
          context.push('/posts/${post.id}');
        },
      ),
    );
  }
}
```

### Step 9: Create Main UI Page

Create the main UI page that orchestrates all components.

**Location**: `lib/presentation/[feature_name]/view/[feature]_page.dart`

```dart
// lib/presentation/posts/view/posts_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_name/di/service_locator.dart';
import 'package:project_name/presentation/posts/cubit/posts_cubit.dart';
import 'package:project_name/presentation/posts/components/post_list_component.dart';
import 'package:project_name/presentation/posts/components/post_search_component.dart';

class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl.get<PostsCubit>()..loadPosts(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Posts'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // Navigate to create post
                context.push('/posts/create');
              },
            ),
          ],
        ),
        body: const Column(
          children: [
            PostSearchComponent(),
            Expanded(child: PostListComponent()),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.push('/posts/create');
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```
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
- [ ] Handle errors with Result (Success/Error)
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
5. **Error Handling**: Always use Result for operations that can fail
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
8. ❌ Not using Result for error handling
9. ❌ Using mutable fields in entities
10. ❌ Not using sealed classes for states

---

**Remember**: Clean Architecture is about separation of concerns. Each layer has its responsibility, and dependencies always point inward.