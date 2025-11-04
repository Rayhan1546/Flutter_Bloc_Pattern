import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/cubit/github_repo_cubit.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/cubit/github_repo_state.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/widgets/repository_item.dart';

class GithubRepoList extends StatelessWidget {
  const GithubRepoList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GithubRepoCubit, GithubRepoState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.filteredRepositories.isEmpty) {
          return const Center(child: Text("No Repository to show"));
        }

        return ListView.builder(
          itemCount: state.filteredRepositories.length,
          itemBuilder: (context, index) {
            final repository = state.filteredRepositories[index];
            return RepositoryItem(repository: repository);
          },
        );
      },
    );
  }
}
