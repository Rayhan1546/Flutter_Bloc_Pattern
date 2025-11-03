import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:junie_ai_test/core/utils/app_error.dart';
import 'package:junie_ai_test/data/data_sources/api_data_source.dart';
import 'package:junie_ai_test/data/dto/github_repository/github_repository_dto.dart';
import 'package:junie_ai_test/domain/entities/github_repository/github_repository.dart';
import 'package:junie_ai_test/domain/repositories/github_repo.dart';

class GithubRepoImpl implements GithubRepo {
  final ApiDataSource _apiDataSource;

  GithubRepoImpl(this._apiDataSource);

  @override
  Future<Either<AppError, List<GithubRepository>>> getRepositories() async {
    try {
      final dtos = await _apiDataSource.getRepositories();
      final repositories = dtos.map((dto) => dto.toDomain()).toList();
      return Right(repositories);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(AppError(message: 'Unexpected error: ${e.toString()}'));
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
