import 'package:junie_ai_test/core/utils/result.dart';
import 'package:junie_ai_test/domain/entities/github_repository/github_repository.dart';
import 'package:junie_ai_test/domain/repositories/github_repo.dart';

class GetRepositoriesUseCase {
  final GithubRepo _githubRepo;

  GetRepositoriesUseCase(this._githubRepo);

  Future<Result<List<GithubRepository>>> call() async {
    return await _githubRepo.getRepositories();
  }
}
