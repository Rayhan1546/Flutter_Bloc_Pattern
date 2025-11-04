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
