import 'package:dio/dio.dart';
import 'package:junie_ai_test/data/data_sources/api_data_source.dart';
import 'package:junie_ai_test/data/repositories/github_repo_impl.dart';
import 'package:junie_ai_test/domain/repositories/github_repo.dart';
import 'package:junie_ai_test/domain/use_cases/get_repositories_use_case.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/cubit/github_repo_cubit.dart';
import 'package:junie_ai_test/di/service_locator.dart';

/// Base module interface for dependency registration
abstract class DIModule {
  Future<void> register();
}

/// Global service locator instance
final sl = ServiceLocator();

/// Network module - registers Dio and network-related dependencies
class NetworkModule implements DIModule {
  @override
  Future<void> register() async {
    // Register Dio as singleton
    sl.registerSingleton<Dio>(
      Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ),
    );
  }
}

/// Data module - registers data sources and repositories
class DataModule implements DIModule {
  @override
  Future<void> register() async {
    // Register ApiDataSource as singleton
    sl.registerSingleton<ApiDataSource>(ApiDataSource(sl.get<Dio>()));

    // Register GithubRepo implementation as singleton
    sl.registerSingleton<GithubRepo>(GithubRepoImpl(sl.get<ApiDataSource>()));
  }
}

/// Domain module - registers use cases
class DomainModule implements DIModule {
  @override
  Future<void> register() async {
    // Register GetRepositoriesUseCase as singleton
    sl.registerSingleton<GetRepositoriesUseCase>(
      GetRepositoriesUseCase(sl.get<GithubRepo>()),
    );
  }
}

/// Presentation module - registers cubits/blocs as factories
class PresentationModule implements DIModule {
  @override
  Future<void> register() async {
    // Register GithubRepoCubit as factory (new instance each time)
    sl.registerFactory<GithubRepoCubit>(
      () => GithubRepoCubit(sl.get<GetRepositoriesUseCase>()),
    );
  }
}
