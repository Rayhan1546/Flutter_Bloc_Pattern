import 'package:junie_ai_test/data/dto/github_repository/github_repository_dto.dart';

/// Abstract API service for GitHub endpoints
/// Defines contracts for all GitHub API operations
abstract class GithubApiService {
  /// Fetches list of repositories from GitHub API
  ///
  /// Returns a list of [GithubRepositoryDto] from the API response
  /// Throws [DioException] on network errors
  Future<List<GithubRepositoryDto>> getRepositories();

  /// Fetches a specific repository by ID
  ///
  /// [repoId] The repository ID
  /// Returns a single [GithubRepositoryDto]
  /// Throws [DioException] on network errors
  Future<GithubRepositoryDto> getRepositoryById(int repoId);

  /// Searches repositories by query
  ///
  /// [query] The search query
  /// [page] Page number for pagination (optional)
  /// [perPage] Number of results per page (optional)
  /// Returns a list of [GithubRepositoryDto] matching the query
  /// Throws [DioException] on network errors
  Future<List<GithubRepositoryDto>> searchRepositories({
    required String query,
    int? page,
    int? perPage,
  });

  /// Fetches user repositories
  ///
  /// [username] The GitHub username
  /// Returns a list of [GithubRepositoryDto] owned by the user
  /// Throws [DioException] on network errors
  Future<List<GithubRepositoryDto>> getUserRepositories(String username);
}
