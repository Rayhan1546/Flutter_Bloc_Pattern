import 'package:junie_ai_test/data/data_sources/remote/api_client/api_client.dart';
import 'package:junie_ai_test/data/data_sources/remote/api_service/github_api_service.dart';
import 'package:junie_ai_test/data/dto/github_repository/github_repository_dto.dart';

/// Implementation of GitHub API service
/// Handles all HTTP requests using ApiClient abstraction
class GithubApiServiceImpl implements GithubApiService {
  final ApiClient _apiClient;

  GithubApiServiceImpl(this._apiClient);

  @override
  Future<List<GithubRepositoryDto>> getRepositories() async {
    final response = await _apiClient.get<List<dynamic>>('repositories');
    return response.map((json) => GithubRepositoryDto.fromJson(json)).toList();
  }

  @override
  Future<GithubRepositoryDto> getRepositoryById(int repoId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      'repositories/$repoId',
    );
    return GithubRepositoryDto.fromJson(response);
  }

  @override
  Future<List<GithubRepositoryDto>> searchRepositories({
    required String query,
    int? page,
    int? perPage,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      'search/repositories',
      queryParameters: {
        'q': query,
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
      },
    );

    final items = response['items'] as List;
    return items.map((json) => GithubRepositoryDto.fromJson(json)).toList();
  }

  @override
  Future<List<GithubRepositoryDto>> getUserRepositories(String username) async {
    final response = await _apiClient.get<List<dynamic>>(
      'users/$username/repos',
    );
    return response.map((json) => GithubRepositoryDto.fromJson(json)).toList();
  }
}
