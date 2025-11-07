import 'dart:typed_data';
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
import 'package:junie_ai_test/data/data_sources/local/local_key_value_store.dart';
import 'package:junie_ai_test/data/data_sources/local/hive/hive_local_key_value_store.dart';
import 'package:junie_ai_test/data/data_sources/local/hive/github_repo_cache.dart';
import 'package:junie_ai_test/core/utils/encryption_key_provider.dart';
import 'package:junie_ai_test/data/data_sources/local/token_local_data_source.dart';

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

    // Register GitHub repos cache
    sl.registerSingleton<GithubRepoCache>(
      GithubRepoCache(sl.get<LocalKeyValueStore>()),
    );

    // Register GithubRepo implementation as singleton
    sl.registerSingleton<GithubRepository>(
      GithubRepositoryImpl(
        sl.get<GithubApiService>(),
        sl.get<GithubRepoCache>(),
      ),
    );
  }
}

/// Local storage module - registers Hive key-value store
class LocalModule implements DIModule {
  @override
  Future<void> register() async {
    final store = HiveLocalKeyValueStore();
    await store.init();

    // Set AES-256 encryption key via provider (placeholder strategy)
    // IMPORTANT: Replace StaticEncryptionKeyProvider with a secure key source
    final keyProvider = StaticEncryptionKeyProvider(Uint8List(32));
    final key = await keyProvider.getKey();
    await store.setEncryptionKey(key);

    sl.registerSingleton<LocalKeyValueStore>(store);

    // Token data source (uses encrypted storage by default)
    sl.registerSingleton<TokenLocalDataSource>(
      TokenLocalDataSource(sl.get<LocalKeyValueStore>()),
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
