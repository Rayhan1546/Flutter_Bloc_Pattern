import 'package:junie_ai_test/core/utils/result.dart';
import 'package:junie_ai_test/domain/entities/github_repository/github_repository.dart';

abstract class GithubRepo {
  Future<Result<List<GithubRepository>>> getRepositories();
}
