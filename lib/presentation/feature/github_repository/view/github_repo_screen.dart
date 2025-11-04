import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:junie_ai_test/di/di_module.dart';
import 'package:junie_ai_test/presentation/common/widgets/error_retry_widget.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/components/github_repo_list.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/components/github_repo_search_bar.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/cubit/github_repo_cubit.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/cubit/github_repo_state.dart';

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
        body: BlocBuilder<GithubRepoCubit, GithubRepoState>(
          builder: (context, state) {
            if (state.error != null) {
              return ErrorRetryWidget(
                error: state.error ?? '',
                onTapRetry: () =>
                    context.read<GithubRepoCubit>().loadRepositories(),
              );
            }

            return const Column(
              children: [
                GithubRepoSearchBar(),
                Expanded(child: GithubRepoList()),
              ],
            );
          },
        ),
      ),
    );
  }
}
