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
        final repositoriesState = state.repositoriesState;

        if (repositoriesState is AsyncLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (repositoriesState is AsyncError) {
          final message = (repositoriesState as AsyncError).message;

          return ErrorRetryWidget(
            error: message,
            onTapRetry: () => cubit.loadRepositories(),
          );
        }

        if (repositoriesState is AsyncSuccess<List<GithubRepo>>) {
          final data = repositoriesState.data;

          if (data.isEmpty) {
            return const Center(child: Text("No Repository to show"));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final repository = data[index];
              return RepositoryItem(repository: repository);
            },
          );
        }

        return SizedBox.shrink();
      },
    );
  }
}
