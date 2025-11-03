import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:junie_ai_test/presentation/github_repository/cubit/github_repo_cubit.dart';
import 'package:junie_ai_test/presentation/github_repository/cubit/github_repo_state.dart';
import 'package:junie_ai_test/presentation/github_repository/widgets/repository_item.dart';

class GithubRepoScreen extends StatefulWidget {
  final GithubRepoCubit cubit;

  const GithubRepoScreen({super.key, required this.cubit});

  @override
  State<GithubRepoScreen> createState() => _GithubRepoScreenState();
}

class _GithubRepoScreenState extends State<GithubRepoScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.cubit.loadRepositories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GitHub Repositories'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search repositories...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            widget.cubit.searchRepositories('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (query) {
                  setState(() {});
                  widget.cubit.searchRepositories(query);
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<GithubRepoCubit, GithubRepoState>(
                builder: (context, state) {
                  return switch (state) {
                    GithubRepoInitial() => const Center(
                      child: Text('Initialize'),
                    ),
                    GithubRepoLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    GithubRepoLoaded(:final filteredRepositories) =>
                      filteredRepositories.isEmpty
                          ? const Center(
                              child: Text(
                                'No repositories found',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredRepositories.length,
                              itemBuilder: (context, index) {
                                final repository = filteredRepositories[index];
                                return RepositoryItem(repository: repository);
                              },
                            ),
                    GithubRepoError(:final message) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => widget.cubit.loadRepositories(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
