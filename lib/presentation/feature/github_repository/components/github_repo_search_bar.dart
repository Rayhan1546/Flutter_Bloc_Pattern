import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/cubit/github_repo_cubit.dart';

class GithubRepoSearchBar extends StatelessWidget {
  const GithubRepoSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GithubRepoCubit>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search repositories...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (query) => cubit.searchRepositories(query),
      ),
    );
  }
}
