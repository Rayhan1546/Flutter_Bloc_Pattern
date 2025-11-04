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
