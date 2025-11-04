import 'package:dio/dio.dart';
import 'package:junie_ai_test/data/data_sources/remote/api_client/api_client.dart';
import 'package:junie_ai_test/data/data_sources/remote/api_client/github_api_client.dart';
import 'package:junie_ai_test/data/data_sources/remote/api_service/github_api_service.dart';
import 'package:junie_ai_test/data/data_sources/remote/api_service/github_api_service_impl.dart';
import 'package:junie_ai_test/data/repositories/github_repository_impl.dart';
import 'package:junie_ai_test/domain/repositories/github_repository.dart';
import 'package:junie_ai_test/domain/use_cases/get_repositories_use_case.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/cubit/github_repo_cubit.dart';
import 'package:junie_ai_test/di/service_locator.dart';

/// Global service locator instance
final sl = ServiceLocator();

/// Base module interface for dependency registration
abstract class DIModule {
  Future<void> register();
}

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
    // Register API clients
    sl.registerSingleton<ApiClient>(GithubApiClient(sl.get<Dio>()));

    // Register remote API services
    sl.registerSingleton<GithubApiService>(
      GithubApiServiceImpl(sl.get<ApiClient>()),
    );

    // Register GithubRepo implementation as singleton
    sl.registerSingleton<GithubRepository>(
      GithubRepositoryImpl(sl.get<GithubApiService>()),
    );
  }
}

/// Domain module - registers use cases
class DomainModule implements DIModule {
  @override
  Future<void> register() async {
    // Register GetRepositoriesUseCase as singleton
    sl.registerSingleton<GetRepositoriesUseCase>(
      GetRepositoriesUseCase(sl.get<GithubRepository>()),
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
