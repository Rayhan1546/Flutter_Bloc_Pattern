import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:junie_ai_test/data/data_sources/api_data_source.dart';
import 'package:junie_ai_test/data/repositories/github_repo_impl.dart';
import 'package:junie_ai_test/domain/repositories/github_repo.dart';
import 'package:junie_ai_test/domain/use_cases/get_repositories_use_case.dart';
import 'package:junie_ai_test/presentation/github_repository/cubit/github_repo_cubit.dart';
import 'package:junie_ai_test/presentation/github_repository/github_repo_screen.dart';

// Global instances for dependency injection
late Dio dio;
late ApiDataSource apiDataSource;
late GithubRepo githubRepo;
late GetRepositoriesUseCase getRepositoriesUseCase;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const MyApp());
}

Future<void> setupDependencies() async {
  // Initialize Dio
  dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Initialize data sources
  apiDataSource = ApiDataSource(dio);

  // Initialize repositories
  githubRepo = GithubRepoImpl(apiDataSource);

  // Initialize use cases
  getRepositoriesUseCase = GetRepositoriesUseCase(githubRepo);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Repos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: GithubRepoScreen(cubit: GithubRepoCubit(getRepositoriesUseCase)),
    );
  }
}
