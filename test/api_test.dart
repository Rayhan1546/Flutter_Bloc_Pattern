import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:junie_ai_test/data/data_sources/api_data_source.dart';
import 'package:junie_ai_test/data/repositories/github_repo_impl.dart';

void main() {
  test('Fetch GitHub repositories from API', () async {
    // Arrange
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    final apiDataSource = ApiDataSource(dio);
    final repository = GithubRepoImpl(apiDataSource);

    // Act
    final result = await repository.getRepositories();

    // Assert
    result.fold(
      (error) => fail('Expected success but got error: ${error.message}'),
      (repositories) {
        expect(repositories, isNotEmpty);
        expect(repositories.first.id, isNotNull);
        expect(repositories.first.name, isNotEmpty);
        expect(repositories.first.owner.login, isNotEmpty);
      },
    );
  });
}
