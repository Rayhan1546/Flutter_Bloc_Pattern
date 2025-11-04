import 'package:junie_ai_test/domain/entities/github_repository/github_repository.dart';

class GithubRepoState {
  final bool isLoading;
  final List<GithubRepo> repositories;
  final List<GithubRepo> filteredRepositories;
  final String? error;

  GithubRepoState({
    required this.isLoading,
    required this.repositories,
    required this.filteredRepositories,
    this.error,
  });

  GithubRepoState.initial()
    : this(
        isLoading: false,
        repositories: [],
        filteredRepositories: [],
        error: null,
      );

  GithubRepoState copyWith({
    bool? isLoading,
    List<GithubRepo>? repositories,
    List<GithubRepo>? filteredRepositories,
    String? Function()? error,
  }) {
    return GithubRepoState(
      isLoading: isLoading ?? this.isLoading,
      repositories: repositories ?? this.repositories,
      filteredRepositories: filteredRepositories ?? this.filteredRepositories,
      error: error != null ? error() : this.error,
    );
  }
}
