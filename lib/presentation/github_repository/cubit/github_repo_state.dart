import 'package:junie_ai_test/domain/entities/github_repository/github_repository.dart';

sealed class GithubRepoState {
  const GithubRepoState();
}

class GithubRepoInitial extends GithubRepoState {
  const GithubRepoInitial();
}

class GithubRepoLoading extends GithubRepoState {
  const GithubRepoLoading();
}

class GithubRepoLoaded extends GithubRepoState {
  final List<GithubRepository> repositories;
  final List<GithubRepository> filteredRepositories;

  const GithubRepoLoaded({
    required this.repositories,
    required this.filteredRepositories,
  });
}

class GithubRepoError extends GithubRepoState {
  final String message;

  const GithubRepoError(this.message);
}
