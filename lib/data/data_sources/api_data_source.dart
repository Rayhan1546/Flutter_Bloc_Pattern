import 'package:dio/dio.dart';
import 'package:junie_ai_test/data/dto/github_repository/github_repository_dto.dart';

class ApiDataSource {
  final Dio _dio;

  ApiDataSource(this._dio);

  Future<List<GithubRepositoryDto>> getRepositories() async {
    final response = await _dio.get('https://api.github.com/repositories');
    return (response.data as List)
        .map((json) => GithubRepositoryDto.fromJson(json))
        .toList();
  }
}
