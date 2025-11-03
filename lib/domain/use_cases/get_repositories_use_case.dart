import 'package:dartz/dartz.dart';
import 'package:junie_ai_test/core/utils/app_error.dart';
import 'package:junie_ai_test/domain/entities/github_repository/github_repository.dart';
import 'package:junie_ai_test/domain/repositories/github_repo.dart';

class GetRepositoriesUseCase {
  final GithubRepo _githubRepo;

  GetRepositoriesUseCase(this._githubRepo);

  Future<Either<AppError, List<GithubRepository>>> call() async {
    return await _githubRepo.getRepositories();
  }
}
