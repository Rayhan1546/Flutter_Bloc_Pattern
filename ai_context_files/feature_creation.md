# Feature Creation Guide

This guide explains how to create new features following the project's Clean Architecture patterns and coding style, as exemplified by the `github_repository` feature.

## Overview

The project follows a **Clean Architecture** pattern with a clear separation of layers:

- **Domain Layer**: Contains the core business logic, entities, and use cases. It is pure Dart and has no dependencies on other layers.
- **Data Layer**: Implements the repository interfaces defined in the domain layer and handles data fetching from external sources (API, local database, etc.).
- **Presentation Layer**: Contains the UI and state management logic (Cubits). It depends on the domain layer to access business logic.
- **Core Layer**: Provides shared utilities, such as state management helpers (`AsyncState`), error handling (`Result`), and extensions.

**Dependency Rule**: Dependencies must always point inward, from the outer layers (Presentation, Data) to the inner layer (Domain).

**Flow**: UI (Screen) → Cubit → Use Case → Repository Interface → Repository Implementation → Data Source

## Directory Structure

A new feature should follow this directory structure:

```
lib/
├── core/
│   ├── state/
│   │   └── async_state.dart
│   └── utils/
│       └── result.dart
├── data/
│   ├── data_sources/
│   │   └── [feature_name]_remote_data_source.dart
│   ├── dto/
│   │   └── [feature_name]/
│   │       └── [entity_name]_dto.dart
│   └── repositories/
│       └── [feature_name]_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── [feature_name]/
│   │       ├── [entity_name].dart
│   │       └── [related_entity].dart
│   ├── repositories/
│   │   └── [feature_name]_repository.dart
│   └── use_cases/
│       └── [action]_[feature_name]_use_case.dart
└── presentation/
    └── feature/
        └── [feature_name]/
            ├── components/
            │   ├── [feature_name]_list.dart
            │   └── [feature_name]_search_bar.dart
            ├── cubit/
            │   ├── [feature_name]_cubit.dart
            │   └── [feature_name]_state.dart
            ├── view/
            │   └── [feature_name]_screen.dart
            └── widgets/
                └── [item_widget].dart
```

## Step-by-Step Guide

### 1. Domain Layer

#### a. Entities

Define the core business models. These are pure Dart classes with no Flutter dependencies.

**Example**: `lib/domain/entities/github_repository/github_repository.dart`
```dart
import 'package:junie_ai_test/domain/entities/github_repository/owner.dart';

class GithubRepo {
  final int id;
  final String nodeId;
  final String name;
  final String fullName;
  final bool private;
  final Owner owner;
  final String htmlUrl;
  final String? description;
  final bool fork;
  final String url;

  const GithubRepo({
    required this.id,
    required this.nodeId,
    required this.name,
    required this.fullName,
    required this.private,
    required this.owner,
    required this.htmlUrl,
    this.description,
    required this.fork,
    required this.url,
  });

  // copyWith, ==, and hashCode methods...
}
```

#### b. Repository Interface

Define the abstract contract for data operations in the domain layer.

**Example**: `lib/domain/repositories/github_repository.dart`
```dart
import 'package:junie_ai_test/core/utils/result.dart';
import 'package:junie_ai_test/domain/entities/github_repository/github_repository.dart';

abstract class GithubRepository {
  Future<Result<List<GithubRepo>>> getRepositories();
}
```

#### c. Use Case

Create a use case for each specific business operation.

**Example**: `lib/domain/use_cases/get_repositories_use_case.dart`
```dart
import 'package:junie_ai_test/core/utils/result.dart';
import 'package:junie_ai_test/domain/entities/github_repository/github_repository.dart';
import 'package:junie_ai_test/domain/repositories/github_repository.dart';

class GetRepositoriesUseCase {
  final GithubRepository _githubRepo;

  GetRepositoriesUseCase(this._githubRepo);

  Future<Result<List<GithubRepo>>> call() async {
    return await _githubRepo.getRepositories();
  }
}
```

### 2. Presentation Layer

#### a. State

Define the state class for the feature, using `AsyncState` to manage asynchronous operations.

**Example**: `lib/presentation/feature/github_repository/cubit/github_repo_state.dart`
```dart
import 'package:junie_ai_test/core/state/async_state.dart';
import 'package:junie_ai_test/domain/entities/github_repository/github_repository.dart';

class GithubRepoState {
  final AsyncState<List<GithubRepo>> repositoriesState;

  GithubRepoState({required this.repositoriesState});

  GithubRepoState.initial() : this(repositoriesState: AsyncInitial());

  GithubRepoState copyWith({AsyncState<List<GithubRepo>>? repositoriesState}) {
    return GithubRepoState(
      repositoriesState: repositoriesState ?? this.repositoriesState,
    );
  }
}
```

#### b. Cubit

Implement the Cubit to manage the feature's state and interact with use cases.

**Example**: `lib/presentation/feature/github_repository/cubit/github_repo_cubit.dart`
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:junie_ai_test/core/state/async_state.dart';
import 'package:junie_ai_test/core/utils/result.dart';
import 'package:junie_ai_test/domain/entities/github_repository/github_repository.dart';
import 'package:junie_ai_test/domain/use_cases/get_repositories_use_case.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/cubit/github_repo_state.dart';

class GithubRepoCubit extends Cubit<GithubRepoState> {
  final GetRepositoriesUseCase _getRepositoriesUseCase;

  GithubRepoCubit(this._getRepositoriesUseCase)
    : super(GithubRepoState.initial());

  late List<GithubRepo> repositoryList = [];

  Future<void> loadRepositories() async {
    emit(state.copyWith(repositoriesState: AsyncLoading()));

    final result = await _getRepositoriesUseCase();

    switch (result) {
      case Success(:final data):
        repositoryList = data;
        emit(state.copyWith(repositoriesState: AsyncSuccess(data)));
      case Error(:final error):
        emit(state.copyWith(repositoriesState: AsyncError(error.message)));
    }
  }

  void searchRepositories(String query) {
    if (query.isEmpty) {
      emit(state.copyWith(repositoriesState: AsyncSuccess(repositoryList)));
      return;
    }

    final filtered = repositoryList.where((repo) {
      return repo.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    emit(state.copyWith(repositoriesState: AsyncSuccess(filtered)));
  }
}
```

#### c. Screen

Create the main screen for the feature, providing the `BlocProvider` and laying out the UI components.

**Example**: `lib/presentation/feature/github_repository/view/github_repo_screen.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:junie_ai_test/di/di_module.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/components/github_repo_list.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/components/github_repo_search_bar.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/cubit/github_repo_cubit.dart';

class GithubRepoScreen extends StatelessWidget {
  const GithubRepoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl.get<GithubRepoCubit>()..loadRepositories(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GitHub Repositories'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Column(
          children: [
            GithubRepoSearchBar(),
            GithubRepoList(),
          ],
        ),
      ),
    );
  }
}
```

#### d. Components

Build the UI components that make up the screen.

**Example**: `lib/presentation/feature/github_repository/components/github_repo_list.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:junie_ai_test/core/state/async_state.dart';
import 'package:junie_ai_test/domain/entities/github_repository/github_repository.dart';
import 'package:junie_ai_test/presentation/common/widgets/error_retry_widget.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/cubit/github_repo_cubit.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/cubit/github_repo_state.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/widgets/repository_item.dart';

class GithubRepoList extends StatelessWidget {
  const GithubRepoList({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GithubRepoCubit>();

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

          AsyncSuccess<List<GithubRepo>>(:final data) => Expanded(
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final repository = data[index];
                return RepositoryItem(repository: repository);
              },
            ),
          ),

          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}
```

**Example**: `lib/presentation/feature/github_repository/components/github_repo_search_bar.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/cubit/github_repo_cubit.dart';

class GithubRepoSearchBar extends StatelessWidget {
  const GithubRepoSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GithubRepoCubit>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search repositories...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (query) => cubit.searchRepositories(query),
      ),
    );
  }
}
```

#### e. Widgets

Create smaller, reusable widgets used by the components.

**Example**: `lib/presentation/feature/github_repository/widgets/repository_item.dart`
```dart
import 'package:flutter/material.dart';
import 'package:junie_ai_test/domain/entities/github_repository/github_repository.dart';

class RepositoryItem extends StatelessWidget {
  final GithubRepo repository;

  const RepositoryItem({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(repository.owner.avatarUrl),
          radius: 24,
        ),
        title: Text(
          repository.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: // ... subtitle implementation
        isThreeLine: true,
      ),
    );
  }
}
```