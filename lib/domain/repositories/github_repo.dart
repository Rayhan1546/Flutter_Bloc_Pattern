import 'package:dartz/dartz.dart';
import 'package:junie_ai_test/core/utils/app_error.dart';
import 'package:junie_ai_test/domain/entities/github_repository/github_repository.dart';

abstract class GithubRepo {
  Future<Either<AppError, List<GithubRepository>>> getRepositories();
}
