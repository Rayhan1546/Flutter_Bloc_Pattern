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
        if (state is GithubRepoInitial) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is GithubRepoLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is GithubRepoLoaded) {
          final filteredRepositories = state.filteredRepositories;
          if (filteredRepositories.isEmpty) {
            return const Center(child: Text("No Repository to show"));
          }
          return Expanded(
            child: ListView.builder(
              itemCount: filteredRepositories.length,
              itemBuilder: (context, index) {
                final repository = filteredRepositories[index];
                return RepositoryItem(repository: repository);
              },
            ),
          );
        } else if (state is GithubRepoError) {
          return Center(
            child: Text(
              'Error: ${state.message}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
