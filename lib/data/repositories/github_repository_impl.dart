import 'package:dio/dio.dart';
import 'package:junie_ai_test/core/utils/app_error.dart';
import 'package:junie_ai_test/core/utils/result.dart';
import 'package:junie_ai_test/data/data_sources/local/hive/github_repo_cache.dart';
import 'package:junie_ai_test/data/data_sources/mock_data/github_repo_mock_data.dart';
import 'package:junie_ai_test/data/data_sources/remote/api_service/github_api_service.dart';
import 'package:junie_ai_test/data/dto/github_repository/github_repository_dto.dart';
import 'package:junie_ai_test/domain/entities/github_repository/github_repository.dart';
import 'package:junie_ai_test/domain/repositories/github_repository.dart';

class GithubRepositoryImpl implements GithubRepository {
  final GithubApiService _githubApiService;
  final GithubRepoCache _cache;

  GithubRepositoryImpl(this._githubApiService, this._cache);

  @override
  Future<Result<List<GithubRepo>>> getRepositories() async {
    // return Success(GithubRepoMockData.getMockData());
    try {
      final dtos = await _githubApiService.getRepositories();
      // Persist to local cache for offline-first
      await _cache.save(dtos);
      final repositories = dtos.map((dto) => dto.toDomain()).toList();
      return Success(repositories);
    } on DioException catch (e) {
      // Fallback to cached data on network error
      final cached = _cache.get();
      if (cached.isNotEmpty) {
        final repos = cached.map((dto) => dto.toDomain()).toList();
        return Success(repos);
      }
      return Error(_handleDioError(e));
    } catch (e) {
      return Error(AppError(message: 'Unexpected error: ${e.toString()}'));
    }
  }

  AppError _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError(
          message: 'Connection timeout. Please check your internet.',
          statusCode: 408,
        );
      case DioExceptionType.badResponse:
        return AppError(
          message: error.response?.data['message'] ?? 'Server error',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return AppError(message: 'Request cancelled');
      case DioExceptionType.connectionError:
        return AppError(message: 'No internet connection');
      default:
        return AppError(message: error.message ?? 'Unknown error');
    }
  }
}
