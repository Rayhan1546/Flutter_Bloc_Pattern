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
      return repo.name.toLowerCase().contains(query.toLowerCase()) ||
          repo.fullName.toLowerCase().contains(query.toLowerCase()) ||
          (repo.description?.toLowerCase().contains(query.toLowerCase()) ??
              false);
    }).toList();

    emit(state.copyWith(repositoriesState: AsyncSuccess(filtered)));
  }
}
