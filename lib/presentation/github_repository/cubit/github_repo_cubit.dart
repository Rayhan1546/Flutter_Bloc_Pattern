import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:junie_ai_test/domain/use_cases/get_repositories_use_case.dart';
import 'package:junie_ai_test/presentation/github_repository/cubit/github_repo_state.dart';

class GithubRepoCubit extends Cubit<GithubRepoState> {
  final GetRepositoriesUseCase _getRepositoriesUseCase;

  GithubRepoCubit(this._getRepositoriesUseCase)
      : super(const GithubRepoInitial());

  Future<void> loadRepositories() async {
    emit(const GithubRepoLoading());

    final result = await _getRepositoriesUseCase();

    result.fold(
      (error) => emit(GithubRepoError(error.message)),
      (repositories) => emit(GithubRepoLoaded(
        repositories: repositories,
        filteredRepositories: repositories,
      )),
    );
  }

  void searchRepositories(String query) {
    final currentState = state;
    if (currentState is GithubRepoLoaded) {
      if (query.isEmpty) {
        emit(GithubRepoLoaded(
          repositories: currentState.repositories,
          filteredRepositories: currentState.repositories,
        ));
      } else {
        final filtered = currentState.repositories
            .where((repo) =>
                repo.name.toLowerCase().contains(query.toLowerCase()) ||
                repo.fullName.toLowerCase().contains(query.toLowerCase()) ||
                (repo.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
        emit(GithubRepoLoaded(
          repositories: currentState.repositories,
          filteredRepositories: filtered,
        ));
      }
    }
  }
}
