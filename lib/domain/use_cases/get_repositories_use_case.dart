import 'package:junie_ai_test/core/utils/result.dart';
import 'package:junie_ai_test/domain/entities/github_repository/github_repository.dart';
import 'package:junie_ai_test/domain/repositories/github_repository.dart';

class GetRepositoriesUseCase {
  final GithubRepository _githubRepo;

  GetRepositoriesUseCase(this._githubRepo);

  Future<Result<List<GithubRepo>>> call() async {
    return await _githubRepo.getRepositories();
  }
}
